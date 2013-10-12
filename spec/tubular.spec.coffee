
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

