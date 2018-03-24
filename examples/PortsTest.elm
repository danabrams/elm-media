port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import Media.State exposing (Error, State, defaultVideo, now)
import Task exposing (attempt)


type alias Model =
    { ports : State
    , native : State
    }


init : ( Model, Cmd Msg )
init =
    ( { ports = defaultVideo "VideoPlayer"
      , native = defaultVideo "VideoPlayer"
      }
    , Cmd.none
    )


type Msg
    = NoOp
    | NativeUpdate (Result Error State)
    | UpdateButton
    | PortsUpdate Json.Encode.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateButton ->
            ( model, Cmd.batch [ attempt NativeUpdate <| now model.native.id, updateButton model.ports.id ] )

        NativeUpdate result ->
            case result of
                Err x ->
                    ( model, Cmd.none )

                Ok state ->
                    ( { model | native = state }, Cmd.none )

        PortsUpdate s ->
            let
                result =
                    Json.Decode.decodeValue Media.State.state s
            in
            case result of
                Err x ->
                    ( model, Cmd.none )

                Ok state ->
                    ( { model | ports = state }, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ video
            [ id "VideoPlayer"
            , src "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
            , controls True
            , loop True
            ]
            []
        , p [] [ text "Current Time:\n" ]
        , p [] [ text <| "via native: " ++ toString model.native.currentTime ++ "    " ++ "via ports: " ++ toString model.ports.currentTime ]
        , p [] [ text <| "via native: " ++ toString (floor <| model.native.currentTime / frameRate) ++ " frames   " ++ "via ports: " ++ toString (floor <| model.ports.currentTime / frameRate) ++ " frames" ]
        , button [ onClick UpdateButton ] [ text "Update" ]
        ]


frameRate =
    1 / 59.94


subscriptions : Model -> Sub Msg
subscriptions model =
    currentState PortsUpdate


main =
    Html.program { init = init, update = update, view = view, subscriptions = subscriptions }


port updateButton : String -> Cmd msg


port currentState : (Json.Encode.Value -> msg) -> Sub msg
