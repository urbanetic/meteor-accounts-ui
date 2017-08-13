templateName = 'usersTable'
TemplateClass = Template[templateName]

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
  users: -> getTemplate().data?.items ? Meteor.users.find({username: {$not: 'admin'}})
  settings: ->
    isAdmin = AccountsUtil.isAdmin()
    dateFormatter = (value, object) ->
      if value then Spacebars.SafeString Dates.toLong(value) else 'N/A'
    settings =
      fields: [
        {key: 'username', label: 'Username', sort: 'ascending'}
        {key: 'profile.name', label: 'Name', sort: 'ascending'}
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
            return unless value
            value.sort()
            value.join(', ')
        }
        {
          key: 'profile.signUp.date'
          label: 'Sign-Up Date'
          fn: dateFormatter
        }
        {
          key: 'profile.activation.date'
          label: 'Activation Date'
          fn: dateFormatter
        }
      ]
      onDelete: (args) -> _.each args.ids, (id) ->
        Meteor.call 'users/remove', id, (err, result) ->
          if err then Logger.error(err)
      crudMenu: isAdmin
    _.extend settings, @settings
    if @showUsernames == false
      settings.fields.shift()
    if isAdmin
      settings.fields.unshift
        key: 'enabled'
        label: 'Enabled'
        fn: (value, object) ->
          checkedStr = if value then 'checked' else ''
          Spacebars.SafeString('<input type="checkbox" ' + checkedStr + '/>')
    settings

getTemplate = (template) -> Templates.getNamedInstance(templateName, template)
