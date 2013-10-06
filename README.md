
Lean View Framework
===================

Simple concept:

    model instance + template -> view instance

This library is meant to quickly build views around models and view-models (MVVM) using a template-like DSL.

Opinions:

* lean is better
  * composition over extension
  * dependency injection is handled externally (unlike Angular)
  * no yet-another-templating-language/syntax - just terse JS/CoffeeScript that reads like a template
  * in general, no explicit dependency on HTML or DOM - although 90% of the useful code is concerned with DOM manipulation
* fat model, thin template: Mustache/Handlebars-like philosophy, MVVM
  * declarative/functional glue code is preferred over event-based
* two-way binding is a limited metaphor
  * *input* is on the opposite side of the *view*: user data and actions are fed into the *model* via imperative verb methods
  * data flow: *input* -> *model* -> *view*
  * but of course *input* and *view* are closely intertwined as part of the presentation layer
  * this includes AJAX

Minor clarifications:

* there is no such core concept as "destructor" for a view - the DOM-specific logic introduces a concept of "no longer relevant" and implements the corresponding unwatching conditions
