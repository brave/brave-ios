function notifyNodeSource(node, src, mimeType) {
    var name = node.title;
    if (name == null || typeof name == 'undefined' || name == "") {
        name = document.title;
    }

    if (mimeType == null || typeof mimeType == 'undefined' || mimeType == "") {
        if (node.constructor.name == 'HTMLVideoElement') {
            mimeType = 'video';
        }

        if (node.constructor.name == 'HTMLAudioElement') {
            mimeType = 'audio';
        }
    }

    if (src != "") {
        window.webkit.messageHandlers.playlistCacheLoader.postMessage({
                                                                    "name": name,
                                                                    "src": src,
                                                                    "pageSrc": window.location.href,
                                                                    "pageTitle": document.title,
                                                                    "mimeType": mimeType,
                                                                    "duration": node.duration !== node.duration ? 0.0 : node.duration
                                                                    });
    }
}

function notifyNode(node) {
    notifyNodeSource(node, node.src, node.type);
}

function observeNode(node) {
    if (node.observer == null || node.observer === undefined) {
        node.observer = new MutationObserver(function (mutations) {
            notifyNode(node);
        });
        node.observer.observe(node, { attributes: true, attributeFilter: ["src"] });
        notifyNode(node);

        node.addEventListener('loadedmetadata', function() {
            notifyNode(node);
        });
    }
}

function observeDocument(node) {
    if (node.observer == null || node.observer === undefined) {
        node.observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                mutation.addedNodes.forEach(function (node) {
                    if (node.constructor.name == "HTMLVideoElement") {
                        observeNode(node);
                    }
                    else if (node.constructor.name == "HTMLAudioElement") {
                        observeNode(node);
                    }
//                    else if (node.constructor.name == "HTMLSourceElement") {
//                        if (node.parentNode.constructor.name == "HTMLVideoElement") {
//                            console.log('Found Child');
//                        }
//                    }
                });
            });
        });
        node.observer.observe(node, { subtree: true, childList: true });
    }
}

function observeDynamicElements(node) {
    var original = node.createElement;
    node.createElement = function (tag) {
        if (tag === 'audio' || tag === 'video') {
            var result = original.call(node, tag);
            observeNode(result);
            notifyNode(result);
            return result;
        }
        return original.call(node, tag);
    };
}

function getAllVideoElements() {
    return document.querySelectorAll('video');
}

function getAllAudioElements() {
    return document.querySelectorAll('audio');
}

function onReady(fn) {
    if (document.readyState === "complete" || document.readyState === "interactive") {
        setTimeout(fn, 1);
    } else {
        document.addEventListener("DOMContentLoaded", fn);
    }
}

//TODO: Modify to not use mutation observers
//TODO: Modify to not use intervals
//^ Fix all of the above using a node.add and node.insert hook instead.
function observePage() {
    observeDocument(document);
    observeDynamicElements(document);

//    onReady(function() {
//        getAllVideoElements().forEach(function(node) {
//            observeNode(node);
//            notifyNode(node);
//        });
//    });

    // Timeinterval is needed for DailyMotion as their DOM is bad
    var interval = setInterval(function(){
        getAllVideoElements().forEach(function(node) {
            observeNode(node);
            notifyNode(node);
        });

        getAllAudioElements().forEach(function(node) {
            observeNode(node);
            notifyNode(node);
        });
    }, 1000);

    var timeout = setTimeout(function() {
        clearInterval(interval);
        clearTimeout(timeout);
    }, 10000);
}

observePage();
