module Video exposing (..)

import Html exposing (Html, button, div, text, video, source, track)
import Html.Attributes exposing (controls, id, src, style, width, height)
import Html.Events exposing (onClick)
import Media exposing (Error, load, pause, play, playbackToString, seek, timeToString)
import Media.Events exposing (onDurationChange, onError, onLoadStart, onLoadedData, onLoadedMetadata, onPaused, onPlaying, onProgress, onStalled, onTimeUpdate)
import Media.State exposing (Playback(..), State, defaultVideo)
import Task


type alias Model =
    State


type Msg
    = Play
    | Pause
    | Reload
    | Restart
    | Seek Float
    | MediaUpdate State
    | ErrorHandler (Result Error ())


init : ( Model, Cmd Msg )
init =
    ( defaultVideo "VideoPlayer", Cmd.none )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Play ->
            ( model, Task.attempt ErrorHandler <| play model.id )

        Pause ->
            ( model, Task.attempt ErrorHandler <| pause model.id )

        Seek time ->
            ( model, Task.attempt ErrorHandler <| seek model.id time )

        Reload ->
            ( model, Task.attempt ErrorHandler <| load model.id )

        Restart ->
            ( model
            , Cmd.batch
                [ Task.attempt ErrorHandler <| seek model.id 0
                , Task.attempt ErrorHandler <| play model.id
                ]
            )

        MediaUpdate mediaState ->
            ( mediaState, Cmd.none )

        ErrorHandler result ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        buttonText =
            case model.playback of
                Playing ->
                    "Pause"

                Paused ->
                    "Play"

                Ended ->
                    "Restart"

                _ ->
                    playbackToString model.playback

        buttonMsg =
            case model.playback of
                Playing ->
                    Pause

                Ended ->
                    Restart

                Problem err ->
                    Reload

                _ ->
                    Play
    in
        div []
            [ video
                [ id model.id
                , onDurationChange MediaUpdate
                , onTimeUpdate MediaUpdate
                , onPlaying MediaUpdate
                , onPaused MediaUpdate
                , onLoadedData MediaUpdate
                , onLoadStart MediaUpdate
                , onLoadedMetadata MediaUpdate
                , onProgress MediaUpdate
                , onError MediaUpdate
                , onStalled MediaUpdate
                , width 320
                , height 240
                ]
                [ source [ src "https://p-events-delivery.akamaized.net/18oihuabsdfvoiuhbsdfv03/m3u8/hls_vod_mvp.m3u8" ] []
                , track [ src "https://p-events-delivery.akamaized.net/18oihuabsdfvoiuhbsdfv03/vod327/cc4/eng/1803lohjbsdfvaspdijhbn.vtt" ] []
                ]
            , div [ style [ ( "display", "block" ) ] ]
                [ text <| timeToString model.currentTime ++ "/" ++ timeToString model.duration ]
            , div [ style [ ( "display", "block" ) ] ]
                [ text <| "Video Dimensions: " ++ toString model.videoSize.width ++ "x" ++ toString model.videoSize.height ]
            , div [ style [ ( "display", "block" ) ] ]
                [ button [ onClick <| Seek <| model.currentTime - 15 ] [ text "Back 15s" ]
                , button [ onClick buttonMsg ] [ text buttonText ]
                , button [ onClick <| Seek <| model.currentTime + 15 ] [ text "Forward 15s" ]
                ]
            ]



-- MAIN


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
