module Media.State
    exposing
        ( currentTime
        , getId
        , duration
        , source
        , playbackStatus
        , PlaybackStatus(..)
        , PlaybackError
        , ReadyState(..)
        , readyState
        , mediaType
        , MediaType(..)
        , networkState
        , NetworkState(..)
        , videoSize
        , buffered
        , seekable
        , played
        , TimeRanges
        , textTracks
        , TextTrack
        , VTTCue
        , TextTrackMode(..)
        , TextTrackKind(..)
        )

{-| ###State

@docs getId, MediaType, mediaType, duration, PlaybackStatus, PlaybackError, playbackStatus, currentTime, duration, source, ReadyState, readyState, NetworkState, networkState, videoSize, TimeRanges, buffered, played, seekable, TextTrack, TextTrackKind, TextTrackMode, VTTCue, textTracks

-}

import Internal.Types as Types


type alias State =
    Types.State


{-| Represents whether the Media Element is an HTMLAudioElement or HTMLVideoElement,
NOT where the file is an audio or video file. Audio files play in video elements
and vice-versa.
-}
type MediaType
    = Audio
    | Video


{-| Represents an error in loading or playing the file, produced by the HTMLMediaElement,
and a string representing the browsers error message.

The posibilities are:
Aborted: The user aborted loading the video.
Network: A network error stopped the video from loading.
Decode: the browser is unable to decode this file.
Unsupported: the browser does not support playback of this file.

-}
type PlaybackError
    = Aborted String
    | Network String
    | Decode String
    | Unsupported String


{-| Represents the current status of playback in the Media Element.

Here are the possibilites:
Paused: Media is not playing (and not Ended)
Playing: Media is playing
Loading: Media is still loading, does not have enough data to start playing
Buffering: Media is buffering. Media is not playing
Ended: Media completed. Media is not playing
PlaybackError: Media has encountered a problem and is not playing.

-}
type PlaybackStatus
    = Paused
    | Playing
    | Loading
    | Buffering
    | Ended
    | PlaybackError PlaybackError


{-| Represents a more precise record of how much of the media file has been
loaded and is ready to play.

HaveNothing: No information about the media
HaveMetadata: Information about the media, but no meaningful stream data
HaveCurrentData: Data is available only for the current frame, not anything beyond that
HaveFutureData: Data for some, but not all, of the remaining stream is available (as little as two frames worth)
HaveEnoughData: Enough data to play media through to end without further buffering, if data bandwidth remains constant

-}
type ReadyState
    = HaveNothing
    | HaveMetadata
    | HaveCurrentData
    | HaveFutureData
    | HaveEnoughData


{-| The HTMLMediaElement loads its own resources (most of the time). This
type represents the state of it's network connection.

Empty: No data loaded or loading
Idle: Element has a resource, but is not currently loading it (possibly because it is finished loading in its entirety)
Loading: browser is downloading the media
NoSource: No valid source provided

-}
type NetworkState
    = Empty
    | Idle
    | DataLoading
    | NoSource


{-| This type represents a List TimeRange. A TimeRange is simply `{start: float, end: float}`.

This type is used to represent attributes about a timeline that have multiple value,
such as the sections of a media that have been played already.

This will always be a list.

NOTE: This cannot be used without adding an asArray property to the TimeRanges.prototype in javascript.
You can do so like this:
`if (!(TimeRanges.prototype.asArray)) {
Object.defineProperty(TimeRanges.prototype, "asArray", { get: function () { var arr = []; for (i = 0; i < this.length; i++) { arr.push({ start: this.start(i), end: this.end(i) }); }; return arr; } });
}`
or you can use function "modifyTimeRanges() in the file "Port/mediaPort.js."

-}
type alias TimeRanges =
    List Types.TimeRange


{-| Represents a subtitle, captions, or other synchronized text track.
-}
type alias TextTrack =
    { id : String
    , activeCues : List VTTCue
    , cues : List VTTCue
    , kind : TextTrackKind
    , inBandMetadataTrackDispatchType : String
    , label : String
    , language : String
    , mode : TextTrackMode
    }


{-| Represents the possible kinds of TextTrack.

If this module can't figure out what kind it is, it will produce an `Other String`,
with the string representing the kind attribute presented by the browser.

-}
type TextTrackKind
    = Captions
    | Chapters
    | Descriptions
    | Metadata
    | Subtitles
    | Other String
    | None


{-| Represents where the text track is currently Showing (active), Hidden (active but non-visible),
or Disabled (not active)
-}
type TextTrackMode
    = Disabled
    | Hidden
    | Showing


{-| Represents a single, WebVTT text cue. The structure looks like this:

`type alias VTTCue =
{ text : String
, startTime : Float
, endTime : Float`
}

-}
type alias VTTCue =
    Types.VTTCue



{- GETTERS -}


{-| Takes your state and returns a string representing it's id.

Since State and Id are both opaque types, this is the easiest way to
access the id of the media element.

-}
getId : State -> String
getId state =
    case state of
        Types.State iState ->
            case iState.id of
                Types.Id idString ->
                    idString


{-| Getter to get the MediaType of an element from a State.
-}
mediaType : State -> MediaType
mediaType state =
    case state of
        Types.State s ->
            case s.mediaType of
                Types.Audio ->
                    Audio

                Types.Video ->
                    Video


{-| Getter to get the PlaybackStatus of an element from a State.
-}
playbackStatus : State -> PlaybackStatus
playbackStatus state =
    case state of
        Types.State s ->
            case s.playbackStatus of
                Types.Paused ->
                    Paused

                Types.Playing ->
                    Playing

                Types.Loading ->
                    Loading

                Types.Buffering ->
                    Buffering

                Types.Ended ->
                    Ended

                Types.PlaybackError p ->
                    PlaybackError (toPlaybackError p)


toPlaybackError : Types.PlaybackError -> PlaybackError
toPlaybackError err =
    case err of
        Types.Aborted s ->
            Aborted s

        Types.Network s ->
            Network s

        Types.Decode s ->
            Decode s

        Types.Unsupported s ->
            Unsupported s


{-| Getter to get the readyState of an element from a State.
-}
readyState : State -> ReadyState
readyState state =
    case state of
        Types.State s ->
            case s.readyState of
                Types.HaveNothing ->
                    HaveNothing

                Types.HaveMetadata ->
                    HaveMetadata

                Types.HaveCurrentData ->
                    HaveCurrentData

                Types.HaveFutureData ->
                    HaveFutureData

                Types.HaveEnoughData ->
                    HaveEnoughData


{-| Getter to get the src of an element from a State.
-}
source : State -> String
source state =
    case state of
        Types.State iState ->
            iState.source


{-| Getter to get the currentTime of an element from a State.
-}
currentTime : State -> Float
currentTime state =
    case state of
        Types.State iState ->
            iState.currentTime


{-| Getter to get the duration of an element from a State.

NOTE: On a live stream, duration will return Infinity. You need to use
the seekable function instead.

-}
duration : State -> Float
duration state =
    case state of
        Types.State iState ->
            iState.duration


{-| Getter to get the NetworkState of an element from a State.
-}
networkState : State -> NetworkState
networkState state =
    case state of
        Types.State s ->
            case s.networkState of
                Types.Empty ->
                    Empty

                Types.Idle ->
                    Idle

                Types.DataLoading ->
                    DataLoading

                Types.NoSource ->
                    NoSource


{-| Getter to get the video of an element from the State of a video element.

NOTE: If used on an HTMLAudioElement it will return a `Nothing`.

On an HTMLVideoElement it returns `Just {width: Int, height: Int}`.

-}
videoSize : State -> Maybe { width : Int, height : Int }
videoSize state =
    case state of
        Types.State s ->
            case s.mediaType of
                Types.Audio ->
                    Nothing

                Types.Video ->
                    Just { width = s.videoWidth, height = s.videoHeight }


{-| Getter to get the buffered TimeRanges of an element from a State.

Buffered represents the parts of the media that have been loaded and cached
and are ready for playback.

-}
buffered : State -> TimeRanges
buffered state =
    case state of
        Types.State s ->
            s.buffered


{-| Getter to get the seekable TimeRanges of an element from a State.

Seekable represents the part of media that the user can currently navigate to.

Useful for figuring out the length of a livestream.

-}
seekable : State -> TimeRanges
seekable state =
    case state of
        Types.State s ->
            s.seekable


{-| Getter to get the played TimeRanges of an element from a State.

Played ranges are the parts of the video that the user has watched already.

-}
played : State -> TimeRanges
played state =
    case state of
        Types.State s ->
            s.played


{-| Getter to get the textTracks of an element from a State.
-}
textTracks : State -> List TextTrack
textTracks state =
    let
        textTrackModeConverter : Types.TextTrackMode -> TextTrackMode
        textTrackModeConverter mode =
            case mode of
                Types.Hidden ->
                    Hidden

                Types.Disabled ->
                    Disabled

                Types.Showing ->
                    Showing

        textTrackKindConverter : Types.TextTrackKind -> TextTrackKind
        textTrackKindConverter kind =
            case kind of
                Types.Captions ->
                    Captions

                Types.Chapters ->
                    Chapters

                Types.Descriptions ->
                    Descriptions

                Types.Metadata ->
                    Metadata

                Types.Subtitles ->
                    Subtitles

                Types.Other o ->
                    Other o

                Types.None ->
                    None

        textTrackConverter : Types.TextTrack -> TextTrack
        textTrackConverter tt =
            { id = tt.id
            , activeCues = tt.activeCues
            , cues = tt.cues
            , kind = textTrackKindConverter tt.kind
            , inBandMetadataTrackDispatchType = tt.inBandMetadataTrackDispatchType
            , label = tt.label
            , language = tt.language
            , mode = textTrackModeConverter tt.mode
            }
    in
        case state of
            Types.State s ->
                List.map textTrackConverter s.textTracks
