module Media exposing (..)

{-| This is a very experimental attempt to wrap the HTML5 Media API,
making it possible to write more sophisticated audio and video players
in elm. Let me reiterate, this is experiemental, and not nearly ready
for production. Use at your peril.

This library is helpful if you want to add some basic commands to an
audio or video player, or if you want be an abstration, such as a
reusable view, to provide more functionality than the browser's built-in
media player.

Media is an interesting element to wrap in elm, because it inherently has
state. If the player is playing, its currentTime and duration, and other
properties may change regardless of user interaction. I tried to follow
the elm guidelines and believe this should be a subscription, returning
state every returnAnimationFrame, but honestly, Effect Managers are beyond
me at this point, and I need some help to implement this. For the time being
I'm using the getState function as a workaround.

It uses native code to return the record State which is a pretty close
mapping to the properties of the HTMLMediaElement. (I would love to
replace this with a JSON decoder, and originally prototyped this way, but
cannot figure out how to bring TimeRanges objects into elm without
writing a native TimeRanges decoder--which may happen in the future).

It also uses native code to wrap the basic HTMLMediaElement methods:
play, pause, load, fastSeek, and canPlayType. This is
unavoidable. It also uses native code for the function seek. There might
be an alternative way to do this using Html.Attributes.property, but I
haven't figured it out yet.

All of these functions are Tasks, and perform checks in the native code
to try to catch errors.


### Helpers

@docs muted


### Media Control

@docs play, pause, load, fastSeek, seek


### canPlayMedia

@docs canPlayMedia, CanPlay


### Elm-Media Errors

@docs Error

-}

import Html exposing (Attribute)
import Html.Attributes exposing (property)
import Json.Encode as Encode exposing (bool)
import Media.State exposing (Id, State)
import Native.Media
import Task exposing (Task)
import Time exposing (Time)


{-| These are errors thrown by the tasks defined in this module.

NotFound: No element with that Id was found. Returns the Id provided
NotMediaElement: The element found with that Id was not an HTMLMediaElement. Returns the Id provided and the constructor of the element found with that id
PlayPromiseFailure: On modern browsers, Play() returns a promise.

-}
type alias Error =
    Media.State.Error



-- PROPERTY & ATTRIBUTE HELPERS


{-| A helper function for easily setting the muted property on a media element.

    player =
        audio [ id "player1", controls True, muted False, src "audiofile.mp3" ]
            []

-}
muted : Bool -> Attribute msg
muted muted =
    property "muted" (Encode.bool muted)



-- TASKS


{-| Tries to take an Id and switch it to a Playing state of Playback. Can fail if the Id isn't found, isn't an HTMLMediaElement, or fails to play.
-}
play : Id -> Task Error ()
play id =
    Native.Media.play


{-| Tries to take an Id switch it to a Paused state of Playback. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
pause : Id -> Task Error ()
pause id =
    Native.Media.pause


{-| Tries to take an Id, finds a media element and resets it. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
load : Id -> Task Error ()
load id =
    Native.Media.load


{-| Tries to take an Id and Time, find a media element and change the playback position to the provided Time. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
seek : Id -> Time -> Task Error ()
seek id time =
    Native.Media.seek


{-| Take an Id and Time, find a media element and change the playback position to the provided Time. Gives up some precision (compared to setting currentTime to desired seek value) for speed. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
fastSeek : Id -> Time -> Task Error ()
fastSeek id time =
    Native.Media.fastSeek


{-| Tries to find a media element by Id and test if it can a given MIME-type, provided as a String.
-}
canPlayMedia : Id -> String -> Task Error CanPlay
canPlayMedia id mediaType =
    Native.Media.canPlayType


{-| These are the three possible results of canPlayType.

Probably: This source is probably a playable type (probably because media can have all sorts of problem and browser support is all over the place)
Maybe: The player can try to play the media, but until it does, it has no idea where it will play or not
No: The media definitely cannot be played

-}
type CanPlay
    = Probably
    | Maybe
    | No
