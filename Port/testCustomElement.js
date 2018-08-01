class HTMLTextTrackElement extends HTMLElement {
    constructor() {
        super();
        if (this.hasAttribute("mode")) {
            let modeAttr = this.getAttribute("mode");
            if ((modeAttr == "showing") || (modeAttr == "hidden")) {
                _mode = mode;
            }
        } else {
            _mode = "disabled";
        }

        let _track = _parentTrack();
        if (_track != null) {
            _track.mode = _mode;
        }
    }

    get mode() {
        let track = parentTrack();

        if (track != null) {
            _mode = track.mode;
            this.setAttribute("mode", _mode)
            return _mode;
        } else {
            return "";

        }
    }

    set mode(mode) {
        let track = _parentTrack();

        if (track != null) {
            track.mode = mode;
            _mode = mode;
            this.setAttribute('mode', _mode);
        }
        return;
    }

    _parentTrack() {
        if ((_track = null) || (_track = undefined)) {
            var par = this.parentNode;
            if ((par == null) || (par == undefined)) {
                console.log("null parentNode");
                setTimeout(function () { this.mode = m; }.bind(this), 16);
            } else if ((par.tagName.toLowerCase() == "audio") || (par.tagName.toLowerCase() == "video")) {
                var track;
                for (i = 0; i < par.textTracks.length; i++) {
                    track = par.textTracks[i];
                    if (track.id == this.id) {
                        if (track.kind == this.kind) {
                            if (track.label == this.label) {
                                return track;
                            }
                        }
                    }
                }
            }
            return null;
        } else {
            return _track;
        }
    }


}

customElements.define('text-track', HTMLTextTrackElement);
