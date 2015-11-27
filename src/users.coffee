Meteor.methods

  'users/upsert': (modifier, options) ->
    options = _.extend({
      # Pass false if only inserts should be possible.
      allowUpdate: true
    }, options)
    isAdmin = AccountsUtil.isAdmin(@userId)
    config = AccountsUi.config()
    signUpAllowed = config.signUp.enabled

    modifier = Objects.flattenProperties(modifier)
    username = modifier.username
    name = modifier.name
    if name?
      delete modifier.name
      modifier['profile.name'] = name
    password = modifier.password
    delete modifier.password
    roles = modifier.roles
    delete modifier.roles
    if roles? then roles = _.union(roles ? [], ['user'])

    selector = {}
    if modifier._id
      selector._id = modifier._id
      delete modifier._id
    else
      $or = []
      if username
        $or.push {username: username}
      _.each modifier.emails, (email) ->
        $or.push {'emails.address': email.address}
      selector = {$or: $or}
    
    Logger.info('Upserting user', selector, modifier, options)
    # Prevent sending emails from blocking other users.
    @unblock()

    existingUser = Meteor.users.findOne(selector)

    if existingUser? and !options.allowUpdate
      throw new Meteor.Error(500, 'User already exists.')
    else if !isAdmin and existingUser? and existingUser._id != @userId
      throw new Meteor.Error(403, 'Not authorized to update other users.')
    else if !isAdmin and !existingUser? and !signUpAllowed
      throw new Meteor.Error(403, 'SignUp not permitted.')
    
    unless existingUser then modifier['profile.signUp.date'] = new Date()

    enabled = modifier.enabled
    if enabled? and !isAdmin
      throw new Meteor.Error(403, 'Only admins can enable/disable users.')
    else if existingUser? and AccountsUtil.isAdmin(existingUser) and enabled?
      throw new Meteor.Error(403, 'Admins cannot be enabled/disabled')
    unless existingUser
      # For users without the `enabled` field, enable them if we don't require sign-up approval
      # or the admin user is creating the new user.
      enabled ?= config.signUp.requireApproval == false or isAdmin
      modifier.enabled = enabled

    Meteor.users.upsert selector, $set: modifier
    user = Meteor.users.findOne(selector)
    email = user.emails?[0]
    enabled = user.enabled
    if password? then Accounts.setPassword(user._id, password)
    Roles.setUserRoles(user._id, roles) if roles?

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
      if email? and config.email.enabled and email.verified != true
        # If no password is set then the enrollment link will create a password for the user.
        # If the password is set, the user only needs to verify their email address.
        if password?
          Accounts.sendVerificationEmail(user._id)
        else
          # TOOD(aramk) Not handled - set a password for now
          throw new Meteor.Error(500, 'User must have a password set - AccountsUi cannot handle ' +
              'enrollment yet.')
      
        Logger.info('Sent sign-up email to new user')
    
    if existingUser? and existingUser.enabled != enabled
      action = if enabled then 'enabled' else 'disabled'
      Logger.info('User ' + action, user._id)
      AccountsUi.sendEmailToAdmin
        subject: 'User ' + Strings.toTitleCase(action)
        html: '<p>User has been ' + action + '</p>' + userTable
      if enabled and !user.profile.activation?.date?
        Meteor.users.upsert selector, $set:
          'profile.activation.date': new Date()
        user = Meteor.users.findOne(selector)
        if email?
          siteUrl = 'http://' + Accounts.emailTemplates.siteName + '/'
          templateArgs =
            user: user
            siteUrl: siteUrl
            loginUrl: siteUrl + config.login.path
          emailArgs = {user: user._id}
          emailConfig = config.email.templates.activation
          _.each emailConfig, (value, key) ->
            if Types.isFunction(value) then value = value.call(emailConfig, templateArgs)
            emailArgs[key] = value
          AccountsUi.sendEmailToUser(emailArgs)

    Logger.info('Upserted user', user._id)
    user._id

  'users/remove': (id) ->
    unless AccountsUtil.isAdmin(@userId)
      throw new Meteor.Error(403, 'Admin privileges required.')
    Meteor.users.remove(id)

Accounts.validateLoginAttempt (attempt) ->
  return false unless attempt.allowed
  user = attempt.user
  config = AccountsUi.config()
  signUp = config.signUp
  if (config.account.enabledByDefault and user.enabled != false) or
      AccountsUtil.isAdmin(user) or
      user.enabled == true
    return true
  else
    throw new Meteor.Error(403, config.strings.disabledAccount)

# Default roles.
AccountsUtil.createRoles(['admin', 'user'])
