
window.TodoAppTemplate = ->
  console.log @sampleValue

  @use window.tubularHtml, ->

    @element '.acme-container-box', { role: 'container' }, ->
      @attr dataTodoItemCount: 'itemCount'

      @element 'h1#sampleHeading', ->
        @text 'Hello, world'
