Form = AccountsForm.define('verifyForm')

Form.created = ->
  @isPending = new ReactiveVar(true)
  @error = new ReactiveVar()

Form.rendered = ->
  verifyToken = Session.get('verifyToken')
  unless verifyToken
    @error.set('No token provided.')
    @isPending.set(false)
    return
  Accounts.verifyEmail verifyToken, (err, result) =>
    if err
      @error.set(err.reason ? err.toString())
    @isPending.set(false)

Form.helpers
  isPending: ->
    template = Form.getTemplate()
    !template.error.get()? && template.isPending.get()
