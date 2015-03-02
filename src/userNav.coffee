TemplateClass = Template.userNav

TemplateClass.events
  
  'click .logout.button': (e, template) ->
    result = confirm('Are you sure you want to logout?')
    Meteor.logout() if result
  
  'click .login.button': (e, template) -> AccountsUi.goToLogin()
