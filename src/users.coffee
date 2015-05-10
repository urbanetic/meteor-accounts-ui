Meteor.methods

  'users/upsert': (userArgs, options) ->
    options = _.extend({
      # Pass false if only inserts should be possible.
      allowUpdate: true
    }, options)
    unless AccountsUtil.isAdmin()
      throw new Meteor.Error(403, 'Admin privileges required.')
    username = userArgs.username
    name = userArgs.name
    password = userArgs.password
    emails = userArgs.emails
    roles = userArgs.roles || []
    roles = _.union(roles, ['user'])
    selector = {}
    if userArgs._id
      selector._id = userArgs._id
    else if username
      selector.username = username
    user = Meteor.users.findOne(selector)
    if !user && !password
      throw new Meteor.Error(500, 'Cannot create a user without a password.')
    else if (user && !options.allowUpdate)
      throw new Meteor.Error(500, 'User already exists and updates are not allowed.')
    Meteor.users.upsert selector,
      $set:
        username: username,
        'profile.name': name,
        emails: emails
    user = Meteor.users.findOne(selector)
    password && Accounts.setPassword(user._id, password)
    Roles.setUserRoles(user._id, roles)
    user._id

  'users/remove': (id) ->
    if !Roles.userIsInRole(Meteor.user(), ['admin'])
      throw new Meteor.Error(403, 'Admin privileges required.')
    Meteor.users.remove(id)
