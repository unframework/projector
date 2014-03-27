
(if define? then define else ((module) -> window.tubularHtml = module()))(->
  install: (viewModel, onRootElement) ->
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

    viewModel.element = (options...) ->
      subTemplate = null

      elementName = null
      elementId = null
      elementClassList = []
      elementAttributeMap = {}

      if options.length and typeof(options[options.length - 1]) is 'function'
        subTemplate = options.pop()

      if options.length and typeof(options[0]) is 'string'
        elementName = options.shift()

        # parse #id and .class suffixes
        elementName = elementName.replace /[#.][^#.\[]*|\[[^\]]*\]/g, (a) ->
          if a[0] is '#'
            elementId = a.substring(1)
          else if a[0] is '['
            pair = a.substring(1, a.length - 1).split('=', 2)
            elementAttributeMap[pair[0]] = if pair[1] isnt undefined then pair[1] else pair[0]
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
      # @todo random name
      if not @$tubularHtmlOnDestroy
        @$tubularHtmlOnDestroy = createBroadcast()

      # attribute binding
      for o in [ elementAttributeMap ].concat(options)
        for attributeName, attributeGetter of o
          snakeCaseName = attributeName.replace /[a-z][A-Z]/g, (a) ->
            a[0] + '-' + a[1].toLowerCase()

          if typeof attributeGetter is 'function'
            @bind 'value', attributeGetter, ->
              childDom.setAttribute snakeCaseName, @value
          else
            childDom.setAttribute snakeCaseName, attributeGetter

      # if first element ever created, report it for external consumption, otherwise just append
      if @$tubularHtmlCursor
        @$tubularHtmlCursor childDom
      else
        onRootElement childDom

      if subTemplate
        @fork ->
          @$tubularHtmlCursor = createCursor(childDom)
          subTemplate.call(this)

    viewModel.text = (getter) ->
      textNode = null
      cursor = @$tubularHtmlCursor

      if typeof getter isnt 'function'
        textNode = @$tubularHtmlCursor().ownerDocument.createTextNode(getter)
        @$tubularHtmlCursor textNode
      else
        @bind 'text', getter, ->
          if textNode
            newNode = textNode.ownerDocument.createTextNode(@text)
            textNode.parentNode.replaceChild(newNode, textNode)
            textNode = newNode
          else
            textNode = cursor().ownerDocument.createTextNode(@text)
            cursor textNode

    viewModel.onClick = (callback) ->
      currentDom = @$tubularHtmlCursor()
      listener = =>
        callback()
        @refresh()

      currentDom.addEventListener 'click', listener, false

    viewModel.value = () ->
      @$tubularHtmlCursor().value

    viewModel.when = (expr, subTemplate) ->
      self = this
      currentCondition = false # default state is false
      childOnDestroy = null

      currentDom = @$tubularHtmlCursor()

      startNode = currentDom.ownerDocument.createComment('^' + expr)
      endNode = currentDom.ownerDocument.createComment('$' + expr)

      @$tubularHtmlCursor startNode
      @$tubularHtmlCursor endNode

      binding = @bind 'value', expr, ->
        condition = !!@value # coerce to boolean

        if currentCondition isnt condition
          if condition
            childOnDestroy = createBroadcast()

            # forking the original view-model, since this one is based around the condition model value
            self.fork ->
              @$tubularHtmlCursor = createCursor(currentDom, endNode)
              @$tubularHtmlOnDestroy = childOnDestroy
              subTemplate.call(this)
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
    viewModel.each = (expr, itemName, subTemplate) ->
      listGetter = expr
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

        # @todo check against nulls
        itemBinding = @bind itemName, (-> listGetter()[index]), ->
          # clear old dom
          while itemStartNode.nextSibling isnt itemEndNode
            currentDom.removeChild(itemStartNode.nextSibling)

          if itemOnDestroy
            itemOnDestroy()

          itemOnDestroy = createBroadcast()

          @fork ->
            @$tubularHtmlCursor = createCursor(currentDom, itemEndNode)
            @$tubularHtmlOnDestroy = itemOnDestroy
            subTemplate.call(this, index)

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

      binding = @bind 'length', (-> listGetter().length), ->
        length = @length

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
)
