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
        # Whether users are initially disabled and require admin approval after sign-up.
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
        templates:
          activation:
            subject: 'Account Activation'
            html: (args) -> '<p>Your user account has been activated. Please log in with ' +
              'the link below:</p><a href="' + args.loginUrl + '">' + args.loginUrl + '</a>'
          # Uses the default in Meteor.
          verifyEmail: {}
          resetPassword: {}
      account:
        # Whether users (existing and future) are enabled unless explicitly disabled.
        enabledByDefault: false

      setUpRoutes: ->
        config = @config()
        createRoute 'login', config.login
        if config.forgot.enabled == true
          createRoute 'forgotPassword', config.forgot
          createRoute 'resetPassword', config.reset
        if config.signUp.enabled == true
          createRoute 'signUp', config.signUp
          createRoute 'verifyEmail', config.verify

        @_loginHandle = Tracker.autorun =>
          config = @config()
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
    clonedConfig = Setter.clone(@_config)
    unless config then return clonedConfig
    setUpRoutes(@_config.setUpRoutes) if Meteor.isClient
    @setUpTemplates() if Meteor.isServer
    clonedConfig

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

  getAdminController: _.once (args) ->
    args = Setter.merge
      onBeforeAction: ->
        return unless @ready()
        AccountsUi.signInRequired(@, {callNext: false})
        user = Meteor.user()
        if AccountsUtil.isAdmin(user) then @next() else AccountsUi.goToLogin()
    , args
    Routes.getBaseController().extend(args)

ROUTE_NAMES = ['login', 'forgotPassword', 'resetPassword', 'signUp', 'verifyEmail']
setUpRoutes = _.once (callback) -> callback.call(AccountsUi)
createRoute = (name, args) ->
  routerArgs = {}
  _.each ['path', 'template', 'layoutTemplate', 'controller', 'onBeforeAction'], (property) ->
    routerArgs[property] = args[property] if args[property]?
  Router.route name, routerArgs

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
      fromAddress = config.email.fromAddress
      unless fromAddress
        throw new Error('AccountsUi: "from" email address not provided')
      email = Setter.defaults email,
        from: fromAddress
      Logger.info('Created email', email)
      email

    sendEmail: (email) ->
      email = @createEmail(email)
      @_trySendEmail(email, 3)

    _trySendEmail: (email, triesLeft) ->
      return unless triesLeft > 0
      try
        @_sendEmail(email)
      catch err
        Logger.error('Error sending email', err, email)
        triesLeft--
        if triesLeft > 0
          Logger.info 'Retrying email -', triesLeft, Strings.pluralize('try', triesLeft, 'tries'),
              'left...'
          _.delay(
            => @_trySendEmail(email, triesLeft)
            2000
          )

    _sendEmail: (email) -> Email.send(email)

    sendEmailToAdmin: (email) ->
      config = AccountsUi.config()
      adminAddress = config.email.adminAddress
      unless adminAddress
        throw new Error('AccountsUi: Admin email address not provided')
      email = Setter.defaults email,
        to: adminAddress
      @sendEmail(email)

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
      email = Setter.defaults email,
        to: emailAddress
      @sendEmail(email)

    setUpTemplates: ->
      # Merges any email template overrides into the Meteor config.
      config = @config()
      _.each ['resetPassword', 'enrollAccount', 'verifyEmail'], (prop) ->
        _.extend Accounts.emailTemplates[prop], config.email.templates[prop]
