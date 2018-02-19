module Media.Events exposing (onDurationChange, onPaused, onPlaying, onSeeked, onTimeUpdate, state)

{-| ###Events

@docs onPlaying, onPaused, onTimeUpdate, onDurationChange, onSeeked

###Decoders

@docs state

-}

import Array exposing (fromList, get)
import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode exposing (Decoder, Value, andThen, bool, fail, field, float, int, list, map, map2, map3, map4, string, succeed, value)
import Json.Decode.Pipeline exposing (custom, decode, optional, optionalAt, required, requiredAt, resolve)
import Media
import Media.State exposing (MediaError(..), MediaType(..), NetworkState(..), Playback(..), PlaybackGroup, ReadyState(..), State, TimeGroup, TimeRange, VideoSize)
import Native.Media


{-| -}
onSeeked : (State -> msg) -> Attribute msg
onSeeked tagger =
    on "seeked" <| target tagger state


{-| -}
onPlaying : (State -> msg) -> Html.Attribute msg
onPlaying tagger =
    on "play" <| target tagger state


{-| -}
onPaused : (State -> msg) -> Html.Attribute msg
onPaused tagger =
    on "pause" <| target tagger state


{-| -}
onTimeUpdate : (State -> msg) -> Attribute msg
onTimeUpdate tagger =
    on "timeupdate" <| target tagger state


{-| -}
onDurationChange : (State -> msg) -> Attribute msg
onDurationChange tagger =
    on "durationchange" <| target tagger state


{-| Fired when the loading of the media stalls
-}
onStalled : (State -> msg) -> Attribute msg
onStalled tagger =
    on "stalled" <| target tagger state


{-| -}
target : (a -> msg) -> Decoder a -> Decoder msg
target tagger decoder =
    map tagger <| field "target" decoder



--DECODERS


{-| -}
state : Decoder State
state =
    decode State
        |> required "id" string
        |> custom mediaType
        |> custom playbackGroup
        |> required "volume" float
        |> required "muted" bool
        |> custom timeGroup
        |> custom videoSize


{-| -}
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


{-| -}
playbackGroup : Decoder PlaybackGroup
playbackGroup =
    decode PlaybackGroup
        |> custom playback
        |> required "loop" bool
        |> required "playbackRate" float
        |> required "currentSrc" string
        |> custom readyState
        |> custom networkState


{-| -}
playback : Decoder Playback
playback =
    let
        toPlayback : Bool -> Maybe MediaError -> ReadyState -> Bool -> Decoder Playback
        toPlayback paused error ready ended =
            case paused of
                False ->
                    case error of
                        Just err ->
                            succeed <| Error err

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
                                            succeed Playing

                True ->
                    succeed Paused
    in
    decode toPlayback
        |> required "paused" bool
        |> custom mediaError
        |> custom readyState
        |> required "ended" bool
        |> resolve


{-| -}
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


{-| -}
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


{-| -}
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


{-| -}
timeGroup : Decoder TimeGroup
timeGroup =
    let
        toTimeGroup : Float -> Float -> Value -> Value -> Value -> Decoder TimeGroup
        toTimeGroup current duration bufferedValue seekableValue playedValue =
            decode
                { current = current
                , duration = duration
                , buffered = timeRanges bufferedValue
                , seekable = timeRanges seekableValue
                , played = timeRanges playedValue
                }
    in
    decode toTimeGroup
        |> required "currentTime" float
        |> required "duration" float
        |> required "buffered" value
        |> required "seekable" value
        |> required "played" value
        |> resolve


{-| -}
videoSize : Decoder VideoSize
videoSize =
    decode VideoSize
        |> optional "videoWidth" int 0
        |> optional "videoHeight" int 0


{-| -}
timeRanges : Value -> List TimeRange
timeRanges =
    Native.Media.decodeTimeRanges
