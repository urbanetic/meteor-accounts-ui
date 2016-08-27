Package.describe({
  name: 'urbanetic:accounts-ui',
  summary: 'Simple UI for Meteor Accounts',
  git: 'https://github.com/urbanetic/meteor-accounts-ui.git',
  version: '0.5.1'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@1.4.0.1');
  api.use([
    'accounts-password',
    'coffeescript',
    'email',
    'http',
    'underscore',
    'tracker@1.0.5',
    'aldeed:collection2@2.3.2',
    'aldeed:simple-schema@1.3.0',
    'aramk:q@1.0.1_1',
    'aramk:routes@0.2.2',
    'digilord:roles@1.2.12',
    'matb33:collection-hooks@0.8.0',
    'reactive-var@1.0.5',
    'urbanetic:utility@1.0.1'
  ], ['client', 'server']);
  api.use([
    'templating',
    'jquery',
    'less',
    'aldeed:autoform@5.1.2',
    'aramk:collection-table@0.4.1'
  ], 'client');
  api.use([
    'urbanetic:accounts-local@0.1.1'
  ], 'server', {weak: true});
  api.use([
    'aramk:checkbox@0.1.0'
  ], ['client', 'server'], {weak: true});
  api.imply(['accounts-password', 'digilord:roles', 'aldeed:autoform']);
  api.addFiles([
    'src/AccountsUi.coffee',
    'src/AccountsUtil.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/AccountsForm.coffee',
    'src/accounts-ui.less',
    'src/loginForm.html',
    'src/loginForm.coffee',
    'src/forgotPasswordForm.html',
    'src/forgotPasswordForm.coffee',
    'src/resetPasswordForm.html',
    'src/resetPasswordForm.coffee',
    'src/signUpForm.html',
    'src/signUpForm.coffee',
    'src/userNav.html',
    'src/userNav.coffee',
    'src/userForm.html',
    'src/userForm.coffee',
    'src/usersTable.html',
    'src/usersTable.coffee',
    'src/verifyForm.html',
    'src/verifyForm.coffee'
  ], 'client');
  api.addFiles([
    'src/users.coffee',
    'src/emails.coffee'
  ], ['server']);
  api.export([
    'AccountsUi',
    'AccountsUtil'
  ], ['client', 'server']);
});
