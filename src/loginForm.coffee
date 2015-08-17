Form = AccountsForm.define('loginForm')

Form.rendered = -> Form.getUsernameInput(@).focus()

eventsMap =
  'submit form': (e, template) -> Form.onSubmit(e, template)
  'click .forgot.button': ->
    Logger.track 'Accounts forgot'
    AccountsUi.goToForgot()
  'click .sign-up.button': ->
    Logger.track 'Accounts signup'
    AccountsUi.goToSignUp()
_.extend Form.eventsMap, eventsMap
Form.events(eventsMap)

_.extend Form,

  onSubmit: (e, template) ->
    $username = @getUsernameInput(template)
    $password = template.$('[name="password"]')
    username = $username.val().trim()
    password = $password.val().trim()
    $password.val('').focus()
    $submit = @getSubmitButton()
    if username == '' || password == ''
      err = 'Must provide both username and password'
      Logger.error(err, {notify: false})
      @addMessage @createErrorMessage(err)
      return false
    Logger.debug('Logging in with username:', username)
    $submit.addClass('disabled')
    Q.when(@login(username, password, template)).fin(
      -> $submit.removeClass('disabled')
    ).done()
    return false

  login: (username, password, template) ->
    df = Q.defer()
    Meteor.loginWithPassword username, password, (err) =>
      if err
        Logger.error 'Error when logging in', err, notify: false
        Logger.track 'Accounts login failure', username: username
        @addMessage @createErrorMessage(err), template
        df.reject(err)
      else
        Logger.info('Successfully logged in', username)
        df.resolve()
    df.promise
