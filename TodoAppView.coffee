
window.TodoAppTemplate = ->
  console.log @sampleValue

  @fork window.tubularHtml, ->

    @element '.acme-container-box', { role: 'container' }, ->
      @attr dataTodoItemCount: 'itemCount'

      #@when 'itemCount', ->
      @element 'h1#sampleHeading', ->
        @text 'Hello, world'

      @element 'a', { href: '#' }, ->
        @text 'Click me!'

        @onClick 'updateItemCount'
