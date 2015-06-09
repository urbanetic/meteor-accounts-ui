Form = AccountsForm.define('signUpForm')

Form.helpers
  settings: ->
    onSuccess: ->
      console.log('on success', arguments)

Form.events
  
  'click .cancel.button': -> AccountsUi.goToLogin()

  'click .submit.button': (e, template) ->
    Form.clearMessages()
    $form = $('form', getUserForm(template))
    $form.submit()

getUserForm = (template) -> $('.user-form')
