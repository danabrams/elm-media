# Elm-Media

A New, port-based wrapper on the HTML Media API. This has been ported, with no improvements, to Elm 0.19.

## Trying out the example

To try out the example:

1. Clone this repo.
2. Download the [elephants-dream mp4](https://archive.org/details/ElephantsDream) and move it to `examples/elephants-dream-medium.mp4` and the [subtitle track](https://github.com/gpac/gpac/blob/master/tests/media/webvtt/elephants-dream-subtitles-en.vtt) and move it to `examples/elephants-dream-subtitles-en.vtt`.
3. Navigate to the `examples` directory and run `elm make Main.elm --output=main.js`.
4. Start an http server in the root directory of the repo. [This](https://www.npmjs.com/package/http-server) node server worked well.
5. In a browser, navigate to `http://127.0.0.1:8080/examples/Main.html`.

## Getting Started

This project requires a port (and some other javascript). You can set it up by importing the "Port/mediaPort.js" file into your html file, and doing something like the following:

```html 
   <script src="main.js"></script>
   <script src="../Port/mediaApp.js"></script>

   <script>
        MediaApp.Modify.timeRanges();
        /* Adds the "asArray getter to the TimeRanges object prototype, allowing us to decode the media element state without using Native/Kernel Code */
        MediaApp.Modify.tracks();
        /* Adds the "mode" setter and getter to the HTMLTrack object prototype, letting us show/hide/disable text tracks from the view function. */

        let elmApp = Elm.Main.fullscreen();
        /* Creates a fullscreen Elm App from our example (Main.elm) */
        elmApp.ports.outbound.subscribe(MediaApp.portHandler);
        /* Subscribe to our port and pass it the default portHandler(msg) function from "/Port/mediaApp.js" */
    </script>
```


### Tracking Media Element State

You can use this library without any ports or javascript at all, if all you want to do is track the state of the media element.

1) Put a `Media.State` type in your model:

```elm
import Media

type alias Model =
    { mediaState: Media.State}
```

2) `Media.State` is an opaque type, so you can't craft one by hand (it's a representation of the internat state of the media element, managed by the browser). It's important, however, to give each media element a unique id, and to try to nudge you into doing say, you have to put it into you `init` function with a function called `newVideo` (or `newAudio` if you're creating an audio player), which takes a `String` (representing your unique id), and returns a kind of default state of an uninitialized media object.

```elm
import Media.State exposing (newVideo)

init = ({state = newVideo "myVideo"}, Cmd.none)
```

3) Create a video element in your view function with the function `Media.Video`. It takes the state you've already created,so you don't have to worry about messing up the unique id, then it works like any other `Html` element, with a `List (Attribute msg)` and a `List (Html msg)`, returning an `Html msg`.

More media-centric attributes are available in the `Media.Attributes` module.

```elm
import Media exposing (video)
import Media.Attributes exposing (src, muted, autoplay, controls)

view model =
    Media.video model.state [ src "MyVideo.mp4", muted True, autoplay True, controls True ] []
```

4) At this point, you have a media element, but you're not actually tracking it's state. We need to create a `(State -> Msg)` and update our model accordingly.

You'll find most of the media-centric events are wrapped in the `Media.Events` model, as well as a useful function allEvents that simply provides a list of all the common media events, so you can update your model frequently, without having to type out several dozen events.

```elm
import Media.Events exposing(onTimeUpdate, allEvents)
import Media exposing (video)
import Media.Attributes exposing (src, muted, autoplay, controls)

type Msg =
    MediaStateUpdate State

update msg model =
    case msg of
        MediaStateUpdate s ->
            ({ model | state = state }, Cmd.none)

view model =
    Media.video model.state ([ src "MyVideo.mp4", muted True, autoplay True, controls True, onTimeUpdate MediaStateUpdate] ++ (allEvents MediaStateUpdate)[]
```

5) State is an opaque type, so to access the data inside it, you'll need to use the getter functions in `Media.State`, like `currentTime` or `playbackStatus`.

```elm
import Media.State exposing (currentTime)
import Html exposing (p, text, div)

view model =
    div [] 
        [ Media.video model.state 
            ([ src "MyVideo.mp4", muted True, autoplay True, controls True] ++ (allEvents MediaStateUpdate)
            []
        , p [] [text ("Current Time: " ++ currentTime model.state)]
        ]
```

6) (Optional) Elm can't decode the TimeRanges object of a media element without using Native/Kernel code, so if you need to read the seekable, played, or buffered properties, you need to setup an extra piece of javascript in you html file.

I've created a handy function that creates an `asArray` getter on every TimeRange object, which simply returns the object's values in an array form that Elm can decode. You can set it up like so:

```html
<script src="/Port/mediaApp.js"></script>

    <script>
        MediaApp.Modify.timeRanges();
        /* Adds the "asArray getter to the TimeRanges object prototype, allowing us to decode the media element state without using Native/Kernel Code */
    </script>
```

### Playback Controls

It's impossible, or wildly impractical to control playback (play, pause, seek, load) of a media element from Elm without using Native/Kernel code, except through a port, so that's what we have here.

You need to create a port in Elm like this:

```elm
import Media exposing (PortMsg)

port outbound : PortMsg -> Cmd msg
```

And, of course, you'll need a port in defined in your Html to handle the messages it receives. You can write your own, but the one I provide in "Port/mediaApp.js" checks to try and eliminate runtime errors (if you have a runtime error, let me know and I will try to add prevent in future versions).

To use the mediaApp.js port handler function, you just create your port in the html and pass is the `MediaApp.portHandler` function.

PortMsg is a simple type.

```elm
type alias PortMsg =
    { tag : String
    , id : String
    , data : Encode.Value
    }
```

You can easily craft your own PortMsg if you want, but the `Media` module includes some helper functions to make it easier: `play`, `pause`, `seek`, `load`.

`play`, `pause`, and `load` just take a Media.State record--and your port function--and generate a `Cmd Msg` to send out a port, so you can use them in an `update` function.

```elm
import Media exposing (play)

update msg model =
    case msg of
        Play ->
            ( model, play model.state myPort )
```

`seek` also takes a float value, which represents the time you want to seek to.

NOTE: It's possible "seek" is a word that seems obvious to me in my media-developer cultural bubble. It just means "change the current time of the player to x."


### Text Tracks

This version of the library FINALLY includes support for subtitles, chapters, captions, and synched metadata...you can find the relevant attributes on the track tag in `Media.Attributes`.

I hope to improve this part of the library substantially over the next month, so I won't go into much depth for now.

Just reach out on slack or discourse if you have any questions.
