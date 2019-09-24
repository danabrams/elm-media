module Main exposing (main)

import Html exposing (Html, div)
import Media exposing (newVideo, video)
import Media.Attributes exposing (controls)
import Media.Source exposing (mediaCapture)


main : Html msg
main =
    div []
        [ video (newVideo "capture")
            [ controls True ]
            [ ( "mediaCapture", mediaCapture [] [] ) ]
        ]
