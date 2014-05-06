
Lean Reactive View Framework
============================

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
