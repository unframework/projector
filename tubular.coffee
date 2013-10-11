
window.tubular = (rootModel, rootTemplate) ->
  createNotifier = ->
    list = []

    (callback) ->
      if typeof callback isnt 'function'
        # invoke watches and cull ones that request to be removed
        # for speed, we just rewrite the portion of the list in place every time, eliminating cleared watches
        # @todo surely, this should be wrapped in try/catch
        count = list.length
        index = 0
        compactedCount = 0

        while index < count
          listener = list[index]
          index += 1

          if listener[0]
            # preserve the listener for next run
            list[compactedCount] = listener
            compactedCount += 1

            listener[0]()

        # truncate compacted listener list (preserving any watches that have been added during this run)
        list.splice(compactedCount, count - compactedCount)

        console.log 'watch count', list.length

      else
        listener = [ callback ]
        list.push listener

        # return a handle to be able to unwatch
        ->
          # delayed removal for safety
          listener[0] = null

  modelNotify = createNotifier()

  # recursive getter that freezes actual path elements inside the closures
  createPathGetter = (target, list) ->
    createGetter = (parentGetter, index) ->
      if index >= list.length
        parentGetter
      else
        element = list[index]
        currentGetter = ->
          v = parentGetter()

          if typeof v isnt 'object'
            undefined
          else if typeof v[element] is 'function'
            v[element].bind(v)
          else
            v[element]

        createGetter currentGetter, index + 1

    createGetter (-> target), 0

  rootVariableFinder = ((varName) -> throw 'unknown variable ' + varName)

  createBoundVariableFinder = (parentFinder, varName, boundValue, notify) ->
    createGetter = (subPath) ->
      createPathGetter boundValue, subPath

    (name, callback) ->
      if name is varName
        callback createGetter, notify
      else
        parentFinder name, callback

  createMutableVariableFinder = (parentFinder, varName, varValue) ->
    varNotify = createNotifier()
    createGetter = (subPath) ->
      createPathGetter varValue, subPath

    (name, callback) ->
      if name is varName
        callback createGetter, varNotify
      else
        parentFinder name, callback

  createScope = (variableFinder) ->
    {
      bind: (subName, path, subTemplate) ->
        viewInstance = this

        sourceVarName = path[0]
        subPath = path.slice 1

        variableFinder sourceVarName, (createGetter, notify) ->
          getter = createGetter(subPath)
          value = getter()

          clear = notify ->
            # get and compare with cached values
            newValue = getter()
            if newValue isnt value
              value = newValue
              runTemplate viewInstance, createScope(createBoundVariableFinder(variableFinder, subName, value, notify)), subTemplate

          runTemplate viewInstance, createScope(createBoundVariableFinder(variableFinder, subName, value, notify)), subTemplate

          { clear: clear }

      get: (path) ->
        sourceVarName = path[0]
        subPath = path.slice 1

        result = undefined
        resultNotify = undefined
        variableFinder sourceVarName, (createGetter, notify) ->
          result = createGetter(subPath)()
          resultNotify = notify

        if typeof result is 'object'
          undefined
        else if typeof result is 'function'
          (-> result(); resultNotify())
        else
          result

      set: (varName, initialValue, subTemplate) ->
        runTemplate this, createScope(createMutableVariableFinder(variableFinder, varName, initialValue)), subTemplate

      isolate: (map, subTemplate) ->
        viewInstance = this
        varGetters = {}
        varNotifiers = {}
        varValues = {}
        clears = []

        runIsolatedTemplate = ->
          isolatedFinder = rootVariableFinder
          for name, notify of varNotifiers
            isolatedFinder = createBoundVariableFinder(isolatedFinder, name, varValues[name], notify)
          runTemplate viewInstance, createScope(isolatedFinder), subTemplate

        listener = ->
          changed = false

          for name, getter of varGetters
            # get and compare with cached values
            newValue = getter()
            if newValue isnt varValues[name]
              varValues[name] = newValue
              changed = true

          if changed
            runIsolatedTemplate()

        for varName, sourcePath of map
          sourceVarName = sourcePath[0]
          subPath = sourcePath.slice 1

          variableFinder sourceVarName, (createGetter, notify) ->
            getter = createGetter(subPath)
            varValues[varName] = getter()
            varGetters[varName] = getter
            varNotifiers[varName] = notify

            clears.push notify(listener)

        runIsolatedTemplate()

        {
          clear: ->
            clear() for clear in clears()
            clears = null
        }
    }

  # @todo mask a top-level property and also keep track of which scope notifier it is
  # @todo this works exactly like before, except the bound model is not "this", but a named property, to allow access to previous scopes
  # @todo this fits the idea of a model still - it's now a view-model, groomed by the template glue code for convenience
  # @todo an alternative could be to track "parent" scope name - but this just fits programmer mindset better and is more convenient and closer to the template conventions
  runTemplate = (viewPrototype, preInitMap, template) ->
    viewInstance =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate viewInstance, map, subTemplate

    if preInitMap
      viewInstance[n] = v for n, v of preInitMap

    viewInstance.__proto__ = viewPrototype

    template.call(viewInstance)

    undefined # prevent stray output

  initialScope = createScope createBoundVariableFinder(rootVariableFinder, '_', rootModel, modelNotify)

  runTemplate Object.prototype, initialScope, rootTemplate
