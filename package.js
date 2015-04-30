Package.describe({
  name: 'urbanetic:accounts-ui',
  summary: 'Simple UI for Meteor Accounts',
  git: 'https://github.com/urbanetic/meteor-accounts-ui.git',
  version: '0.3.0'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'http',
    'accounts-password',
    'accounts-ui',
    'aldeed:collection2@2.3.2',
    'aldeed:simple-schema@1.3.0',
    'aramk:utility@0.8.3',
    'aramk:q@1.0.1_1',
    'digilord:roles@1.2.12',
    'matb33:collection-hooks@0.7.6'
  ], ['client', 'server']);
  api.use([
    'templating',
    'jquery',
    'less',
    'aldeed:autoform@4.0.7',
    'aramk:collection-table@0.3.4'
  ], 'client');
  api.use([
    'urbanetic:accounts-local@0.1.1'
  ], 'server', {weak: true});
  api.use([
    'aramk:routes:0.2.0'
  ], ['client', 'server'], {weak: true});
  api.addFiles([
    'src/AccountsUtil.coffee'
  ], ['client', 'server']);
  api.addFiles([
    'src/AccountsUi.coffee',
    'src/loginForm.html',
    'src/loginForm.less',
    'src/loginForm.coffee',
    'src/userNav.html',
    'src/userNav.less',
    'src/userNav.coffee',
    'src/userForm.html',
    'src/userForm.coffee',
    'src/usersTable.html',
    'src/usersTable.coffee'
  ], 'client');
  api.addFiles([
    'src/users.coffee'
  ], ['server']);
  api.export([
    'AccountsUi',
    'AccountsUtil'
  ], ['client', 'server']);
});
