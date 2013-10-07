
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

Immutability
------------

The view should not be able to modify the model. The only way to truly enforce that is by only expose string, number and boolean values to the view. I.e. the framework should not expose objects or functions, and just resolve path-gets into primitives.

There is already a clear mental concept of associating a specific view instance with the specific model value (of any type). This is different than Angular's scope in that the model value is the scope. One-to-one with the view instance. Binding is a way to generate a new view for every new value. So the individual strings and numbers get their own views, and the latter can get the primitive value via "get as number" or "get as string", etc, getters.

View State
----------

The view instance is already exposed as "this" in the template code. The framework code has nothing to do with that. To emulate live-bound state introduced by the *template*, we can "manually" introduce broadcasters into the view instance and then extend e.g. HTML library code to support those in addition to the regular model bindings. The prototype inheritance of views will expose the broadcaster to any forked sub-views.

Forms and Input
---------------

The user thinks in terms of actions (send chat message, drag file to folder), and those are representable as simple methods on the model.

The browser form maps very well to the concept of that kind of "action". We can have an "action" directive that contains and maps a variety of inputs (as well as buttons that invoke it) - and on submit just calls a single model method. Implemented as a form, too, to benefit from native browser support for keyboard shortcuts, etc, even CSS.

There is also a use case for a dedicated form view-model. For complex dynamic collection forms, etc, it makes sense to still have the full power of bound templates and declarative view building. So for this we construct a fully independent model - the form view-model - that *copies* original model info on init but does not bind to it to listen. Since it is an independent binding watch-list, we can afford to have a lot of interactivity just within that form (e.g. dynamically updated collections, lots of onkeypress callbacks, etc) and then have it wrap up nicely into one original model method call. This kind of view model would of course be implemented as a reusable helper. What's interesting is that the helper is a model itself, but it's instantiated from the template.

This touches on the topic of validation of course. Business-primitive approach works well here: the form helper first does validation per-input-value using just model-defined business object constructors in isolation. The business objects are concepts such as "valid email", "valid name" - wrappers or filters for raw input data. If all the objects are OK, they are passed as arguments to the actual model action method. That might also generate an error. Errors during the input gathering and method execution stages are loosely equivalent to the HTTP 400 and 500 status codes, correspondingly. So of course we just catch exceptions in both cases and the form helper stores them declaratively for display.

In this description actual latent AJAX calls and storage implementation are fully part of the model code. I.e. the model code will use various techniques to implement all that, but as far as this view framework is concerned it's all encapsulated away. The form helper will expose a generic callback-based hook to the template glue, which in turn will invoke the model as appropriate (synchronously or asynchronously).
