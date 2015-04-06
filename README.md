
# Projector (Alpha): Experimental View Framework Build-Along

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
messageBox.appendChild(document.createText('Hello, world!'));

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
    'font-family': 'Playfair Display',
    'font-size': '24px',
    'color': '#34495e'
};

document.body.appendChild(h('div', { style: messageCSS }, 'Hello, world!'));
```

Very classy. Note that we didn't have to create any `.css` files yet. We are using CSS styling declarations, but we are simply defining them in the code for now.

We like refactoring, so we will clean this up a bit:

```js
var fonts = require('google-fonts');
var h = require('hyperscript');

fonts.add({ 'Playfair Display': [ '400' ] });

function renderMessage(text) {
    return h('div', { style: {
        'font-family': 'Playfair Display',
        'font-size': '24px',
        'color': '#34495e'
    } }, text);
}

document.body.appendChild(renderMessage('Hello, world!'));
```

Why did we keep the `appendChild` call outside of `renderMessage`? To aid **composition**. This way we can pass output of `renderMessage` through some other function before calling `appendChild` (to e.g. wrap it in a nice shadow) - all without modifying `renderMessage` itself. We have composed the app out of the message renderer as a code module and the consumer of its output (the `appendChild` bit).

## Going Deeper

First, a few core definitions:

- **server**
    - typically a VM in a cloud datacenter (EC2, Azure, Heroku, Linode, Rackspace, etc)
    - trusted by the application maintainer: can be an authority on business logic state such as a bank account balance
- **client** aka **user device**
    - web browser or mobile browser, screen reader, etc
    - not trusted by the application maintainer: cannot be a source of business logic state (can't store bank account balance on mobile phone except as cache)
- **business logic state**
    - application state that is relevant and persistent outside a specific user interaction
    - typically stored in a database on the server

The app displays business logic state onto the user device. The user decides on what the next command is going to be and the presentation layer forwards it back to be applied to business state.

> This is akin to *projection* in the math sense (representing a source shape as adapted view, but also possibly running that transformation in reverse). Hence "Projector", by the way.

Design first, optimize later. Imagine a perfect world with infinite CPU power, GPU speed and bandwidth, and zero network lag. There is still a distinct server/client split: because of who gets to control the running code. We trust the server, we don't trust the client. Pretending that the server is just one instance, running in memory, and will never fail, here is our idealized client-side framework code:

```js
setInterval(function () {
    // process input
    queuedUserCommands.forEach(function (command) {
        somehowInstantlySendCommandToBeAppliedToBusinessState(command);
    });

    // render resulting state
    var businessState = somehowInstantlyGetBusinessState();

    representStateOnScreen(businessState);
}, 5); // 200fps, because why not, in this hypothetical unicorn world
```

*@todo add more stuff*

Some background information about the repo is in the [contribution guidelines](CONTRIBUTING.md).

