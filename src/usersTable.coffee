TemplateClass = Template.usersTable

TemplateClass.events
  'change .enabled input[type="checkbox"]': (e, template) ->
    $checkbox = $(e.currentTarget)
    user = Blaze.getData($checkbox.closest('tr')[0])
    enabled = $checkbox.is(':checked')
    modifier = {_id: user._id, enabled: enabled}
    $checkbox.prop('disabled', true)
    Meteor.call 'users/upsert', modifier, (err, result) ->
      $checkbox.prop('disabled', false)
      if err then Logger.error(err)

TemplateClass.helpers
  users: -> Meteor.users.find({username: {$not: 'admin'}})
  settings: ->
    isAdmin = AccountsUtil.isAdmin()
    settings =
      fields: [
        {key: 'username', label: 'Username'}
        {key: 'profile.name', label: 'Name'}
        {
          key: 'emails'
          label: 'Email'
          fn: (value, object) ->
            emails = _.map value, (email) -> email.address
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
      onDelete: (args) -> _.each args.ids, (id) -> Meteor.call('users/remove', id)
      crudMenu: isAdmin
    if isAdmin
      settings.fields.push
        key: 'enabled'
        label: 'Enabled'
        fn: (value, object) ->
          checkedStr = if value then 'checked' else ''
          Spacebars.SafeString('<input type="checkbox" ' + checkedStr + '/>')
    settings
