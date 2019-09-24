module Internal.Types exposing (Id(..), InternalState, MediaType(..), NetworkState(..), PlaybackError(..), PlaybackStatus(..), ReadyState(..), State(..), TextTrack, TextTrackKind(..), TextTrackMode(..), TimeRange, VTTCue, defaultAudio, defaultVideo)


type alias InternalState =
    { id : Id
    , mediaType : MediaType
    , playbackStatus : PlaybackStatus
    , readyState : ReadyState
    , source : String
    , currentTime : Float
    , duration : Float
    , networkState : NetworkState
    , videoWidth : Int
    , videoHeight : Int
    , buffered : List TimeRange
    , seekable : List TimeRange
    , played : List TimeRange
    , textTracks : List TextTrack
    }


type State
    = State InternalState


type Id
    = Id String


type MediaType
    = Audio
    | Video


type PlaybackStatus
    = Paused
    | Playing
    | Loading
    | Buffering
    | Ended
    | PlaybackError PlaybackError


type PlaybackError
    = Aborted String
    | Network String
    | Decode String
    | Unsupported String


type ReadyState
    = HaveNothing
    | HaveMetadata
    | HaveCurrentData
    | HaveFutureData
    | HaveEnoughData


type NetworkState
    = Empty
    | Idle
    | DataLoading
    | NoSource


type alias TimeRange =
    { start : Float
    , end : Float
    }



{- type alias AudioTrack =
   { id : String
   , kind : TrackKind
   , label : String
   , language : String
   , enabled : Bool
   }
-}


type TextTrackKind
    = Captions
    | Chapters
    | Descriptions
    | Metadata
    | Subtitles
    | Other String
    | None



{- type alias VideoTrack =
   { id : String
   , kind : TrackKind
   , label : String
   , language : String
   , selected : Bool
   }
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


type TextTrackMode
    = Disabled
    | Hidden
    | Showing


type alias VTTCue =
    { text : String
    , startTime : Float
    , endTime : Float
    }


defaultVideo : String -> State
defaultVideo idString =
    State
        { id = Id idString
        , mediaType = Video
        , playbackStatus = Paused
        , readyState = HaveNothing
        , source = ""
        , currentTime = 0.0
        , duration = 0.0
        , networkState = Idle
        , videoWidth = 0
        , videoHeight = 0
        , buffered = []
        , seekable = []
        , played = []
        , textTracks = []
        }


defaultAudio : String -> State
defaultAudio idString =
    State
        { id = Id idString
        , mediaType = Audio
        , playbackStatus = Paused
        , readyState = HaveNothing
        , source = ""
        , currentTime = 0.0
        , duration = 0.0
        , networkState = Idle
        , videoWidth = 0
        , videoHeight = 0
        , buffered = []
        , seekable = []
        , played = []

        --, audioTracks = []
        --, videoTracks = []
        , textTracks = []
        }
