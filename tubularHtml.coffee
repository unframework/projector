
window.tubularHtml =
  element: (options...) ->
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

    childDom = @dom.ownerDocument.createElement(elementName or 'div')

    if elementId isnt null # still trigger for empty ID string
      childDom.setAttribute 'id', elementId

    if elementClassList.length
      childDom.setAttribute 'class', elementClassList.join ' '

    for o in options
      for n, v of o
        childDom.setAttribute n, v

    @dom.appendChild(childDom)

    if subTemplate
      @withDOM childDom, subTemplate

  attr: (setting) ->
    for n, path of setting
      snakeCaseName = n.replace /[a-z][A-Z]/g, (a) ->
        a[0] + '-' + a[1].toLowerCase()

      @with path, (v) ->
        @dom.setAttribute snakeCaseName, v

  text: (setting) ->
    childDom = @dom.ownerDocument.createTextNode(setting)
    @dom.appendChild(childDom)

  onClick: (path) ->
    currentAction = null

    @dom.addEventListener 'click', =>
      if typeof currentAction is 'function'
        @apply currentAction
    , false

    @with path, (action) ->
      # @todo a cleanup conditional?
      currentAction = action

  when: (path, subTemplate) ->
    self = this
    currentCondition = null # not true/false to always trigger first run

    startNode = @dom.ownerDocument.createComment('^' + path);
    @dom.appendChild(startNode)

    @with path, (v) ->
      condition = !!v # coerce to boolean

      if currentCondition isnt condition
        if condition
          subTemplate.call(self)
        else
          while startNode.nextSibling isnt endNode
            startNode.parentNode.removeChild startNode.nextSibling # @todo optimize using local vars

        currentCondition = condition

    endNode = @dom.ownerDocument.createComment('$' + path);
    @dom.appendChild(endNode)
