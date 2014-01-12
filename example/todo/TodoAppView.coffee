
define ['cs!tubularHtml', 'cs!tubularForm'], (tubularHtml, tubularForm) ->
  ->
    this.app = window.app;

    class Action
      constructor: (@callback) ->
        @isPending = false
        @currentPromise = null

      invoke: ->
        promise = callback()

        @isPending = true
        @currentPromise = promise

        onCompletion = =>
          if @currentPromise is promise
            @isPending = false
            @currentPromise = null

        if @currentPromise.then
          @currentPromise.then onCompletion
        else
          onCompletion()

    tubularHtml.install this, (element) ->
      # immediately append
      # @todo this could be saved for later appending elsewhere, too
      document.getElementById('container').appendChild(element)

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
      dataTodoItemCount: '{{ app.itemList.length }}'
    }, ->

      @fork { tabs: createMenu([ 'Main', 'Settings' ]) }, ->
        @element 'ul', ->
          @each 'tabs', 'tab', (tabIndex) ->
            @element 'li', ->
              @element 'a', { href: '#' }, ->
                @text '{{ tab.label }}'
                @onClick => @tab.activate()

        @each 'tabs', 'tab', (tabIndex) ->
          @when 'tab.active', ->
            @element 'fieldset', ->
              @element 'legend', ->
                @text '{{ tab.label }}'

      @when 'app.itemList.length', ->
        @element 'h1#sampleHeading', ->
          @text 'Hello, world {{ app.itemList.length }}'

        @element 'ul', ->
          @each 'app.itemList', 'item', ->
            @element 'li', ->
              @text 'This is: {{ item.label }}'

              testAction = ((label, cb) -> setTimeout (-> cb('Error processing action')), 500)

              @element 'form[action=]', ->
                labelGetter = null
                @action = new tubularForm(=>
                  testAction labelGetter()
                )

                @onSubmit =>
                  @action.invoke()

                @when 'action.isPending', ->
                  @text 'Loading...'

                @when 'action.error', ->
                  @text '{{ action.error }}'

                @element 'label', ->
                  @text 'Enter new item label'
                  @element 'input[type=text]', ->
                    labelGetter = (=> @value())

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
