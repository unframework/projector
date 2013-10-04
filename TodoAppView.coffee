
window.TodoAppView = (todoApp) ->
  console.log @sampleValue

  @use {
    sampleValue: 'Hello, sample value'
    sampleExtension: ->
      console.log 'Hello, sample extension, here\'s the local dom:', @dom
  }, ->
    console.log @sampleValue
    @sampleExtension()

    @element '.acme-container-box', { role: 'container' }, ->
      @attr dataTodoItemCount: 3

      @sampleExtension()

      @element 'h1#sampleHeading', ->
        @text 'Hello, world'

