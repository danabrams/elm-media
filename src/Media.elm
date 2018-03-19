module Media exposing (..)

{-| This is an experimental attempt to wrap the HTML5 Media API,
making it possible to write more sophisticated audio and video players
in Elm. Let me reiterate, this is experiemental, and not ready
for production. Use at your peril.

This package is a fairly direct layer over the Media API. I'm all for higher
level abstractions, but when dealing with media, a player _is_ the abstraction.
This package will hopefully allow myself and others to write great players that
abstract away the annoying details of dealing with audio & video. I've also
published an example of such a player [here](https://github.com/danabrams/elm-audio-player-example).

This package uses native code for a set of tasks that control playback
of media (Play, Pause, Load, Seek, etc) and to get the current state of
the media (Media.State.now) and also to check if a the browser supports
a given filetype (canPlayType).

It also uses native code to decode TimeRanges objects (which cannot be accessed
via an array syntax and therefore cannot be decoded currently in pure Elm).

Aside from the basic playback tasks, the heart of this library is a Json decoder that
takes an HtmlMediaElement's state and decodes it to an Elm record, as well as a set
of events that return a (Media.State.State -> Msg) so you can update your model
whenever these events fire. Also, there's a subscription for getting the state every
animation frame, in case you need a more frame accurate result, but this comes
with a performance penalty, and most great javascript media players simply rely on the
events, so I don't recommend.

Four important parts of writing players are not wrapped by this library:

1.  Subtitles - These are very important and are the next thing on my list to implement,
    I just need to figure out the cross-browser issues first. I'm very sensitive to the needs
    of hearing impaired users, so this is a top priority.

2.  Media Source Extensions - This is a portion of the Media API that allows us to do live
    streaming and adaptibe bitrate media. I think I have a good design for it, but it's a big
    challenge, and I want to make sure people like the API design of the basic Media API first.

3.  Web Audio - Web Audio API is often used to calculate the waveforms of audio files in
    audio players. However, wrapping that part of the Web API is beyond the scope of this package.
    Use ports for now. If this package gains acceptance and use, I'll commit to doing Web Audio
    as well.

4.  Fullscreen API - This is a pretty necessary Web API for writing a proper video player,
    but it beyond the scope of this package (besides, smarter people are working on this).

But as long as you're not planning to display subtitles, do live streaming (or Adaptive Bitrate),
generate waveforms or make a video fullscreen, this package should be ready to go.

This is a 1.0.0, and I'd love your feedback.


### Helpers

@docs muted, playbackRate, timeToString, playbackToString


### Media Control

@docs play, pause, load, fastSeek, seek


### canPlayMedia

@docs canPlayType, CanPlay


### Elm-Media Errors

@docs Error

-}

import Html exposing (Attribute)
import Html.Attributes exposing (property)
import Json.Encode as Encode exposing (bool)
import Media.State exposing (Id, Playback(..), State)
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


{-| A helper function for easily setting the muted property on a media element.

    player =
        audio [ id "player1", controls True, muted False, src "audiofile.mp3" ]
            []

-}
playbackRate : Float -> Attribute msg
playbackRate rate =
    property "playbackRate" (Encode.float rate)



-- TASKS


{-| Tries to take an Id and switch it to a Playing state of Playback. Can fail if the Id isn't found, isn't an HTMLMediaElement, or fails to play.
-}
play : Id -> Task Error ()
play =
    Native.Media.play


{-| Tries to take an Id switch it to a Paused state of Playback. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
pause : Id -> Task Error ()
pause =
    Native.Media.pause


{-| Tries to take an Id, finds a media element and resets it. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
load : Id -> Task Error ()
load =
    Native.Media.load


{-| Tries to take an Id and Time, find a media element and change the playback position to the provided Time. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
seek : Id -> Time -> Task Error ()
seek =
    Native.Media.seek


{-| Take an Id and Time, find a media element and change the playback position to the provided Time. Gives up some precision (compared to setting currentTime to desired seek value) for speed. Can fail if the Id isn't found or it isn't an HTMLMediaElement.
-}
fastSeek : Id -> Time -> Task Error ()
fastSeek =
    Native.Media.fastSeek


{-| Tries to find a media element by Id and test if it can a given MIME-type, provided as a String.
-}
canPlayType : Id -> String -> Task Error CanPlay
canPlayType =
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


{-| Converts a time value, such as a currentTime or duration, and returns a nicely
formatted string. Values of NaN or infinity will return 0:00.

It will always return a single-digit minute place and double-digit second place.
It will automatically format the minutes to two digits when necessary

-}
timeToString : Float -> String
timeToString time =
    let
        timeDigits : Int -> String
        timeDigits v =
            if v <= 9 then
                "0" ++ toString v
            else
                toString v

        h =
            floor time // 3600

        m =
            rem (floor time) 3600 // 60

        s =
            rem (rem (floor time) 3600) 60
    in
    if isNaN time then
        "0:00"
    else if isInfinite time then
        "0:00"
    else if h <= 0 then
        toString m ++ ":" ++ timeDigits s
    else
        toString h ++ ":" ++ timeDigits m ++ ":" ++ timeDigits s


{-| Takes a Playback type and returns a nicely formatted string
-}
playbackToString : Playback -> String
playbackToString status =
    case status of
        Paused ->
            "Paused"

        Playing ->
            "Playing"

        Loading ->
            "Loading"

        Buffering ->
            "Buffering"

        Ended ->
            "End"

        Problem err ->
            "Problem"
