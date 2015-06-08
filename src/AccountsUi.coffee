AccountsUi =

  _config: null

  config: (config) ->
    @_config ?=
      login:
        route: 'login'
        template: 'loginForm'
      forgot:
        enabled: false
        route: 'forgot'
        template: 'forgotForm'
      signUp:
        enabled: false
        route: 'signup'
        template: 'signUpForm'
      passwordSignupFields: 'USERNAME_AND_EMAIL'
      setUpRoutes: ->
        config = @config()
        createRoute(config.login.route, config.login.template)
        if config.forgot.enabled == true
          createRoute(config.forgot.route, config.forgot.template)

    Setter.merge(@_config, config)
    unless config then return @_config
    setUp.call(@)
    setUpRoutes(@_config.setUpRoutes)
    @_config

  signInRequired: (router, args) ->
    args = Setter.merge({
      callNext: true
    }, args)
    user = Meteor.user()
    @goToLogin() unless user
    if args.callNext then router.next()

  onAfterLogin: -> @_config.afterLogin?()

  goToLogin: -> Router.go(@_config.login.route)

  goToForgot: ->
    unless @_config.forgot.enabled
      throw new Error('Forgot password not allowed')
    Router.go(@_config.forgot.route)

setUpRoutes = _.once (callback) -> callback.call(AccountsUi)
createRoute = (route, templateName) ->
  Router.route route,
    path: route
    template: templateName

setUp = _.once ->
  config = @config()
  Accounts.ui.config(passwordSignupFields: config.passwordSignupFields)
