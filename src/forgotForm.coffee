TemplateClass = Template.forgotForm

TemplateClass.events
  
  'click .cancel.button': -> AccountsUi.goToLogin()

  'click .submit.button': (e, template) ->
    username = template.$('[name="username"]')
    AccountsUi.forgotPassword(username: username)
