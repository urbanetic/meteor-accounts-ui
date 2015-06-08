# accounts-ui

Simple UI for Meteor Accounts.

## Setup

To configure the package, call the following from the client on startup:

```
Meteor.startup(function() {
  AccountsUi.config({
    // Additinonal configuration.
  });
});
```

A login route will be created based on these settings.

## Routing

This package relies on [Iron Router](https://github.com/EventedMind/iron-router) for routing.

To prevent unauthorized access to routes, use `AccountsUi.signInRequired(router)`. For example:

```
// Globally.
Router.onBeforeAction(function() {
  AccountsUi.signInRequired(this);
});

// In a controller.
var BaseController = RouteController.extend({
  onBeforeAction: function() {
    if (!this.ready()) {
      return;
    }
    AccountsUi.signInRequired(this);
  },
  action: function() {
	this.ready() && this.render();
  }
});
```

## Templates

The login form can be rendered with `{{> loginForm}}`. The default configuration will take care of all the routing and template rendering.

The user navigation can be shown with `{{> userNav}}`. It will show the current user's name and a sign out button, or a sign in button if no user is found.
