Meteor.methods

  'users/upsert': (modifier, options) ->
    options = _.extend({
      # Pass false if only inserts should be possible.
      allowUpdate: true
    }, options)
    isAdmin = AccountsUtil.isAdmin(@userId)
    config = AccountsUi.config()
    signUpAllowed = config.signUp.enabled
    unless isAdmin || signUpAllowed
      throw new Meteor.Error(403, 'SignUp not permitted.')

    modifier = Objects.flattenProperties(modifier)
    username = modifier.username
    name = modifier.name
    if name?
      delete modifier.name
      modifier['profile.name'] = name
    password = modifier.password
    delete modifier.password
    roles = modifier.roles || []
    delete modifier.roles
    roles = _.union(roles, ['user'])
    enabled = modifier.enabled
    if enabled? && !isAdmin
      throw new Meteor.Error(403, 'Only admins can enable/disable users.')
    enabled ?= !config.signUp.requireApproval || isAdmin
    modifier.enabled = enabled

    selector = {}
    if modifier._id
      selector._id = modifier._id
      delete modifier._id
    else if username
      selector.username = username
    
    Logger.info('Upserting user', selector, modifier)

    existingUser = Meteor.users.findOne(selector)
    if (existingUser? && !options.allowUpdate)
      throw new Meteor.Error(500, 'User already exists and updates are not allowed.')
    else if !isAdmin && existingUser? && existingUser._id != @userId
      throw new Meteor.Error(403, 'Not authorized to update other users.')
    Meteor.users.upsert selector, $set: modifier
    user = Meteor.users.findOne(selector)
    email = user.emails?[0]
    enabled = user.enabled
    if password? then Accounts.setPassword(user._id, password)
    Roles.setUserRoles(user._id, roles)

    # Create a user table for use in emails.
    row = (title, content) -> '<tr><th>' + title + '</th><td>' + content + '</td></tr>'
    userTable =
      '<table>' + 
      row('ID', user._id) +
      row('Name', user.profile.name) +
      row('Email', email?.address) +
      '</table>'
    
    # Send an email for sign-ups.
    unless existingUser?
      Logger.info('User sign-up succeeded')
      # Send the admin an email to notify of new users.
      AccountsUi.sendEmailToAdmin
        subject: 'User Sign-Up'
        html: '<p>A new user has signed up:</p>' + userTable

      # Send the user a new email to verify their email address.
      if email? && email.verified != true
        # If no password is set then the enrollment link will create a password for the user.
        # If the password is set, the user only needs to verify their email address.
        if password?
          Accounts.sendVerificationEmail(user._id)
        else
          # TOOD(aramk) Not handled - set a password for now
          throw new Meteor.Error(500, 'User must have a password set - AccountsUi cannot handle ' +
              'enrollment yet.')
          # Accounts.sendEnrollmentEmail(user._id)
      Logger.info('Sent sign-up email to new user')
    
    if existingUser? && existingUser.enabled != enabled
      action = if enabled then 'enabled' else 'disabled'
      Logger.info('User ' + action, user._id)
      AccountsUi.sendEmailToAdmin
        subject: 'User ' + Strings.toTitleCase(action)
        html: '<p>User has been ' + action + '</p>' + userTable
      if enabled && email?
        loginUrl = 'http://' + Accounts.emailTemplates.siteName + '/' + config.login.path
        AccountsUi.sendEmailToUser
          user: user._id
          subject: 'Account Activation'
          html: '<p>Your user account has been activated. Please log in with the link below:</p>' +
              '<a href="' + loginUrl + '">' + loginUrl + '</a>'

    Logger.info('Upserted user', user._id)
    user._id

  'users/remove': (id) ->
    unless AccountsUtil.isAdmin(@userId)
      throw new Meteor.Error(403, 'Admin privileges required.')
    Meteor.users.remove(id)

Accounts.validateLoginAttempt (attempt) ->
  return false unless attempt.allowed
  config = AccountsUi.config()
  user = attempt.user
  if config.signUp.requireApproval && user.enabled != true && !AccountsUtil.isAdmin(user)
    throw new Meteor.Error(403, config.strings.disabledAccount)
  return true