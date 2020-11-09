Meteor.methods

  'users/upsert': (modifier, options) ->
    options = _.extend({
      # Pass false if only inserts should be possible.
      allowUpdate: true
      authorize: true
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

    # Add a default user role for new users. Don't change the roles for existing users unless necessary.
    # If roles are provided, ensure the default role is always present.
    if !existingUser? or roles? then roles = _.union(roles ? [], ['user'])

    if existingUser? and !options.allowUpdate
      throw new Meteor.Error(500, 'User already exists.')
    else if options.authorize and !isAdmin and existingUser? and existingUser._id != @userId
      AccountsUtil.authorizeAction('updateUser', {userId: existingUser._id})
    else if options.authorize and !isAdmin and !existingUser? and !signUpAllowed
      throw new Meteor.Error(403, 'SignUp not permitted.')
    
    unless existingUser then modifier.createdAt = new Date()

    enabled = modifier.enabled
    if enabled? and options.authorize and !isAdmin
      throw new Meteor.Error(403, 'Only admins can enable/disable users.')
    else if existingUser? and AccountsUtil.isAdmin(existingUser) and enabled?
      throw new Meteor.Error(403, 'Admins cannot be enabled/disabled')
    unless existingUser
      # For users without the `enabled` field, enable them if we don't require sign-up approval
      # or the admin user is creating the new user.
      requireApproval = config.signUp.requireApproval
      if Types.isFunction(requireApproval)
        requireApprovalValue = requireApproval.call(this, Setter.clone(modifier),
            Setter.clone(roles))
      else
        requireApprovalValue = requireApproval
      enabled ?= requireApprovalValue == false or isAdmin
      modifier.enabled = enabled

    Meteor.users.upsert selector, $set: modifier
    user = Meteor.users.findOne(selector)
    email = user.emails?[0]
    enabled = user.enabled
    if password? then Accounts.setPassword(user._id, password)
    Roles.setUserRoles(user._id, roles) if roles?

    Logger.info('Upserted user', user._id)
    return user._id

  'users/remove': (id) ->
    AccountsUtil.authorizeAction('removeUser', {userId: id})
    Meteor.users.remove(id)

Accounts.validateLoginAttempt (attempt) ->
  return false unless attempt.allowed and attempt.user?
  user = attempt.user
  config = AccountsUi.config()
  signUp = config.signUp
  if config.account.alwaysEnabled or (config.account.enabledByDefault and user.enabled != false) or
      AccountsUtil.isAdmin(user) or
      user.enabled == true
    return true
  else
    throw new Meteor.Error(403, config.strings.disabledAccount)

# Default roles.
AccountsUtil.createRoles(['admin', 'user'])
