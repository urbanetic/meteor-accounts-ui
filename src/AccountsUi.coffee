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

  signInRequired: (router, args) ->
    args = Setter.merge({
      callNext: true
    }, args)
    user = Meteor.user()
    @goToLogin() unless user
    if args.callNext then router.next()

  onAfterLogin: -> @_config.afterLogin?()

  goToLogin: -> Router.go(@_config.loginRoute)
