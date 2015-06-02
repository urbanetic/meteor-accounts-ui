AccountsUtil =

  addCollectionAuthorization: (collection, options) ->
    options = _.extend({
    }, options)
    if Meteor.isServer
      name = Collections.getName(collection)
      # Only publish documents belonging to the logged in user.
      Meteor.publish name, ->
        userId = this.userId
        return unless userId
        user = Meteor.users.findOne(userId)
        username = user.username
        Logger.info('User subscribed to collection', userId, username, name)
        @onStop ->
          Logger.info('User unsubscribed from collection', userId, username, name)
        if username == 'admin'
          # Admin can see all docs.
          collection.find()
        else
          if options.userSelector
            selector = options.userSelector(userId: userId, user: user, username: username)
          else
            selector = {author: username}
          collection.find(selector)

    # Add the logged in user as the author when a doc is created in the collection.
    collection.before.insert (userId, doc) ->
      doc.author = Meteor.users.findOne(userId)?.username
  
  isOwner: (doc, user) ->
    user = @_resolveUser(user)
    doc.author == user.username

  authorize: (doc, user, predicate) ->
    user = @_resolveUser(user)
    if predicate
      result = predicate(doc, user)
    else
      result = @isOwner(doc, user) || @isAdmin(user)
    unless result
      throw new Meteor.Error(403, 'Access denied')

  isAdmin: (user) ->
    user = @_resolveUser(user)
    Roles.userIsInRole(user, 'admin')

  _resolveUser: (user) ->
    if Types.isString(user)
      user = Meteor.users.findOne(user)
    else
      # If no user is provided, attempt to request the current one. This will fail in publish
      # methods where this.userId should be used instead. If this is undefined since no user is
      # logged in, the logic below will still be invoked. In this case, we should consume the
      # exception.
      try
        user ?= Meteor.user()
      catch e
    user

# Set up role publications.

if Meteor.isServer
  Meteor.publish 'roles', -> Meteor.roles.find({})
else
  Meteor.subscribe('roles')
