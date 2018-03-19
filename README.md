# Elm-Media

An experimental Elm wrapper for the HTML5 Media API.

## Getting Started

This project includes native code, so unless it gets white-listed by the powers that be, it will have to be installed manually.

### Installing Manually

Instructions for installing an unpublished module can be found [here](http://faq.elm-community.org/#how-do-i-install-an-elm-package-that-has-not-been-published-to-packageselm-langorg-for-use-in-my-project)


## Better Documentation

Since this package contains native code and therefore can't be pubished to [Elm Packages](https://package.elm-lang.org), you can't read the documentation I wrote easily.

You can however preview it by uploading [documentation.json](https://github.com/danabrams/elm-media/blob/master/documentation.json) to [here](http://package.elm-lang.org/help/docs-preview) 

## Goals & Feedback

My goal is for this library to be included, eventually, as an official way to write media players in elm. This is a crucially important part of the web api, in use on almost all of the biggest sites on the web, including youtube, facebook, twitter, linked in, as well as many of the smallest. Any site that uses anything other than the default browser players (and you really shouldn't be using the defaults, unless you're Apple and you want to make your media Safari only) uses this api, mostly by using third party players. This is a huge portion of web pages and web apps.

For people making a single-purpose media app, such as a podcast player, ports is probably a fine way to do this, although this library certainly makes it easier and safer (once it's gotten some code review and feedback).

However, the real benefit comes from the ability to create media players as a reusable view, that a user can configure and reuse. The only way to do this is with a native wrapping of the API, as packages with ports cannot be included. My goal was to create this package to help enable elm developers to develop reusable view players, so that the community as a whole can have awesome, rich media support.

This is the first public release, and I need some feedback. It's still missing a lot of features, but I'd appreciate any feedback, particularly bugs and API design.

## Thank Yous
This package wouldn't exist without the help, brain-pickings and encouragement of Richard Feldman. I think everyone in the community owes a debt of gratitude to Richard, whether for his training, elm-css, elm-test, or anything else. This library is no different.

I also want to thank the members of the Elm NYC meetup for their encouragement and design suggestions. Ian Mackenzie, in particular, already pointed out something to me in one of my examples that caused me to refactor quite a bit. As always, he was smarter than I and his point was even better than I initially saw.