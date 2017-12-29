createUserTable = (user) ->
  # Create a user table for use in emails.
  row = (title, content) -> '<tr><th>' + title + '</th><td>' + content + '</td></tr>'
  return '<table>' +
    row('ID', user._id) +
    row('Name', user.profile.name) +
    row('Email', email?.address) +
    '</table>'

# Send an email for sign-ups.
Meteor.users.after.insert (userId, doc) ->
  config = AccountsUi.config()
  return unless config.email.enabled and config.signUp.email != false
  # Wait for the roles to be added in users.coffee
  Meteor.startup(-> (Meteor.setTimeout (->
    user = Meteor.users.findOne(_id: doc._id)
    userTable = createUserTable(user)
    # Send the admin an email to notify of new users.
    AccountsUi.sendEmailToAdmin
      subject: 'User Sign-Up'
      html: '<p>A new user has signed up:</p>' + userTable
    # Send the user a new email to verify their email address.
    email = user.emails?[0]
    if email? and email.verified != true then Accounts.sendVerificationEmail(user._id)
  ), 1000))

Meteor.users.after.update (userId, user) ->
  config = AccountsUi.config()
  return unless config.email.enabled
  
  email = user.emails?[0]
  return unless email?
  
  enabled = user.enabled
  return unless @previous.enabled != enabled

  action = if enabled then 'enabled' else 'disabled'
  Logger.info('User ' + action, user._id)
  userTable = createUserTable(user)
  AccountsUi.sendEmailToAdmin
    subject: 'User ' + Strings.toTitleCase(action)
    html: '<p>User has been ' + action + '</p>' + userTable

  unless user.profile.activation?.date?
    Meteor.users.upsert user._id, {$set: 'profile.activation.date': new Date()}
    user = Meteor.users.findOne(_id: user._id)
    siteUrl = 'http://' + Accounts.emailTemplates.siteName + '/'
    templateArgs =
      user: user
      siteUrl: siteUrl
      loginUrl: siteUrl + config.login.path
    emailArgs = {user: user._id}
    emailConfig = config.email.templates.activation
    _.each emailConfig, (value, key) ->
      if Types.isFunction(value) then value = value.call(emailConfig, templateArgs)
      emailArgs[key] = value
    AccountsUi.sendEmailToUser(emailArgs)
