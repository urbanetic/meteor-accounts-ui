AccountsUtil =

  AUTHOR_FIELD: 'author'

  addCollectionAuthorization: (collection, options) ->
    options = _.extend({
      publish: true
    }, options)

    AUTHOR_FIELD = @AUTHOR_FIELD
    if Meteor.isServer && options.publish
      name = Collections.getName(collection)
      # Only publish documents belonging to the logged in user.
      Meteor.publish name, ->
        userId = @userId
        return unless userId
        user = Meteor.users.findOne(userId)
        username = user.username
        userStr = "User '#{username}'<#{userId}>"
        Logger.info("#{userStr} subscribed to collection '#{name}'")
        @onStop ->
          Logger.info("#{userStr} unsubscribed from collection '#{name}'")
        
        if AccountsUtil.isAdmin(userId)
          selector = {}
          # Admin can see all docs.
          collection.find()
        else
          if options.userSelector
            selector = options.userSelector(userId: userId, user: user, username: username)
          else
            selector = AccountsUtil._createAuthorSelector(userId, username)

        args = _.toArray(arguments)
        options.beforePublish?.call(@, args, selector)
        collection.find(selector)

    # Add the logged in user as the author when a doc is created in the collection.
    collection.before.insert (userId, doc) ->
      user = Meteor.users.findOne(userId)
      author = doc[AUTHOR_FIELD] ?= user?._id
      unless author
        suffix = ' when inserting doc in collection ' + Collections.getName(collection)
        if !user?
          throw new Error('User not provided' + suffix)
        else
          throw new Error('No author provided' + suffix)
  
  isOwner: (doc, user) ->
    userId = @resolveUser(user)?._id
    userId? && @resolveUser(doc[@AUTHOR_FIELD])?._id == userId

  hasOwner: (doc) -> doc[@AUTHOR_FIELD]?

  isOwnerOrAdmin: (doc, user) -> @isOwner(doc, user) || @isAdmin(user)

  isAuthorized: (doc, user, predicate) ->
    user = @resolveUser(user)
    if predicate
      predicate(doc, user)
    else
      @isOwnerOrAdmin(doc, user)

  authorize: (doc, user, predicate) ->
    unless @isAuthorized(doc, user, predicate)
      throw new Meteor.Error(403, 'Access denied')

  authorizeUser: (user, predicate) ->
    predicate ?= (user) -> user?
    unless predicate(@resolveUser(user)) then throw new Meteor.Error(403, 'Access denied')

  isAdmin: (user) ->
    user = @resolveUser(user)
    Roles.userIsInRole(user, 'admin')

  resolveUser: (user) ->
    if Types.isString(user)
      user = Meteor.users.findOne(@_createUserSelector(user, user))
    else
      # If no user is provided, attempt to request the current one. This will fail in publish
      # methods where this.userId should be used instead. If this is undefined since no user is
      # logged in, the logic below will still be invoked. In this case, we should consume the
      # exception.
      try
        user ?= Meteor.user()
      catch e
    user

  _createAuthorSelector: (userId, username) ->
    # NOTE: Selector allows both username (legacy) or userId in the author field.
    usernameSelector = {}
    usernameSelector[@AUTHOR_FIELD] = username
    userIdSelector = {}
    userIdSelector[@AUTHOR_FIELD] = userId
    {$or: [userIdSelector, usernameSelector]}

  _createUserSelector: (userId, username) ->
    # NOTE: Selector allows both username (legacy) or userId in the author field.
    {$or: [{_id: userId}, username: username]}

  allowOwner: (userId, doc) -> (userId? && !@hasOwner(doc)) || @isOwnerOrAdmin(doc, userId)

  setUpCollectionAllow: (collection) ->
    allowOwner = @allowOwner.bind(@)
    collection.allow
      insert: (userId, doc) -> userId?
      update: allowOwner
      remove: allowOwner

  createRoles: (roles) ->
    existingRoles = Roles.getAllRoles().map (role) -> role.name
    newRoles = _.difference(roles, existingRoles)
    _.each newRoles, (role) -> Roles.createRole(role)

# Set up role publications.

if Meteor.isServer
  Meteor.publish 'roles', -> Meteor.roles.find({})
else
  Meteor.subscribe('roles')
