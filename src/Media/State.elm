module Media.State exposing (..)

{-| This module provides definitions for types representing the state of an HTMLMediaElement. I provided as few details as I could, and figure out as much for a user as possible, but players are complicated, and require a lot of information to do different things. It's likely that no player will need to simultaneously use all the fields I've exposed, and it's likely that most will never need more than a few, like duration, volume, currentTime, etc.

Media is constantly updating itself, without user interaction--which is to say, it has side effects. This library deals with those side effects by providing a subscription to those side effects.

You can also use decode to transform a value representing an HTMLMediaElement into a State.

###State

@docs State

###Getting and Decoding State

@docs now, everyFrame

###State Types

@docs Id, MediaType, PlaybackGroup, Playback
@docs MediaError, ReadyState, NetworkState
@docs TimeGroup, TimeRange, Error, VideoSize

-}

import Array exposing (Array)
import Dict
import Json.Decode exposing (Value)
import Native.Media
import Process
import Task exposing (Task)
import Time exposing (Time)


-- Types


{-| The core record of the media library. This represents the state of an HTMLMediaElement at a given moment. getState and subscribe both return a state record. In other words, this is a record representing the current state of side effects on a media object.

You probably don't need this in your model. Instead, create a simpler abstraction with just the fields you need, such as:

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

-}
type alias State =
    { id : Id
    , mediaType : MediaType
    , playback : PlaybackGroup
    , volume : Float
    , muted : Bool
    , time : TimeGroup
    , videoSize : { width : Int, height : Int }
    }


{-| -}
type MediaType
    = Audio
    | Video { width : Int, height : Int }


{-| -}
type alias PlaybackGroup =
    { status : Playback
    , loop : Bool
    , rate : Float
    , source : String
    , ready : ReadyState
    , network : NetworkState
    }


{-| -}
type alias TimeGroup =
    { current : Time
    , duration : Time
    , buffered : List TimeRange
    , seekable : List TimeRange
    , played : List TimeRange
    }


{-| Takes an Id, and returns a State of it. Can result in Error if the Id is not found, or the element found by that Id isn't an HTMLMediaElement.
-}
now : Id -> Task Error State
now =
    Native.Media.getStateWithId


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


{-| String representing the Dom Id of your media element.

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
    = Playing
    | Paused
    | Loading
    | Buffering
    | Ended
    | Error MediaError


{-| -}
type Error
    = NotFound String
    | NotMediaElement String String
    | PlayPromiseFailure String
    | NotTimeRanges String


{-| -}
type alias VideoSize =
    { width : Int
    , height : Int
    }
