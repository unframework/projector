
tubular = (rootDom, rootView) ->
  viewPrototype =
    element: (options...) ->
      childView = null

      elementName = null

      if options.length and typeof(options[options.length - 1]) is 'function'
        childView = options.pop()

      for o in options
        if typeof(o) is 'string'
          throw 'cannot specify element name twice' if elementName isnt null
          elementName = o # @todo also parse # and . characters

      childDom = @dom.ownerDocument.createElement(elementName or 'div')
      @dom.appendChild(childDom)

      if childView
        invoke childDom, childView

    attr: (setting) ->
      for n, v of setting
        snakeCaseName = n.replace /[a-z][A-Z]/g, (a) ->
          a[0] + '-' + a[1].toLowerCase()

        @dom.setAttribute snakeCaseName, v

    text: (setting) ->
      childDom = @dom.ownerDocument.createTextNode(setting)
      @dom.appendChild(childDom)

  invoke = (dom, view) ->
    viewContext =
      dom: dom

    viewContext.__proto__ = viewPrototype

    view.apply(viewContext)

    undefined # prevent stray output

  invoke rootDom, rootView
