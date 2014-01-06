
(if define? then define else ((module) -> window.tubular = module()))(->
  (rootTemplate) ->
    # @todo prevent recursion
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
            if listener[0]
              # delayed removal for safety
              listener[0] = null
            else
              throw 'already unbound' # fail fast

    modelNotify = createNotifier()

    makeKeyValue = (k, v) ->
      kv = {}
      kv[k] = v
      kv

    initialScope = {
        bind: (subName, getter, subTemplate) ->
          viewInstance = this
          value = getter()

          clear = modelNotify ->
            # get and compare with cached values
            newValue = getter()
            if newValue isnt value
              value = newValue
              runTemplate viewInstance, makeKeyValue(subName, value), subTemplate

          runTemplate viewInstance, makeKeyValue(subName, value), subTemplate

          { clear: clear }

        refresh: modelNotify
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

      viewInstance[n] = v for n, v of preInitMap

      viewInstance.__proto__ = viewPrototype

      template.call(viewInstance)

      undefined # prevent stray output

    runTemplate Object.prototype, initialScope, rootTemplate
)
