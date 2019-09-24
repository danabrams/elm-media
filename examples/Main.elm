port module Main exposing (Model, Msg(..), SourceType(..), TrackState(..), init, main, outbound, update, view)

import Browser
import Html exposing (button, div, p, text, track)
import Html.Attributes exposing (id, kind, src, srclang)
import Html.Events exposing (onClick)
import Html.Keyed exposing (node)
import Media exposing (PortMsg, load, mute, newVideo, pause, play, seek, video)
import Media.Attributes exposing (anonymous, autoplay, controls, crossOrigin, label, mode, playsInline)
import Media.Events
import Media.Source exposing (mediaCapture, source)
import Media.State exposing (PlaybackStatus(..), currentTime, duration, playbackStatus, played)


port outbound : PortMsg -> Cmd msg


type alias Model =
    { state : Media.State
    , trackState : TrackState
    , mediaSource : SourceType
    }


type SourceType
    = VideoSource
    | MediaCapture


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
    | ToggleSource


init : () -> ( Model, Cmd Msg )
init _ =
    let
        model =
            { state = newVideo "myVideo", trackState = Hide, mediaSource = VideoSource }
    in
    ( model, Cmd.none )


view : Model -> Browser.Document Msg
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

        -- mutButton =
        playedRange tr =
            p [] [ text <| "\nStart :" ++ String.fromFloat tr.start ++ ", End: " ++ String.fromFloat tr.end ]

        playedRanges =
            List.map playedRange (played model.state)

        trackAttr =
            case model.trackState of
                Hide ->
                    mode Media.State.Hidden

                Show ->
                    mode Media.State.Showing

        isVideo =
            case model.mediaSource of
                VideoSource ->
                    True

                MediaCapture ->
                    False

        videoElement =
            case model.mediaSource of
                VideoSource ->
                    ( "video"
                    , video
                        model.state
                        (Media.Events.allEvents MediaStateUpdate
                            ++ [ playsInline True, controls True, crossOrigin anonymous ]
                        )
                        [ ( "source", source "elephants-dream-medium.mp4" [] )
                        , ( "track"
                          , track
                                [ id "track"
                                , src "elephants-dream-subtitles-en.vtt"
                                , kind "subtitles"
                                , srclang "en"
                                , label "English"
                                , trackAttr
                                ]
                                []
                          )
                        ]
                    )

                MediaCapture ->
                    ( "cap"
                    , video model.state
                        (Media.Events.allEvents MediaStateUpdate
                            ++ [ playsInline True, controls True, crossOrigin anonymous, autoplay True ]
                        )
                        [ ( "media-capture", mediaCapture [] [] ) ]
                    )

        mediaInfo =
            case model.mediaSource of
                VideoSource ->
                    [ p [] [ text ("current: " ++ (String.fromFloat <| currentTime model.state)) ]
                    , p [] [ text ("duration: " ++ (String.fromFloat <| duration model.state)) ]
                    , p [] <| [ text "Played Ranges: " ] ++ playedRanges
                    ]

                MediaCapture ->
                    [ p [] [ text "Live Capture" ] ]
    in
    { title = "Elm Media Example"
    , body =
        [ div []
            [ node "div" [] [ videoElement ]
            , p []
                [ playPauseButton
                , button [ onClick <| Seek 25 ] [ text "25s" ]
                , button [ onClick ToggleSource ] [ text "Toggle Source" ]
                , if isVideo then
                    button [ onClick ToggleTextTrack ] [ text "Toggle Subtitles" ]

                  else
                    text ""
                ]
            , div [] mediaInfo
            ]
        ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        _ =
            Debug.log "model" model
    in
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

        ToggleSource ->
            let
                newModel =
                    case model.mediaSource of
                        VideoSource ->
                            { model | mediaSource = MediaCapture }

                        MediaCapture ->
                            { model | mediaSource = VideoSource }
            in
            ( newModel, load model.state outbound )

        _ ->
            ( model, Cmd.none )


main : Program () Model Msg
main =
    Browser.document { init = init, view = view, update = update, subscriptions = always Sub.none }
