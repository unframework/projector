
(if define? then define else ((module) -> window.projectorExpr = module()))(->
  (viewModel) ->
    parseExpression = (target, expr) ->
      list = expr.split('.')

      createGetter = (parentGetter, index) ->
        if index >= list.length
          parentGetter
        else
          element = list[index]
          currentGetter = ->
            v = parentGetter()

            if v is null
              undefined
            else if typeof v isnt 'object'
              undefined
            else
              v[element]

          createGetter currentGetter, index + 1

      createGetter (-> target), 0

    viewModel.eval = (expr) ->
      parseExpression this, expr

    viewModel.tmpl = (curlyString) ->
      target = this
      slices = []

      # parse static/dynamic string slices and create bindings along the way
      re = /{{\s*(.*?)\s*}}/g
      lastEnd = 0
      while match = re.exec(curlyString)
        if match.index > lastEnd
          slices.push ((staticString) -> (-> staticString))(curlyString.substring lastEnd, match.index)

        slices.push parseExpression(target, match[1])

        lastEnd = match.index + match[0].length

      if curlyString.length > lastEnd
        slices.push ((staticString) -> (-> staticString))(curlyString.substring lastEnd, curlyString.length)

      (->
        (part() for part in slices).join('')
      )
)
