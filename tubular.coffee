
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

  wrapModelProperty = (target, notify) ->
    targetType = typeof target

    if targetType isnt 'object' and targetType isnt 'function'
      # nothing mutable to wrap
      target

    else
      # return a binding function
      wrapper = (pathElementList, name, subTemplate) ->
        # @todo return dummy unwatched binding if path is empty (can never generate a change of value)
        viewInstance = this
        getter = createPathGetter target, pathElementList
        value = getter()

        clear = notify ->
          # get and compare with cached values
          newValue = getter()
          if newValue isnt value
            value = newValue
            map = {}
            map[name] = wrapModelProperty(value, notify)
            viewInstance.fork map, subTemplate

        initialMap = {}
        initialMap[name] = wrapModelProperty(value, notify)
        viewInstance.fork initialMap, subTemplate

        # return a handle to be able to unwatch
        { clear: clear }

      if targetType is 'function'
        # add an invoker
        wrapper.invoke = () ->
          # @todo try/catch? or just let it fail-fast
          target()
          notify()

      wrapper

  initialScope = {}
  for n, v of rootModel
    initialScope[n] = wrapModelProperty((if typeof v is 'function' then v.bind(rootModel) else v), modelNotify)

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

  runTemplate Object.prototype, initialScope, rootTemplate
