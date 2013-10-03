
tubular = (rootDom, rootView) ->
  rootViewPrototype =
    use: (map, childView) ->
      viewPrototype = {}
      viewPrototype[n] = v for n, v of map
      viewPrototype.__proto__ = @__proto__

      invoke viewPrototype, @dom, childView

    element: (options...) ->
      childView = null

      elementName = null
      elementId = null
      elementClassList = []

      if options.length and typeof(options[options.length - 1]) is 'function'
        childView = options.pop()

      if options.length and typeof(options[0]) is 'string'
        elementName = options.shift()

        # parse #id and .class suffixes
        elementName = elementName.replace /[#.][^#.]*/g, (a) ->
          if a[0] is '#'
            elementId = a.substring(1)
          else
            elementClassList.push a.substring(1)

          '' # strip suffix from original name

      childDom = @dom.ownerDocument.createElement(elementName or 'div')

      if elementId isnt null # still trigger for empty ID string
        childDom.setAttribute 'id', elementId

      if elementClassList.length
        childDom.setAttribute 'class', elementClassList.join ' '

      for o in options
        for n, v of o
          childDom.setAttribute n, v

      @dom.appendChild(childDom)

      if childView
        invoke @__proto__, childDom, childView

    attr: (setting) ->
      for n, v of setting
        snakeCaseName = n.replace /[a-z][A-Z]/g, (a) ->
          a[0] + '-' + a[1].toLowerCase()

        @dom.setAttribute snakeCaseName, v

    text: (setting) ->
      childDom = @dom.ownerDocument.createTextNode(setting)
      @dom.appendChild(childDom)

  invoke = (viewPrototype, dom, view) ->
    viewContext =
      dom: dom

    viewContext.__proto__ = viewPrototype

    view.apply(viewContext)

    undefined # prevent stray output

  invoke rootViewPrototype, rootDom, rootView
