module Media.Source exposing
    ( source
    , fileType, FileType(..), audioCodec, videoCodec
    , timeFragment, idFragment, trackFragment
    , track
    , mediaCapture
    --, spatialFragment
    --, spatialFragmentWithPercent
    )

{-| API for creating better source elements. Includes support for easily generating mime type and
codec attributes, and also for generating Media Fragment URIs.

@docs source


# Mime Types & Codecs

@docs fileType, FileType, audioCodec, videoCodec


# Media Fragment API

\*\* Note: If you check the code, there's commented out support for spatial fragments. However, so far as I can
tell, no browser has ever implemented this part of the spec for video. \*\*

@docs timeFragment, idFragment, trackFragment


# Tracks (Subtitles, captions, metadata, etc)

@docs track


# Media Capture

@docs mediaCapture

-}

import Html exposing (Attribute, Html, audio, node)
import Html.Attributes exposing (controls, src, type_)


{-| Represents different audio and video formats. Some also include codec information.
-}
type FileType
    = MP3
    | AAC
    | MP4
    | HLS
    | Ogg
    | OggAudio
    | OggVideo
    | OggOpus
    | WebMAudio
    | WebMVideo
    | Wave
    | FLAC
    | Custom String



{- Spatial fragments don't appear to ever have been implemented by any browser, commenting them out -}


type Fragment
    = Temporal ( Float, Float )
    | Id String
    | Track String



--| SpatialWithPixels SpatialPixels
--| SpatialWithPercent SpatialPercent
{-
   type alias SpatialPixels =
       { x : Int, y : Int, width : Int, height : Int }


   type alias SpatialPercent =
       { x : Float, y : Float, width : Float, height : Float }
-}


type alias GatheredAttributes =
    { url : String
    , mime : Maybe String
    , audioCodec : Maybe String
    , videoCodec : Maybe String
    , fragments : List Fragment
    }


{-| A better source function. This function lets you generate a media source. It requires a Url and
a list of Source msgs, which represent either Mime types (such as WebM or MP4), codecs (such as vp9 or hevc),
or media fragments(such as #t=(0,10).

I really want to encourage the use of Mime types and codecs, as they let us to offer multiple sources with different
levels of encoding efficiency, while allowing a fallback for compatibility.

For instance, you might want to offer an h265 MP4 (most efficient) for Edge and recent safari users, a VP9
WebM (more efficient than h264) for Firefox and Chrome users, a high-variant h264 MP4 (very compatible) for
older browsers, and a baseline-variant h264 MP4 (extremely compatible) for older mobile browsers. We can achieve
that, like so:

```video
        [   source "media-h265.mp4" [fileType MP4, videoCodec "hevc"]
        ,   source "media-vp9.webm" [fileType WebMVideo, videoCodec "vp9"]
        ,   source "media-high.mp4" [fileType MP4, videoCodec "avc1.64001E"]
        ,   source "media-baseline.mp4" [fileType MP4, videoCodec "avc1.42E01E"]
        ]
```

-}
source : String -> List (Source msg) -> Html msg
source url attrs =
    let
        initAttributes =
            { url = url
            , mime = Nothing
            , audioCodec = Nothing
            , videoCodec = Nothing
            , fragments = []
            }

        gathered =
            List.foldl gatherAttributes initAttributes attrs

        codecs =
            case ( gathered.audioCodec, gathered.videoCodec ) of
                ( Nothing, Nothing ) ->
                    Nothing

                ( Just _, Nothing ) ->
                    gathered.audioCodec

                ( Nothing, Just _ ) ->
                    gathered.videoCodec

                ( Just ac, Just vc ) ->
                    Just <| vc ++ "," ++ ac

        mime =
            case gathered.mime of
                Just m ->
                    case codecs of
                        Just c ->
                            [ type_ <| m ++ "; codecs=\"" ++ c ++ "\"" ]

                        Nothing ->
                            [ type_ m ]

                Nothing ->
                    []

        fragment =
            if List.isEmpty gathered.fragments then
                ""

            else
                "#" ++ fragmentsToUriString gathered.fragments

        sourceAttributes =
            mime
    in
    Html.source ([ src <| url ++ fragment ] ++ sourceAttributes) []


{-| -}
playableType : List (Source msg) -> String
playableType attrs =
    let
        initAttributes =
            { url = ""
            , mime = Nothing
            , audioCodec = Nothing
            , videoCodec = Nothing
            , fragments = []
            }

        gathered =
            List.foldl gatherAttributes initAttributes attrs

        codecs =
            case ( gathered.audioCodec, gathered.videoCodec ) of
                ( Nothing, Nothing ) ->
                    Nothing

                ( Just _, Nothing ) ->
                    gathered.audioCodec

                ( Nothing, Just _ ) ->
                    gathered.videoCodec

                ( Just ac, Just vc ) ->
                    Just <| vc ++ "," ++ ac
    in
    case gathered.mime of
        Just m ->
            case codecs of
                Just c ->
                    m ++ "; codecs=\"" ++ c ++ "\""

                Nothing ->
                    m

        Nothing ->
            ""


gatherAttributes : Source msg -> GatheredAttributes -> GatheredAttributes
gatherAttributes attr gathered =
    case attr of
        Mime mime ->
            { gathered | mime = Just mime }

        AudioCodec codec ->
            { gathered | audioCodec = Just codec }

        VideoCodec codec ->
            { gathered | videoCodec = Just codec }

        MimeWithAudioCodec { mime, codec } ->
            { gathered | mime = Just mime, audioCodec = Just codec }

        MimeWithVideoCodec { mime, codec } ->
            { gathered | mime = Just mime, videoCodec = Just codec }

        MimeWithCodecs { mime, mimeAudioCodec, mimeVideoCodec } ->
            { gathered | mime = Just mime, audioCodec = Just mimeAudioCodec, videoCodec = Just mimeVideoCodec }

        Frag newFragment ->
            { gathered | fragments = gathered.fragments ++ [ newFragment ] }


fragmentsToUriString : List Fragment -> String
fragmentsToUriString fragments =
    case fragments of
        [] ->
            ""

        [ fragment ] ->
            fragmentToString fragment

        fragment :: more ->
            fragmentToString fragment ++ "&" ++ fragmentsToUriString more


fragmentToString : Fragment -> String
fragmentToString fragment =
    case fragment of
        Temporal ( start, end ) ->
            "t=" ++ String.fromFloat start ++ "," ++ String.fromFloat end

        Id name ->
            "id=" ++ name

        Track name ->
            "track=" ++ name



{- Not implemented by any browser ever, commenting out:
   SpatialWithPixels pixels ->
       "xywh=pixel:"
           ++ toString pixels.x
           ++ ","
           ++ toString pixels.y
           ++ ","
           ++ toString pixels.width
           ++ ","
           ++ toString pixels.height

   SpatialWithPercent percent ->
       "xywh=percent:"
           ++ toString percent.x
           ++ ","
           ++ toString percent.y
           ++ ","
           ++ toString percent.width
           ++ ","
           ++ toString percent.height
-}


type Source msg
    = Mime String
    | AudioCodec String
    | VideoCodec String
    | MimeWithAudioCodec { mime : String, codec : String }
    | MimeWithVideoCodec { mime : String, codec : String }
    | MimeWithCodecs { mime : String, mimeAudioCodec : String, mimeVideoCodec : String }
    | Frag Fragment


{-| Used to set a type (and possibly a codec) with pre-built settings, using the union type FileType.

`source [fileType OggOpus]` becomes `<source type="audio/ogg; codecs="opus"">`

-}
fileType : FileType -> Source msg
fileType mime =
    case mime of
        MP3 ->
            Mime "audio/mpeg"

        AAC ->
            Mime "audio/aac"

        MP4 ->
            Mime "video/mp4"

        HLS ->
            Mime "application/x-mpegURL"

        Ogg ->
            Mime "application/ogg"

        OggAudio ->
            Mime "audio/ogg"

        OggVideo ->
            Mime "video/ogg"

        OggOpus ->
            MimeWithAudioCodec { mime = "audio/ogg", codec = "opus" }

        WebMAudio ->
            Mime "audio/WebM"

        WebMVideo ->
            Mime "video/WebM"

        Wave ->
            Mime "audio/wav"

        FLAC ->
            Mime "audio/flac"

        _ ->
            Mime ""


{-| For adding a custom audio codec:

`source "media.webm" [ fileType WebMAudio, audioCodec "opus"]` becomes `<source type="audio/WebM; codecs="opus"">`

-}
audioCodec : String -> Source msg
audioCodec codec =
    AudioCodec codec


{-| {-| For adding a custom audio codec:

`source "media.webm" [ fileType WebMVideo, videoCodec "vp9"]` becomes `<source type="video/WebM; codecs="vp9"">`

-}

-}
videoCodec : String -> Source msg
videoCodec codec =
    VideoCodec codec


{-| Allows you to specify a start and end time for a media file:

`source "media.mp4" [fileType MP4, timeFragment (2,15)]` will specify the video media.mp4
from 2 seconds in until 15 seconds in.

\*\* Note: This is the most cross-browser compatible part of the Media Fragments I've seen. I haven't tested
Windows at all yet, but this seems to work on the latest versions of Safari, Chrome, and Firefox.

Also note, this doesn't appear to work on any of the browsers with the `loop` attribute. It will merely
play as normal, with the time-fragment, but without looping \*\*

-}
timeFragment : ( Float, Float ) -> Source msg
timeFragment times =
    Frag <| Temporal times


{-| Allows you to specify a source where you jump to a specific time based on an id string
embedded in the source.

`source "media.mp4" [fileType MP4, idFragment "#Chapter1"]` will start playing at #Chapter1.

\*\* Note: Honestly, I produce mp4's all day, every day for a living, and I've never seen this used on the web.
I've only seen it implemented differently.

In theory, MP4 is a subset of the MOV container format, and I believe WebM is a subset of MKV, both of which
support chapters, but I've never seen either with ids.

I'm going to do some work with FFMPEG, Apple Compressor, Adobe Media Encoder and MP4Box to find out, but until then,
this is built the HTML5 spec, but untested. \*\*

-}
idFragment : String -> Source msg
idFragment name =
    Frag <| Id name


{-| Allows you to specify a specific track in a multi-track file.

`source "media.mp4" [fileType MP4, trackFragment "spanish-audio"]` becomes
`<source src="media.mp4" type="video/mp4#track=spanish-audio>"`

\*\* Note: Multi-track files are a rarity on the internet. Players like YouTube tend to implement
this functionality in a different way. That said, I definitely can create multi-track files and test
this cross-browser, and will do so ASAP. \*\*

-}
trackFragment : String -> Source msg
trackFragment name =
    Frag <| Track name



{- Commenting this out as I don't believe it's ever been implemented by any browser:

   spatialFragment : { x : Int, y : Int, width : Int, height : Int } -> Source msg
   spatialFragment { x, y, width, height } =
       Frag <| SpatialWithPixels { x = x, y = y, width = width, height = height }


   spatialFragmentWithPercent : { x : Float, y : Float, width : Float, height : Float } -> Source msg
   spatialFragmentWithPercent { x, y, width, height } =
       Frag <| SpatialWithPercent { x = x, y = y, width = width, height = height }
-}


{-| -}
mediaCapture : List (Attribute msg) -> List (Html msg) -> Html msg
mediaCapture attrs childs =
    node "media-capture" attrs childs


{-| -}
track : List (Attribute msg) -> List (Html msg) -> Html msg
track attrs childs =
    Html.track attrs childs
