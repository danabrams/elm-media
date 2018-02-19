
var _danabrams$elm_media$Native_Media = function(){




    var rAF = typeof requestAnimationFrame !== 'undefined' ? requestAnimationFrame : function(callback) { callback(); };
    
    function fail(value){
        return _elm_lang$core$Native_Scheduler.fail(value);
    }

    function succeed(value){
        return _elm_lang$core$Native_Scheduler.succeed(value);
    }


    function withMediaNode(id, doStuff)
    {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback)
        {
            rAF(function()
            {
                var media = document.getElementById(id);
                if (media === null)
                {
                    callback(fail({ ctor: 'NotFound', _0: id }));
                    console.log("Not Found" + id);
                    return;
                } else if (!(media instanceof HTMLMediaElement))
                {
                    callback(fail({ctor: 'NotMediaElement', _0: id, _1: media.tagName}));
                    console.log("Not a MediaElement" + id + media.tagName);
                    return;
                }
                callback(doStuff(media));
            });
        });
    }


    function getStateWithId(id){
        return withMediaNode(id, function(media) {
            return succeed(media);
        });
    }

    function pause(id){
        return withMediaNode(id, function(media) {
            media.pause();
            return succeed(_elm_lang$core$Native_Utils.Tuple0);
        });
    }

    function play(id){
        return withMediaNode(id, function(media) {
            var playPromise = media.play();
            if (playPromise !== undefined) {
                playPromise.then(function(){
                    return succeed(_elm_lang$core$Native_Utils.Tuple0);
                }).catch(function(error){
                    console.log("PlayPromiseFailure")
                    return fail({ctor: "PlayPromiseFailure", _0: error});
                });
            } else {
            return succeed(_elm_lang$core$Native_Utils.Tuple0);
            }
        });
    }


    function seek(id, time){
        return withMediaNode(id, function(media) {
            media.currentTime = time;
            return succeed(_elm_lang$core$Native_Utils.Tuple0);
        });
    }

    function fastSeek(id, time){
        return withMediaNode(id, function(media) {
            media.fastSeek(time);
            return succeed(_elm_lang$core$Native_Utils.Tuple0);
        });
    }

    function load(id){
        return withMediaNode(id, function(media) {
            media.load();
            return succeed(_elm_lang$core$Native_Utils.Tuple0);
        }); 
    }

    function canPlayType(id, type){
        return withMediaNode(id, function(media) {
            switch (media.canPlayType(type)){
                case "probably":
                   return success({ ctor: "Probably" });
                case "maybe":
                    return success({ ctor: "Maybe" });
                case "":
                    return success({ ctor: "No" });
            }
        }); 
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