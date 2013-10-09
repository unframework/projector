
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

  createViewScope = (model) ->
    viewModel = {}
    viewModelNotify = createNotifier()

    bindOnChange = (viewInstance, getter, notify, subTemplate) ->
      value = getter()

      clear = notify ->
        # get and compare with cached values
        newValue = getter()
        if newValue isnt value
          value = newValue
          viewInstance.fork createViewScope(value), subTemplate

      viewInstance.fork createViewScope(value), subTemplate

      # return a handle to be able to unwatch
      { clear: clear }

    bindVariable = (viewInstance, name, subTemplate) ->
      bindOnChange viewInstance, (-> viewModel[name]), viewModelNotify, subTemplate

    bindIndex = (viewInstance, index, subTemplate) ->
      getter = if typeof model is 'object' then (-> model[index]) else (-> undefined)
      bindOnChange viewInstance, getter, modelNotify, subTemplate

    bindPath = (viewInstance, pathElementList, subTemplate) ->
      # recursive getter that freezes actual path elements inside the closures
      createGetter = (parentGetter, index) ->
        if index >= pathElementList.length
          parentGetter
        else
          element = pathElementList[index]
          createGetter (-> v = parentGetter(); if typeof v isnt 'object' then undefined else v[element]), index + 1

      getter = createGetter (-> model), 0
      bindOnChange viewInstance, getter, modelNotify, subTemplate

    {
      bind: (path, subTemplate) ->
        if typeof path isnt 'string'
          bindIndex this, path, subTemplate
        else if path[0] is '@'
          bindVariable this, path.substring(1), subTemplate
        else
          bindPath this, path.split('.'), subTemplate

      get: () ->
        # @todo type-check for primitives for true immutability
        model

      variable: (name, value) ->
        viewModel[name] = value
        viewModelNotify()

      apply: (path) ->
        target = null
        method = model
        elementList = if typeof path is 'string' then path.split('.') else [ path ]

        for element in elementList
          target = method
          method = target[element]

        # @todo wrap in an try/catch? or just let it bubble up? need to fail-fast here
        method.call(target)

        modelNotify()
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

  runTemplate Object.prototype, createViewScope(rootModel), rootTemplate
