AccountsUi =

  _config: null

  config: (config) ->
    config = @_config = _.extend({
      loginRoute: 'login'
      loginTemplate: 'loginForm'
    }, config)
    loginRoute = config.loginRoute
    loginTemplate = config.loginTemplate
    if Router
      Router.route(loginRoute, {path: loginRoute, template: loginTemplate})

  signInRequired: (router) ->
    config = @_config
    user = Meteor.user()
    @goToLogin() unless user
    router.next()

  onAfterLogin: -> @_config.afterLogin?()

  goToLogin: -> Router.go(@_config.loginRoute)
