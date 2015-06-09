formName = 'userForm'
TemplateClass = Template[formName]
collectionName = 'users'
collectionTitle = 'Users'

Meteor.startup ->

  getRoles = (callback) ->
    Meteor.subscribe 'roles', ->
      # Don't show "user" role as an option which is added to all users.
      roles = Meteor.roles.find({name: {$not: 'user'}}).map (role) -> role.name
      callback(roles)

  schema = new SimpleSchema
    username:
      type: String
      max: 20
    password:
      type: String
      optional: true
    'profile.name':
      type: String
      max: 20
    email:
      type: String
      regEx: SimpleSchema.RegEx.Email
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
    collectionName: collectionName

    onRender: ->
      # Hide password field unless checkbox is checked.
      $passwordCheckbox = getPasswordCheckbox(@)
      $passwordCheckbox.on 'change', =>
        $password = getPasswordInput(@).parent()
        $password.toggle(Template.checkbox.isChecked(getPasswordCheckbox(@)))
      $passwordCheckbox.trigger('change')
      $buttons = @$('.buttons .button')
      $buttons.addClass('disabled')
      $roles = @$('.roles.field select')
      doc = @data.doc
      getRoles (roles) =>
        $buttons.removeClass('disabled')
        _.each roles, (name) ->
          $role = $('<option value="' + name + '">' + name + '</option>')
          $roles.append $role
          if doc?.roles && _.contains(doc.roles, name) then $role.prop('selected', true)

    onSubmit: (insertDoc, updateDoc, currentDoc) ->
      username = insertDoc.username
      name = insertDoc.profile.name
      password = insertDoc.password
      roles = insertDoc.roles
      modifier =
        username: username
        name: name
        roles: roles
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
      Meteor.call 'users/upsert', modifier, {allowUpdate: currentDoc?}, (err, result) =>
        if err
          Logger.error('Error creating user', err)
        else
          @done()
      return false

    hooks:
      docToForm: (doc) ->
        emails = doc.emails
        if emails && emails.length > 0
          doc.email = doc.emails[0].address
        return doc

  getPasswordInput = (template) -> getTemplate(template).$('[name="password"]')

  getPasswordCheckbox = (template) -> getTemplate(template).$('.change-password.checkbox')

  getTemplate = (template) -> Templates.getNamedInstance(formName, template)

  getSettings = (template) -> getTemplate(template).settings || {}
