
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', {
    role: 'container'
    dataTodoItemCount: '{{ itemList.length }}'
  }, ->

    @when 'itemList.length', ->
      @element 'h1#sampleHeading', ->
        @text 'Hello, world {{ itemList.length }}'

      @element 'ul', ->
        @each 'itemList', 'item', ->
          #@variable 'isEdited', true

          @element 'li', ->
            @text 'This is: {{ item.label }}'

            @element 'a', { href: '#' }, ->
              @text 'Update Me'
              # @onClickToggle 'isEdited'

            # @when '@isEdited', ->
            #   @element ->
            #     @text 'This is an edit form'

    @element 'a', { href: '#' }, ->
      @text 'Add Item'
      @onClick 'addItem'

    @element 'a', { href: '#' }, ->
      @text 'Update Item'
      @onClick 'updateItem'

    @element 'a', { href: '#' }, ->
      @text 'Remove Item'
      @onClick 'removeItem'
