
This is not a software project, but a documentation project. However, architectural guidelines still apply,
beyond just instructions on how to check out code. Some of the core principles and inspirations are outlined here.

## Inspiration

Developing application UI on the web is complex. There are a thousand frameworks to choose from and lots of passionate opinion making decisions unclear. That is combined with the fact that we rarely get to join a project before certain technical decisions were already committed to, and the toolset/framework are set in place. But this is not just a historical anomaly.

**User interfaces and user experience are hard to build**. Hundreds of possible device combinations, accessibility, performance optimization, and of course human behaviour being incredibly complex to understand. And business keeps changing, so the UI gets to be tweaked and rewritten many times in an application's lifecycle.

This is important to master, though. Front end is not only the part of the app closest to the user, but also one of the biggest project time sinks, and typically a huge source of bugs and instability.

## View Framework From Scratch

One of the best ways to learn to do something is to build it anew from scratch. See http://www.linuxfromscratch.org/, for example. This is not about NIH or saddling project successors with unproven new code, but gaining foresight and ability to critically evaluate existing frameworks and tools.

Typically, folks learn a toolchain through the "do X in order to get Y" pattern. Incremental, recipe-driven steps. Bang it with a wrench until it works. This is especially true for front-end code, because browser incompatibilities, awkward standards and huge variation in teammate skill level make for a lot of stress and cognitive overload. That obviously does not help see the forest for the trees.

We will start from scratch, but **consider the problem as a whole**.

## Design First, Optimize Later

A lot of complexity in existing code frameworks comes from *optimizations and workarounds*. But not just performance and device support: framework creators have to consider team workflow, existing development infrastructure, existing culture and skillsets of teammates, etc.

We will start with naive assumptions first. That will allow us identify the core skeleton structure of any existing framework, and then tell which design decisions were part of the foundational mental model, and which were technical and social "hacks" that made it work at the time but may no longer be relevant with newer devices and developer demographics.


