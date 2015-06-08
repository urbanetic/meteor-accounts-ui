@AccountsForm =

  define: (name) ->
    Form = Template[name]

    Form.helpers
      config: -> AccountsUi.config()

    Form.events
      'submit form': (e, template) ->
        e.preventDefault()
        Form.clearMessages()
    
    _.extend Form,
      getFormDom: (template) -> @getTemplate(template).$('form')

      getSubmitButton: (template) -> @getTemplate(template).$('[type="submit"]')

      clearMessages: (template) ->
        @getFormDom(template).removeClass('error')
        @getMessagesDom(template).empty()

      addMessage: ($message, template) ->
        if Types.isString($message)
          $message = @createMessage($message)
        @getMessagesDom(template).prepend($message)
        @getFormDom(template).toggleClass 'error', $message.hasClass('error')

      getMessagesDom: (template) -> @getTemplate(template).$('.messages')

      getUsernameInput: (template) -> @getTemplate(template).$('[name="username"]')

      createMessage: (msg, type) -> $('<div class="ui message ' + type + '">' + msg + '</div>')

      createErrorMessage: (err) ->
        msg = err.reason ? err.toString()
        @createMessage(msg, 'error')

      getTemplate: (template) -> Templates.getNamedInstance(name, template)
