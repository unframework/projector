
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', { role: 'container' }, ->
    @attr dataTodoItemCount: 'itemCount'

    @when 'itemCount', ->
      @element 'h1#sampleHeading', ->
        @text 'Hello, world'

    @element 'a', { href: '#' }, ->
      @text 'Click me!'

      @onClick 'updateItemCount'
