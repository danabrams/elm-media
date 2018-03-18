module Media.Events exposing (onDurationChange, onError, onLoadStart, onLoadedData, onLoadedMetadata, onPaused, onPlay, onPlaying, onProgress, onSeeked, onSeeking, onStalled, onTimeUpdate)

{-| ###Events

@docs onPlaying, onPaused, onTimeUpdate, onDurationChange, onSeeked, onLoadedData, onPaused, onLoadedMetadata

-}

import Array exposing (fromList, get)
import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode exposing (Decoder, field, map)
import Media.State exposing (State, state)


{-| -}
onSeeked : (State -> msg) -> Attribute msg
onSeeked tagger =
    on "seeked" <| target tagger state


{-| -}
onSeeking : (State -> msg) -> Attribute msg
onSeeking tagger =
    on "seeking" <| target tagger state


{-| -}
onPlay : (State -> msg) -> Html.Attribute msg
onPlay tagger =
    on "play" <| target tagger state


{-| -}
onPlaying : (State -> msg) -> Html.Attribute msg
onPlaying tagger =
    on "playing" <| target tagger state


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


{-| -}
onAbort : (State -> msg) -> Attribute msg
onAbort tagger =
    on "abort" <| target tagger state


{-| -}
onCanPlay : (State -> msg) -> Attribute msg
onCanPlay tagger =
    on "canplay" <| target tagger state


{-| -}
onCanPlayThrough : (State -> msg) -> Attribute msg
onCanPlayThrough tagger =
    on "canplaythrough" <| target tagger state


{-| -}
onEmptied : (State -> msg) -> Attribute msg
onEmptied tagger =
    on "emptied" <| target tagger state


{-| Fired when the loading of the media stalls
-}
onStalled : (State -> msg) -> Attribute msg
onStalled tagger =
    on "stalled" <| target tagger state


{-| -}
onError : (State -> msg) -> Attribute msg
onError tagger =
    on "error" <| target tagger state


{-| -}
onLoadedData : (State -> msg) -> Attribute msg
onLoadedData tagger =
    on "loadeddata" <| target tagger state


{-| -}
onLoadedMetadata : (State -> msg) -> Attribute msg
onLoadedMetadata tagger =
    on "loadedmetadata" <| target tagger state


{-| -}
onLoadStart : (State -> msg) -> Attribute msg
onLoadStart tagger =
    on "loadstart" <| target tagger state


{-| -}
onLoadSuspend : (State -> msg) -> Attribute msg
onLoadSuspend tagger =
    on "suspend" <| target tagger state


{-| -}
onWaiting : (State -> msg) -> Attribute msg
onWaiting tagger =
    on "waiting" <| target tagger state


{-| -}
onProgress : (State -> msg) -> Attribute msg
onProgress tagger =
    on "progress" <| target tagger state


{-| -}
target : (a -> msg) -> Decoder a -> Decoder msg
target tagger decoder =
    map tagger <| field "target" decoder
