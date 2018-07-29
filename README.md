# Elm-Media

A New, port-based wrapper on the HTML Media API
## Getting Started

This project requires a port (and some other javascript). You can set it up by importing the "Port/mediaPort.js" file into your html file, and doing something like the following:

`   
    <script>
        var elmApp = Elm.Main.fullscreen();

        addMediaPort(elmApp.ports.playbackControl);
        modifyTimeRanges();

    </script>
`

