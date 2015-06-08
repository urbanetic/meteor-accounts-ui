TemplateClass = Template.userNav

TemplateClass.events
  
  'click .logout.button': (e, template) ->
    result = confirm('Are you sure you want to logout?')
    Meteor.logout() if result
  
  'click .login.button': (e, template) -> AccountsUi.goToLogin()

TemplateClass.helpers

  onAccountsRoute: ->
    config = AccountsUi.config()
    currentRoute = Router.getCurrentName()
    routes = [config.login.route, config.forgot.route, config.signUp.route]
    _.indexOf(routes, currentRoute) >= 0
