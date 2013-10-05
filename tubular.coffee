
window.tubular = (rootModel, rootDom, rootTemplate) ->
  watchList = []

  runTemplate = (model, viewPrototype, viewDOM, template) ->
    viewModel =
      dom: viewDOM

      use: (map, subTemplate) ->
        # copy the prototype into a clean object
        newPrototype = {}
        newPrototype[n] = v for n, v of map
        newPrototype.__proto__ = viewPrototype

        runTemplate model, newPrototype, viewDOM, subTemplate

      withDOM: (newDOM, subTemplate) ->
        runTemplate model, viewPrototype, newDOM, subTemplate

      with: (path, subTemplate) ->
        value = model[path]

        watchList.push ->
          # get and compare with cached values
          newValue = model[path]
          if newValue isnt value
            value = newValue
            runTemplate value, viewPrototype, viewDOM, subTemplate

        runTemplate value, viewPrototype, viewDOM, subTemplate

    viewModel.__proto__ = viewPrototype

    template.call(viewModel, model)

    undefined # prevent stray output

  runTemplate rootModel, {}, rootDom, rootTemplate
