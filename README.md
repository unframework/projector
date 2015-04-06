
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

And then point your browser at http://127.0.0.1:9966 to see it.

*@todo: fiddle links*

## Hello, World!

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

