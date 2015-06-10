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
      verify:
        path: 'verify-email/:verifyToken'
        template: 'verifyForm'
        onBeforeAction: ->
          verifyToken = @params.verifyToken
          Session.set('verifyToken', verifyToken)
          @next()
      strings:
        disabledAccount: 'Your account has not been activated. Please contact us for assistance.'
        resetDisabledAccount: 'Password reset. Your account has not yet been activated. ' +
            'Please contact us for assistance.'
      email:
        fromAddress: null
        adminAddress: null
      # passwordSignupFields: 'USERNAME_AND_EMAIL'
      setUpRoutes: ->
        config = @config()
        createRoute 'login', config.login
        if config.forgot.enabled == true
          createRoute 'forgotPassword', config.forgot
          createRoute 'resetPassword', config.reset
        if config.signUp.enabled == true
          createRoute 'signUp', config.signUp
          createRoute 'verifyEmail', config.verify

        Tracker.autorun ->
          user = Meteor.user()
          currentRoute = Router.getCurrentName()
          if currentRoute == 'login' && user then config.login.onSuccess?()
        Routes.crudRoute Meteor.users,
          data:
            settings:
              onSuccess: -> Router.goToLastPath() || Router.go('/')
              onCancel: -> Router.goToLastPath() || Router.go('/')
          onBeforeAction: -> if Meteor.isAdmin() then @next() else AccountsUi.goToLogin()

    Setter.merge(@_config, config)
    unless config then return @_config
    unless @_config.email.adminAddress
      throw new Error('AccountsUi: Admin email address not provided')
    unless @_config.email.fromAddress
      throw new Error('AccountsUi: From email address not provided')
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

ROUTE_NAMES = ['login', 'forgotPassword', 'resetPassword', 'signUp', 'verifyEmail']
setUpRoutes = _.once (callback) -> callback.call(AccountsUi)
createRoute = (name, args) -> Router.route name,
  # NOTE: We mix various properties so it's not safe to pass all arguments into route().
  path: args.path
  template: args.template
  onBeforeAction: args.onBeforeAction

if Meteor.isServer
  Meteor.startup ->
    # Redefine these URLs to be compatible with Iron Router by removing the '#/' prefix.
    Accounts.urls.resetPassword = (token) -> Meteor.absoluteUrl('reset-password/' + token)
    # Enrolling will send a link to verify the email address.
    Accounts.urls.enrollAccount = (token) -> Meteor.absoluteUrl('enroll-account/' + token)
    Accounts.urls.verifyEmail = (token) -> Meteor.absoluteUrl('verify-email/' + token)

  _.extend AccountsUi,
    createEmail: (email) ->
      config = AccountsUi.config()
      email = _.extend({
        from: config.email.fromAddress
      }, email)

    sendEmail: (email) ->
      @unblock()
      Email.send(email)

    sendEmailToAdmin: (email) ->
      config = AccountsUi.config()
      email = _.extend({
        to: config.email.adminAddress
      }, email)
      @sendEmail(email)
      Logger.info('Sent email to admin', email)

    sendEmailToUser: (args) ->
      selector = args.user
      delete args.user
      email = args
      config = AccountsUi.config()
      user = Meteor.users.findOne(selector)
      unless user
        Logger.warn('Cannot send email to user - selector found no matches', selector, email)
        return
      emailAddress = user.emails[0].address
      unless emailAddress
        Logger.warn('Could not send email to user - no email address', selector, email)
        return
      email = _.extend({
        to: emailAddress
      }, email)
      @sendEmail(email)
      Logger.info('Sent email to user', selector, email)
