port module Main exposing (..)

import Html exposing (div, source, button, text, p, track)
import Html.Attributes exposing (src, controls)
import Html.Events exposing (onClick)
import Media exposing (videoWithEvents, play, pause, seek, PortMsg, newVideo)
import Media.State exposing (currentTime, duration, id, playbackStatus, PlaybackStatus(..), played, TimeRanges)


port playbackControl : PortMsg -> Cmd msg


type alias Model =
    Media.State


type Msg
    = NoOp
    | Play
    | Pause
    | Seek Float
    | MediaStateUpdate Media.State


init : ( Model, Cmd Msg )
init =
    ( newVideo "myVideo", Cmd.none )


view model =
    let
        playPauseButton =
            case playbackStatus model of
                Playing ->
                    button [ onClick Pause ] [ text "Pause" ]

                Paused ->
                    button [ onClick Play ] [ text "Play" ]

                _ ->
                    button [ onClick Play ] [ text "Other" ]

        playededRange tr =
            p [] [ text <| "\nStart :" ++ (toString tr.start) ++ ", End: " ++ (toString tr.end) ]

        playedRanges =
            (List.map playededRange (played model))
    in
        div []
            [ videoWithEvents model
                MediaStateUpdate
                [ controls True ]
                [ source [ src "https://www.quirksmode.org/html5/videos/big_buck_bunny.mp4" ] []
                ]
            , playPauseButton
            , button [ onClick <| Seek 15 ] [ text "15s" ]
            , p [] [ text ("current: " ++ (toString <| currentTime model)) ]
            , p [] [ text ("duration: " ++ (toString <| duration model)) ]
            , p [] <| [ text "Played Ranges: " ] ++ playedRanges
            ]


update msg model =
    case msg of
        Play ->
            ( model, play model playbackControl )

        Pause ->
            ( model, pause model playbackControl )

        Seek time ->
            ( model, seek model time playbackControl )

        MediaStateUpdate state ->
            ( state, Cmd.none )

        _ ->
            ( model, Cmd.none )


main =
    Html.program { init = init, view = view, update = update, subscriptions = always Sub.none }
