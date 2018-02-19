module Main exposing (..)

import AnimationFrame
import Debug exposing (log)
import Html exposing (Html, audio, div, p, text, video)
import Html.Attributes exposing (attribute, autoplay, controls, id, src, type_)
import Html.Events
import Json.Decode
import Media exposing (muted)
import Media.Events exposing (onDurationChange, onPaused, onPlaying, onTimeUpdate)
import Media.State exposing (Error(..), Id, NetworkState(..), State)
import Task exposing (perform)
import Time exposing (Time)


---- MODEL ----


type alias Model =
    PlayerState


type alias PlayerState =
    { id : Id
    , source : Source
    , error : Maybe Error
    , state : Maybe State
    }


type Source
    = MP3 String


init : ( Model, Cmd Msg )
init =
    ( { id = "podcastPlayer"
      , source = MP3 "assets/Elm_Town_25.mp3"
      , error = Nothing
      , state = Nothing
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = Frame Time
    | MediaUpdate State
    | Pause State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Frame time ->
            ( model, Cmd.none )

        MediaUpdate media ->
            ( { model | state = Just media }, Cmd.none )

        Pause media ->
            ( { model | state = Just media }, Cmd.none )



--    Video state ->
--        ( { model | state = Just media, currentTime = state.time.current }, Cmd.none )
---- VIEW ----


view : Model -> Html Msg
view model =
    let
        time =
            case model.state of
                Just media ->
                    media.time.current

                Nothing ->
                    0
    in
    div []
        [ audioPlayer model
        , p [ id "luftballoon" ]
            [ text ("  currentTime: " ++ toString time) ]
        ]


processError : Maybe Media.Error -> String
processError error =
    case error of
        Nothing ->
            ""

        Just (NotFound id) ->
            Debug.log "Not Found: " id

        Just (NotMediaElement id class) ->
            Debug.log "Not a Media Element: " ("Element '#" ++ id ++ "' is an instance of '" ++ class ++ "")

        Just (PlayPromiseFailure error) ->
            Debug.log "Media.play() promise failed with the following message: " error

        Just (NotTimeRanges class) ->
            Debug.log "Value passed to runtime decoder of TimeRanges was not a TimeRanges object, but rather of " class


audioPlayer : Model -> Html Msg
audioPlayer player =
    let
        error =
            processError player.error
    in
    audio
        [ id player.id
        , controls True
        , autoplay True
        , muted False
        , onTimeUpdate MediaUpdate
        , onPaused Pause
        ]
        [ source player.source ]


videoPlayer : Model -> Html Msg
videoPlayer player =
    let
        error =
            processError player.error
    in
    video
        [ id "video"
        , controls True
        , autoplay True
        , muted False
        , onTimeUpdate MediaUpdate
        , onPaused Pause
        , src "https://devstreaming-cdn.apple.com/videos/wwdc/2017/102xyar2647hak3e/102/hls_vod_mvp.m3u8"
        ]
        []


source : Source -> Html msg
source mediaSource =
    case mediaSource of
        MP3 url ->
            Html.source [ src url, type_ "audio/mpeg" ] [ text "Your browser does not support playback of the MP3 format. Please try another browser, such as Chrome." ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }


subscription model =
    AnimationFrame.times Frame
