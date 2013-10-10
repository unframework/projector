
window.tubularHtml = (viewModel, onRootElement) ->
  # defensive check
  throw 'must supply root element callback' if typeof onRootElement isnt 'function'

  createBroadcast = () ->
    listenerList = []

    (callback) ->
      if not callback
        # clean out listener list and safely fire the listeners
        oldListenerList = listenerList
        listenerList = null

        l() for l in oldListenerList
      else
        listenerList.push callback

  createCursor = (dom, trailer) ->
    # the state is a closure that normally returns the current context DOM, or inserts a child node if one is given
    (node) ->
      if node
        if trailer then dom.insertBefore(node, trailer) else dom.appendChild(node)
      else
        dom

  bindCurlyString = (view, curlyString, display) ->
    slices = []

    createBinding = (sliceIndex, path) ->
      binding = view.bind 'value', path.split('.'), ->
        # @todo don't fire spurious displays while constructing? this is not efficient anyway
        slices[sliceIndex] = @get 'value'
        display slices.join('')

      view.$tubularHtmlOnDestroy ->
        binding.clear()

    # parse static/dynamic string slices and create bindings along the way
    re = /{{\s*(.*?)\s*}}/g
    lastEnd = 0
    while match = re.exec(curlyString)
      if match.index > lastEnd
        slices.push curlyString.substring lastEnd, match.index

      slices.push null
      createBinding slices.length - 1, match[1]

      lastEnd = match.index + match[0].length

    if curlyString.length > lastEnd
      slices.push curlyString.substring lastEnd, curlyString.length

    # initial display
    display slices.join('')

  viewModel.element = (options...) ->
    subTemplate = null

    elementName = null
    elementId = null
    elementClassList = []

    if options.length and typeof(options[options.length - 1]) is 'function'
      subTemplate = options.pop()

    if options.length and typeof(options[0]) is 'string'
      elementName = options.shift()

      # parse #id and .class suffixes
      elementName = elementName.replace /[#.][^#.]*/g, (a) ->
        if a[0] is '#'
          elementId = a.substring(1)
        else
          elementClassList.push a.substring(1)

        '' # strip suffix from original name

    ownerDocument = if @$tubularHtmlCursor then @$tubularHtmlCursor().ownerDocument else document
    childDom = ownerDocument.createElement(elementName or 'div')

    if elementId isnt null # still trigger for empty ID string
      childDom.setAttribute 'id', elementId

    if elementClassList.length
      childDom.setAttribute 'class', elementClassList.join ' '

    # initialize root destroy broadcast
    if not @$tubularHtmlOnDestroy
      @$tubularHtmlOnDestroy = createBroadcast()

    # attribute binding
    for o in options
      for attributeName, attributeTemplate of o
        snakeCaseName = attributeName.replace /[a-z][A-Z]/g, (a) ->
          a[0] + '-' + a[1].toLowerCase()

        bindCurlyString this, attributeTemplate, (v) ->
          childDom.setAttribute snakeCaseName, v

    # if first element ever created, report it for external consumption, otherwise just append
    if @$tubularHtmlCursor
      @$tubularHtmlCursor childDom
    else
      onRootElement childDom

    if subTemplate
      @fork {
        $tubularHtmlCursor: createCursor(childDom)
      }, subTemplate

  viewModel.text = (curlyString) ->
    textNode = null

    bindCurlyString this, curlyString, (text) =>
      if textNode
        newNode = textNode.ownerDocument.createTextNode(text)
        textNode.parentNode.replaceChild(newNode, textNode)
        textNode = newNode
      else
        textNode = @$tubularHtmlCursor().ownerDocument.createTextNode(text)
        @$tubularHtmlCursor textNode

  viewModel.onClick = (path) ->
    currentDom = @$tubularHtmlCursor()
    currentInvoker = null

    binding = @bind 'invoker', path.split('.'), -> currentInvoker = @get 'invoker'
    listener = => currentInvoker()

    currentDom.addEventListener 'click', listener, false

    # clean up state
    @$tubularHtmlOnDestroy ->
      binding.clear()
      currentDom.removeEventListener 'click', listener

  viewModel.onClickToggle = (variableName) ->
    currentValue = null
    currentDom = @$tubularHtmlCursor()

    binding = @bind 'value', [ variableName ], -> currentValue = @get 'value'
    listener = => @set variableName, !currentValue

    currentDom.addEventListener 'click', listener, false

    # clean up state
    @$tubularHtmlOnDestroy ->
      binding.clear()
      currentDom.removeEventListener 'click', listener

  viewModel.when = (path, subTemplate) ->
    self = this
    currentCondition = false # default state is false
    childOnDestroy = null

    currentDom = @$tubularHtmlCursor()

    startNode = currentDom.ownerDocument.createComment('^' + path)
    endNode = currentDom.ownerDocument.createComment('$' + path)

    @$tubularHtmlCursor startNode
    @$tubularHtmlCursor endNode

    binding = @bind 'value', path.split('.'), ->
      condition = !!@get 'value' # coerce to boolean

      if currentCondition isnt condition
        if condition
          childOnDestroy = createBroadcast()

          # forking the original view-model, since this one is based around the condition model value
          self.fork {
            $tubularHtmlCursor: createCursor(currentDom, endNode)
            $tubularHtmlOnDestroy: childOnDestroy
          }, subTemplate
        else
          while startNode.nextSibling isnt endNode
            startNode.parentNode.removeChild startNode.nextSibling # @todo optimize using local vars

          childOnDestroy()

        currentCondition = condition

    # clear binding when destroying, and clean up child
    @$tubularHtmlOnDestroy ->
      binding.clear()

      if currentCondition
        childOnDestroy()

  # @todo we can't overthink the array state diff tracking logic (e.g. "item inserted" or "item removed")
  # because ultimately, that sort of event information should come from the model itself
  # e.g. to fade out a spliced-out element of a list should really involve just creating *new* "flash" DOM
  # just to show the fadeout animation instead of reusing a piece of DOM from the original list
  # doing too much guessing otherwise would trip up on cases where item content just changed and "seems" as if something
  # was removed but actually wasn't
  viewModel.each = (pathString, itemName, subTemplate) ->
    path = pathString.split '.'
    currentDom = @$tubularHtmlCursor()
    endNode = currentDom.ownerDocument.createComment('...')
    items = []

    @$tubularHtmlCursor endNode

    loopCursor = createCursor(currentDom, endNode)

    createItemSlot = (index) =>
      itemStartNode = currentDom.ownerDocument.createComment('^[]')
      itemEndNode = currentDom.ownerDocument.createComment('$[]')
      loopCursor itemStartNode
      loopCursor itemEndNode

      itemOnDestroy = null

      itemBinding = @bind itemName, path.concat([ index ]), ->
        # clear old dom
        while itemStartNode.nextSibling isnt itemEndNode
          currentDom.removeChild(itemStartNode.nextSibling)

        if itemOnDestroy
          itemOnDestroy()

        itemOnDestroy = createBroadcast()

        @fork {
          $tubularHtmlCursor: createCursor(currentDom, itemEndNode)
          $tubularHtmlOnDestroy: itemOnDestroy
        }, subTemplate

      # provide a cleanup callback
      () ->
        itemBinding.clear()

        if itemOnDestroy
          itemOnDestroy()

        # clean up DOM immediately
        while itemStartNode.nextSibling isnt itemEndNode
          currentDom.removeChild(itemStartNode.nextSibling)

        currentDom.removeChild(itemStartNode)
        currentDom.removeChild(itemEndNode)

    binding = @bind 'length', path.concat([ 'length' ]), ->
      length = @get 'length'

      # add items
      while items.length < length
        items.push createItemSlot(items.length)

      # remove items
      while items.length > length
        itemCleanup = items.pop()
        itemCleanup()

    # clear bindings when destroying, and clean up items
    @$tubularHtmlOnDestroy ->
      binding.clear()
      itemCleanup() for itemCleanup in items
