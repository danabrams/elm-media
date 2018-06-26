var _Media_call = F2(function (functionName, id) {
    return _Media_withNode(id, function (node) {
        node[functionName]();
        return __Utils_Tuple0;
    });
});

function _Browser_withNode(id, doStuff) {
    return __Scheduler_binding(function (callback) {

        var node = document.getElementById(id);
        callback(function () {
            if (node === null) {
                __Scheduler_fail(__Media_NotFound(id));
            } else if (!(node instanceof HTMLMediaElement)) {
                __Scheduler_fail(__Media_NotMediaElement(id, node.nodeName));
            }
            else { __Scheduler_succeed(doStuff(node)) }
        });

    });
}
