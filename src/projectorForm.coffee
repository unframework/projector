
(if define? then define else ((module) -> window.projectorHtml = module()))(->
  (viewModel) ->
    viewModel.form = (options, actionArgumentList, formSubTemplate) ->
      action = options.action
      fieldGetterMap = {}

      form = {
        action: null
      }

      field = (name, fieldSubTemplate) ->
        @fork ->
          @fieldValue = (callback) ->
            if fieldGetterMap[name]
              throw 'field ' + name + ' already defined'
            else
              fieldGetterMap[name] = callback

          fieldSubTemplate.call(this)

      @element 'form[action=]', ->
            @form = form
            formElement = @$projectorHtmlCursor()

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

                @refresh()

              form.action = actionRequest
              @refresh()

              action.apply(null, argumentValues)

              false

            formElement.addEventListener 'submit', onSubmit, false

            @fork ->
              @field = field
              formSubTemplate.call(this)
)
