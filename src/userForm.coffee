formName = 'userForm'
TemplateClass = Template[formName]
collectionName = 'users'

Meteor.startup ->

  getRoles = (callback) ->
    Meteor.subscribe 'roles', ->
      # Don't show "user" role as an option which is added to all users.
      roles = Meteor.roles.find({name: {$not: 'user'}}).map (role) -> role.name
      callback(roles)

  schema = new SimpleSchema
    username:
      type: String
    password:
      type: String
      optional: true
    'profile.name':
      type: String
    email:
      type: String
      regEx: SimpleSchema.RegEx.Email
    enabled:
      type: Boolean
      defaultValue: false
    roles:
      type: [String]
      # TODO(aramk) Custom asynch validation doesn't work.
      # https://github.com/aldeed/meteor-autoform/issues/919
      # custom: ->
      #   getRoles (roles) ->
      #     unless _.contains(roles, @value)
      #       schema.namedContext(formName).addInvalidKeys [{
      #         name: 'roles'
      #         type: 'notAllowed'
      #         value: 'Invalid role provided for user'
      #       }]
      defaultValue: []
      optional: true

  Form = Forms.defineModelForm
    name: formName
    schema: schema
    collection: Meteor.users
    collectionName: collectionName

    onRender: ->
      # Hide password field unless checkbox is checked.
      $passwordCheckbox = getPasswordCheckbox(@)
      $passwordCheckbox.on 'change', =>
        $password = getPasswordInput(@).parent()
        $password.toggle(Template.checkbox.isChecked(getPasswordCheckbox(@)))
      $passwordCheckbox.trigger('change')
      $buttons = @$('.buttons .button')
      $roles = @$('.roles.field select')
      return unless $roles.length > 0
      $buttons.addClass('disabled')
      doc = @data.doc
      getRoles (roles) =>
        $buttons.removeClass('disabled')
        _.each roles, (name) ->
          $role = $('<option value="' + name + '">' + name + '</option>')
          $roles.append $role
          if doc?.roles && _.contains(doc.roles, name) then $role.prop('selected', true)

    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      settings = getSettings(@template)
      password = insertDoc.password
      modifier =
        username: insertDoc.username
        name: insertDoc.profile.name
        enabled: insertDoc.enabled
      modifier.roles = insertDoc.roles if insertDoc.roles?
      options =
        allowUpdate: settings.allowUpdate ? currentDoc?
      if currentDoc
        modifier._id = currentDoc._id
      email = insertDoc.email
      if email && email.trim().length > 0
        modifier.emails = [{address: email, verified: false}]
      else
        modifier.emails = []
      shouldChangePassword = !currentDoc || Template.checkbox.isChecked(getPasswordCheckbox())
      if shouldChangePassword
        modifier.password = password
      # Only allow updates in an update form.
      Meteor.call 'users/upsert', modifier, options, (err, result) =>
        delete modifier.password
        if err
          notifyArg = undefined
          if settings.loggerNotify == false then notifyArg = {notify: false}
          Logger.error('Error creating user', err, notifyArg)
          @done(err, null)
        else
          modifier._id = result
          @done(null, modifier)
      return false

    hooks:
      docToForm: (doc) ->
        emails = doc.emails
        if emails && emails.length > 0
          doc.email = doc.emails[0].address
        doc

  Form.helpers
    isAdmin: -> AccountsUtil.isAdmin()

  getPasswordInput = (template) -> getTemplate(template).$('[name="password"]')

  getPasswordCheckbox = (template) -> getTemplate(template).$('.change-password.checkbox')

  getTemplate = (template) -> Templates.getNamedInstance(formName, template)

  getSettings = (template) -> getTemplate(template).data?.settings || {}
