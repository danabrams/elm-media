function setupAll(controlPort) {
    modifyTimeRanges();
    addMediaPort(controlPort);
}

function modifyTimeRanges() {
    if (!(TimeRanges.prototype.asArray)) {
        Object.defineProperty(TimeRanges.prototype, "asArray", { get: function () { var arr = []; for (i = 0; i < this.length; i++) { arr.push({ start: this.start(i), end: this.end(i) }); }; return arr; } });
    }
    return;
}

function getMediaNode(id) {
    let media = document.getElementById(id);
    if (media === null) {
        console.log("node with id #" + id + " not found");
        return null;
    } else if (!(media instanceof HTMLMediaElement)) {
        return null;
    } else {
        return media;
    }
}

function addMediaPort(controlPort) {

    if (controlPort.subscribe !== undefined) {
        controlPort.subscribe(function (msg) {
            var media = null;
            switch (msg.tag) {
                case "Play":
                    media = getMediaNode(msg.id);
                    if (media === null) {
                        break;
                    } else {
                        let playPromise = media.play();
                        if (playPromise !== undefined) {
                            playPromise.then(function () {
                            }).catch(function () {
                                console.log("media element with id #" + msg.data.id + " failed to play");
                            });
                        } else {
                            console.log("HTMLMediaElement.play() does not return a promise in this browser.");
                        }
                        break;
                    }
                case "Pause":
                    media = getMediaNode(msg.id);
                    if (media === null) {
                        break;
                    } else {
                        media.pause();
                        break;
                    }
                case "Seek":
                    media = getMediaNode(msg.id);
                    if (media === null) {
                        break;
                    } else {
                        media.currentTime = msg.data;
                        break;
                    }
                case "FastSeek":
                    media = getMediaNode(msg.id);
                    if (media === null) {
                        break;
                    } else {
                        media.fastSeek(msg.data);
                    }
                case "Load":
                    media = getMediaNode(msg.id);
                    if (media === null) {
                        break;
                    } else {
                        media.load();
                    }
                default:
                    break;
            }

        });
    }
}