
TodoAppView = (todoApp) ->
    @element '.acme-container-box', { role: 'container' }, ->
      @attr dataTodoItemCount: 3

      @element 'h1#sampleHeading', ->
        @text 'Hello, world'

