
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
