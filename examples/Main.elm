port module Main exposing (..)

import Html exposing (div, source, button, text, p, track, video)
import Html.Attributes exposing (id, src, kind, srclang)
import Html.Events exposing (onClick)
import Media exposing (play, pause, seek, PortMsg, newVideo, changeTextTrackMode)
import Media.State exposing (currentTime, duration, getId, playbackStatus, PlaybackStatus(..), played, TimeRanges)
import Media.Attributes exposing (label, playsInline, controls, mode, crossOrigin, anonymous)
import Media.Events


port outbound : PortMsg -> Cmd msg


type alias Model =
    { state : Media.State
    , trackState : TrackState
    }


type TrackState
    = Hide
    | Show


type Msg
    = NoOp
    | Play
    | Pause
    | Seek Float
    | MediaStateUpdate Media.State
    | ToggleTextTrack


init : ( Model, Cmd Msg )
init =
    ( { state = newVideo "myVideo", trackState = Hide }, Cmd.none )


view : Model -> Html.Html Msg
view model =
    let
        playPauseButton =
            case playbackStatus model.state of
                Playing ->
                    button [ onClick Pause ] [ text "Pause" ]

                Paused ->
                    button [ onClick Play ] [ text "Play" ]

                _ ->
                    button [ onClick Play ] [ text "Other" ]

        playededRange tr =
            p [] [ text <| "\nStart :" ++ (toString tr.start) ++ ", End: " ++ (toString tr.end) ]

        playedRanges =
            (List.map playededRange (played model.state))

        trackAttr =
            case model.trackState of
                Hide ->
                    mode Media.State.Hidden

                Show ->
                    mode Media.State.Showing
    in
        div []
            [ video
                {- model.state -}
                ((Media.Events.allEvents MediaStateUpdate)
                    ++ [ Html.Attributes.id "myVideo", playsInline True, controls True, src "elephants-dream-medium.mp4", crossOrigin anonymous ]
                )
                [ track
                    [ id "track"
                    , src "elephants-dream-subtitles-en.vtt"
                    , kind "subtitles"
                    , srclang "en"
                    , label "English"
                    , trackAttr
                    ]
                    []
                ]
            , playPauseButton
            , button [ onClick <| Seek 25 ] [ text "25s" ]
            , button [ onClick ToggleTextTrack ] [ text "Toggle Subtitles" ]
            , p [] [ text ("current: " ++ (toString <| currentTime model.state)) ]
            , p [] [ text ("duration: " ++ (toString <| duration model.state)) ]
            , p [] <| [ text "Played Ranges: " ] ++ playedRanges
            ]


update msg model =
    case msg of
        Play ->
            ( model, play model.state outbound )

        Pause ->
            ( model, pause model.state outbound )

        Seek time ->
            ( model, seek model.state time outbound )

        MediaStateUpdate state ->
            ( { model | state = state }, Cmd.none )

        ToggleTextTrack ->
            let
                newTrackState =
                    case model.trackState of
                        Show ->
                            Hide

                        _ ->
                            Show
            in
                ( { model | trackState = newTrackState }, Cmd.none )

        _ ->
            ( model, Cmd.none )


main =
    Html.program { init = init, view = view, update = update, subscriptions = always Sub.none }
