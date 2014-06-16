
(if define? then define else ((module) -> window.projectorHtml = module()))(->
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

      ownerDocument = if @$projectorHtmlCursor then @$projectorHtmlCursor().ownerDocument else document
      childDom = ownerDocument.createElement(elementName or 'div')

      if elementId isnt null # still trigger for empty ID string
        childDom.setAttribute 'id', elementId

      if elementClassList.length
        childDom.setAttribute 'class', elementClassList.join ' '

      # attribute binding
      for o in [ elementAttributeMap ].concat(options)
        for attributeName, attributeGetter of o
          snakeCaseName = attributeName.replace /[a-z][A-Z]/g, (a) ->
            a[0] + '-' + a[1].toLowerCase()

          if typeof attributeGetter is 'function'
            @watch attributeGetter, (v) ->
              childDom.setAttribute snakeCaseName, v
          else
            childDom.setAttribute snakeCaseName, attributeGetter

      # if first element ever created, report it for external consumption, otherwise just append
      if @$projectorHtmlCursor
        @$projectorHtmlCursor childDom
      else
        onRootElement childDom

      if subTemplate
        @fork ->
          @$projectorHtmlCursor = createCursor(childDom)
          subTemplate.call(this)

    viewModel.text = (getter) ->
      textNode = null
      cursor = @$projectorHtmlCursor

      if typeof getter isnt 'function'
        textNode = @$projectorHtmlCursor().ownerDocument.createTextNode(getter)
        @$projectorHtmlCursor textNode
      else
        @watch getter, (v) ->
          if textNode
            newNode = textNode.ownerDocument.createTextNode(v)
            textNode.parentNode.replaceChild(newNode, textNode)
            textNode = newNode
          else
            textNode = cursor().ownerDocument.createTextNode(v)
            cursor textNode

    viewModel.on = (name, optionsList..., callback) ->
      options = if optionsList.length then optionsList[0] else {}
      isPreventDefault = !!options.preventDefault

      currentDom = @$projectorHtmlCursor()
      listener = (e) =>
        if isPreventDefault
            e.preventDefault()

        callback()
        @refresh()

      # @todo check if element is being transitioned out
      currentDom.addEventListener name, listener, false

    viewModel.value = () ->
      @$projectorHtmlCursor().value

    viewModel.when = (expr, subTemplate) ->
      destroy = null

      currentDom = @$projectorHtmlCursor()
      startNode = currentDom.ownerDocument.createComment('^' + expr)
      endNode = currentDom.ownerDocument.createComment('$' + expr)

      @$projectorHtmlCursor startNode
      @$projectorHtmlCursor endNode

      # @todo see if this can be made universal? need a hook to destroy immediate children
      # something like onDestroy but does not propagate down to grandchildren
      @watch (-> !!expr()), (condition) ->
        if condition
          destroy = @scope ->
            @$projectorHtmlCursor = createCursor(currentDom, endNode)
            subTemplate.call(this)
        else if destroy isnt null
          destroy()

          while startNode.nextSibling isnt endNode
            startNode.parentNode.removeChild startNode.nextSibling # @todo optimize using local vars

    # @todo we can't overthink the array state diff tracking logic (e.g. "item inserted" or "item removed")
    # because ultimately, that sort of event information should come from the model itself
    # e.g. to fade out a spliced-out element of a list should really involve just creating *new* "flash" DOM
    # just to show the fadeout animation instead of reusing a piece of DOM from the original list
    # doing too much guessing otherwise would trip up on cases where item content just changed and "seems" as if something
    # was removed but actually wasn't
    viewModel.each = (expr, itemName, subTemplate) ->
      listGetter = expr
      currentDom = @$projectorHtmlCursor()
      endNode = currentDom.ownerDocument.createComment('...')
      items = []

      @$projectorHtmlCursor endNode

      loopCursor = createCursor(currentDom, endNode)

      createItemSlot = (index) =>
        itemStartNode = currentDom.ownerDocument.createComment('^[]')
        itemEndNode = currentDom.ownerDocument.createComment('$[]')
        loopCursor itemStartNode
        loopCursor itemEndNode

        cleanupDom = ->
          # clear old dom
          while itemStartNode.nextSibling isnt itemEndNode
            currentDom.removeChild(itemStartNode.nextSibling)

        # @todo check against nulls
        scopeDestroy = @scope ->
          innerScopeDestroy = null

          @watch (-> listGetter()[index]), (v) ->
            if innerScopeDestroy isnt null
              innerScopeDestroy()

            cleanupDom()

            innerScopeDestroy = @scope ->
              this[itemName] = v;

              # assign cursor last to prevent name clash
              @$projectorHtmlCursor = createCursor(currentDom, itemEndNode)

              subTemplate.call(this, index)

        # provide a cleanup callback
        () ->
          scopeDestroy()

          cleanupDom()
          currentDom.removeChild(itemStartNode)
          currentDom.removeChild(itemEndNode)

      @watch (-> listGetter().length), (length) ->
        # add items
        while items.length < length
          items.push createItemSlot(items.length)

        # remove items
        while items.length > length
          itemCleanup = items.pop()
          itemCleanup()
)
