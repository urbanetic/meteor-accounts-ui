Package.describe({
  name: 'urbanetic:accounts-ui',
  summary: 'Simple UI for Meteor Accounts',
  git: 'https://github.com/urbanetic/meteor-accounts-ui.git',
  version: '2.0.0'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1.10.2');
  api.use([
    'accounts-password@2.3.1',
    'coffeescript@2.2.1_1',
    'email@2.0.0',
    'http',
    'underscore',
    'tracker@1.0.5',
    'aldeed:collection2@3.5.0',
    'aldeed:simple-schema@1.3.0',
    'aramk:q@1.0.1_1',
    'aramk:routes@1.0.0',
    'alanning:roles@3.4.0',
    'matb33:collection-hooks@1.1.2',
    'reactive-var@1.0.5',
    'urbanetic:utility@3.0.0'
  ], ['client', 'server']);
  api.use([
    'templating@1.3.2',
    'jquery@1.11.10',
    'less@4.0.0',
    'aldeed:autoform@7.0.0',
    'aramk:collection-table@2.0.0'
  ], 'client');
  api.use([
    'urbanetic:accounts-local@2.0.0'
  ], 'server', {weak: true});
  api.use([
    'aramk:checkbox@2.0.0'
  ], ['client', 'server'], {weak: true});
  api.imply(['accounts-password@2.3.1', 'alanning:roles', 'aldeed:autoform']);
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
