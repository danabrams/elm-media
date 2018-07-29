module Internal.Decode exposing (..)

import Json.Decode exposing (Decoder, succeed, Value, andThen, bool, fail, field, float, int, list, maybe, map, map2, map3, map4, string, succeed, value)
import Json.Decode.Pipeline exposing (custom, optional, optionalAt, required, requiredAt, resolve)
import Internal.Types exposing (..)


decodeState : Decoder State
decodeState =
    let
        toState :
            String
            -> MediaType
            -> PlaybackStatus
            -> ReadyState
            -> String
            -> Float
            -> Float
            -> NetworkState
            -> Int
            -> Int
            -> List TimeRange
            -> List TimeRange
            -> List TimeRange
            -> List TextTrack
            -> Decoder State
        toState idString typeOfMedia pbStatus rdyState src current dur netState wid hght buff seek played {- aTracks vTracks -} tTracks =
            succeed <|
                State
                    { id = Id idString
                    , mediaType = typeOfMedia
                    , playbackStatus = pbStatus
                    , readyState = rdyState
                    , source = src
                    , currentTime = current
                    , duration = dur
                    , networkState = netState
                    , videoWidth = wid
                    , videoHeight = hght
                    , buffered = buff
                    , seekable = seek
                    , played = played
                    , textTracks = tTracks
                    }
    in
        succeed toState
            |> required "id" string
            |> custom decodeMediaType
            |> custom decodePlaybackStatus
            |> custom decodeReadyState
            |> required "currentSrc" string
            |> required "currentTime" float
            |> required "duration" float
            |> custom decodeNetworkState
            |> optional "videoWidth" int 0
            |> optional "videoHeight" int 0
            |> optionalAt [ "buffered", "asArray" ] (list decodeTimeRange) []
            |> optionalAt [ "seekable", "asArray" ] (list decodeTimeRange) []
            |> optionalAt [ "played", "asArray" ] (list decodeTimeRange) []
            |> optional "textTracks" (collection decodeTextTrack) []
            |> resolve


decodeMediaType : Decoder MediaType
decodeMediaType =
    let
        toMediaType : String -> Decoder MediaType
        toMediaType element =
            case element of
                "AUDIO" ->
                    succeed Audio

                "VIDEO" ->
                    succeed Video

                _ ->
                    fail <| "This decoder only knows how to decode the state of Audio and Video elements, but was given an element of type " ++ element
    in
        succeed toMediaType
            |> required "tagName" string
            |> resolve


decodePlaybackStatus : Decoder PlaybackStatus
decodePlaybackStatus =
    let
        toPlaybackStatus : Maybe PlaybackError -> ReadyState -> Bool -> Bool -> Decoder PlaybackStatus
        toPlaybackStatus error ready ended paused =
            case error of
                Just err ->
                    succeed <| PlaybackError err

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
        succeed toPlaybackStatus
            |> custom decodePlaybackError
            |> custom decodeReadyState
            |> required "ended" bool
            |> required "paused" bool
            |> resolve


decodePlaybackError : Decoder (Maybe PlaybackError)
decodePlaybackError =
    let
        toPlaybackError : Int -> String -> Decoder (Maybe PlaybackError)
        toPlaybackError code message =
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
        succeed toPlaybackError
            |> optionalAt [ "error", "code" ] int 0
            |> optionalAt [ "error", "message" ] string ""
            |> resolve


decodeReadyState : Decoder ReadyState
decodeReadyState =
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
        succeed toReadyState
            |> required "readyState" int
            |> resolve


decodeNetworkState : Decoder NetworkState
decodeNetworkState =
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
        succeed toNetworkState
            |> required "networkState" int
            |> resolve


decodeTimeRange : Decoder TimeRange
decodeTimeRange =
    succeed TimeRange
        |> required "start" float
        |> required "end" float



{- decodeAudioTrack : Decoder AudioTrack
   decodeAudioTrack =
       succeed AudioTrack
           |> required "id" string
           |> custom decodeTrackKind
           |> required "label" string
           |> required "language" string
           |> required "enabled" bool



   decodeVideoTrack : Decoder VideoTrack
      decodeVideoTrack =
          succeed VideoTrack
              |> required "id" string
              |> custom decodeTrackKind
              |> required "label" string
              |> required "language" string
              |> required "selected" bool
-}


decodeTextTrack : Decoder TextTrack
decodeTextTrack =
    succeed TextTrack
        |> required "id" string
        |> optional "activeCues" (collection decodeVttCue) []
        |> optional "cues" (collection decodeVttCue) []
        |> custom decodeTextTrackKind
        |> required "inBandMetadataTrackDispatchType" string
        |> required "label" string
        |> required "language" string
        |> custom decodeTextTrackMode


decodeVttCue : Decoder VTTCue
decodeVttCue =
    succeed VTTCue
        |> required "text" string
        |> required "startTime" float
        |> required "endTime" float


decodeTextTrackMode : Decoder TextTrackMode
decodeTextTrackMode =
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
        succeed toMode
            |> optional "mode" string ""
            |> resolve


decodeTextTrackKind : Decoder TextTrackKind
decodeTextTrackKind =
    let
        toKind : String -> Decoder TextTrackKind
        toKind kind =
            if kind == "captions" then
                succeed Captions
            else if kind == "chapters" then
                succeed Chapters
            else if (kind == "description" || kind == "descriptions") then
                succeed Descriptions
            else if kind == "metadata" then
                succeed Metadata
            else if kind == "subtitles" then
                succeed Subtitles
            else if (kind == "" || kind == " ") then
                succeed None
            else
                succeed <| Other kind
    in
        succeed toKind
            |> optional "kind" string ""
            |> resolve


collection : Decoder a -> Decoder (List a)
collection decoder =
    field "length" int
        |> andThen
            (\length ->
                List.range 0 (length - 1)
                    |> List.map (\index -> field (toString index) decoder)
                    |> List.foldr (map2 (::)) (succeed [])
            )
