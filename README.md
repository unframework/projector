
# Projector: View Framework Build-Along

Let's build a web view framework from scratch! And learn something along the way.

## Setup

Some useful utilities to run local JS files in browser:

```sh
sudo npm install -g browserify beefy
```

When you save a file called `example.js`, run it like this:

```sh
beefy example.js
```

And then point your browser at http://127.0.0.1:9966 to see it. If you update the JS file, just hit "Refresh" in the browser to run the latest code.

*@todo: fiddle links*

## Hello, World!

Any app we build shows some stuff on screen.

```js
var messageBox = document.createElement('div');
messageBox.appendChild(document.createTextNode('Hello, world!'));

document.body.appendChild(messageBox);
```

That works, but is kind of gross. We will use a library called [Hyperscript](https://github.com/dominictarr/hyperscript) to simplify things.

> Note: [jQuery](https://jquery.com/) could also be used, but it is way too much for what we need here. Do [try jQuery](http://learn.jquery.com/) at some point - it's nice!

```sh
npm install hyperscript
```

And here is the updated code:

```js
var h = require('hyperscript');

document.body.appendChild(h('div', 'Hello, world!'));
```

Done.

## Adding Styling

Let's make the message box look nice.

Web fonts make an amazing difference. We'll use Google Fonts because they are free and easy to get set up.

```sh
npm install google-fonts
```

```js
var fonts = require('google-fonts');
var h = require('hyperscript');

fonts.add({ 'Playfair Display': [ '400' ] });

var messageCSS = {
    'font': '24px Playfair Display',
    'color': '#34495e'
};

document.body.appendChild(h('div', { style: messageCSS }, 'Hello, world!'));
```

Very classy. Ahem. Note that we didn't have to create any `.css` files yet, and didn't use actual CSS classes. We are using CSS styling declarations, but by simply defining them in the code and applying to the message DOM element directly for now.

We like refactoring, so we will clean this up a bit:

```js
var fonts = require('google-fonts');
var h = require('hyperscript');

fonts.add({ 'Playfair Display': [ '400' ] });

function renderMessage(text) {
    return h('div', { style: {
        'font': '24px Playfair Display',
        'color': '#34495e'
    } }, text);
}

document.body.appendChild(renderMessage('Hello, world!'));
```

Why did we keep the `appendChild` call outside of `renderMessage`? To aid **composition**. This way we can pass output of `renderMessage` through some other function before calling `appendChild` (e.g. to wrap it in a nice shadow) - all without modifying `renderMessage` itself. We have composed the app out of the message renderer as a code module and the consumer of its output (the `appendChild` bit).

## Interaction

So far all we have is just some text on a page. Real apps allow for interaction: user input.

Let's add a button that increments a counter.

```js
var fonts = require('google-fonts');
var h = require('hyperscript');

var counter = 0;

fonts.add({ 'Playfair Display': [ '400' ] });

function renderMessage(text) {
    return h('div', { style: {
        'font': '24px Playfair Display',
        'color': '#34495e'
    } }, text);
}

function renderButton(text, clickHandler) {
    return h('button', { style: {
        'font': '16px Playfair Display',
        'background': '#2ecc71', 'color': '#fff',
        'border-radius': '3px', 'border': 'none'
    }, onclick: clickHandler }, text);
}

function renderAll() {
    return h('div', [ renderMessage('Hello, world!'), renderButton('Click Me', function () {
        counter += 1;
        console.log('counter value: ' + counter);
    }) ]);
}

document.body.appendChild(renderAll());
```

The counter in this case is the so-called "application state", and the button translates user actions (clicks) into meaningful operations on the application state (incrementing the counter).

It is important to mentally mark application state variables and code as distinct from everything else. Rendering stuff on screen usually means a lot of style-dependent code, so keeping it separate from application code means easier editing and maintenance.

We need to show the counter value on screen, instead of the log. We can do that by just replacing the `'Hello, world!'` string with `'Counter:' + counter` of course. But when the counter changes, what do we do then? We simply render new UI.

But how do we know when the counter changes? The answer to that is laughably simple: when the user clicks anything! It makes sense: our program state only changes when something external "nudges it along". We will simply listen for all the clicks that ever happen and update the screen.

```js
var fonts = require('google-fonts');
var h = require('hyperscript');

var counter = 0;

fonts.add({ 'Playfair Display': [ '400' ] });

function renderMessage(text) {
    return h('div', { style: {
        'font': '24px Playfair Display',
        'color': '#34495e'
    } }, text);
}

function renderButton(text, clickHandler) {
    return h('button', { style: {
        'font': '16px Playfair Display',
        'background': '#2ecc71', 'color': '#fff',
        'border-radius': '3px', 'border': 'none'
    }, onclick: clickHandler }, text);
}

function renderAll() {
    return h('div', { id: 'ui' }, [ renderMessage('Counter value: ' + counter), renderButton('Click Me', function () {
        counter += 1;
    }) ]);
}

document.body.appendChild(renderAll());
document.body.addEventListener('click', function () {
    document.body.replaceChild(renderAll(), document.getElementById('ui'));
});
```

The UI gets replaced even on clicks *outside* the button (i.e. when the counter doesn't change). Is that a problem? Not really, since it happens fast enough and with no side effects. Any code we write to optimize that case is going to complicate the logic and create chances for bugs to happen.

But there is a side effect, actually. Because we replace the entire UI, nice things like keyboard focus on the button get completely cleared out! Also, if we were to build out a huge complex application screen, replacing the entire thing on every little click would get very slow. This is where things get complex. Or do they?

## Virtual DOM

There is a way to do a "soft replace" on DOM elements that is both faster and less destructive. Instead creating real (heavy) DOM element in our `render` functions, we can generate so-called "virtual DOM". Actually, our code will look exactly the same (since we use inline Hyperscript syntax), but now we can pipe the results through a special optimizer that does the soft-replacement.

```sh
npm install virtual-dom
```

```js
var fonts = require('google-fonts');
var h = require('virtual-dom/h');

var counter = 0;

fonts.add({ 'Playfair Display': [ '400' ] });

function renderMessage(text) {
    return h('div', { style: {
        'font': '24px Playfair Display',
        'color': '#34495e'
    } }, text);
}

function renderButton(text, clickHandler) {
    return h('button', { style: {
        'font': '16px Playfair Display',
        'background': '#2ecc71', 'color': '#fff',
        'border-radius': '3px', 'border': 'none'
    }, onclick: clickHandler }, text);
}

function renderAll() {
    return h('div', { id: 'ui' }, [ renderMessage('Counter value: ' + counter), renderButton('Click Me', function () {
        counter += 1;
    }) ]);
}

var diff = require('virtual-dom/diff');
var patch = require('virtual-dom/patch');
var createElement = require('virtual-dom/create-element');

var ui = renderAll();
document.body.appendChild(createElement(ui));
document.body.addEventListener('click', function () {
    var oldUI = ui;
    patch(document.getElementById('ui'), diff(oldUI, ui = renderAll()));
});
```

That was easy: the only changes we made was include `virtual-dom/h` instead of `hyperscript` (to generate virtual DOM instead of real DOM), and complicate the DOM replacement step.

How it works now is this: we always keep a reference to the previous rendered virtual DOM, and then on every refresh the optimizer simply walks through *differences* between the new and previous virtual DOM trees (that's what `diff` computes) and then applies a `patch` to the real browser DOM. It's simpler than it sounds, and we can pretty much forget about these nitty-gritty details from now on.

## To Be Continued

*@todo add more stuff*

Some background information about the repo is in the [contribution guidelines](CONTRIBUTING.md).

