Form = AccountsForm.define('forgotPasswordForm')

Form.created = ->
  @isSuccess = new ReactiveVar(false)

Form.events
  'click .submit.button': (e, template) ->
    Form.clearMessages()
    # TODO(aramk) Use an AutoForm schema for validation.
    email = template.$('[name="email"]').val().trim()
    if email.length == 0
      Form.addMessage Form.createErrorMessage('Email field cannot be empty'), template
      return
    $submit = $(e.currentTarget).addClass('disabled')
    Accounts.forgotPassword {email: email}, (err, result) ->
      $submit.removeClass('disabled')
      template.isSuccess.set(!err)
      if err
        Logger.track 'Accounts forgot failure', error: err.toString()
        msg = Form.createErrorMessage(err)
      else
        Logger.track 'Accounts forgot success', email: email
        msg = Form.createMessage('An email has been sent. Please check your spam folder.', 'green')
      Form.addMessage(msg, template)

Form.helpers
  isSuccess: -> Form.getTemplate().isSuccess.get()
