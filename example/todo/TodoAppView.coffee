
define ['cs!tubularHtml', 'cs!tubularForm', 'cs!tubularExpr'], (tubularHtml, tubularForm, tubularExpr) ->
  ->
    this.app = window.app;

    tubularExpr.install this

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
      dataTodoItemCount: @tmpl('{{ app.itemList.length }}')
    }, ->

      @fork { tabs: createMenu([ 'Main', 'Settings' ]) }, ->
        @element 'ul', ->
          @each @eval('tabs'), 'tab', (tabIndex) ->
            @element 'li', ->
              @element 'a', { href: '#' }, ->
                @text @tmpl('{{ tab.label }}')
                @onClick => @tab.activate()

        @each @eval('tabs'), 'tab', (tabIndex) ->
          @when @eval('tab.active'), ->
            @element 'fieldset', ->
              @element 'legend', ->
                @text @tmpl('{{ tab.label }}')

      @when @eval('app.itemList.length'), ->
        @element 'h1#sampleHeading', ->
          @text @tmpl('Hello, world {{ app.itemList.length }}')

        @element 'ul', ->
          @each @eval('app.itemList'), 'item', ->
            @element 'li', ->
              @text @tmpl('This is: {{ item.label }} eh')

              testAction = ((label, cb) -> setTimeout (-> cb('Error processing action')), 500)
              @form { action: testAction }, [ 'itemLabel' ], ->
                @when @eval('form.action.incomplete'), ->
                  @text 'Loading...'

                @when @eval('form.action.error'), ->
                  @text @tmpl('{{ form.action.error }}')

                @field 'itemLabel', ->
                  @element 'label', ->
                    @text 'Enter new item label'
                    @element 'input[type=text]', ->
                      @fieldValue (=> @value())

                @element 'button[type=submit]', -> @text 'Save'

      @element 'a', { href: '#' }, ->
        @text 'Add Item'
        @onClick => @app.addItem()

      @element 'a', { href: '#' }, ->
        @text 'Update Item'
        @onClick => @app.updateItem()

      @element 'a', { href: '#' }, ->
        @text 'Remove Item'
        @onClick => @app.removeItem()
