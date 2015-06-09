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
    enabled = false
    if !config.signUp.requireApproval || isAdmin then enabled = true

    modifier = Objects.flattenProperties(modifier)
    username = modifier.username
    name = modifier.name
    if name
      delete modifier.name
      modifier['profile.name'] = name
    password = modifier.password
    delete modifier.password
    emails = modifier.emails
    roles = modifier.roles || []
    delete modifier.roles
    roles = _.union(roles, ['user'])

    selector = {}
    if modifier._id
      selector._id = modifier._id
      delete modifier._id
    else if username
      selector.username = username
    
    Logger.info('Upserting user', selector, modifier)

    user = Meteor.users.findOne(selector)
    if !user && !password
      throw new Meteor.Error(500, 'Cannot create a user without a password.')
    else if (user && !options.allowUpdate)
      throw new Meteor.Error(500, 'User already exists and updates are not allowed.')
    else if !user && !isAdmin && user._id != @userId
      throw new Error(403, 'Not authorized to update other users.')
    Meteor.users.upsert selector, $set: modifier
    user = Meteor.users.findOne(selector)
    password && Accounts.setPassword(user._id, password)
    Roles.setUserRoles(user._id, roles)
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
