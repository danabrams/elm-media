port module Main exposing (..)

import Html exposing (div, button, text, p)
import Html.Attributes exposing (id, kind, srclang, src)
import Html.Events exposing (onClick)
import Media exposing (load, play, pause, seek, PortMsg, newVideo, changeTextTrackMode, video)
import Media.State exposing (currentTime, duration, getId, playbackStatus, PlaybackStatus(..), played, TimeRanges)
import Media.Attributes exposing (label, playsInline, controls, mode, crossOrigin, anonymous, autoplay)
import Media.Events
import Media.Source exposing (mediaCapture, source, track)
import Html.Keyed exposing (node)


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


init : ( Model, Cmd Msg )
init =
    ( { state = newVideo "myVideo", trackState = Hide, mediaSource = VideoSource }, Cmd.none )


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
                        ((Media.Events.allEvents MediaStateUpdate)
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
                        ((Media.Events.allEvents MediaStateUpdate)
                            ++ [ playsInline True, controls True, crossOrigin anonymous, autoplay True ]
                        )
                        [ ( "media-capture", mediaCapture [] [] ) ]
                    )

        mediaInfo =
            case model.mediaSource of
                VideoSource ->
                    [ p [] [ text ("current: " ++ (toString <| currentTime model.state)) ]
                    , p [] [ text ("duration: " ++ (toString <| duration model.state)) ]
                    , p [] <| [ text ("Played Ranges: ") ] ++ playedRanges
                    ]

                MediaCapture ->
                    [ p [] [ text "Live Capture" ] ]
    in
        div []
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


main =
    Html.program { init = init, view = view, update = update, subscriptions = always Sub.none }
