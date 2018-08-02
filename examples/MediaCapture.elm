port module Main exposing (..)

import Html exposing (div, button, text, p)
import Html.Attributes
import Media.Source exposing (mediaCapture)
import Media exposing (State, newVideo, video)
import Media.Attributes exposing (controls)


main =
    div []
        [ video (newVideo "capture")
            [ controls True ]
            [ mediaCapture [] [] ]
        ]
