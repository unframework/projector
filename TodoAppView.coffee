
window.TodoAppView = ->
  console.log @sampleValue

  @extend {
    sampleValue: 'Hello, sample value'
    sampleExtension: ->
      console.log 'Hello, sample extension, here\'s the local dom:', @dom
  }, ->
    console.log @sampleValue
    @sampleExtension()

    @element '.acme-container-box', { role: 'container' }, ->
      @attr dataTodoItemCount: 'itemCount'

      @sampleExtension()

      @element 'h1#sampleHeading', ->
        @text 'Hello, world'

