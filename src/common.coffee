AccountsUi =

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
      if Meteor.isClient
        username = Meteor.users.findOne(userId)?.username
      else
        username = 'admin'
      doc.author = username
