let MediaApp =
{
    portHandler: function (msg) {
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




    }
    , Modify:
    {
        timeRanges: function () {
            if (!(TimeRanges.prototype.asArray)) {
                Object.defineProperty(TimeRanges.prototype, "asArray", { get: function () { var arr = []; for (i = 0; i < this.length; i++) { arr.push({ start: this.start(i), end: this.end(i) }); }; return arr; } });
            }
            return;
        },
        tracks: function () {
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
            } else {
                return;
            }
        }

    }
    , Elements: {
        defineMediaCapture: function () {
            class MediaCapture extends HTMLElement {
                constructor() {
                    let self = super();
                    this._constraints = { audio: true, video: true };
                    return self;

                }

                connectedCallback() {
                    let video = this.parentNode;
                    let cons = this._constraints;
                    if (navigator.mediaDevices === undefined) {
                        navigator.mediaDevices = {};
                    }

                    if (navigator.mediaDevices.getUserMedia === undefined) {
                        navigator.mediaDevices.getUserMedia = function (constraints) {

                            // First get ahold of the legacy getUserMedia, if present
                            var getUserMedia = navigator.webkitGetUserMedia || navigator.mozGetUserMedia;

                            // Some browsers just don't implement it - return a rejected promise with an error
                            // to keep a consistent interface
                            if (!getUserMedia) {
                                return Promise.reject(new Error('getUserMedia is not implemented in this browser'));
                            }

                            // Otherwise, wrap the call to the old navigator.getUserMedia with a Promise
                            return new Promise(function (resolve, reject) {
                                getUserMedia.call(navigator, constraints, resolve, reject);
                            });
                        }
                    }
                    navigator.mediaDevices.getUserMedia({ audio: true, video: true })
                        .then(function (stream) {
                            // Older browsers may not have srcObject
                            if ("srcObject" in video) {
                                video.srcObject = stream;
                            } else {
                                // Avoid using this in new browsers, as it is going away.
                                video.src = window.URL.createObjectURL(stream);
                            }
                        })
                        .catch(function (err) {
                            console.log(err.name + ": " + err.message);
                        });


                }
            }



            customElements.define("media-capture", MediaCapture);
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