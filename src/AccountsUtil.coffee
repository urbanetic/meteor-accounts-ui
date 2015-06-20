AccountsUtil =

  AUTHOR_FIELD: 'author'

  addCollectionAuthorization: (collection, options) ->
    options = _.extend({
    }, options)
    AUTHOR_FIELD = @AUTHOR_FIELD
    if Meteor.isServer
      name = Collections.getName(collection)
      # Only publish documents belonging to the logged in user.
      Meteor.publish name, ->
        userId = this.userId
        return unless userId
        user = Meteor.users.findOne(userId)
        username = user.username
        Logger.info("User '#{username}' subscribed to collection '#{name}'")
        @onStop ->
          Logger.info("User '#{username}' unsubscribed from collection '#{name}'")
        if username == 'admin'
          # Admin can see all docs.
          collection.find()
        else
          if options.userSelector
            selector = options.userSelector(userId: userId, user: user, username: username)
          else
            selector = {}
            selector[AUTHOR_FIELD] = username
          collection.find(selector)

    # Add the logged in user as the author when a doc is created in the collection.
    collection.before.insert (userId, doc) ->
      user = Meteor.users.findOne(userId)
      author = doc[AUTHOR_FIELD] ?= user?.username
      unless author
        suffix = ' when inserting doc in collection ' + Collections.getName(collection)
        if !user?
          throw new Error('User not provided' + suffix)
        else if !user.username?
          throw new Error('No username provided' + suffix)
        else
          throw new Error('No author provided' + suffix)
  
  isOwner: (doc, user) ->
    user = @resolveUser(user)
    doc[@AUTHOR_FIELD] == user?.username

  isOwnerOrAdmin: (doc, user) -> @isOwner(doc, user) || @isAdmin(user)

  isAuthorized: (doc, user, predicate) ->
    user = @resolveUser(user)
    if predicate
      predicate(doc, user)
    else
      isOwnerOrAdmin(user)

  authorize: (doc, user, predicate) ->
    unless @isAuthorized(doc, user, predicate)
      throw new Meteor.Error(403, 'Access denied')

  isAdmin: (user) ->
    user = @resolveUser(user)
    Roles.userIsInRole(user, 'admin')

  resolveUser: (user) ->
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

  allowOwner: (userId, doc) -> @isOwnerOrAdmin(doc, userId)

  setUpCollectionAllow: (collection) ->
    allowOwner = @allowOwner.bind(@)
    collection.allow
      insert: (userId, doc) -> userId?
      update: allowOwner
      remove: allowOwner

# Set up role publications.

if Meteor.isServer
  Meteor.publish 'roles', -> Meteor.roles.find({})
else
  Meteor.subscribe('roles')
