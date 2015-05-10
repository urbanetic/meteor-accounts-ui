formName = 'userForm'
TemplateClass = Template[formName]
collectionName = 'users'
collectionTitle = 'Users'

Meteor.startup ->

  Meteor.subscribe 'roles', ->

    # Don't show "user" role as an option which is added to all users.
    roles = Meteor.roles.find({name: {$not: 'user'}}).map (role) -> role.name
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
        optional: true
      roles:
        type: [String]
        allowedValues: roles
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

      onSubmit: (insertDoc, updateDoc, currentDoc) ->
        username = insertDoc.username
        name = insertDoc.profile.name
        password = insertDoc.password
        roles = insertDoc.roles
        userArgs =
          username: username
          name: name
          roles: roles
        if currentDoc
          userArgs._id = currentDoc._id
        email = insertDoc.email
        if email && email.trim().length > 0
          userArgs.emails = [{address: email, verified: false}]
        else
          userArgs.emails = []
        shouldChangePassword = !currentDoc || Template.checkbox.isChecked(getPasswordCheckbox())
        if shouldChangePassword
          userArgs.password = password
        # Only allow updates in an update form.
        Meteor.call 'users/upsert', userArgs, {allowUpdate: !!currentDoc}, (err, result) =>
          if err
            Logger.error('Error creating user', err)
          else
            @done()
        return false
      
      docToForm: (doc) ->
        emails = doc.emails
        if emails && emails.length > 0
          doc.email = doc.emails[0].address
        return doc

  getPasswordInput = (template) -> getTemplate(template).$('[name="password"]')

  getPasswordCheckbox = (template) -> getTemplate(template).$('.change-password.checkbox')

  getTemplate = (template) -> Templates.getNamedInstance(formName, template)

  getSettings = (template) -> getTemplate(template).settings || {}
