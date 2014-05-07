
(if define? then define else ((module) -> window.projector = module()))(->
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

    initializeScope = (parentNotify) ->
      scopeNotify = createNotifier()
      scopeClear = parentNotify scopeNotify

      @watch = (getter, subTemplate) ->
        value = getter()
        viewInstance = this

        scopeNotify =>
          # get and compare with cached values
          newValue = getter()
          if newValue isnt value
            value = newValue
            @fork (-> subTemplate.call this, value)

        @fork (-> subTemplate.call this, value)

      @scope = (subTemplate) ->
        subClear = null

        @fork ->
          subClear = initializeScope.call this, scopeNotify
          subTemplate.call this

        subClear

      scopeClear

    rootView =
      fork: (subTemplate) ->
        # create clean sub-view model and initialize it with given values
        # @todo use Object.create
        subView = {}
        subView.__proto__ = this

        subTemplate.call subView
        undefined # prevent stray output

      refresh: (-> modelNotify()) # only allow invoking notification mode

    initializeScope.call rootView, modelNotify

    rootTemplate.call rootView
)
