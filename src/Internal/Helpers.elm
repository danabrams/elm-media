module Internal.Helpers exposing (..)

import Media.State exposing (TextTrackMode(..), TextTrackKind(..))


{-| Simple conversion from a TextTrackMode to string
-}
textTrackModeToString : TextTrackMode -> String
textTrackModeToString mode =
    case mode of
        Showing ->
            "showing"

        Hidden ->
            "hidden"

        _ ->
            "disabled"


{-| Simple conversion from a string to TextTrackMode
-}
stringToTextTrackMode : String -> TextTrackMode
stringToTextTrackMode str =
    case str of
        "showing" ->
            Showing

        "hidden" ->
            Hidden

        _ ->
            Disabled
