module Podcast exposing (..)

import Color exposing (black, white)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Attribute, Html, div)
import Html.Attributes
import Json.Encode
import Media exposing (Error, muted, play)
import Media.Events exposing (onDurationChange, onPaused, onPlaying, onTimeUpdate)
import Media.State as Media
import Svg exposing (svg)
import Svg.Attributes as SvgAttr
import Svg.Events
import Task
import Time.DateTime exposing (DateTime, fromTimestamp, hour, minute, second)
import Window


type alias Model =
    { episode : Episode
    , podcast : Podcast
    , duration : Float
    , currentTime : Float
    , device : Device
    , state : Maybe Media.State
    }


type Device
    = Unknown
    | Phone { orientation : Orientation, size : Window.Size }
    | Tablet { orientation : Orientation, size : Window.Size }
    | Desktop { orientation : Orientation, size : Window.Size }


type Orientation
    = Portrait
    | Landscape


type alias Enclosure =
    { url : String
    , length : String
    , mediaType : String
    }


type alias Podcast =
    { title : String
    , home : String
    }


type alias Episode =
    { title : String
    , link : String
    , description : String
    , enclosure : Enclosure
    , episodeNumber : Int
    , poster : String
    , showNotes : String
    }


type Msg
    = NoOp
    | Resize Window.Size
    | MediaUpdate Media.State
    | Play
    | HandleError (Result Error ())


init : ( Model, Cmd Msg )
init =
    ( { episode =
            { title = "Elm Town 27 - Murphy Randle's Story"
            , link = "http://elmtown.audio/27-murphy-randle"
            , description = "Surprise! Mario Rogic is your host for this episode, because he's interviewing the normal host of the podcast, Murphy Randle."
            , enclosure =
                { url = "https://audio.simplecast.com/27550e4a.mp3"
                , length = "40985895"
                , mediaType = "audio/mpeg"
                }
            , episodeNumber = 27
            , poster = "https://media.simplecast.com/episode/image/111821/1518046334-artwork.jpg"
            , showNotes = "<p>Surprise! Mario Rogic is your host for this episode, because he's interviewing the normal host of the podcast, Murphy Randle.  Listen to hear about Murphy's background in Animation, and how Murphy came to the world of Web development, and eventually started Elm Town!</p>\n\n<a name='Links'></a>\n<h1>Links</h1>\n\n<ul>\n<li>(00:25:50) <a href='https://www.youtube.com/watch?v=-JlC2Q89yg4'>Climbing Into Elm </a></li>\n</ul>\n\n\n<a name='Picks'></a>\n<h2>Picks</h2>\n\n<ul>\n<li>(00:39:15) <a href='https://www.scalyr.com'>Scalyr</a></li>\n<li>(00:40:19) <a href='https://www.patreon.com/towncasts'>Our Patreon</a></li>\n<li>(00:40:37) <a href='https://reason.town/'>Reason Town</a></li>\n</ul>"
            }
      , podcast = { title = "Elm Town", home = "Https://Elmtown.audio" }
      , device = Unknown
      , duration = 0
      , currentTime = 0
      , state = Nothing
      }
    , Task.perform Resize Window.size
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize size ->
            let
                device =
                    processWindowSize size
            in
            ( { model | device = device }, Cmd.none )

        MediaUpdate state ->
            ( { model
                | duration = state.time.duration
                , currentTime = state.time.current
                , state = Just state
              }
            , Cmd.none
            )

        Play ->
            ( model, Task.attempt HandleError <| Media.pause "#podcastPlayer" )

        HandleError error ->
            let
                _ =
                    Debug.log "Dan Error Time Town" error
            in
            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


processWindowSize : Window.Size -> Device
processWindowSize size =
    let
        w =
            size.width

        h =
            size.height

        p =
            w < h
    in
    case p of
        True ->
            if w <= 1000 then
                Phone { orientation = Portrait, size = size }
            else if w <= 1200 then
                Tablet { orientation = Portrait, size = size }
            else
                Desktop { orientation = Portrait, size = size }

        False ->
            if h <= 1000 then
                Phone { orientation = Landscape, size = size }
            else if h <= 1200 then
                Tablet { orientation = Landscape, size = size }
            else
                Desktop { orientation = Landscape, size = size }



-- Views


view : Model -> Html Msg
view model =
    case model.device of
        Unknown ->
            div [] []

        Phone _ ->
            phoneView model

        _ ->
            phoneView model


phoneView : Model -> Html Msg
phoneView model =
    Element.layout
        [ Background.color white
        ]
    <|
        case model.device of
            Phone device ->
                column [ width fill, height fill, alignTop ]
                    [ stickyPlayerView model
                    , episodeView model
                    , logoView model
                    , audioPlayer model
                    ]

            _ ->
                column [ width fill, height fill, alignTop ]
                    [ stickyPlayerView model
                    , episodeView model
                    , logoView model
                    , audioPlayer model
                    ]


logoView : Model -> Element msg
logoView model =
    row [ width fill, height (px 94), alignBottom, paddingXY 20 0, Background.color <| Color.darkBlue, Font.color white ]
        [ el [ Font.alignLeft, alignLeft, Font.bold, Font.size 54 ] (text "Elmcast")
        , el [ Font.alignRight, alignRight, Font.size 54, centerY, paddingEach { right = 20, left = 0, bottom = 0, top = 0 } ] (text "+")
        ]


episodeView : Model -> Element msg
episodeView model =
    let
        viewHeight =
            case model.device of
                Phone device ->
                    case device.orientation of
                        Portrait ->
                            if device.size.width <= 750 then
                                device.size.height - (201 + 94)
                            else
                                device.size.height - (251 + 94)

                        Landscape ->
                            device.size.height - 94

                _ ->
                    800
    in
    paragraph [ width fill, height (px viewHeight), scrollbarY, spacing 5, Font.alignLeft, Font.size 30, paddingXY 50 0, spacing 5, scrollbarY, alignTop ] [ html <| textHtml model.episode.showNotes ]


stickyPlayerView : Model -> Element Msg
stickyPlayerView model =
    let
        posterSize =
            case isPhablet model.device of
                True ->
                    260

                False ->
                    210
    in
    column
        [ width fill
        , height (px <| posterSize + 1)
        ]
        [ row [ width fill, height (px posterSize), spacingXY 10 0 ]
            [ posterImage model posterSize
            , column [ width fill, height (px posterSize), center, paddingXY 0 5, spacingXY 0 25 ]
                [ smallTitle model
                , controlRowView model
                , el [ width fill, alignBottom ] <| playerTimes model
                ]
            ]
        , el [ width fill, alignLeft, height (px 4), alignTop, alignLeft ] <| playHead model
        ]


playerTimes : Model -> Element msg
playerTimes model =
    let
        titleSize =
            case isPhablet model.device of
                True ->
                    32

                False ->
                    24
    in
    row [ width fill, height (px titleSize), center ]
        [ el
            [ alignLeft
            , Font.alignLeft
            , Font.color Color.darkGray
            , Font.size titleSize
            , Font.italic
            ]
            (text <| timeToString model.currentTime)
        , el
            [ alignRight
            , Font.alignRight
            , Font.color Color.darkGray
            , Font.italic
            , Font.size titleSize
            , padding 10
            ]
            (text <| "-" ++ timeToString (model.duration - model.currentTime))
        ]


audioPlayer : Model -> Element Msg
audioPlayer model =
    html <|
        Html.audio
            [ Html.Attributes.id "podcastPlayer"
            , Html.Attributes.controls True
            , onPlaying MediaUpdate
            , onTimeUpdate MediaUpdate
            , onPaused MediaUpdate
            , onDurationChange MediaUpdate
            ]
            [ Html.source
                [ Html.Attributes.src model.episode.enclosure.url
                , Html.Attributes.type_ model.episode.enclosure.mediaType
                ]
                []
            ]


smallTitle : Model -> Element msg
smallTitle model =
    let
        titleSize =
            case isPhablet model.device of
                True ->
                    32

                False ->
                    24
    in
    column [ width fill, paddingXY 10 0, height (px (titleSize * 2)), alignTop, alignLeft, Font.alignLeft, Font.size titleSize ]
        [ el [ width fill, Font.bold ] (text model.podcast.title)
        , el [ width fill, Font.italic ] (text model.episode.title)
        ]


largeTitle : Model -> Element msg
largeTitle model =
    paragraph [ width fill, height fill ]
        [ link [ width fill, Font.size 48, Font.center, Font.bold ]
            { url = model.podcast.home, label = text model.podcast.title }
        , link [ Font.size 36, Font.alignLeft, Font.italic, Font.color Color.darkBlue ]
            { url = model.episode.link, label = text model.episode.title }
        ]


isPhablet : Device -> Bool
isPhablet device =
    case device of
        Phone d ->
            case d.orientation of
                Portrait ->
                    d.size.width > 750

                Landscape ->
                    d.size.height > 750

        _ ->
            False


controlRowView : Model -> Element Msg
controlRowView model =
    let
        size =
            case isPhablet model.device of
                True ->
                    100

                False ->
                    72

        iconSize =
            px size

        fontSize =
            size // 3
    in
    row
        [ width fill, height iconSize, spaceEvenly, centerY, paddingXY (size // 3) 0 ]
        [ el [ height iconSize, centerY, width iconSize ] (html <| backwardIcon "black")
        , el [ height iconSize, centerY, width iconSize ] (html <| playIcon "black")
        , el [ height iconSize, centerY, width iconSize ] (html <| forwardIcon "black")
        , column [ height iconSize, width iconSize, center, centerY ]
            [ el [ Font.alignRight, centerY, width fill, height (px fontSize), Font.size fontSize ] (text "1.25x") ]
        ]


posterImage : Model -> Int -> Element msg
posterImage model size =
    image
        [ width (px size)
        , height (px size)
        ]
        { src = model.episode.poster
        , description = "Poster Image for episode " ++ toString model.episode.episodeNumber
        }


textHtml : String -> Html msg
textHtml html =
    div
        [ Json.Encode.string html
            |> Html.Attributes.property "innerHTML"
        ]
        []


playHead : Model -> Element msg
playHead model =
    let
        duration =
            case model.duration <= 0 of
                False ->
                    model.duration

                True ->
                    0.0001

        width =
            case model.device of
                Phone device ->
                    device.size.width

                Tablet device ->
                    device.size.width

                Desktop device ->
                    device.size.width

                _ ->
                    0

        toPercent : Float -> String
        toPercent x =
            toString ((x / duration) * 100) ++ "%"

        playedX =
            toPercent model.currentTime

        bufferedX =
            toPercent buffered
    in
    html <|
        svg [ SvgAttr.width "100%", SvgAttr.height "4", SvgAttr.viewBox <| "0 0 " ++ toString width ++ " 4", SvgAttr.overflow "visible" ]
            [ Svg.filter [ SvgAttr.id "bottomShadow", SvgAttr.width "105%", SvgAttr.height "150%" ]
                [ Svg.feOffset
                    [ SvgAttr.result "offsetOut"
                    , SvgAttr.in_ "SourceAlpha"
                    , SvgAttr.dx "0"
                    , SvgAttr.dy "1"
                    ]
                    []
                , Svg.feColorMatrix
                    [ SvgAttr.result "colorOut"
                    , SvgAttr.in_ "offsetOut"
                    , SvgAttr.type_ "matrix"
                    , SvgAttr.values "0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.75 0"
                    ]
                    []
                , Svg.feGaussianBlur
                    [ SvgAttr.result "blurOut"
                    , SvgAttr.in_ "colorOut"
                    , SvgAttr.stdDeviation "1.5"
                    ]
                    []
                , Svg.feBlend [ SvgAttr.in_ "SourceGraphic", SvgAttr.in2 "blurOut", SvgAttr.mode "normal" ] []
                ]
            , Svg.g [ SvgAttr.strokeWidth "4", SvgAttr.filter "url(#bottomShadow)" ]
                [ Svg.line [ SvgAttr.stroke "lightgrey", SvgAttr.x1 "0", SvgAttr.y1 "0", SvgAttr.x2 "100%", SvgAttr.y2 "0" ] []
                , Svg.line [ SvgAttr.stroke "grey", SvgAttr.x1 "0", SvgAttr.y1 "0", SvgAttr.x2 bufferedX, SvgAttr.y2 "0" ] []
                , Svg.line [ SvgAttr.stroke "orangered", SvgAttr.x1 "0", SvgAttr.y1 "0", SvgAttr.x2 playedX, SvgAttr.y2 "0" ]
                    []
                , Svg.circle
                    [ SvgAttr.stroke "none", SvgAttr.fill "orangered", SvgAttr.cx playedX, SvgAttr.cy "0", SvgAttr.r "6" ]
                    []
                ]
            ]


timeToString : Float -> String
timeToString time =
    let
        timeDigits : Int -> String
        timeDigits v =
            case v <= 9 of
                True ->
                    "0" ++ toString v

                False ->
                    toString v

        h =
            floor time // 3600

        m =
            rem (floor time) 3600 // 60

        s =
            rem (rem (floor time) 3600) 60
    in
    case h <= 0 of
        False ->
            timeDigits h ++ ":" ++ timeDigits m ++ ":" ++ timeDigits s

        True ->
            timeDigits m ++ ":" ++ timeDigits s


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes Resize



-- SVG Icons


playIcon : String -> Html Msg
playIcon color =
    svg [ SvgAttr.viewBox "0 0 36 36", Svg.Events.onClick Play ]
        [ Svg.polygon [ SvgAttr.fill color, SvgAttr.points "4 0 4 36 36 18" ] [] ]


forwardIcon : String -> Html msg
forwardIcon color =
    svg [ SvgAttr.viewBox "0 0 36 36" ]
        [ Svg.circle
            [ SvgAttr.cx "18"
            , SvgAttr.cy "18"
            , SvgAttr.r "15"
            , SvgAttr.stroke color
            , SvgAttr.strokeWidth "2"
            , SvgAttr.fill "none"
            , SvgAttr.strokeDashoffset "3"
            , SvgAttr.strokeDasharray "75, 25"
            ]
            []
        , Svg.polygon [ SvgAttr.fill color, SvgAttr.points "18 6 18 0 22 3" ] []
        , Svg.text_ [ SvgAttr.x "18", SvgAttr.y "22", SvgAttr.fontSize "12", SvgAttr.textAnchor "middle" ] [ Svg.text "30s" ]
        ]


backwardIcon : String -> Html msg
backwardIcon color =
    svg
        [ SvgAttr.viewBox "0 0 36 36"

        {--, Svg.Events.onClick <| Seek (model.currentTime - 30)--}
        ]
        [ Svg.circle
            [ SvgAttr.cx "18"
            , SvgAttr.cy "18"
            , SvgAttr.r "15"
            , SvgAttr.stroke color
            , SvgAttr.strokeWidth "2"
            , SvgAttr.fill "none"
            , SvgAttr.strokeDashoffset "30"
            , SvgAttr.strokeDasharray "75, 25"
            ]
            []
        , Svg.polygon [ SvgAttr.fill color, SvgAttr.points "14 3 18 0 18 6" ] []
        , Svg.text_ [ SvgAttr.x "18", SvgAttr.y "22", SvgAttr.fontSize "12", SvgAttr.textAnchor "middle" ] [ Svg.text "30s" ]
        ]


buffered =
    2000
