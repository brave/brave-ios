window.__firefox__.includeOnce("Playlist", function() {
    
    
    function notify(target, type) {
        if (target) {
            var name = target.title;
            if (name == null || typeof name == 'undefined' || name == "") {
                name = document.title;
            }
            
            if (target.src !== "") {
                window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                            "name": name,
                                                                            "src": target.src,
                                                                            "pageSrc": window.location.href,
                                                                            "pageTitle": document.title,
                                                                            "mimeType": type,
                                                                            "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                            "detected": false,
                                                                            });
            }
            else {
                document.querySelectorAll('source').forEach(function(node) {
                    if (node.src !== "") {
                        if (node.closest('video') === target) {
                            window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                        "name": name,
                                                                                        "src": node.src,
                                                                                        "pageSrc": window.location.href,
                                                                                        "pageTitle": document.title,
                                                                                        "mimeType": type,
                                                                                        "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                                        "detected": false,
                                                                                        });
                        }
                        
                        if (node.closest('audio') === target) {
                            window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                        "name": name,
                                                                                        "src": node.src,
                                                                                        "pageSrc": window.location.href,
                                                                                        "pageTitle": document.title,
                                                                                        "mimeType": type,
                                                                                        "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                                        "detected": false,
                                                                                        });
                        }
                    }
                });
            }
        }
    }
    
    function onLongPressActivated(event) {
        var target = event.target;

        var targetVideo = target.closest("video");
        var targetAudio = target.closest("audio");

        // Video or Audio might have some sort of overlay..
        // Like player controls for pause/play, etc..
        // So we search for video/audio elements relative to touch position.
        if (!targetVideo && !targetAudio) {
            var touchX = event.touches[0].clientX + window.scrollX;
            var touchY = event.touches[0].clientY + window.scrollY;
        
            var videoElements = document.querySelectorAll('video');
            for (element of videoElements) {
                var rect = element.getBoundingClientRect();
                var x = rect.left + window.scrollX;
                var y = rect.top + window.scrollY;
                var w = rect.right - rect.left;
                var h = rect.bottom - rect.top;
                
                if (touchX >= x && touchX <= (x + w) && touchY >= y && touchY <= (y + h)) {
                    targetVideo = element;
                    break;
                }
            }
            
            var audioElements = document.querySelectorAll('audio');
            for (element of audioElements) {
                var rect = element.getBoundingClientRect();
                var x = rect.left + window.scrollX;
                var y = rect.top + window.scrollY;
                var w = rect.right - rect.left;
                var h = rect.bottom - rect.top;
                
                if (touchX >= x && touchX <= (x + w) && touchY >= y && touchY <= (y + h)) {
                    targetAudio = element;
                    break;
                }
            }
            
            //No elements found nearby so do nothing..
            if (!targetVideo && !targetAudio) {
                //webkit.messageHandlers.playlistHelper.postMessage({});
                return;
            }
        }
        
        //Elements found
        if (targetVideo) {
            notify(targetVideo, 'video');
        }

        if (targetAudio) {
            notify(targetAudio, 'audio');
        }
    }
    
    function setupLongPress() {
        var timer = null;
        var touchDuration = 800;
        var cancelDistance = 50;
        var touchEvent = null;
        
        function onLongPress() {
            timer = null;
            if (touchEvent) {
                onLongPressActivated(touchEvent);
            }
        };

        window.addEventListener("touchstart", function(event) {
            if (!timer) {
                touchEvent = event;
                timer = setTimeout(onLongPress, touchDuration);
            }
        }, true);
        
        window.addEventListener("touchmove", function(event) {
            if (timer) {
                var x = touchEvent.touches[0].clientX - event.touches[0].clientX;
                var y = touchEvent.touches[0].clientY - event.touches[0].clientY;
                var distance = Math.sqrt((x * y) + (y * y));
                
                if (distance >= cancelDistance) {
                    clearTimeout(timer);
                    timer = null;
                }
            }
        }, true);
        
        window.addEventListener("touchend", function(event) {
            if (timer) {
                clearTimeout(timer);
                timer = null;
            }
        }, true);
    }
    
    // MARK: ---------------------------------------
    
    function setupDetector() {
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
                
                if (node.constructor.name == 'HTMLSourceElement') {
                    videoNode = node.closest('video');
                    if (videoNode != null && typeof videoNode != 'undefined') {
                        mimeType = 'video'
                    } else {
                        mimeType = 'audio'
                    }
                }
            }

            if (src !== "") {
                window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                            "name": name,
                                                                            "src": src,
                                                                            "pageSrc": window.location.href,
                                                                            "pageTitle": document.title,
                                                                            "mimeType": mimeType,
                                                                            "duration": node.duration !== node.duration ? 0.0 : node.duration,
                                                                            "detected": true
                                                                            });
            } else {
                var target = node;
                document.querySelectorAll('source').forEach(function(node) {
                    if (node.src !== "") {
                        if (node.closest('video') === target) {
                            window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                        "name": name,
                                                                                        "src": node.src,
                                                                                        "pageSrc": window.location.href,
                                                                                        "pageTitle": document.title,
                                                                                        "mimeType": mimeType,
                                                                                        "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                            "detected": true
                                                                                        });
                        }
                        
                        if (node.closest('audio') === target) {
                            window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                        "name": name,
                                                                                        "src": node.src,
                                                                                        "pageSrc": window.location.href,
                                                                                        "pageTitle": document.title,
                                                                                        "mimeType": mimeType,
                                                                                        "duration": target.duration !== target.duration ? 0.0 : target.duration,
                                                                            "detected": true
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

            onReady(function() {
                getAllVideoElements().forEach(function(node) {
                    observeNode(node);
                });

                getAllAudioElements().forEach(function(node) {
                    observeNode(node);
                });
            });
        }

        observePage();
    }
    
    
    // MARK: -----------------------------
    
    setupLongPress();
    setupDetector();
});


//function setZoom(zoom,el) {
//
//      transformOrigin = [0,0];
//        el = el || instance.getContainer();
//        var p = ["webkit", "moz", "ms", "o"],
//            s = "scale(" + zoom + ")",
//            oString = (transformOrigin[0] * 100) + "% " + (transformOrigin[1] * 100) + "%";
//
//        for (var i = 0; i < p.length; i++) {
//            el.style[p[i] + "Transform"] = s;
//            el.style[p[i] + "TransformOrigin"] = oString;
//        }
//
//        el.style["transform"] = s;
//        el.style["transformOrigin"] = oString;
//
//}
//
//var zoom = 1;
//var width = 100;
//
//function bigger() {
//    zoom = zoom + 0.1;
//    width = 100 / zoom;
//    document.body.style.transformOrigin = "left top";
//    document.body.style.transform = "scale(" + zoom + ")";
//    document.body.style.width = width + "%";
//}
//function smaller() {
//    zoom = zoom - 0.1;
//    width = 100 / zoom;
//    document.body.style.transformOrigin = "left top";
//    document.body.style.transform = "scale(" + zoom + ")";
//    document.body.style.width = width + "%";
//}
