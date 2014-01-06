
(if define? then define else ((module) -> window.tubularHtml = module()))(->
  install: (viewModel) ->
    viewModel.form = (options, actionArgumentList, formSubTemplate) ->
      action = options.action
      fieldGetterMap = {}

      form = {
        action: null
        refresh: (->) # dummy hook to trigger watch-list refresh @todo this better!
      }

      field = (name, fieldSubTemplate) ->
        @fork {
          fieldValue: (callback) ->
            if fieldGetterMap[name]
              throw 'field ' + name + ' already defined'
            else
              fieldGetterMap[name] = callback
        }, fieldSubTemplate

      @element 'form[action=]', ->
            @form = form
            formElement = @$tubularHtmlCursor()

            onSubmit = (event) =>
              event.preventDefault()

              actionRequest = { incomplete: true }

              argumentValues = (fieldGetterMap[v]() for v in actionArgumentList)
              console.log 'submitting', argumentValues

              argumentValues.push (err, success) =>
                actionRequest.incomplete = false
                actionRequest.error = if err then err else null
                actionRequest.value = if err then null else success

                console.log 'submit complete', actionRequest

                @get([ 'form', 'refresh' ])()

              form.action = actionRequest
              @get([ 'form', 'refresh' ])()

              action.apply(null, argumentValues)

              false

            formElement.addEventListener 'submit', onSubmit, false
            @$tubularHtmlOnDestroy -> formElement.removeEventListener 'submit', onSubmit

            @fork {
              field: field
            }, formSubTemplate
)
