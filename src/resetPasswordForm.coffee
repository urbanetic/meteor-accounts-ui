Form = AccountsForm.define('resetPasswordForm')

Form.created = ->
  @showLoginButton = new ReactiveVar(false)

Form.events
  'click .submit.button': (e, template) ->
    Form.clearMessages()
    newPassword = template.$('[name="password"]').val().trim()
    if newPassword.length == 0
      Form.addMessage Form.createErrorMessage('Email field is missing'), template
      return
    $submit = $(e.currentTarget).addClass('disabled')
    template = Form.getTemplate(template)
    Accounts.resetPassword Session.get('resetToken'), newPassword, (err, result) ->
      template.showLoginButton.set(false)
      $submit.removeClass('disabled')
      if err
        config = AccountsUi.config()
        if err.reason == config.strings.disabledAccount
          msg = Form.createMessage(config.strings.resetDisabledAccount, 'blue')
          template.showLoginButton.set(true)
        else
          msg = Form.createErrorMessage(err)
      else
        msg = Form.createMessage('Password reset. Now logging in.', 'green')
        setTimeout (-> Router.go('login')), 1000
      Form.addMessage(msg, template)

Form.helpers
  showLoginButton: -> Form.getTemplate().showLoginButton.get()
