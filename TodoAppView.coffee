
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', { role: 'container' }, ->
    @bind 'itemList', ->
      @attr dataTodoItemCount: 'length'

      @when 'length', ->
        @element 'h1#sampleHeading', ->
          @staticText 'Hello, world'
          @text 'length'

        @element 'ul', ->
          @each (item) ->
            @element 'li', ->
              @staticText 'This is: ' + item

    @element 'a', { href: '#' }, ->
      @staticText 'Add Item'
      @onClick 'addItem'

    @element 'a', { href: '#' }, ->
      @staticText 'Remove Item'
      @onClick 'removeItem'
