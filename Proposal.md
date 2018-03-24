# Elm-Media: a Web Platform Proposal, Prototype Implementation, and Discussion Jumping Off Point

## Introduction

About 6 months ago, I felt confident enough in my Elm knowledge to undertake the first steps of a long term project, a video training platform.

The problem I quickly ran into is that the Media API has not yet been wrapped in Elm. This was something of a blocker.

For a living, I produce videos and live streams, mostly for large companies with household names. My programming work involves both creating tools for creating these video programs (live streaming in particular is somewhat ad-hoc and DIY still, which is the really fun part of my job) and creating platforms for consuming this video.

I saw an opportunity: both for me to learn more about Elm and API design, and also to contribute something to the community. At first, I thought I might just create a first-class video player in Elm, but as I explored, it quickly became clear that much of the underlying infrastructure wasn't yet exposed, which created a major blocker.

I started by very quickly creating a basic API protoype using ports...and using it to create a cool Christmas present for my dad!

Richard Feldman very helpfully suggested I mock up the API by writing the function names with type signatures, but make everythign Debug.crash, and also to write the documentation, and then create the documentation.json, and send it to him and others I trusted to take a look, then send it to Elm-dev google group (this was just before the transition to discourse).

I did this quickly, but then noticed some problems. I decided I needed to prototype a few things, and it quickly got out of control. My justification for this is that even if this whole implementation and design gets thrown out, this was an EXCELLENT learning exercise for me, and I think my design of the API is much better for it. Certainly my knowledge of Elm is better for it, and even if it's all tossed and problematic, I don't regret it for a second.

**That said, for the next API I design, I definitely will do it the way Richard suggested first. I know much more than I did six months ago.**

## Defining the Media API

For this initial phase of API design, I just want to focus on the core fucntions of the Media API: managing the state of an HTML5 MediaElement (a player represented by an <audio> or <video> tag). This design has to do with the pieces necessary to build an audio or video player, like Video.js or JW Player, not doing interactive audio or video processing with related API's like Web Audio API or live streaming with Media Source Elements. / I do intend to work on those once this portion is complete, and all of them require this foundation. /

**GOAL:** An elm developer should be able to use this library to write a cross-browser compatible audio or video player, with subtitle support (for accessibility).

## Use Cases

Honestly, for almost all media playback, a more sophisticated player than the built in audio and video tag. There is a lot of inconsistency among browsers on what the player controls look like when rendered, what functions controls they expose, what download policies they operate under. These players have different autoplay policies, which can cause broken pages. It's just a mess. A custom player can overcome these with a better abstraction.

The only case that the built in browser audio and video players should be used in when you're only targeting a single browser, with known capabilities, as Apple used to do with their [live stream events](https://www.apple.com/apple-events/september-2017/). Otherwise, you should be using a custom player (And to my point, Apple now does. This link has never worked on Chrome before).

Even worse, different browsers support completely different media file formats and codecs. The formats they agree on are s lowest-common demoninator, often the least efficient, and relying solely on them leads to a worse end user experience. Ideally, a developer would be able to specify a great sounding, 128kbps AAC file for Safari, a great sounding 128kbps Ogg for Firefox, and a less great sounding, but more compatible 128kbps MP3 for browsers that don't support AAC or Ogg. The situation is even more drastic on the video side of things, where you might be able to save several gigabytes by serving an H.265 MP4 to Safari or Edge over the very compatible H.264 MP4. You might also want to serve a somewhat more efficient, but not as efficient WebM to Firefox and Chrome, and an H.264 MP4 to browsers that don't support either (mostly older browsers).

Having the basic parts of the Media API wrapped will also allow us to write media players that expose more advanced functionality, such as playlist functionality (letting another source start after one ends).

The Media API is also a crucial foundation for other APIs, such as Web Audio, which can be used for writing things like synthesizers and drum machines, but also for things like a sound effects library for game engines.

**But the biggest benefit, I think, is the ability to write reusable media players (as reusable views) that abstract away a lot of the boilerplate wiring that go into making a media player.** I imagine that a company like NoRedInk, for instance, could use a video player based on this library to add video tooltips to their application, and make it even easier to learn.

I'm sure there are other use-cases, and I'd love to hear them, and lend my expertise in any way I can.

## Resources for understanding the Media API

* MDN's [documentation](https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement) is excellent. Only a few things are missing, mostly from AudioTracks, VideoTracks, TextTracks.

* [this tutorial](https://developer.mozilla.org/en-US/Apps/Fundamentals/Audio_and_video_delivery/cross_browser_video_player) from Mozilla is also great.


## Design Challenges

The primary challenge is that an Html5 MediaElement is a component that to a great degree, manages its own state. Once it is given a source, it automatically makes the necessary HTTP requests and manages downloading the media file. As it loads, the duration of the mediaPlayer may change. Once it begins playing, the currentTime will play. Eventually the media will end, and may change from the playing state to the paused state.

Some attributes should be managed by the user as declaritive attributes on the audio or video function: volume, muted, playbackRate, loop, controls, autoplay. Some of these are already included in Html.Attributes. Some are not and should be included here. Some have weird quirks that need to be understood.

But for many of the attributes of a media player, the browser can update them outside the actions of the developer, and this is unavoidable (I actually explored writing a custom player in both Rust/WebAssembly and WebComponents that could be advanced frame by frame...it's possible, but can't take advantage of GPU or CPU acceleration, and therefore can only be used for VHS-quality video).

The way this is handled in JavaScript is to use Document.getElementById() to find the given MediaElement and simply get the current value from it as an object: "var x = player.currentTime;".

Obviously this object-oriented approach is a non-starter in Elm.

## Proposed Solution

Luckily, a MediaElement is a standard JavaScript object, and can be passed into Elm using Json. The heart of my proposal and my current implementation is just a Json decoder, using a Pipeline decoder, to decode this value into an Elm record.

I want to provide the user two opportunities to decode the record:

1) **Get the state right now** By using the Media.State.now id task, which under the hood will look for a tag with that id, make sure it's an audio or video element, and return a result with either it or an Error to the decoder. The main use-case for this, so far as I can see, is for initialization (instead of using a default state, essentially blank)

2) **Using the Media API events** By using the handy Html5 Media Events, mostly listed [here](https://developer.mozilla.org/en-US/docs/Web/Guide/Events/Media_events). We can create a custom event in Elm using Html.Events.on, decode the event target (which is the MediaElement), and grab it's state as a Json Value, then send it to the State decoder.

**QUESTION: Do you think I should be separating out just parts of the state relevant to the called event...That is, only return duration and seekable when the "durationchange" event is triggered or currentTime and played on a "timeupdate"? I'd like to discuss this choice in particular.**

**Note, originally had a third way, but have determined it unnecessary**

## State

The Record in question is the Media.State type. It looks like this:

```type alias State =
    { id : Id
    , mediaType : MediaType
    , playback : Playback
    , source : String
    , currentTime : Float
    , duration : Float
    , readyState : ReadyState
    , network: NetworkState  
    , buffered : List TimeRange
    , seekable : List TimeRange
    , played : List TimeRange
    , videoSize : { width : Int, height : Int }
    }```

I'll go through it line by line:

1) id - Id is a just a type alias to a String. This is the unique id of the MediaElement. Unique Ids are really important in this proposal, so I'm including it here.

2) mediaType - a MediaType is an ADT representing the tagName of the mediaElement, either Audio or Video. Audio and Video are mostly the handled the same, but you might want to draw the player differently.

3) playback - Playback is another ADT, representing the current playback state of the player: 

` type Playback
    = Paused
    | Playing
    | Loading
    | Buffering
    | Ended
    | Problem PlaybackError `

PlaybackError is another ADT representing the errors a player might generate: 

`type MediaError
    = Aborted String
    | Network String
    | Decode String
    | Unsupported String`

4) currentTime - represents the time of current playback. Where the playhead is, basically. It's a float, representing seconds (true SMPTE timecode would have killed the browsers? Yeesh).

5) duration - Another float, representing the lennth of the loaded media once loaded. Before loading the media's metadata, it will return Nan, and if it's a live stream, it will return infinity (seekable will have to be used to determine duration in the case of a live stream).

6) readyState - an ADT representing how much data the player has loaded of the source media. (This is represented by an int representing one of five states in JavaScript...making me think JavaScript is really in need of some kind of better Enum). Here's what it looks like in my API proposal. They correspond exactly to the web API, but Elm's ADT make it's better:

'type ReadyState
    = HaveNothing
    | HaveMetadata
    | HaveCurrentData
    | HaveFutureData
    | HaveEnoughData'

7) networkState - similar to the situation with readyState, this exposed the current network of the player, using an ADT, which looks like this:

'type NetworkState
    = Empty
    | Idle
    | DataLoading
    | NoSource`

8) seekable - is a List TimeRange. TimeRange is a simple record, {state: Float, end: Float}, representing the start and end points of a portion of a media file. Seekable is a list, because multiple portions might be seekable, or unseekable (such as commercials). In my experience, seekable usually returns a list with just one member, and duration usually works better. But I want to include it because it's crucial in live streaming, where duration doesn't work.

9) buffered and played - also List TimeRange. buffered represents the parts of the media that have been loaded by the player, and played represents the parts that have been watched. It may be a bit tricky to understand why this isn't just a float of how far into the media the player has buffered, and how far has been played. But what if you open a long video, watch thirty seconds, then jump ahead to 40 minutes in and watch for a minute. Now you've played 0-30, 2400-2460. And most browser players are smart enough to buffer the portions of the media you're about to play first (if the media container format supports it).

10) videoSize { width: 0, height: 0} - this represents the pixel size of the media, not the displayed size. Both fields default to 0 on audio files.

### Problems with Decoding Media.State.State

With the exception of one type, all of this can be done with a standard Json Decode Pipeline. That's awesome, and I really want to thank Richard Feldman for helping me understand these pipelines better, as well as Brian Hicks excellent book, which would be really well thumb-marked if it weren't a PDF on my desktop.

**However,** TimeRange gives us an issue. It's a crucial field for more advanced players and live streaming, but in javascript, it returns an object looks like this: 

`{ length: index, start(index), end(index)}`

Ugh. It doesn't have a collection or array syntax either, you can't do start[1] or buffered[1].start. This was a real blocker for me, and I had to write a native decoder in Javascript to do so. *I also think this is tough to do through ports, as by the time the Json value is returned to the elm runtime, the information may well be out of date, and being up to date matters for the use case of this info).

This right here might be a fairly niche case, but it could be a blocker for which ports is not a viable option. I'm not sure. 

## Playback Control

Decoding our state from media events lets us manage side effects coming from the browser's player, but it doesn't allow us to initiate those side effects. In other words, it doesn't allow us to control playback.

I tried to do this in a declarative way, at first. One model for controlling a player is to have an on/off switch, or play/pause, if you will. On a record-player, for instace, there may be a switch that starts and stops the motor, or on a reel to reel tape deck, or a motion picture projector.

However, it became apparent to me after a lot of failed attempts that this doesn't accurately represent the real playback controls of media players. Turning playback on can fail, and it can also change state on its own, even if you've declaritively instructed it to do so, such as when the file comes to the end (or, in the real world, the record needle reaches the inner grooves of the record).

Only a live source, like a radio or live stream, can realistically be designed this way.

So I've designed a few tasks, that return a Result Error (), for controlling playback:

1) pause id - pauses the playback. Give it the id of the player you want to pause; under the hood, it gets that element, checks that it's not null, checks that it's a MediaElement, then uses the pause() method.

2) play id - same as above, but attempts to begin playback. Worth noting, that on browsers that support promises, we can also check that playback successfully started, becuase the play() method returns a promise after it does. And my implementation does exactly that.

3) load id - reloads the player once a new source is given. This lets you play a second file, maybe a commercial, or a second file in a playlist.

4) seek id time - changes the currentTime of the player, and thus the playhead. 

5) fastSeek id time - same as seek but uses the fastSeek() method, which looks for keyframes in the media file, and gives up frame accuracy for performance.

6) canPlayType id type - lets you check that the player is capable of playing a given mimetype (or mimetype & codec). This lets you do elegant failover, serve multiple container formats and codecs, and skip media files that aren't compatible rather than generating an error.

## Miscellaneous

My reference implementation also includes a few helper functions that don't really need to be addressed here. They're just nicities, such as creating a nice property function for muted and playbackRate, or making a human-readible string out of duration. 


## Higher-Level Abstractions

I've gone back and forth about whether I should abstract away from the browser API more. But I keep coming back to the fact that the higher-level abstraction for the media API is called a media player.

The goal of this library is to wrap the API precisely so that I, and others, can create a variety of audio and video players (my guess is there'll be one canonical video player, as video players are pretty much the same, they just have different features...but audio players are a great place to utilize creative layout and design! Honestly, it's been fun writing a variety of audio players for this project.)

## Next Steps

* Feedback - I'd like to get feedback on this design. Is the design totally bunk? Then how can we design around these problems. Is the design solid but certain aspects need improvement? Great. I really want your thoughts, criticisms, and ideas.

* Implementation - Once there's general agreement that the design is solid, I'll implement it. If my current protoype is acceptable, great. If it needs to be redone from scratch, so be it. I'd also love feedback on these details, when the time comes: naming things, organizing things, necessary helper functions, etc.

* Refinement - My end goal is for this to be white-listed some day, so I want to aggressively refine to get it up to Elm-lang's high standards.

* Related API's - once we're in agreement that this package is fully baked, and he we have a good player or two, I'd like to start this process over to wrap some related API's. For my purposed, MediaSource Elements is the most pressing, although it involves some big challenges (I do have some ideas though). Web Audio is another that I think would be helpful to any number of people, and to me for some of the long term stuff I want to do. I'll definitely do one of these before I write much code, though. Lesson learned.

## Lingering Questions

###Subtitles

I really want to get subtitles included as early as possible in this process. Accessibility should be a priority to us all.

There's been a major change in the format of subtitling done in browsers over the past half-decade, and though they've mostly settled on WebVTT, I need to do some work still on checking the cross-browser compatibility issues.

Alternatively, this is probably and area where we could implement a parser in pure Elm, and manage subtitles ourselves. This lets us support more than one format and have excellent cross-broswer compatibility, but it doesn't let us use subtitles on media containers that have embedded VTT.

**I'd really love to hear thoughts on this issue**

## Thanks

Thanks for reading this monster document. I'm sorry for writing such a long proposal, I didn't have to time to write a short one. I appreciate that you got to this place. ~~Since you did make it to the end, here's the secret code: 04 80 FE 57. Use it responsibly. The first one to send me the above code privately gets a free slice of pizza, or cappucino, or beer from me when I next see them in person.~~ Sorry, we already had a winner!