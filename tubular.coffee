
window.tubular = (rootModel, rootTemplate) ->
  watchList = []

  runTemplate = (model, viewPrototype, template, preInitMap) ->
    viewModel =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate model, viewModel, subTemplate, map

      bind: (path, subTemplate) ->
        value = model[path]

        watch = ->
          # get and compare with cached values
          newValue = model[path]
          if newValue isnt value
            value = newValue
            runTemplate value, viewModel, subTemplate

        watch.isCleared = false

        watchList.push watch

        runTemplate value, viewModel, subTemplate

        # return a handle to be able to unwatch
        {
          clear: ->
            # delayed removal for safety
            watch.isCleared = true
        }

      apply: (run) ->
        # fail fast on error
        if typeof run isnt 'function'
          throw 'cannot apply a non-function, got ' + typeof run

        # @todo wrap in an try/catch? or just let it bubble up?
        run.call(model)

        # invoke watches and cull ones that request to be removed
        # for speed, we just rewrite the portion of the list in place every time, eliminating cleared watches
        # @todo surely, this should be wrapped in try/catch
        watchCount = watchList.length
        watchIndex = 0
        compactedWatchCount = 0

        while watchIndex < watchCount
          watch = watchList[watchIndex]
          watchIndex += 1

          if not watch.isCleared
            # preserve the watch for next run
            watchList[compactedWatchCount] = watch
            compactedWatchCount += 1

            watch()

        # truncate compacted watch list (preserving any watches that have been added during this run)
        watchList.splice(compactedWatchCount, watchCount - compactedWatchCount)

        console.log 'watch count', watchList.length

    if preInitMap
      viewModel[n] = v for n, v of preInitMap

    viewModel.__proto__ = viewPrototype

    template.call(viewModel, model)

    undefined # prevent stray output

  runTemplate rootModel, Object.prototype, rootTemplate
