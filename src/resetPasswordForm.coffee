Form = AccountsForm.define('resetPasswordForm')

Form.events
  
  'click .cancel.button': -> AccountsUi.goToLogin()

  'click .submit.button': (e, template) ->
    Form.clearMessages()
    newPassword = template.$('[name="password"]').val().trim()
    if newPassword.length == 0
      Form.addMessage Form.createErrorMessage('Email field is missing'), template
      return
    $submit = $(e.currentTarget).addClass('disabled')
    Accounts.resetPassword Session.get('resetToken'), newPassword, (err, result) ->
      $submit.removeClass('disabled')
      if err
        msg = Form.createErrorMessage(err)
      else
        msg = Form.createMessage('Password reset.', 'green')
        setTimeout (-> Router.go('login')), 1000
      Form.addMessage(msg, template)

