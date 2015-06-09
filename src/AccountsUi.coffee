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
        requireApproval: true
        path: 'sign-up'
        template: 'signUpForm'
      strings:
        disabledAccount: 'Your account has not been activated. Please contact us for assistance.'
      # passwordSignupFields: 'USERNAME_AND_EMAIL'
      setUpRoutes: ->
        config = @config()
        createRoute 'login', config.login
        if config.forgot.enabled == true
          createRoute 'forgotPassword', config.forgot
          createRoute 'resetPassword', config.reset
        if config.signUp.enabled == true
          createRoute 'signUp', config.signUp
        Tracker.autorun ->
          user = Meteor.user()
          currentRoute = Router.getCurrentName()
          if currentRoute == 'login' && user then AccountsUi.onAfterLogin()
        Routes.crudRoute Meteor.users,
          data:
            settings:
              onSuccess: -> Router.goToLastPath() || Router.go('/')
              onCancel: -> Router.goToLastPath() || Router.go('/')
          onBeforeAction: -> if Meteor.isAdmin() then @next() else AccountsUi.goToLogin()

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

  goToSignUp: ->
    unless @_config.forgot.enabled
      throw new Error('Sign-up not allowed')
    Router.go('signUp')

  isOnAccountsRoute: ->
    config = @config()
    currentRoute = Router.getCurrentName()
    _.indexOf(ROUTE_NAMES, currentRoute) >= 0

ROUTE_NAMES = ['login', 'forgotPassword', 'resetPassword', 'signUp']
setUpRoutes = _.once (callback) -> callback.call(AccountsUi)
createRoute = (name, args) -> Router.route name, args
# Set up the default configuration.
AccountsUi.config()

if Meteor.isServer
  Meteor.startup ->
    # Redefine these URLs to be compatible with Iron Router by removing the '#/' prefix.
    Accounts.urls.resetPassword = (token) -> Meteor.absoluteUrl('reset-password/' + token)
    Accounts.urls.enrollAccount = (token) -> Meteor.absoluteUrl('enroll-account/' + token)
