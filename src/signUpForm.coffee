Form = AccountsForm.define('signUpForm')

Form.created = ->
  @isSuccess = new ReactiveVar(false)

Form.helpers
  settings: ->
    onSuccess: ->
      template = Form.getTemplate(@template)
      template.isSuccess.set(true)
      onFinish(template)
    onError: (operation, err) ->
      template = Form.getTemplate(@template)
      template.isSuccess.set(false)
      msg = Form.createErrorMessage(err)
      Form.addMessage(msg, template)
      onFinish(template)
  isSuccess: -> Form.getTemplate().isSuccess.get()

Form.events
  'click .submit.button': (e, template) ->
    Form.clearMessages()
    $form = $('form', getUserForm(template))
    Form.getSubmitButton(template).addClass('disabled')
    $form.submit()

getUserForm = (template) -> $('.user-form')
onFinish = (template) -> Form.getSubmitButton(template).removeClass('disabled')
