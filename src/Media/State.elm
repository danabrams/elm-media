module Media.State
    exposing
        ( Error(..)
        , Id
        , MediaError(..)
        , MediaType(..)
        , NetworkState(..)
        , Playback(..)
        , ReadyState(..)
        , State
        , TimeRange
        , VideoSize
        , default
        , defaultAudio
        , defaultVideo
        , everyFrame
        , now
        , state
        )

{-| This module provides definitions for types representing the state of an HTMLMediaElement. I provided as few details as I could, and figure out as much for a user as possible, but players are complicated, and require a lot of information to do different things. It's likely that no player will need to simultaneously use all the fields I've exposed, and it's likely that most will never need more than a few, like duration, volume, currentTime, etc.

Media is constantly updating itself, without user interaction--which is to say, it has side effects. This library deals with those side effects by providing a subscription to those side effects.

You can also use decode to transform a value representing an HTMLMediaElement into a State.

###State

@docs State, default, defaultAudio, defaultVideo

###Getting and Decoding State

@docs everyFrame, now, state

###State Types

@docs Id, MediaType, Playback
@docs MediaError, ReadyState, NetworkState
@docs TimeRange, Error, VideoSize

-}

--import Array exposing (Array)
--import Dict

import Json.Decode exposing (Decoder, Value, andThen, bool, fail, field, float, int, list, maybe, map, map2, map3, map4, string, succeed, value)
import Json.Decode.Pipeline exposing (custom, decode, optional, optionalAt, required, requiredAt, resolve)
import Json.Decode.Extra exposing (collection)
import Native.Media
import Task exposing (Task)
import Time exposing (Time)


-- Types


{-| The core record of the media library. This represents the state of an HTMLMediaElement at a given moment. getState and subscribe both return a state record. In other words, this is a record representing the current state of side effects on a media object.

You can put this in your model or create a simpler abstraction with just the fields you need, such as:

type alias Model =
{ id: String
, currentTime: Float
, duration: Float
}

Then in your update function, just update the fields you need with the fields from the State:

type Msg
= Media.State.State

update model msg =
case msg of
MediaUpdate state ->
({ model | currentTime = state.currentTime
, duration = state.duration }
,
Cmd.none )

**Important:** Please make sure to give your audio and video elements a unique Id.

**NOTE: Most browsers will not return a duration of infinity during a live stream, use the "seekable" TimeRange instead.

-}
type alias State =
    { id : Id
    , mediaType : MediaType
    , playback : Playback
    , source : String
    , currentTime : Time
    , duration : Time
    , ready : ReadyState
    , network : NetworkState
    , timeRanges :
        { buffered : List TimeRange
        , seekable : List TimeRange
        , played : List TimeRange
        }
    , videoSize : { width : Int, height : Int }
    , audioTracks : List AudioTrack
    , videoTracks : List VideoTrack
    , textTracks : List TextTrack
    }


{-| Returns a default state, given an id, a mediaType (Audio or Video),
and a Maybe source. This can be thought of as empty player state, for
putting in your init, if the media isn't loaded.
-}
default :
    { id : Id
    , mediaType : MediaType
    , source : Maybe String
    }
    -> State
default options =
    { id = options.id
    , mediaType = options.mediaType
    , playback = Paused
    , source = Maybe.withDefault "" options.source
    , currentTime = 0.0
    , duration = 0.0
    , ready = HaveNothing
    , network = Idle
    , timeRanges =
        { seekable = []
        , buffered = []
        , played = []
        }
    , videoSize = { width = 0, height = 0 }
    , audioTracks = []
    , videoTracks = []
    , textTracks = []
    }


{-| Returns a default state for an Audio player, with source "".
Just give it an id.
-}
defaultAudio : Id -> State
defaultAudio id =
    default { id = id, mediaType = Audio, source = Nothing }


{-| Returns a default state for a Video player, with source "".
Just give it an id.
-}
defaultVideo : Id -> State
defaultVideo id =
    default { id = id, mediaType = Video, source = Nothing }


{-| -}
type MediaType
    = Audio
    | Video


{-| "ready" represents how much data the player has loaded from the meida file.
"network" represents the current network usage in loading the media file.
-}
type alias DataGroup =
    { ready : ReadyState
    , network : NetworkState
    }


{-| Represents three TimeRange lists:

"buffered": which parts of the media file have been loaded and are available
for immediately playback.

"seekable": what parts of the media can be seeked to by the user (useful for
determining duration in a live stream, for instance).

"played": what portions of the media have been played, so you can write a more
specific played indicator.

-}
type alias TimeGroup =
    { buffered : List TimeRange
    , seekable : List TimeRange
    , played : List TimeRange
    }


nowRaw : Id -> Task Error Value
nowRaw =
    Native.Media.getMediaById


{-| Takes an Id, and returns the State of a mediaElement with that id.
Can result in Error if the Id is not found, or the element found by that
id isn't an HTMLMediaElement.
-}
now : Id -> Task Error State
now id =
    nowRaw id
        |> Task.andThen
            (\value ->
                case Json.Decode.decodeValue state value of
                    Ok media ->
                        Task.succeed media

                    Err e ->
                        Task.fail (NotFound e)
            )


{-| **Very Important -- Not Yet Implemented -- Do Not Use**

A media element has many attributes that will update themselves without any user input. This is a serious side-effect. This function lets you subscribe to its current State, delivered with each Animation Frame, via requestAnimationFrame().

    main =
        Html.Program
            { init = init
            , view = view
            , update = update
            , subscriptions = subscription
            }

        subscription = Media.subscribe "audioPlayer" updateMediaState

You can also get these updates using getState after a variety of events in Media.Events, but subscription should be your prefered way to keep track of the side effects.

-}
everyFrame : Id -> (Result Error State -> msg) -> Sub msg
everyFrame id tagger =
    Debug.crash "Not Implemented Yet"


{-| String representing the Dom id of your media element.

**Important:** Please, please, please use unique Id's for your media elements. We use the Id to find the element to run Tasks like play, load, and getState. Media.Events events also currently return an Id. Please let them be unique.

-}
type alias Id =
    String


{-| Represents the four possible states of a media player loading
data from the media file:

Empty: No data yet. ReadyState is HaveNothing
Idle: Media Element is active and has a resource, but is not currently using the network to load it|
Loading: Media Element is currently downloading data
NoSource: No Media Element Source found

-}
type NetworkState
    = Empty
    | Idle
    | DataLoading
    | NoSource


{-| Representation of the ReadyState of Media data, which indicates when it will be ready to play.

HaveNothing: No information is available about the media resource
HaveMetadata: Enough information is available that metadata attributes are initialized.
HaveCurrentData: Enough data is available to play the current frame, but only the current frame.
HaveFutureData: Data beyond the current frame is available, but not the entire source. May be as little as two frames.
HaveEnoughData: Enough data is available that if downloading continues at current data rate, user will be able to play until the end of the source without interruption

-}
type ReadyState
    = HaveNothing
    | HaveMetadata
    | HaveCurrentData
    | HaveFutureData
    | HaveEnoughData


{-| Represents a start and end time within the duration of the media source. Does not necessarily (or usually) represent the duration of the media source itself.

Examples include the sections of a media source that are buffered, the sections that are seekable, etc.

-}
type alias TimeRange =
    { start : Time
    , end : Time
    }


{-| These are the errors the media player itself might throw. The errors include a human readable string with specific diagnostic information, passed from the browser itself.

Aborted: Fetching of the media resource was aborted by user request
Network: A Network error occured that prevented the browser from fetching the media, despite it having been previously available
Decode: The browser is unable to decode the media, despite it previously having been supported
Unsupported: The resource or media provider object is not supported or is otherwise unsuitable

-}
type MediaError
    = Aborted String
    | Network String
    | Decode String
    | Unsupported String


{-| Current Playback state of the media player. Error represents a MediaError, thrown by the browser, not an Error thrown by the tasks in this module.
-}
type Playback
    = Paused
    | Playing
    | Loading
    | Buffering
    | Ended
    | Problem MediaError


{-| These are the errors of this library, that may be returned when calling a task
or decoding a state.
-}
type Error
    = NotFound String
    | NotMediaElement String String
    | PlayPromiseFailure String
    | NotTimeRanges String
    | DecodeError String


{-| Represents the size of video media
-}
type alias VideoSize =
    { width : Int
    , height : Int
    }


{-| Represents a single audio track
-}
type alias AudioTrack =
    { id : Id
    , kind : TrackKind
    , label : String
    , language : String
    , enabled : Bool
    }


{-| Represents the possible kinds of audio, video or text track
-}
type TrackKind
    = Alternative
    | Captions
    | Chapters
    | Description
    | Main
    | Metadata
    | Sign
    | Subtitles
    | Translation
    | Commentary
    | None


{-| Represents a single video track
-}
type alias VideoTrack =
    { id : Id
    , kind : TrackKind
    , label : String
    , language : String
    , selected : Bool
    }


{-| Represents a text track (such as synchronized subtitles or data
-}
type alias TextTrack =
    { id : Id
    , activeCues : List VTTCue
    , cues : List VTTCue
    , kind : TrackKind
    , inBandMetadataTrackDispatchType : String
    , label : String
    , language : String
    , mode : TextTrackMode
    }


{-| Represents the current mode of a text track. Disabled = ignored.
Hidden = parsed, but not displayed. Showing = enabled and visible.
-}
type TextTrackMode
    = Disabled
    | Hidden
    | Showing


{-| A text track cue
-}
type alias VTTCue =
    { text : String
    , startTime : Float
    , endTime : Float
    }



--DECODERS


{-| Decodes the current state of an HtmlMediaElement
-}
state : Decoder State
state =
    decode State
        |> required "id" string
        |> custom mediaType
        |> custom playback
        |> required "src" string
        |> required "currentTime" float
        |> required "duration" float
        |> custom readyState
        |> custom networkState
        |> custom timeGroup
        |> custom videoSize
        |> optional "audioTracks" (collection audioTrack) []
        |> optional "videoTracks" (collection videoTrack) []
        |> optional "textTracks" (collection textTrack) []


mediaType : Decoder MediaType
mediaType =
    let
        toMediaType : String -> Decoder MediaType
        toMediaType element =
            case element of
                "AUDIO" ->
                    succeed Audio

                "VIDEO" ->
                    succeed Audio

                _ ->
                    fail <| "This decoder only knows how to decode the state of Audio and Video elements, but was given an element of type " ++ element
    in
        decode toMediaType
            |> required "tagName" string
            |> resolve


playback : Decoder Playback
playback =
    let
        toPlayback : Maybe MediaError -> ReadyState -> Bool -> Bool -> Decoder Playback
        toPlayback error ready ended paused =
            case error of
                Just err ->
                    succeed <| Problem err

                Nothing ->
                    case ready of
                        HaveNothing ->
                            succeed Loading

                        HaveMetadata ->
                            succeed Loading

                        HaveCurrentData ->
                            succeed Buffering

                        HaveFutureData ->
                            succeed Buffering

                        HaveEnoughData ->
                            case ended of
                                True ->
                                    succeed Ended

                                False ->
                                    case paused of
                                        True ->
                                            succeed Paused

                                        False ->
                                            succeed Playing
    in
        decode toPlayback
            |> custom mediaError
            |> custom readyState
            |> required "ended" bool
            |> required "paused" bool
            |> resolve


networkState : Decoder NetworkState
networkState =
    let
        toNetworkState : Int -> Decoder NetworkState
        toNetworkState code =
            case code of
                0 ->
                    succeed Empty

                1 ->
                    succeed Idle

                2 ->
                    succeed DataLoading

                3 ->
                    succeed NoSource

                _ ->
                    fail <| "Unexpect Network State Index: " ++ toString code
    in
        decode toNetworkState
            |> required "networkState" int
            |> resolve


readyState : Decoder ReadyState
readyState =
    let
        toReadyState : Int -> Decoder ReadyState
        toReadyState code =
            case code of
                0 ->
                    succeed HaveNothing

                1 ->
                    succeed HaveMetadata

                2 ->
                    succeed HaveCurrentData

                3 ->
                    succeed HaveFutureData

                4 ->
                    succeed HaveEnoughData

                _ ->
                    fail <| "Unexpect Ready State Index: " ++ toString code
    in
        decode toReadyState
            |> required "readyState" int
            |> resolve


mediaError : Decoder (Maybe MediaError)
mediaError =
    let
        toMediaError : Int -> String -> Decoder (Maybe MediaError)
        toMediaError code message =
            case code of
                0 ->
                    succeed Nothing

                1 ->
                    succeed <| Just (Aborted message)

                2 ->
                    succeed <| Just (Network message)

                3 ->
                    succeed <| Just (Decode message)

                4 ->
                    succeed <| Just (Unsupported message)

                _ ->
                    fail <|
                        "Unexpected HTML5MediaError code: "
                            ++ toString code
                            ++ ": "
                            ++ message
    in
        decode toMediaError
            |> optionalAt [ "error", "code" ] int 0
            |> optionalAt [ "error", "message" ] string ""
            |> resolve


timeGroup : Decoder TimeGroup
timeGroup =
    let
        toTimeGroup : Value -> Value -> Value -> Decoder TimeGroup
        toTimeGroup bufferedValue seekableValue playedValue =
            decode
                { buffered = timeRanges bufferedValue
                , seekable = timeRanges seekableValue
                , played = timeRanges playedValue
                }
    in
        decode toTimeGroup
            |> required "buffered" value
            |> required "seekable" value
            |> required "played" value
            |> resolve


videoSize : Decoder VideoSize
videoSize =
    decode VideoSize
        |> optional "videoWidth" int 0
        |> optional "videoHeight" int 0


audioTrack : Decoder AudioTrack
audioTrack =
    decode AudioTrack
        |> required "id" string
        |> custom trackKind
        |> required "label" string
        |> required "language" string
        |> required "enabled" bool


videoTrack : Decoder VideoTrack
videoTrack =
    decode VideoTrack
        |> required "id" string
        |> custom trackKind
        |> required "label" string
        |> required "language" string
        |> required "selected" bool


textTrack : Decoder TextTrack
textTrack =
    decode TextTrack
        |> required "id" string
        |> optional "activeCues" (collection vttCue) []
        |> optional "cues" (collection vttCue) []
        |> custom trackKind
        |> required "inBandMetadataTrackDispatchType" string
        |> required "label" string
        |> required "language" string
        |> custom textTrackMode


vttCue : Decoder VTTCue
vttCue =
    decode VTTCue
        |> required "text" string
        |> required "startTime" float
        |> required "endTime" float


textTrackMode : Decoder TextTrackMode
textTrackMode =
    let
        toMode : String -> Decoder TextTrackMode
        toMode mode =
            case mode of
                "hidden" ->
                    succeed Hidden

                "showing" ->
                    succeed Showing

                _ ->
                    succeed Disabled
    in
        decode toMode
            |> optional "mode" string ""
            |> resolve


trackKind : Decoder TrackKind
trackKind =
    let
        toKind : String -> Decoder TrackKind
        toKind kind =
            case kind of
                "alternative" ->
                    succeed Alternative

                "captions" ->
                    succeed Captions

                "chapters" ->
                    succeed Chapters

                "description" ->
                    succeed Description

                "descriptions" ->
                    succeed Description

                "main" ->
                    succeed Main

                "metadata" ->
                    succeed Metadata

                "sign" ->
                    succeed Sign

                "subtitles" ->
                    succeed Subtitles

                "translation" ->
                    succeed Translation

                "commentary" ->
                    succeed Commentary

                _ ->
                    succeed None
    in
        decode toKind
            |> optional "kind" string ""
            |> resolve


timeRanges : Value -> List TimeRange
timeRanges =
    Native.Media.decodeTimeRanges
