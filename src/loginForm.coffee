TemplateClass = Template.loginForm

TemplateClass.rendered = -> TemplateClass.getUsernameInput(@).focus()

TemplateClass.events
  'submit form': (e, template) -> TemplateClass.onSubmit(e, template)

_.extend TemplateClass,

  onSubmit: (e, template) ->
    e.preventDefault()
    @clearMessages()
    $username = @getUsernameInput(template)
    $password = template.$('[name="password"]')
    username = $username.val().trim()
    password = $password.val().trim()
    $password.val('').focus()
    $submit = @getSubmitButton()
    if username == '' || password == ''
      err = 'Must provide both username and password'
      Logger.error(err)
      @addMessage(@createErrorMessage(err))
      return
    Logger.debug('Logging in with username:', username)
    $submit.addClass('disabled')
    Q.when(@login(username, password, template)).fin(
      -> $submit.removeClass('disabled')
    ).done()

  login: (username, password, template) ->
    df = Q.defer()
    Meteor.loginWithPassword username, password, (err) ->
      if err
        Logger.error('Error when logging in', err)
        @addMessage(@createErrorMessage(err.message), template)
        q.reject(err)
      else
        Logger.debug('Successfully logged in:', username)
        AccountsUi.onAfterLogin()
        df.resolve()
    df.promise

  getFormDom: (template) -> getTemplate(template).$('form')

  getSubmitButton: (template) -> getTemplate(template).$('[type="submit"]')

  clearMessages: (template) ->
    @getFormDom(template).removeClass('error')
    @getMessagesDom(template).empty()

  addMessage: ($message, template) ->
    @getMessagesDom(template).prepend($message)
    if $message.hasClass('error')
      @getFormDom(template).addClass('error')

  getMessagesDom: (template) -> getTemplate(template).$('.messages')

  getUsernameInput: (template) -> getTemplate(template).$('[name="username"]')

  createErrorMessage: (err) -> $('<div class="ui error message">' + err.toString() + '</div>')

getTemplate = (template) -> template ? Template.instance()

