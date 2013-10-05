
window.tubular = (rootModel, rootTemplate) ->
  watchList = []

  runTemplate = (model, viewPrototype, template, preInitMap) ->
    viewModel =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate model, viewModel, subTemplate, map

      bind: (path, subTemplate) ->
        value = model[path]

        watchList.push (unwatch) ->
          # get and compare with cached values
          newValue = model[path]
          if newValue isnt value
            value = newValue
            runTemplate value, viewModel, (m) ->
              subTemplate.call(this, m, unwatch)

        runTemplate value, viewModel, subTemplate

      apply: (run) ->
        # fail fast on error
        if typeof run isnt 'function'
          throw 'cannot apply a non-function, got ' + typeof run

        # @todo wrap in an try/catch? or just let it bubble up?
        run.call(model)

        # invoke watches and cull ones that request to be removed
        # @todo surely, this should be wrapped in try/catch
        unwatchFlag = null
        unwatchCallback = ->
          unwatchFlag = true

        watchCount = watchList.length
        watchIndex = 0

        while watchIndex < watchCount
          unwatchFlag = false
          watchList[watchIndex](unwatchCallback)

          if unwatchFlag
            watchList.splice(watchIndex, 1)
            watchCount -= 1
          else
            watchIndex += 1

    if preInitMap
      viewModel[n] = v for n, v of preInitMap

    viewModel.__proto__ = viewPrototype

    template.call(viewModel, model)

    undefined # prevent stray output

  runTemplate rootModel, Object.prototype, rootTemplate
