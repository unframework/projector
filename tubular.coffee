
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

  createBoundVariableScope = (parentFinder, varName, boundValue, notify) ->
    createGetter = (subPath) ->
      createPathGetter boundValue, subPath

    createScopeWithFinder (name, callback) ->
      if name is varName
        callback createGetter, notify
      else
        parentFinder name, callback

  createMutableVariableScope = (parentFinder, varName, varValue, withSetter) ->
    varNotify = createNotifier()
    createGetter = (subPath) ->
      if subPath.length isnt 0
        throw 'cannot bind to var subpath'
      else
        (-> varValue)

    # pass back the setter
    withSetter ((v) -> varValue = v; varNotify())

    createScopeWithFinder (name, callback) ->
      if name is varName
        callback createGetter, varNotify
      else
        parentFinder name, callback

  createScopeWithFinder = (variableFinder) ->
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
              runTemplate viewInstance, createBoundVariableScope(variableFinder, subName, value, notify), subTemplate

          runTemplate viewInstance, createBoundVariableScope(variableFinder, subName, value, notify), subTemplate

          { clear: clear }

      get: (varName) ->
        result = undefined
        resultNotify = undefined
        variableFinder varName, (createGetter, notify) ->
          result = createGetter([])()
          resultNotify = notify

        if typeof result is 'object'
          undefined
        else if typeof result is 'function'
          (-> result(); resultNotify())
        else
          result

      variable: (varName, initialValue, subTemplate) ->
        setter = null
        scope = createMutableVariableScope(variableFinder, varName, initialValue, ((v) -> setter = v))
        runTemplate this, scope, (-> subTemplate.call(this, setter))
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

  initialScope = createBoundVariableScope ((varName) -> throw 'unknown variable ' + varName), '_', rootModel, modelNotify

  runTemplate Object.prototype, initialScope, rootTemplate
