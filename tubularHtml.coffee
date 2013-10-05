
window.tubularHtml = (viewModel, onRootElement) ->
  # defensive check
  throw 'must supply root element callback' if typeof onRootElement isnt 'function'

  createState = (dom, trailer) ->
    # the state is a closure that normally returns the current context DOM, or inserts a child node if one is given
    (node) ->
      if node
        if trailer then dom.insertBefore(node, trailer) else dom.appendChild(node)
      else
        dom

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

    for o in options
      for n, v of o
        childDom.setAttribute n, v

    # if first element ever created, report it for external consumption, otherwise just append
    if @$tubularHtmlCursor
      @$tubularHtmlCursor childDom
    else
      onRootElement childDom

    if subTemplate
      @fork { $tubularHtmlCursor: createState(childDom) }, subTemplate

  viewModel.attr = (setting) ->
    for n, path of setting
      snakeCaseName = n.replace /[a-z][A-Z]/g, (a) ->
        a[0] + '-' + a[1].toLowerCase()

      @with path, (v) ->
        @$tubularHtmlCursor().setAttribute snakeCaseName, v

  viewModel.text = (setting) ->
    childDom = @$tubularHtmlCursor().ownerDocument.createTextNode(setting)
    @$tubularHtmlCursor childDom

  viewModel.onClick = (path) ->
    currentAction = null

    @$tubularHtmlCursor().addEventListener 'click', =>
      if typeof currentAction is 'function'
        @apply currentAction
    , false

    @with path, (action) ->
      # @todo a cleanup conditional?
      currentAction = action

  viewModel.when = (path, subTemplate) ->
    self = this
    currentCondition = null # not true/false to always trigger first run

    currentDom = @$tubularHtmlCursor()

    startNode = currentDom.ownerDocument.createComment('^' + path)
    endNode = currentDom.ownerDocument.createComment('$' + path)

    @$tubularHtmlCursor startNode
    @$tubularHtmlCursor endNode

    @with path, (v) ->
      condition = !!v # coerce to boolean

      if currentCondition isnt condition
        if condition
          # forking the original view-model, since this one is based around the condition model value
          self.fork { $tubularHtmlCursor: createState(currentDom, endNode) }, subTemplate
        else
          while startNode.nextSibling isnt endNode
            startNode.parentNode.removeChild startNode.nextSibling # @todo optimize using local vars

        currentCondition = condition

  # @todo we can't overthink the array state diff tracking logic (e.g. "item inserted" or "item removed")
  # because ultimately, that sort of event information should come from the model itself
  # e.g. to fade out a spliced-out element of a list should really involve just creating *new* "flash" DOM
  # just to show the fadeout animation instead of reusing a piece of DOM from the original list
  # doing too much guessing otherwise would trip up on cases where item content just changed and "seems" as if something
  # was removed but actually wasn't
  viewModel.each = (subTemplate) ->
    currentDom = @$tubularHtmlCursor()
    endNode = currentDom.ownerDocument.createComment('...')
    items = []

    @$tubularHtmlCursor endNode

    loopCursor = createState(currentDom, endNode)

    createItemSlot = (index) =>
      itemStartNode = currentDom.ownerDocument.createComment('^[]')
      itemEndNode = currentDom.ownerDocument.createComment('$[]')
      loopCursor itemStartNode
      loopCursor itemEndNode

      isRemoved = false

      @fork { $tubularHtmlCursor: createState(currentDom, itemEndNode) }, ->
        @with index, (v, unwatch) ->
          # clear old dom
          while itemStartNode.nextSibling isnt itemEndNode
            currentDom.removeChild(itemStartNode.nextSibling)

          if isRemoved
            currentDom.removeChild(itemStartNode)
            currentDom.removeChild(itemEndNode)

            unwatch()

          else
            subTemplate.call(this, v)

      # provide a cleanup callback
      () ->
        isRemoved = true

    @with 'length', (length) ->
      # add items
      while items.length < length
        items.push createItemSlot(items.length)

      # remove items
      while items.length > length
        itemCleanup = items.pop()
        itemCleanup()

