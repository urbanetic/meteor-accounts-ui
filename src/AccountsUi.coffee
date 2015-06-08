AccountsUi =

  _config: null

  config: (config) ->
    @_config ?=
      login:
        path: 'login'
        template: 'loginForm'
      forgot:
        enabled: false
        path: 'forgot-password'
        template: 'forgotPasswordForm'
      reset:
        # NOTE: This should not be changed since it's used in the generated emails.
        path: 'reset-password/:resetToken'
        template: 'resetPasswordForm'
        onBeforeAction: ->
          resetToken = @params.resetToken
          Session.set('resetToken', resetToken)
          @next()
      signUp:
        enabled: false
        path: 'signup'
        template: 'signUpForm'
      # passwordSignupFields: 'USERNAME_AND_EMAIL'
      setUpRoutes: ->
        config = @config()
        createRoute 'login', config.login
        if config.forgot.enabled == true
          createRoute 'forgotPassword', config.forgot
          createRoute 'resetPassword', config.reset
        Tracker.autorun ->
          user = Meteor.user()
          currentRoute = Router.getCurrentName()
          if currentRoute == 'login' && user then AccountsUi.onAfterLogin()

    Setter.merge(@_config, config)
    unless config then return @_config
    setUpRoutes(@_config.setUpRoutes) if Meteor.isClient
    @_config

  signInRequired: (router, args) ->
    args = Setter.merge({
      callNext: true
    }, args)
    user = Meteor.user()
    currentRoute = Router.getCurrentName()
    @goToLogin() unless user
    if args.callNext then router.next()

  onAfterLogin: -> @_config.afterLogin?()

  goToLogin: -> Router.go('login')

  goToForgot: ->
    unless @_config.forgot.enabled
      throw new Error('Forgot password not allowed')
    Router.go('forgotPassword')

  isOnAccountsRoute: ->
    config = @config()
    currentRoute = Router.getCurrentName()
    routes = ['login', 'forgotPassword', 'resetPassword']
    _.indexOf(routes, currentRoute) >= 0


setUpRoutes = _.once (callback) -> callback.call(AccountsUi)
createRoute = (name, args) -> Router.route name, args
# Set up the default configuration.
AccountsUi.config()

if Meteor.isServer
  Meteor.startup ->
    # Redefine these URLs to be compatible with Iron Router by removing the '#/' prefix.
    Accounts.urls.resetPassword = (token) -> Meteor.absoluteUrl('reset-password/' + token)
    Accounts.urls.enrollAccount = (token) -> Meteor.absoluteUrl('enroll-account/' + token)
