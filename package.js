Package.describe({
  name: 'urbanetic:accounts-ui',
  summary: 'Simple UI for Meteor Accounts',
  git: 'https://github.com/urbanetic/meteor-accounts-ui.git',
  version: '0.2.1'
});

Package.on_use(function(api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'http',
    'accounts-password',
    'accounts-ui',
    'aramk:utility@0.8.3',
    'aramk:q@1.0.1_1',
    'digilord:roles@1.2.12',
    'matb33:collection-hooks@0.7.6'
  ], ['client', 'server']);
  api.use(['templating', 'jquery', 'less'], 'client');
  api.use(['iron:router@1.0.3'], 'client', {weak: true});
  api.use(['urbanetic:accounts-local@0.1.1'], 'server', {weak: true});
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
    'src/userNav.coffee'
  ], 'client');
  api.export([
    'AccountsUi',
    'AccountsUtil'
  ], ['client', 'server']);
});
