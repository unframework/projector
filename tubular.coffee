
window.tubular = (rootModel, rootTemplate) ->
  createGetter = (model, path) ->
    if model is undefined
      # always is undefined
      (-> undefined)
    else if typeof path isnt 'string'
      # non-strings (numbers)
      (-> model[path])
    else
      elementList = if typeof path is 'number' then path else path.split '.'

      if elementList.length is 1
        # simple fast getter
        (-> model[path])
      else
        # full getter
        ->
          v = model
          for n in elementList
            v = if v is undefined then undefined else v[n]
          v

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

  runTemplate = (model, viewPrototype, template, preInitMap) ->
    viewModel =
      fork: (map, subTemplate) ->
        # create clean sub-view model and initialize it with given values
        runTemplate model, viewModel, subTemplate, map

      get: () ->
        # @todo type-check for primitives for true immutability
        model

      bind: (path, subTemplate) ->
        getter = createGetter model, path
        value = getter()

        clear = modelNotify ->
          # get and compare with cached values
          newValue = getter()
          if newValue isnt value
            value = newValue
            runTemplate value, viewModel, subTemplate

        runTemplate value, viewModel, subTemplate

        # return a handle to be able to unwatch
        { clear: clear }

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
      viewModel[n] = v for n, v of preInitMap

    viewModel.__proto__ = viewPrototype

    template.call(viewModel, model)

    undefined # prevent stray output

  runTemplate rootModel, Object.prototype, rootTemplate
