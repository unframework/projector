
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

  bindOnChange = (getter, notify, viewInstance, subTemplate) ->
    value = getter()

    clear = notify ->
      # get and compare with cached values
      newValue = getter()
      if newValue isnt value
        value = newValue
        runTemplate value, {}, createNotifier(), viewInstance, subTemplate

    runTemplate value, {}, createNotifier(), viewInstance, subTemplate

    # return a handle to be able to unwatch
    { clear: clear }

  runTemplate = (model, viewModel, viewModelNotify, viewPrototype, template, preInitMap) ->
    bindVariable = (name, subTemplate) ->
      bindOnChange (-> viewModel[name]), viewModelNotify, viewInstance, subTemplate

    bindIndex = (index, subTemplate) ->
      getter = if typeof model is 'object' then (-> model[index]) else (-> undefined)
      bindOnChange getter, modelNotify, viewInstance, subTemplate

    bindPath = (pathElementList, subTemplate) ->
      # recursive getter that freezes actual path elements inside the closures
      createGetter = (parentGetter, index) ->
        if index >= pathElementList.length
          parentGetter
        else
          element = pathElementList[index]
          createGetter (-> v = parentGetter(); if typeof v isnt 'object' then undefined else v[element]), index + 1

      getter = createGetter (-> model), 0
      bindOnChange getter, modelNotify, viewInstance, subTemplate

    viewInstance =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate model, viewModel, viewModelNotify, viewInstance, subTemplate, map

      get: () ->
        # @todo type-check for primitives for true immutability
        model

      variable: (name, value) ->
        viewModel[name] = value
        viewModelNotify()

      bind: (path, subTemplate) ->
        if typeof path isnt 'string'
          bindIndex path, subTemplate
        else if path[0] is '@'
          bindVariable path.substring(1), subTemplate
        else
          bindPath path.split('.'), subTemplate

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

    if preInitMap
      viewInstance[n] = v for n, v of preInitMap

    viewInstance.__proto__ = viewPrototype

    template.call(viewInstance, model)

    undefined # prevent stray output

  runTemplate rootModel, {}, createNotifier(), Object.prototype, rootTemplate
