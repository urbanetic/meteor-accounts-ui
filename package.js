Package.describe({
  name: 'urbanetic:accounts-ui',
  summary: 'Simple UI for Meteor Accounts',
  git: 'https://github.com/urbanetic/meteor-accounts-ui.git',
  version: '0.5.0'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'accounts-password',
    'coffeescript',
    'email',
    'http',
    'underscore',
    'tracker@1.0.5',
    'aldeed:collection2@2.3.2',
    'aldeed:simple-schema@1.3.0',
    'aramk:checkbox@0.1.0',
    'aramk:q@1.0.1_1',
    'aramk:utility@0.9.0',
    'aramk:routes@0.2.2',
    'digilord:roles@1.2.12',
    'matb33:collection-hooks@0.7.6',
    'reactive-var@1.0.5'
  ], ['client', 'server']);
  api.use([
    'templating',
    'jquery',
    'less',
    'aldeed:autoform@5.1.2',
    'aramk:collection-table@0.3.4'
  ], 'client');
  api.use([
    'urbanetic:accounts-local@0.1.1'
  ], 'server', {weak: true});
  api.imply(['accounts-password', 'aldeed:autoform']);
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
    'src/users.coffee'
  ], ['server']);
  api.export([
    'AccountsUi',
    'AccountsUtil'
  ], ['client', 'server']);
});
