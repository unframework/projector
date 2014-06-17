
# Projector
[![Build Status](https://travis-ci.org/unframework/projector.svg?branch=master)](https://travis-ci.org/unframework/projector)

## Lean Reactive View Framework

Simple concept:

    model instance + template -> view instance

This library is meant to quickly build views around models and view-models (MVVM) using a template-like DSL.

Features:

* AngularJS style reactive model/scope binding
* hierarchical (view prototype inheritance), ERB style yield (via callbacks)
* comfortable syntax: simple, concise real Javascript/CoffeeScript
* everything is an optional addon, including HTML support (`<canvas>` scenegraph in the works)
* nothing else

Philosophy:

* lean is better
  * composition over extension
  * dependency injection is handled externally (unlike Angular)
  * no yet-another-templating-language/syntax - just terse JS/CoffeeScript that reads like a template
  * in general, no explicit dependency on HTML or DOM - although 90% of the useful code is concerned with DOM manipulation
* fat model, thin template: Mustache/Handlebars-like philosophy, MVVM
  * declarative/functional glue code is preferred over event-based
* input/output model binding
  * data flow: *input* -> *model* -> *view*
  * *input*: user data, actions, network and timers are fed into the *model* via imperative verb methods
  * *view*: render last known state of the *model*

## Naming Conventions

Libraries and components may install methods onto the view-model. A method may be named as a verb (per usual language convention) if and only if it modifies existing view-model state; otherwise it may be named as a *noun*, if and only if it creates (forks) a sub-instance of a view model.

Examples:

* `refresh` (core lib) - verb, refreshes rendered state
* `element` (HTML lib) - noun, creates a view-model sub-instance fork (as well as an HTML element)

Library code may add state properties to a view-model instance. If the library is public and its particular state property is meant for external consumption then the property's name should be prefixed with `$` (dollar sign) and the library's simple name. Preferredly, multiple related state properties should be sub-properties of a single object. Library state not meant for external consumption should be attached as properties with names prefixed with `$$` (double dollar sign) and the library's simple name.

Examples:

* `$action` (action lib) - property containing current exposed state of an invoke-able action, with sub-properties such as `isPending`, `error`, etc.
