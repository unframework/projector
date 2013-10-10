
window.TodoAppTemplate = ->
  window.tubularHtml this, (element) ->
    # immediately append
    # @todo this could be saved for later appending elsewhere, too
    document.getElementById('container').appendChild(element)

  @element '.acme-container-box', {
    role: 'container'
    dataTodoItemCount: '{{ _.itemList.length }}'
  }, ->

    @when '_.itemList.length', ->
      @element 'h1#sampleHeading', ->
        @text 'Hello, world {{ _.itemList.length }}'

      @element 'ul', ->
        @each '_.itemList', 'item', ->
          @variable 'isEdited', true, (setter) ->

            @element 'li', ->
              @text 'This is: {{ item.label }}'

              @element 'a', { href: '#' }, ->
                @text 'Update Me'
                @onClickToggle 'isEdited', setter

              @when 'isEdited', ->
                @element ->
                  @text 'This is an edit form'

    @element 'a', { href: '#' }, ->
      @text 'Add Item'
      @onClick '_.addItem'

    @element 'a', { href: '#' }, ->
      @text 'Update Item'
      @onClick '_.updateItem'

    @element 'a', { href: '#' }, ->
      @text 'Remove Item'
      @onClick '_.removeItem'
