(function() {
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

        if (src !== "") {
            window.webkit.messageHandlers.playlistCacheLoader.postMessage({
                                                                        "name": name,
                                                                        "src": src,
                                                                        "pageSrc": window.location.href,
                                                                        "pageTitle": document.title,
                                                                        "mimeType": mimeType,
                                                                        "duration": node.duration !== node.duration ? 0.0 : node.duration,
                                                                        "detected": true,
                                                                        });
        } else {
            document.querySelectorAll('source').forEach(function(node) {
                if (node.src !== "") {
                    if (node.closest('video') === target) {
                        window.webkit.messageHandlers.playlistCacheLoader.postMessage({
                                                                                    "name": name,
                                                                                    "src": node.src,
                                                                                    "pageSrc": window.location.href,
                                                                                    "pageTitle": document.title,
                                                                                    "mimeType": type,
                                                                                    "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                          "detected": true,
                                                                                    });
                    }
                    
                    if (node.closest('audio') === target) {
                        window.webkit.messageHandlers.playlistCacheLoader.postMessage({
                                                                                    "name": name,
                                                                                    "src": node.src,
                                                                                    "pageSrc": window.location.href,
                                                                                    "pageTitle": document.title,
                                                                                    "mimeType": type,
                                                                                    "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                          "detected": true,
                                                                                    });
                    }
                }
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
})();
