
define ['tubular'], (tubular) ->

  describe 'tubular', ->
    it 'does not define a global in the AMD environment', ->
      expect(window.tubular).toBe undefined

    it 'defines only the scope-related methods + fork for template consumption', ->
      # this would not be done normally, but "clean object" is part of the spec
      memberList = null
      tubular {}, -> memberList = (n for own n, v of this)

      memberList.sort()
      expect(memberList.join(',')).toBe 'bind,fork,get,isolate,set,yield'

    it 'fails on access to nonexistent var', ->
      tubular { TEST_NAME: 'TEST_VALUE' }, ->
        expect((=> @get ['NONEXISTENT_VAR'])).toThrow()

    it 'allows access to the _ var at first', ->
      tubular { TEST_NAME: 'TEST_VALUE' }, ->
        expect(@get ['_', 'TEST_NAME']).toBe 'TEST_VALUE'

    it 'disallows direct access to non-primitives', ->
      model = { n: 1, b: true, nl: null, undef: undefined }
      tubular model, ->
        expect(@get ['_']).toBe undefined

        for own n, v of model
          expect(@get ['_', n]).toBe v

      tubular { f: (->) }, -> expect(@get ['_', 'f']).toEqual jasmine.any(Function)

    it 'binds model methods to instance', ->
      tubular { n: 1, f: ((v) -> @n += 1) }, ->
        method = @get ['_', 'f']
        method()
        expect(@get ['_', 'n']).toBe 2

    it 'passes args and results to/from model methods', ->
      tubular { f: ((v) -> 2 + v) }, ->
        method = @get ['_', 'f']
        expect(method(3)).toBe 5

    it 'sets new bound state', ->
      tubular {}, ->
        @set 'TEST_VAR', { TEST_PROP: 'TEST_VALUE' }, ->
          expect(@get ['TEST_VAR', 'TEST_PROP']).toBe 'TEST_VALUE'

    it 'shadows existing vars with new bound state', ->
      tubular { TEST_PROP: 'TEST_VALUE1' }, ->
        @set '_', { TEST_PROP: 'TEST_VALUE2' }, ->
          expect(@get ['_', 'TEST_PROP']).toBe 'TEST_VALUE2'
        expect(@get ['_', 'TEST_PROP']).toBe 'TEST_VALUE1'

    it 'binds path to a variable', ->
      tubular { TEST_PROP: 'TEST_VALUE' }, ->
        @bind 'TEST_VAR', ['_', 'TEST_PROP'], ->
          expect(@get ['TEST_VAR']).toBe 'TEST_VALUE'

    it 'creates new view when model is updated', ->
      asyncViewGets = []
      modelInvoker = null

      tubular { TEST_PROP: 'TEST_VALUE', f: (-> @TEST_PROP = 'TEST_CHANGED_VALUE') }, ->
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

      tubular { TEST_PROP: 'TEST_VALUE', f: (-> @TEST_PROP = 'TEST_VALUE') }, ->
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

      tubular { n: 0, f: (-> @n += 1) }, ->
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

      tubular { n: 0 }, ->
        binding = @bind 'TEST_VAR', ['_', 'n'], ->

      # run after view init
      binding.clear()

      expect(-> binding.clear()).toThrow()

    it 'isolates scope', ->
      tubular { TEST_PROP: 'TEST_VALUE' }, ->
        @isolate { 'TEST_VAR': ['_', 'TEST_PROP'] }, ->
          expect(=> @get ['_']).toThrow()
          expect(@get ['TEST_VAR']).toBe 'TEST_VALUE'

    it 'yields isolated scope', ->
      tubular { TEST_PROP: 'TEST_VALUE' }, ->
        @isolate { 'TEST_VAR': ['_', 'TEST_PROP'] }, ->
          @set 'TEST_VAR2', {}, ->
            @yield { 'TEST_YIELD_VAR': 'TEST_VAR' }, ->
              expect(=> @get ['TEST_VAR']).toThrow()
              expect(=> @get ['TEST_VAR2']).toThrow()
              expect(@get ['_', 'TEST_PROP']).toBe 'TEST_VALUE'
              expect(@get ['TEST_YIELD_VAR']).toBe 'TEST_VALUE'

    it 'updates isolated scope based on change, but only once per multiple fields changed', ->
      asyncViewGets = []
      modelInvoker = null

      tubular { n: 0, n2: 0, f: (-> @n += 1; @n2 += 2) }, ->
        binding = @isolate { 'TEST_VAR': ['_', 'n'], 'TEST_VAR2': ['_', 'n2'] }, ->
          asyncViewGets.push (=> [ @get(['TEST_VAR']), @get(['TEST_VAR2']) ])

        modelInvoker = @get ['_', 'f']

      # run after view init
      modelInvoker()
      expect(asyncViewGets.length).toBe 2
      expect(asyncViewGets[0]()).toEqual [ 0, 0 ]
      expect(asyncViewGets[1]()).toEqual [ 1, 2 ]
