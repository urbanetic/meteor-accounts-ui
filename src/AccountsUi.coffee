AccountsUi =

  _config: null

  _reactiveConfig: new ReactiveVar()

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
        enabled: true
        fromAddress: null
        adminAddress: null
        emailAdmin: true
        emailUser: true
        templates:
          activation:
            subject: 'Account Activation'
            html: (args) -> '<p>Your user account has been activated. Please log in with ' +
              'the link below:</p><a href="' + args.loginUrl + '">' + args.loginUrl + '</a>'
          # Uses the default in Meteor.
          verifyEmail: {}
          resetPassword: {}
          enrollAccount: {}
      account:
        # Whether users (existing and future) are enabled unless explicitly disabled.
        enabledByDefault: false
        # Whether users are always considered enabled (the enabled property is not enforced).
        alwaysEnabled: false
      # Whether to publish user documents automatically.
      publish:
        enabled: true
        # A callback which returns a boolean for whether users should be published for the given
        # user ID.
        shouldPublish: (userId) -> userId?
        cursor:
          # Returns the selector to use when publishing users given the current user ID.
          getSelector: (userId) -> {}
          # The options passed to the cursor when publishing users given the current user ID.
          getOptions: (userId) ->
            {fields: {profile: 1, emails: 1, roles: 1, username: 1, enabled: 1}}

      setUpRoutes: ->
        return unless Routes?.isConfigured()
        config = @config()
        createRoute 'login', config.login
        if config.forgot.enabled == true
          createRoute 'forgotPassword', config.forgot
          createRoute 'resetPassword', config.reset
        if config.signUp.enabled == true
          createRoute 'signUp', config.signUp
          createRoute 'verifyEmail', config.verify

        # TODO(aramk) Use Accounts.onLogin()?
        @_loginHandle = Tracker.autorun =>
          config = @config()
          user = Meteor.user()
          currentRoute = Router.getCurrentName()
          if currentRoute == 'login' and user
            config.login.onSuccess?()
            # Load requested path before user was redirected to the login form.
            Tracker.nonreactive ->
              afterLoginPath = Session.get('afterLoginPath')
              if afterLoginPath
                Router.go(afterLoginPath)
                Session.set('afterLoginPath', null)

        Routes.crudRoute Meteor.users, Setter.merge
          data:
            settings:
              onSuccess: -> Router.goToLastPath() || Router.go('/')
              onCancel: -> Router.goToLastPath() || Router.go('/')
          onBeforeAction: -> if Meteor.isAdmin() then @next() else AccountsUi.goToLogin()
        , config.usersRoute

    Setter.merge(@_config, config)
    @_reactiveConfig.set(@_config)
    clonedConfig = Setter.clone(@_config)
    unless config then return clonedConfig
    setUpRoutes(@_config.setUpRoutes) if Meteor.isClient
    @setUpTemplates() if Meteor.isServer
    @setUpPubSub()
    clonedConfig

  getReactiveConfig: -> @_reactiveConfig.get()

  signInRequired: (router, args) ->
    args = Setter.merge({
      callNext: true
    }, args)
    user = Meteor.user()
    path = Router.getCurrentPath()
    unless user
      # Since the login route itself will call this method, avoid successive calls.
      Session.setDefault('afterLoginPath', path.path)
      @goToLogin()
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

  setUpPubSub: ->
    config = @config()
    return unless config.publish.enabled
    if Meteor.isServer
      Meteor.publish 'userData', ->
        return [] unless config.publish.shouldPublish(@userId)
        selector = config.publish.cursor.getSelector(@userId)
        options = config.publish.cursor.getOptions(@userId)
        Meteor.users.find(selector, options)
    else if Meteor.isClient
      Meteor.subscribe('userData')


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
    Accounts.urls.enrollAccount = (token) -> Meteor.absoluteUrl('reset-password/' + token)
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
      config = AccountsUi.config()
      return unless config.email.enabled
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
          _.delay(Meteor.bindEnvironment(=> @_trySendEmail(email, triesLeft)), 2000)

    _sendEmail: (email) -> Email.send(email)

    sendEmailToAdmin: (email) ->
      config = AccountsUi.config()
      return unless config.email.enabled
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
      return unless config.email.enabled
      user = Meteor.users.findOne(selector)
      unless user
        Logger.warn('Cannot send email to user - selector found no matches', selector, email)
        return
      emailAddress = user.emails[0].address
      unless emailAddress
        Logger.warn('Could not send email to user - no email address', selector, email)
        return
      to = email.to ?= []
      to.push(emailAddress)
      @sendEmail(email)

    setUpTemplates: ->
      # Merges any email template overrides into the Meteor config.
      config = @config()
      _.each ['resetPassword', 'enrollAccount', 'verifyEmail'], (prop) ->
        _.extend Accounts.emailTemplates[prop], config.email.templates[prop]
