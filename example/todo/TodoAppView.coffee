
define ['cs!tubularHtml', 'cs!tubularForm'], (tubularHtml, tubularForm) ->
  ->
    tubularHtml.install this, (element) ->
      # immediately append
      # @todo this could be saved for later appending elsewhere, too
      document.getElementById('container').appendChild(element)

    tubularForm.install this

    # simple menu view-model
    createMenu = (labelList) ->
      menu = []

      setActiveItem = (index) ->
        for t in menu
          t.active = false
        menu[index].active = true

      createItem = (label) ->
        index = menu.length
        menu.push
          label: label
          active: false
          activate: (-> setActiveItem index)

      createItem(label) for label in labelList
      setActiveItem 0

      menu

    @element '.acme-container-box[role=container]', {
      dataTodoItemCount: '{{ _.itemList.length }}'
    }, ->

      @set 'tabs', createMenu([ 'Main', 'Settings' ]), ->
        @element 'ul', ->
          @each 'tabs', 'tab', (tabIndex) ->
            @element 'li', ->
              @element 'a', { href: '#' }, ->
                @text '{{ tab.label }}'
                @onClick 'tab.activate'

        @each 'tabs', 'tab', (tabIndex) ->
          @when 'tab.active', ->
            @element 'fieldset', ->
              @element 'legend', ->
                @text '{{ tab.label }}'

      @when '_.itemList.length', ->
        @element 'h1#sampleHeading', ->
          @text 'Hello, world {{ _.itemList.length }}'

        @element 'ul', ->
          @each '_.itemList', 'item', ->
            @element 'li', ->
              @text 'This is: {{ item.label }}'

              testAction = ((label, cb) -> setTimeout (-> cb('Error processing action')), 500)
              @form { action: testAction }, [ 'itemLabel' ], ->
                @when 'form.action.incomplete', ->
                  @text 'Loading...'

                @when 'form.action.error', ->
                  @text '{{ form.action.error }}'

                @field 'itemLabel', ->
                  @element 'label', ->
                    @text 'Enter new item label'
                    @element 'input[type=text]', ->
                      @fieldValue (=> @value())

                @element 'button[type=submit]', -> @text 'Save'

      @element 'a', { href: '#' }, ->
        @text 'Add Item'
        @onClick '_.addItem'

      @element 'a', { href: '#' }, ->
        @text 'Update Item'
        @onClick '_.updateItem'

      @element 'a', { href: '#' }, ->
        @text 'Remove Item'
        @onClick '_.removeItem'
