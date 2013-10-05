
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', { role: 'container' }, ->
    @attr dataTodoItemCount: 'itemCount'

    @with 'itemList', ->
      @when 'length', ->
        @element 'h1#sampleHeading', ->
          @text 'Hello, world'

      @element 'ul', ->
        @each ->
          @element 'li', ->
            @text 'Hello, world'

    @element 'a', { href: '#' }, ->
      @text 'Add Item'
      @onClick 'addItem'

    @element 'a', { href: '#' }, ->
      @text 'Remove Item'
      @onClick 'removeItem'
