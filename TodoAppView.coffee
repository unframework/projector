
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
          @each ->
            @element 'li', ->
              @staticText 'This is: '
              @text 'label'

              @element 'a', { href: '#' }, ->
                @staticText 'Update Me'
                @onClick 'update'


    @element 'a', { href: '#' }, ->
      @staticText 'Add Item'
      @onClick 'addItem'

    @element 'a', { href: '#' }, ->
      @staticText 'Update Item'
      @onClick 'updateItem'

    @element 'a', { href: '#' }, ->
      @staticText 'Remove Item'
      @onClick 'removeItem'
