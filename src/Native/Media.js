var _danabrams$elm_media$Native_Media = function() {

var fakeNode = {
	getElementById: function() { return null; },
};

var doc = (typeof document !== 'undefined') ? document : fakeNode;

function withNode(id, doStuff)
{
	return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
			var node = doc.getElementById(id);
			if (node === null)
			{
				callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'NotFound', _0: id }));
				return;
			} else if (!(node instanceof HTMLMediaElement)){
                callback(_elm_lang$core$Native_Scheduler.fail({ ctor: 'NotMediaElement', _0: id, _1: node.nodeName}));
                return;
            }
			callback(_elm_lang$core$Native_Scheduler.succeed(doStuff(node, callback)));
		});
}


function getMediaById(id){
    return withNode(id, function(media){
        return media;
    });
}

function pause(id)
{   return withNode(id, function(media){
        media.pause();
        return _elm_lang$core$Native_Utils.Tuple0;
    });
}

function play(id, callback)
{
	return withNode(id, function(media) {
        var playPromise = media.play();
        if (playPromise !== undefined){
            playPromise.then(function(){
                return _elm_lang$core$Native_Utils.Tuple0;
            }).catch(function(){
                return _elm_lang$core$Native_Scheduler.fail({ ctor: 'PlayPromiseFailure', _0: id });
                
            });
        }
        return _elm_lang$core$Native_Utils.Tuple0;
	});
}



function load(id)
{
	return withNode(id, function(media) {
		media.load();
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function fastSeek(id, time)
{
    return withNode(id, function(media) {
		media.fastSeek(time);
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function seek(id, time)
{
    return withNode(id, function(media) {
		media.currentTime = time;
		return _elm_lang$core$Native_Utils.Tuple0;
	});
}

function canPlayType(id, type)
{
    return withNode(id, function(media) {
        switch (media.canPlayType(type)) {
            case 'probably':
                return {ctor: "Probably"};
            case 'maybe':
                return {ctor: "Maybe"};
            case '':
                return {ctor: "No"};
        }
    });
}


function decodeTimeRanges(ranges)
{
    if (ranges == null) {
        return _elm_lang$core$Result$Err({ctor: 'NotTimeRanges', _0: "Null"});

    } else if ((!(ranges instanceof TimeRanges)) ) {
        return _elm_lang$core$Result$Err({ctor: 'NotTimeRanges', _0: ranges.typeof});
    }
        
    var list = _elm_lang$core$Native_List.Nil;
    for (var i = ranges.length - 1; i >= 0; i--)
    {
        var timeRange = { start: ranges.start(i), end: ranges.end(i) };
        list = _elm_lang$core$Native_List.Cons(timeRange, list);
    }
    return list;
}

return {
    getMediaById: getMediaById,

	play: play,
    pause: pause,
    load: load,
    seek: F2(seek),
    fastSeek: F2(fastSeek),
    canPlayType: F2(canPlayType),

    decodeTimeRanges: decodeTimeRanges
};

}();