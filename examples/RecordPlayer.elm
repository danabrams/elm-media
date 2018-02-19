module Main exposing (..)

--import Element.Events exposing (..)

import Animation
import Animation.Spring.Presets
import Color exposing (darkBlue, grayscale, lightGray, white)
import Css
import Debug
import Draggable
import Draggable.Events exposing (onDragBy, onDragEnd)
import Element exposing (..)
import Element.Background as Background
import Element.Events as Event
import Element.Font as Font
import Element.Input
import Html
import Html.Attributes exposing (src)
import Html.Events exposing (on)
import Json.Decode as Decode
import Maybe
import Media exposing (..)
import Media.Events
import Media.State exposing(..)
import Mouse exposing (Position)
import Svg as Svg
import Svg.Attributes as SvgAttr
import Svg.Events exposing (onClick)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { mediaState : Media.State
    , offset : Float
    , recordRotation : Animation.State
    , switchAnimation : Animation.State
    , armPercentage : Float
    , position : ( Int, Int )
    , drag : Draggable.State String
    , armDrag : Maybe Float
    }


type alias Drag =
    Maybe Int


initialModel : Model
initialModel =
    { mediaState =
        { id = "recordplayer"
        , sources = [ Audio <| HLS "http://campabrams.com/stream/record.m3u8" ]
        , playstate = Paused
        , duration = 3600
        , currentTime = 0
        }
    , offset = 30
    , recordRotation =
        Animation.style
            [ Animation.rotate (Animation.turn 0) ]
    , switchAnimation =
        Animation.styleWith
            (Animation.spring
                Animation.Spring.Presets.stiff
            )
            [ Animation.rotate (Animation.deg 0) ]
    , position = ( 0, 0 )
    , armPercentage = offsetToPercent 3600 30
    , drag = Draggable.init
    , armDrag = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


dragConfig : Draggable.Config String Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy DragByEvent
        , onDragEnd OnDragEnd
        ]



-- UPDATE


type Msg
    = NoOp
    | PlayingEvent
    | PausedEvent
    | TimeUpdate Float
    | OffsetChange String
    | DurationChange Float
    | Play
    | Pause
    | Seek Float
    | Animate Animation.Msg
    | DragMsg (Draggable.Msg String)
    | DragByEvent Draggable.Delta
    | OnDragEnd


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayingEvent ->
            let
                newRecordRotation =
                    Animation.interrupt
                        [ Animation.loop
                            [ Animation.toWith (Animation.speed { perSecond = 0.55 })
                                [ Animation.rotate (Animation.turn 1) ]
                            , Animation.set [ Animation.rotate (Animation.turn 0) ]
                            ]
                        ]
                        model.recordRotation
            in
            ( { model
                | playstate = Playing
                , switchAnimation = switchAnimationOn model
                , recordRotation = newRecordRotation
              }
            , Cmd.none
            )

        PausedEvent ->
            let
                stopRecordRotation =
                    Animation.interrupt
                        []
                        model.recordRotation

                switchAnimationOff =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.rotate (Animation.deg 0)
                            ]
                        ]
                        model.switchAnimation
            in
            ( { model
                | playstate = Paused
                , switchAnimation = switchAnimationOff
                , recordRotation = stopRecordRotation
              }
            , Cmd.none
            )

        TimeUpdate time ->
            ( { model | mediaState = Media.updateCurrentTime model.mediaState time }, Cmd.none )

        DurationChange duration ->
            ( { model | duration = duration }, Cmd.none )

        OffsetChange offsetString ->
            let
                offset =
                    case String.toFloat offsetString of
                        Ok value ->
                            model.duration - value

                        Err error ->
                            model.offset

                newPercent =
                    offsetToPercent model.duration offset
            in
            ( { model | offset = offset }, load "recordplayer" )

        Play ->
            ( { model | switchAnimation = switchAnimationOn model }, play "recordplayer" )

        Pause ->
            ( model, pause "recordplayer" )

        Seek time ->
            let
                offsetDelta =
                    model.currentTime - time

                newOffsetValue =
                    newOffset model.offset offsetDelta model.duration

                newPercentage =
                    offsetToPercent model.duration newOffsetValue
            in
            ( { model | offset = newOffsetValue, armPercentage = newPercentage }, setCurrentTime { id = "recordplayer", time = time } )

        Animate msg ->
            ( { model
                | recordRotation = Animation.update msg model.recordRotation
                , switchAnimation = Animation.update msg model.switchAnimation
              }
            , Cmd.none
            )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model

        DragByEvent ( dx, dy ) ->
            let
                np =
                    model.armPercentage - dx

                newPercentage =
                    if np < 0 then
                        0
                    else if np > 100 then
                        100
                    else
                        np
            in
            ( { model | armPercentage = newPercentage }, Cmd.none )

        OnDragEnd ->
            let
                maxTime =
                    model.currentTime + model.offset

                newOffset =
                    model.duration * ((100 - model.armPercentage) / 100)

                newTime =
                    maxTime - newOffset
            in
            ( { model | offset = newOffset }, setCurrentTime { id = "recordplayer", time = newTime } )

        NoOp ->
            ( model, Cmd.none )


newOffset offset delta duration =
    if delta + offset < 0 then
        0
    else if delta + offset > duration then
        duration
    else
        delta + offset


offsetToPercent duration offset =
    ((duration - offset) / duration) * 100


switchAnimationOn model =
    Animation.interrupt
        [ Animation.to
            [ Animation.rotate (Animation.deg 90) ]
        ]
        model.switchAnimation



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Animation.subscription Animate [ model.recordRotation ]
        , Animation.subscription Animate [ model.switchAnimation ]
        , Draggable.subscriptions DragMsg model.drag
        ]



-- VIEW


view : Model -> Html.Html Msg
view model =
    layout
        [ Background.color (grayscale 0.9), Font.color (grayscale 0.2), Font.size 12 ]
    <|
        column []
            [ row [ height (px 10) ]
                [ el []
                    (html
                        Media.audio model.id model.sources ([Html.Attributes.autoplay True])
                        )
                    )
                ]
            , row [ height (px 400) ] [ el [] (html (recordPlayer model)) ]
            , controlBar model
            ]


progressBar : Model -> Element msg
progressBar model =
    let
        progress =
            toString model.currentTime ++ " of " ++ toString model.duration ++ " , offset = " ++ toString model.offset
    in
    row [] [ el [] (text progress) ]


controlBar : Model -> Element Msg
controlBar model =
    row [ height (px 50), paddingXY 0 50, spacing 50 ]
        [ iconButton "#JumpBackward" (Seek (model.currentTime - 15))
        , playOrPauseButton model.playstate
        , iconButton "#JumpForward" (Seek (model.currentTime + 15))
        ]


playOrPauseButton : PlayState -> Element Msg
playOrPauseButton playstate =
    let
        ( id, msg ) =
            case playstate of
                Playing ->
                    ( "#PauseIcon", Pause )

                Paused ->
                    ( "#PlayIcon", Play )
    in
    iconButton id msg


iconButton : String -> msg -> Element msg
iconButton iconId clickMsg =
    el [ width (px 50), height (px 50) ]
        (html
            (Html.div
                [ Html.Attributes.height 50
                , Html.Attributes.width 50
                ]
                [ Svg.svg
                    [ SvgAttr.height "50px"
                    , SvgAttr.width "50px"
                    ]
                    [ Svg.use [ SvgAttr.xlinkHref iconId ] []
                    , Svg.rect
                        [ SvgAttr.x "0"
                        , SvgAttr.x "0"
                        , SvgAttr.height "50"
                        , SvgAttr.width "50"
                        , Svg.Events.onClick clickMsg
                        , SvgAttr.opacity "0"
                        ]
                        []
                    ]
                ]
            )
        )


safeSeek : String -> Msg
safeSeek timeString =
    case String.toFloat timeString of
        Ok value ->
            Seek value

        Err error ->
            NoOp


recordPlayer model =
    Svg.svg [ SvgAttr.viewBox "0 0 596 656", SvgAttr.height "400px" ] [ playerBase, onOffSwitch model, vinylRecord model, playerArm model ]


onOffSwitch model =
    let
        ( ledColor, clickMsg ) =
            case model.playstate of
                Playing ->
                    ( "#FF1C1C", Pause )

                Paused ->
                    ( "#6E1B1B", Play )
    in
    Svg.g [ SvgAttr.id "Power", Html.Events.onClick clickMsg, SvgAttr.transform "translate(475 550)", SvgAttr.style "overflow: visible" ]
        [ Svg.g (Animation.render model.switchAnimation)
            [ Svg.g [ SvgAttr.id "switch" ]
                [ Svg.circle
                    [ SvgAttr.cx "0"
                    , SvgAttr.cy "00"
                    , SvgAttr.r "10"
                    , SvgAttr.fill "#444444"
                    ]
                    []
                , Svg.rect
                    [ SvgAttr.x "-30"
                    , SvgAttr.y "-2"
                    , SvgAttr.height "5"
                    , SvgAttr.width "30"
                    , SvgAttr.rx "5"
                    , SvgAttr.fill "#444444"
                    ]
                    []
                ]
            ]
        , Svg.circle
            [ SvgAttr.id "LED"
            , SvgAttr.cx "15"
            , SvgAttr.cy "-25"
            , SvgAttr.r "4"
            , SvgAttr.fill ledColor
            ]
            []
        ]


playerArm model =
    let
        minAngle =
            -9

        maxAngle =
            32

        angle =
            let
                a =
                    model.armPercentage * ((maxAngle - minAngle) / 100) + minAngle
            in
            if a < minAngle then
                minAngle
            else if a > maxAngle then
                maxAngle
            else
                a

        transformCode =
            "rotate(" ++ toString angle ++ " 505 100)"
    in
    Svg.g [ SvgAttr.transform transformCode ]
        [ Svg.line
            [ SvgAttr.id "Arm"
            , SvgAttr.x1 "505"
            , SvgAttr.y1 "50"
            , SvgAttr.x2 "505"
            , SvgAttr.y2 "280"
            , SvgAttr.stroke "#B2B2B2"
            , SvgAttr.strokeWidth "8"
            ]
            []
        , Svg.rect
            [ SvgAttr.id "CounterBalance"
            , SvgAttr.fill "#555555"
            , SvgAttr.height "76"
            , SvgAttr.width "40"
            , SvgAttr.x "485"
            , SvgAttr.y "0"
            ]
            []
        , Svg.line
            [ SvgAttr.id "Needle"
            , SvgAttr.stroke "#F1F1F1"
            , SvgAttr.strokeWidth "2"
            , SvgAttr.x1 "505"
            , SvgAttr.y1 "310"
            , SvgAttr.x2 "505"
            , SvgAttr.y2 "330"
            ]
            []
        , Svg.rect
            [ Draggable.mouseTrigger "my-element" DragMsg
            , SvgAttr.id "Capsule"
            , SvgAttr.fill "#666666"
            , SvgAttr.x "495"
            , SvgAttr.y "265"
            , SvgAttr.width "20"
            , SvgAttr.height "60"
            ]
            []
        ]


vinylRecord model =
    Svg.g [ SvgAttr.transform "translate(282, 300)" ]
        [ Svg.g
            (Animation.render model.recordRotation)
            [ Svg.use [ SvgAttr.xlinkHref "#VinylRecord" ] [] ]
        ]


playerBase =
    Svg.g [ SvgAttr.transform "translate(7.5, 57.5)" ]
        [ Svg.use [ SvgAttr.xlinkHref "#PlayerBase" ] []
        ]



{--|> below
                [ el Button
                    [ center, Event.onClick (OffsetChange 60) ]
                    (text "back 60 seconds")
                ]--}


onProgressBarClick : (( Float, Float, Float ) -> msg) -> Html.Attribute msg
onProgressBarClick msg =
    on "click"
        (Decode.map msg <| decodeClickLocations)


decodeClickLocations : Decode.Decoder ( Float, Float, Float )
decodeClickLocations =
    Decode.map3
        (,,)
        (Decode.at [ "pageX" ] Decode.float)
        (Decode.at [ "target", "offsetLeft" ] Decode.float)
        (Decode.at [ "target", "offsetWidth" ] Decode.float)


port load : String -> Cmd msg


port play : String -> Cmd msg


port pause : String -> Cmd msg


port setCurrentTime : { id : String, time : Float } -> Cmd msg


port getCurrentTime : String -> Cmd msg


port updateCurrentTime : (Float -> msg) -> Sub msg
