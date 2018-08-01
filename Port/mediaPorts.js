let MediaApp =
{
    Ports:
    {
        setupElmToJSPort: function (sendPort) {

            if (sendPort.subscribe !== undefined) {
                sendPort.subscribe(function (msg) {
                    var media = null;
                    switch (msg.tag) {
                        case "Play":
                            media = MediaApp.Helpers.getMediaNode(msg.id);
                            if (media === null) {
                                break;
                            } else {
                                let playPromise = media.play();
                                if (playPromise !== undefined) {
                                    playPromise.then(function () {
                                    }).catch(function (err) {
                                        console.log("media element with id #" + msg.data.id + " failed to play because of " + err);
                                    });
                                } else {
                                    console.log("HTMLMediaElement.play() does not return a promise in this browser.");
                                }
                                break;
                            }
                        case "Pause":
                            media = MediaApp.Helpers.getMediaNode(msg.id);
                            if (media === null) {
                                break;
                            } else {
                                media.pause();
                                break;
                            }
                        case "Seek":
                            media = MediaApp.Helpers.getMediaNode(msg.id);
                            if (media === null) {
                                break;
                            } else {
                                media.currentTime = msg.data;
                                break;
                            }
                        case "ChangeTextTrackMode":
                            media = MediaApp.Helpers.getMediaNode(msg.id);
                            if (media === null) {
                                break;
                            } else if (media.textTracks[msg.data.trackNumber] !== undefined) {
                                media.textTracks[msg.data.trackNumber].mode = msg.data.mode;
                                break;
                            }
                            break;
                        case "Load":
                            media = MediaApp.Helpers.getMediaNode(msg.id);
                            if (media === null) {
                                break;
                            } else {
                                media.load();
                                break;
                            }
                        default:
                            break;
                    }

                });
            }
        }
    }
    , Modify:
    {
        TimeRanges: function () {
            if (!(TimeRanges.prototype.asArray)) {
                Object.defineProperty(TimeRanges.prototype, "asArray", { get: function () { var arr = []; for (i = 0; i < this.length; i++) { arr.push({ start: this.start(i), end: this.end(i) }); }; return arr; } });
            }
            return;
        },
        /*TextTracks: function () {
            if (!(HTMLTrackElement.prototype.textTrackModes)) {
                Object.defineProperty(HTMLMediaElement.prototype, "textTrackModes",
                    {
                        set: function (modes) {
                            if (modes.length == this.textTracks.length) {
                                for (i = 0; i < modes.length; i++) {
                                    this.textTracks[i].mode = modes[i];
                                }
                            }
                            return;
                        },
                        get: function () {
                            var modes = [];
                            for (i = 0; i < this.textTracks.length; i++) {
                                modes.push(this.textTracks[i].mode);
                            }
                            return modes;
                        }
                    });
            }
        },
        Track: function () {
            if (!(HTMLTrackElement.prototype.mode)) {
                Object.defineProperty(HTMLTrackElement.prototype, "mode",
                    {
                        set: function (m) {
                            _mode = m;
                            var par = this.parentNode;
                            if ((par == null) || (par == undefined)) {
                                console.log("null parentNode");
                                setTimeout(function () { this.mode = m; }.bind(this), 16);
                            } else if ((par.tagName.toLowerCase() == "audio") || (par.tagName.toLowerCase() == "video")) {
                                var track;
                                for (i = 0; i < par.textTracks.length; i++) {
                                    track = par.textTracks[i];
                                    if (track.id == this.id) {
                                        track.mode = m;

                                        return;
                                    }
                                }
                            }
                        }
                        ,
                        get: function () {
                            return _m;
                        }
                    });
            }
        }*/
        Track: function () {
            if (!(HTMLTrackElement.prototype.mode)) {
                Object.defineProperty(HTMLTrackElement.prototype, "mode",
                    {
                        set: function (m) {
                            console.log(this.track);
                            this.track.mode = m;
                            return;
                        },
                        get: function () {
                            console.log(this.track);
                            return this.track.mode;
                        }
                    });
            }
            if (!(HTMLTrackElement.prototype.oncue))
        }

    }
    , Setup: {
        All: function (controlPort) {
            MediaApp.Modify.TimeRanges();
            MediaApp.Modify.TextTracks();
            addMediaPort(controlPort);
        }
    }
    , Helpers: {
        getMediaNode: function (id) {
            let media = document.getElementById(id);
            if (media === null) {
                console.log("node with id " + id + " not found");
                return null;
            } else if (!(media instanceof HTMLMediaElement)) {
                console.log("node with id " + id + " is not an HTMLMediaElement");
                return null;
            } else {
                return media;
            }
        }
    }
};


