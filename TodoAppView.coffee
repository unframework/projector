
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', {
    role: 'container'
    dataTodoItemCount: '{{ itemList.length }}'
  }, ->

    @bind 'itemList', ->
      @when 'length', ->
        @element 'h1#sampleHeading', ->
          @text 'Hello, world {{ length }}'

        @element 'ul', ->
          @each ->
            @element 'li', ->
              @text 'This is: {{ label }}'

              @element 'a', { href: '#' }, ->
                @text 'Update Me'
                @onClick 'update'


    @element 'a', { href: '#' }, ->
      @text 'Add Item'
      @onClick 'addItem'

    @element 'a', { href: '#' }, ->
      @text 'Update Item'
      @onClick 'updateItem'

    @element 'a', { href: '#' }, ->
      @text 'Remove Item'
      @onClick 'removeItem'
