# Elm-Media

An experimental Elm wrapper for the HTML5 Media API.

## Getting Started

This project includes native code, so unless it gets white-listed by the powers that be, it will have to be installed manually.

### Installing manually

Copy this repo to the directory of your choice.

In your elm-package.json file, make the following changes:

1) Add the directory to which you copied this repo to the "source-directories" field. For instance, if you saved this directory at "~/elm-media/", your elm-package.json might have a field that looks like this:

```"source-directories": [
        ".",
        "~/elm-media"
    ],```

2) add a line allowing native modules, like so: ```"native-modules": true,```

There are several other ways to do this, but this is probably the simplest. 

