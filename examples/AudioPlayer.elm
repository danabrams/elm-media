module AudioPlayer exposing (..)

import Html exposing (Html, audio, text)
import Html.Attributes exposing (autoplay, controls, id, src, type_)
import Media exposing (Error(..), State)


type alias State =
    { id : String
    , sources : List Source
    , currentTime : Float
    , duration : Float
    , playState : PlayState
    , networkState : Media.NetworkState
    , muted : Bool
    , error : Maybe Media.Error
    , buffered : Media.TimeRanges
    }


type PlayState
    = Playing
    | Paused


type Source
    = MP3 String



-- CONFIG


{-| Configuration for your audio player.
**Note:** Your `Config` should _never_ be held in your model.
It should only appear in `view` code.
-}
type Config msg
    = Config
        { modifyMsg : State -> msg
        , removeMsg : msg
        }



-- VIEW


audioPlayer : State -> Html msg
audioPlayer player =
    audio
        [ id player.id
        , controls True
        , autoplay True
        ]
        (List.map source player.sources)


source : Source -> Html msg
source mediaSource =
    case mediaSource of
        MP3 url ->
            Html.source [ src url, type_ "audio/mpeg" ] [ text "Your browser does not support playback of the MP3 format. Please try another browser, such as Chrome." ]
