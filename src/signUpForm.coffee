Form = AccountsForm.define('signUpForm')

Form.created = ->
  @isSuccess = new ReactiveVar(false)

Form.helpers
  settings: -> getUserFormSettings()
  userFormData: -> settings: getUserFormSettings()
  userFormTemplateName: -> getSettings().userFormTemplateName ? 'userForm'
  isSuccess: -> Form.getTemplate().isSuccess.get()

Form.events
  'submit form': (e, template) ->
    Form.clearMessages()

getUserFormSettings = (template) ->
  settings =
    onSuccess: ->
      Logger.track 'Accounts signup success'
      template = Form.getTemplate(@template)
      template.isSuccess.set(true)
      Form.clearMessages(template)
      onFinish(template)
    onError: (operation, err) ->
      Logger.track 'Accounts signup failure', error: err.toString()
      template = Form.getTemplate(@template)
      template.isSuccess.set(false)
      Form.clearMessages(template)
      msg = Form.createErrorMessage(err)
      Form.addMessage(msg, template)
      onFinish(template)
    # Ensures the server fails early with a meaningful message rather than a cryptic MongoDB error
    # if existing user details are submitted.
    allowUpdate: false
    # Don't notify with Logger since we're printing error messages in this template.
    loggerNotify: false

  _.extend settings, getSettings(template)

getSettings = (template) -> Form.getTemplate(template).data?.settings ? {}
getUserForm = (template) -> $('.user-form')
onFinish = (template) -> Form.getSubmitButton(template).removeClass('disabled')
