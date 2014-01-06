
define ['tubular'], (tubular) ->

  describe 'tubular', ->
    it 'does not define a global in the AMD environment', ->
      expect(window.tubular).toBe undefined

    it 'defines only the scope-related methods + fork for template consumption', ->
      # this would not be done normally, but "clean object" is part of the spec
      memberList = null
      tubular -> memberList = (n for own n, v of this)

      memberList.sort()
      expect(memberList.join(',')).toBe 'bind,fork,get,set'

    it 'converts nonexistent paths to undefined', ->
      tubular ->
        @TEST_NAME = 'TEST_VALUE'
        @TEST_NULL = null

        expect(@get ['TEST_NAME', 'TEST_NONEXISTENT']).toBe undefined
        expect(@get ['TEST_NULL', 'TEST_NONEXISTENT']).toBe undefined

    it 'gets values', ->
      model = { n: 1, b: true, nl: null, undef: undefined }
      tubular ->
        for own n, v of model
          this[n] = v

        for own n, v of model
          expect(@get [n]).toBe v

      tubular -> @f = (->); expect(@get ['f']).toEqual jasmine.any(Function)

    it 'binds model methods to instance', ->
      tubular ->
        @n = 1
        @f = (v) -> @n += 1

        method = @get ['f']
        method()
        expect(@get ['n']).toBe 2

    it 'passes args and results to/from model methods', ->
      tubular ->
        @f = ((v) -> 2 + v)
        method = @get ['f']
        expect(method(3)).toBe 5

    it 'sets new bound state', ->
      tubular ->
        @set 'TEST_VAR', { TEST_PROP: 'TEST_VALUE' }, ->
          expect(@get ['TEST_VAR', 'TEST_PROP']).toBe 'TEST_VALUE'

    it 'shadows existing vars with new bound state', ->
      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE1' }
        @set '_', { TEST_PROP: 'TEST_VALUE2' }, ->
          expect(@get ['_', 'TEST_PROP']).toBe 'TEST_VALUE2'
        expect(@get ['_', 'TEST_PROP']).toBe 'TEST_VALUE1'

    it 'binds path to a variable', ->
      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE' }
        @bind 'TEST_VAR', ['_', 'TEST_PROP'], ->
          expect(@get ['TEST_VAR']).toBe 'TEST_VALUE'

    it 'creates new view when model is updated', ->
      asyncViewGets = []
      modelInvoker = null

      tubular ->
        @_ = { TEST_PROP: 'TEST_VALUE', f: (-> @TEST_PROP = 'TEST_CHANGED_VALUE') }
        @bind 'TEST_VAR', ['_', 'TEST_PROP'], ->
          asyncViewGets.push (=> @get ['TEST_VAR'])

        modelInvoker = @get ['_', 'f']

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
        @bind 'TEST_VAR', ['_', 'TEST_PROP'], ->
          runCount += 1

        modelInvoker = @get ['_', 'f']

      # run after view init
      expect(runCount).toBe 1
      modelInvoker()
      expect(runCount).toBe 1

    it 'allows unbinding the view', ->
      runCount = 0
      modelInvoker = null
      binding = null

      tubular ->
        @_ = { n: 0, f: (-> @n += 1) }

        modelInvoker = @get ['_', 'f']
        binding = @bind 'TEST_VAR', ['_', 'n'], ->
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
        @_ = { n: 0 }
        binding = @bind 'TEST_VAR', ['_', 'n'], ->

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
