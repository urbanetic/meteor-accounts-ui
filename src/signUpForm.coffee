Form = AccountsForm.define('signUpForm')

Form.created = ->
  @isSuccess = new ReactiveVar(false)

Form.helpers
  settings: ->
    onSuccess: ->
      Logger.track 'Accounts signup success'
      template = Form.getTemplate(@template)
      template.isSuccess.set(true)
      onFinish(template)
    onError: (operation, err) ->
      Logger.track 'Accounts signup failure', error: err.toString()
      template = Form.getTemplate(@template)
      template.isSuccess.set(false)
      msg = Form.createErrorMessage(err)
      Form.addMessage(msg, template)
      onFinish(template)
    # Ensures the server fails early with a meaningful message rather than a cryptic MongoDB error
    # if existing user details are submitted.
    allowUpdate: false
    # Don't notify with Logger since we're printing error messages in this template.
    loggerNotify: false
  
  isSuccess: -> Form.getTemplate().isSuccess.get()

Form.events
  'click .submit.button': (e, template) ->
    Form.clearMessages()
    $form = $('form', getUserForm(template))
    Form.getSubmitButton(template).addClass('disabled')
    $form.submit()

getUserForm = (template) -> $('.user-form')
onFinish = (template) -> Form.getSubmitButton(template).removeClass('disabled')
