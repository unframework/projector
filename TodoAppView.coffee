
TodoAppView = (todoApp) ->
    @element { class: 'container' }, ->
      @attr dataTodoItemCount: 3

      @element 'h1', ->
        @text 'Hello, world'

