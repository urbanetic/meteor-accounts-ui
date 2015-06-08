if Meteor.isServer
  Meteor.publish 'userData', ->
    return [] unless @userId
    Meteor.users.find({}, {fields: {profile: 1, emails: 1, roles: 1, username: 1}})
else if Meteor.isClient
  Meteor.subscribe('userData')
