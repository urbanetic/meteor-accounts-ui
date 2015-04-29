TemplateClass = Template.usersTable

TemplateClass.helpers
  
  users: -> Meteor.users.find({username: {$not: 'admin'}})

  usersTableSettings: ->
    fields: [
      {key: 'username', label: 'Username'}
      {key: 'profile.name', label: 'Name'},
      {
        key: 'emails'
        label: 'Email'
        fn: (value, object) ->
          emails = _.map value, (email) -> email.address;
          emails.join(', ')
      }
      {
        key: 'roles'
        label: 'Roles'
        fn: (value, object) ->
          value.sort()
          value.join(', ')
      }
    ]
    onDelete: (args) ->
      _.each args.ids, (id) -> Meteor.call('users/remove', id)
