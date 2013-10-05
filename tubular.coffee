
window.tubular = (rootModel, rootTemplate) ->
  watchList = []

  runTemplate = (model, viewPrototype, template, preInitMap) ->
    viewModel =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate model, viewModel, subTemplate, map

      with: (path, subTemplate) ->
        value = model[path]

        watchList.push ->
          # get and compare with cached values
          newValue = model[path]
          if newValue isnt value
            value = newValue
            runTemplate value, viewModel, subTemplate

        runTemplate value, viewModel, subTemplate

      apply: (run) ->
        # fail fast on error
        if typeof run isnt 'function'
          throw 'cannot apply a non-function, got ' + typeof run

        # @todo wrap in an try/catch? or just let it bubble up?
        run.call(model)

        # update watches
        # @todo surely, this should be wrapped in try/catch
        # @todo also, this should be safe WRT in-flight changes to the watchList
        watch() for watch in watchList

    if preInitMap
      viewModel[n] = v for n, v of preInitMap

    viewModel.__proto__ = viewPrototype

    template.call(viewModel, model)

    undefined # prevent stray output

  runTemplate rootModel, Object.prototype, rootTemplate
