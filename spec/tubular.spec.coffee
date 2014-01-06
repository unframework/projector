
define ['tubular'], (tubular) ->

  describe 'tubular', ->
    it 'does not define a global in the AMD environment', ->
      expect(window.tubular).toBe undefined

    it 'defines only the scope-related methods + fork for template consumption', ->
      # this would not be done normally, but "clean object" is part of the spec
      memberList = null
      tubular -> memberList = (n for own n, v of this)

      memberList.sort()
      expect(memberList.join(',')).toBe 'bind,fork,refresh'

    it 'binds path to a variable', ->
      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE' }
        @bind 'TEST_VAR', (=> @_.TEST_PROP), ->
          expect(@TEST_VAR).toBe 'TEST_VALUE'

    it 'creates new view when model is updated', ->
      asyncViewGets = []
      modelInvoker = null

      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE', f: (-> @TEST_PROP = 'TEST_CHANGED_VALUE') }
        @bind 'TEST_VAR', (=> @_.TEST_PROP), ->
          asyncViewGets.push (=> @TEST_VAR)

        modelInvoker = =>
          @_.f()
          @refresh()

      # run after view init
      modelInvoker()
      expect(asyncViewGets.length).toBe 2
      expect(asyncViewGets[0]()).toBe 'TEST_VALUE'
      expect(asyncViewGets[1]()).toBe 'TEST_CHANGED_VALUE'

    it 'does not create new view if model is unchanged', ->
      runCount = 0
      modelInvoker = null

      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE', f: (-> @TEST_PROP = 'TEST_VALUE') }
        @bind 'TEST_VAR', (=> @_.TEST_PROP), ->
          runCount += 1

        modelInvoker = =>
          @_.f()
          @refresh()

      # run after view init
      expect(runCount).toBe 1
      modelInvoker()
      expect(runCount).toBe 1

    it 'allows unbinding the view', ->
      runCount = 0
      modelInvoker = null
      binding = null

      tubular ->
        @n = 0
        @f = (-> @n += 1)

        modelInvoker = =>
          @f()
          @refresh()

        binding = @bind 'TEST_VAR', (=> @n), ->
          runCount += 1

      # run after view init
      expect(runCount).toBe 1

      modelInvoker()
      expect(runCount).toBe 2

      binding.clear()
      modelInvoker()
      expect(runCount).toBe 2

    it 'disallows unbinding twice for same view', ->
      binding = null

      tubular ->
        binding = @bind 'TEST_VAR', (=> 0), ->

      # run after view init
      binding.clear()

      expect(-> binding.clear()).toThrow()

    it 'forks view state', ->
      view1 = null
      view2 = null
      tubular ->
        view1 = this
        @TEST_PROP = 'TEST_VALUE'

        @fork { TEST_PROP: 'VAL2' }, ->
          view2 = this
          @TEST_PROP2 = 'VAL3'

      expect(view1.TEST_PROP).toBe 'TEST_VALUE'
      expect(view2.TEST_PROP).toBe 'VAL2'
      expect(view2.TEST_PROP2).toBe 'VAL3'
