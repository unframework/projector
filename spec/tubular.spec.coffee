
define ['tubular', 'text!tubular.js' ], (tubular, tubularSrc) ->

  describe 'tubular', ->
    it 'does not define a global in the AMD environment', ->
      expect(window.tubular).toBe undefined

    it 'defines a global in a non-AMD environment', ->
      # @todo this better?
      fakeScope = { define: null, window: {} }
      `with (fakeScope) { eval(tubularSrc) }`
      expect(fakeScope.window.tubular).not.toBe undefined

      # extra check to make sure there was no global exposure
      expect(window.tubular).toBe undefined

    it 'defines only the scope-related methods + fork for template consumption', ->
      # this would not be done normally, but "clean object" is part of the spec
      memberList = null
      tubular -> memberList = (n for own n, v of this)

      memberList.sort()
      expect(memberList.join(',')).toBe 'fork,refresh,scope,watch'

    it 'runs watcher immediately with the watched value', ->
      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE' }
        r = null
        @watch (=> @_.TEST_PROP), (v) ->
          r = v
        expect(r).toBe 'TEST_VALUE'

    it 'creates new view when watched model is updated', ->
      subViews = []
      root = null

      tubular ->
        root = this

        @watch (=> Math.random()), (v) ->
          subViews.push this

      # run after view init
      root.refresh()

      expect(subViews.length).toBe 2
      expect(subViews[0]).not.toBe subViews[1]
      expect(subViews[0]).not.toBe root
      expect(subViews[1]).not.toBe root

    it 'reports watched value when it changes', ->
      values = []
      root = null

      tubular ->
        root = this

        @TEST_PROP = 'TEST_VALUE'

        @watch (=> @TEST_PROP), (v) ->
          values.push v

      # run after view init
      root.TEST_PROP = 'TEST_CHANGED_VALUE'
      root.refresh()

      expect(values.length).toBe 2
      expect(values[0]).toBe 'TEST_VALUE'
      expect(values[1]).toBe 'TEST_CHANGED_VALUE'

    it 'does not invoke watch view when watched value does not change', ->
      values = []
      root = null

      tubular ->
        root = this

        @TEST_PROP = 'TEST_VALUE'

        @watch (=> @TEST_PROP), (v) ->
          values.push v

      # run after view init
      root.refresh()

      expect(values.length).toBe 1
      expect(values[0]).toBe 'TEST_VALUE'

    it 'creates a sub-scope', ->
      root = null
      sub = null

      tubular ->
        root = this
        @scope ->
          sub = this

      expect(sub).not.toBe root

    it 'allows unbinding the sub-scope', ->
      values = []
      root = null
      scopeClear = null

      tubular ->
        root = this

        @TEST_PROP = 'TEST_VALUE'

        scopeClear = @scope ->
          @watch (=> @TEST_PROP), (v) ->
            values.push v

      # run after view init
      scopeClear()
      root.TEST_PROP = 'TEST_CHANGED_VALUE'
      root.refresh()

      expect(values.length).toBe 1
      expect(values[0]).toBe 'TEST_VALUE'

    it 'disallows unbinding same sub-scope twice', ->
      scopeClear = null

      tubular ->
        scopeClear = @scope (->)

      scopeClear()
      expect(-> scopeClear()).toThrow()

    it 'forks view state', ->
      view1 = null
      view2 = null
      tubular ->
        view1 = this
        @TEST_PROP = 'TEST_VALUE'

        @fork ->
          view2 = this
          @TEST_PROP = 'VAL2'
          @TEST_PROP2 = 'VAL3'

      expect(view1.TEST_PROP).toBe 'TEST_VALUE'
      expect(view2.TEST_PROP).toBe 'VAL2'
      expect(view2.TEST_PROP2).toBe 'VAL3'
