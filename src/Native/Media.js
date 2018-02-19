
var _danabrams$elm_media$Native_Media = function() {

    var fakeNode = {
        getElementById: function() { return null; },
        addEventListener: function() {},
        removeEventListener: function() {}
    };
    
    var doc = (typeof document !== 'undefined') ? document : fakeNode;

    function withMediaNode(id, doStuff)
    {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
        {
            var media = doc.getElementById(id);
            if (media === null)
            {
                console.log("Not Found" + id);
                callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'NotFound', _0: id }));
                return;
            } else if (!(media instanceof HTMLMediaElement))
            {
                console.log("Not a MediaElement" + id + media.tagName);
                callback(_elm_lang$core$Native_Scheduler.fail({ctor: 'NotMediaElement', _0: id, _1: media.tagName}));
                return;
            }
            callback(_elm_lang$core$Native_Scheduler.succeed(doStuff(media)));
        });
    }

    function getStateWithId(id){
        withMediaNode(id, function(media){
            media.pause();
            return _elm_lang$core$Native_Utils.Tuple0;
        });
    }

    function pause(id){
        withMediaNode(id, function(media){
            media.pause();
        });
        succeed(_elm_lang$core$Native_Utils.Tuple0);
        return;
    }

    function play(id){
        withMediaNode(id, function(media){
            var playPromise = media.play();
            if (playPromise !== undefined) {
                playPromise.then(function(){
                    callback(succeed(_elm_lang$core$Native_Utils.Tuple0));
                    return
                }).catch(function(error){
                    console.log("PlayPromiseFailure")
                    callback(_elm_lang$core$Native_Scheduler.fail({ctor: "PlayPromiseFailure", _0: error}));
                    return;
                });
            }
            return _elm_lang$core$Native_Utils.Tuple0;
        });
    }


    function seek(id, time){
        var media = getMediaNode(id);            
        media.currentTime = time;
        return _elm_lang$core$Native_Utils.Tuple0;
    }

    function fastSeek(id, time){
        var media = getMediaNode(id);
        media.fastSeek(time);
        return _elm_lang$core$Native_Utils.Tuple0;
    }

    function load(id){
        var media = getMediaNode(id);
        media.load();
        return _elm_lang$core$Native_Utils.Tuple0;
    }

    function canPlayType(id, type){
        var media = getMediaNode(id);
        switch (media.canPlayType(type)){
            case "probably":
                return { ctor: "Probably" };
            case "maybe":
                return { ctor: "Maybe" };
            case "":
                return { ctor: "No" };
        } 
    }

    function nothing(){
        return { ctor: 'Nothing' };
    }

    function just(value){
        return { ctor: 'Just', _0: value };
    }   

    function decodeTimeRanges(ranges){
        if (ranges == null) {
            return _elm_lang$core$Result$Err({ctor: 'NotTimeRanges', _0: "Null"});

        } else if ((!(ranges instanceof TimeRanges)) ) {
            return _elm_lang$core$Result$Err({ctor: 'NotTimeRanges', _0: ranges.typeof});
        } else {
            var list = _elm_lang$core$Native_List.Nil;
            for (var i = ranges.length - 1; i >= 0; i--)
            {
                var timeRange = { start: ranges.start(i), end: ranges.end(i) };
                list = _elm_lang$core$Native_List.Cons(timeRange, list);
            }
            return list;
        }
    }
    
    return {
        getStateWithId: getStateWithId,
        pause: pause,
        play: play,
        load: load,
        seek: F2(seek),
        fastSeek: F2(fastSeek),
        canPlayType: F2(canPlayType),
        decodeTimeRanges : decodeTimeRanges
    };
}();