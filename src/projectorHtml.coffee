
(if define? then define else ((module) -> window.projectorHtml = module()))(->
  waitForAll = (list, cb) ->
    doneCount = 0

    wait = ->
      if list.length > doneCount
        completion = (-> doneCount += 1; wait(); undefined)
        list[doneCount].then completion, completion
      else
        cb()

    wait()

  (viewModel, onRootElement) ->
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
            ((snakeCaseName) =>
              @watch attributeGetter, (v) ->
                if v is null
                  childDom.removeAttribute snakeCaseName
                else
                  childDom.setAttribute snakeCaseName, v
            )(snakeCaseName)
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

    viewModel.html = () ->
      @$projectorHtmlCursor()

    viewModel.value = () ->
      @$projectorHtmlCursor().value

    viewModel.region = (expr, subTemplate) ->
      destroy = (->)
      currentWaitList = []

      currentDom = @$projectorHtmlCursor()
      startNode = currentDom.ownerDocument.createComment('^')
      endNode = currentDom.ownerDocument.createComment('$')

      @$projectorHtmlCursor startNode
      @$projectorHtmlCursor endNode

      # @todo see if this can be made universal? need a hook to destroy immediate children
      # something like onDestroy but does not propagate down to grandchildren
      @watch expr, (v) ->
        # clean up previous DOM
        destroy()

        curNode = startNode
        destroyedNodes = []

        while curNode.nextSibling isnt endNode
          curNode = curNode.nextSibling
          destroyedNodes.push curNode

        waitForAll currentWaitList, ->
          for node in destroyedNodes
            node.parentNode.removeChild node

        # move start node over for new content while old content is being deleted
        startNode.parentNode.insertBefore startNode, endNode

        # set up new DOM
        waitList = currentWaitList = []

        destroy = @scope ->
          @$region = {
            waitUntil: (promise) ->
              if promise and promise.then
                waitList.push promise
              else
                throw new Error('expecting a thenable')
          }
          @$projectorHtmlCursor = createCursor(currentDom, endNode)
          subTemplate.call(this, v)

    viewModel.list = (expr, subTemplate) ->
      itemCount = null

      @watch expr, (v) ->
        itemCount = v

      # @todo use non-recursive approach
      createTailTemplate = (itemIndex) ->
        ->
          @region (-> itemIndex < itemCount), (v) ->
            if v
              @fork -> subTemplate.call(this, itemIndex)
              createTailTemplate(itemIndex + 1).call(this)

      createTailTemplate(0).call(this)

    viewModel.when = (expr, subTemplate) ->
      @region (-> !!expr()), (condition) ->
        if condition
          subTemplate.call(this)

    # @todo we can't overthink the array state diff tracking logic (e.g. "item inserted" or "item removed")
    # because ultimately, that sort of event information should come from the model itself
    # e.g. to fade out a spliced-out element of a list should really involve just creating *new* "flash" DOM
    # just to show the fadeout animation instead of reusing a piece of DOM from the original list
    # doing too much guessing otherwise would trip up on cases where item content just changed and "seems" as if something
    # was removed but actually wasn't
    viewModel.each = (expr, itemName, subTemplate) ->
      @region expr, (list) ->
        if list
          @list (-> list.length), (itemIndex) ->
            @region (-> list[itemIndex]), (v) ->
              this[itemName] = v
              subTemplate.call(this, itemIndex)
)
