// The below is needed because the script may not be web-packed into a bundle so it may be missing the run-once code

// MARK: - Include Once

if (!window.__firefox__) {
    window.__firefox__ = {};
}

if (!window.__firefox__.includeOnce) {
    window.__firefox__ = {};
    window.__firefox__.includeOnce = function(key, func) {
        var keys = {};
        if (!keys[key]) {
            keys[key] = true;
            func();
        }
    };
}

// MARK: - Media Detection

window.__firefox__.includeOnce("$<Playlist>", function() {
    function is_nan(value) {
        return typeof value === "number" && value !== value;
    }
    
    function is_infinite(value) {
        return typeof value === "number" && (value === Infinity || value === -Infinity);
    }
    
    function clamp_duration(value) {
        if (is_nan(value)) {
            return 0.0;
        }
        
        if (is_infinite(value)) {
            return Number.MAX_VALUE;
        }
        return value;
    }
    
    function $<sendMessage>(message) {
        if (window.webkit.messageHandlers.$<handler>) {
            window.webkit.messageHandlers.$<handler>.postMessage(message);
        }
    }
    
    function $<notify>(target, type) {
        if (target) {
            var name = target.title;
            if (name == null || typeof name == 'undefined' || name == "") {
                name = document.title;
            }
            
            if (target.src !== "") {
                $<sendMessage>({
                    "securitytoken": "$<security_token>",
                    "name": name,
                    "src": target.src,
                    "pageSrc": window.location.href,
                    "pageTitle": document.title,
                    "mimeType": type,
                    "duration": clamp_duration(target.duration),
                    "detected": false,
                });
            }
            else {
                document.querySelectorAll('source').forEach(function(node) {
                    if (node.src !== "") {
                        if (node.closest('video') === target) {
                            $<sendMessage>({
                                "securitytoken": "$<security_token>",
                                "name": name,
                                "src": node.src,
                                "pageSrc": window.location.href,
                                "pageTitle": document.title,
                                "mimeType": type,
                                "duration": clamp_duration(target.duration),
                                "detected": false,
                            });
                        }
                        
                        if (node.closest('audio') === target) {
                            $<sendMessage>({
                                "securitytoken": "$<security_token>",
                                "name": name,
                                "src": node.src,
                                "pageSrc": window.location.href,
                                "pageTitle": document.title,
                                "mimeType": type,
                                "duration": clamp_duration(target.duration),
                                "detected": false,
                            });
                        }
                    }
                });
            }
        }
    }
    
    function $<onLongPressActivated>(event) {
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
                //webkit.messageHandlers.$<handler>.postMessage({});
                return;
            }
        }
        
        //Elements found
        if (targetVideo) {
            $<notify>(targetVideo, 'video');
        }

        if (targetAudio) {
            $<notify>(targetAudio, 'audio');
        }
    }
    
    function $<setupLongPress>() {
        var timer = null;
        var touchDuration = 800;
        var cancelDistance = 5;
        var touchEvent = null;
        var X = 0;
        var Y = 0;
        
        var event_options = {
            "capture": true,
            "passive": true,
        };
        
        // When the long-press gesture is recognized, we want to disable all selections and context menus on the page
        function clearSelection() {
            var sel;
            if ((sel = document.selection) && sel.empty) {
                sel.empty();
            } else {
                if (window.getSelection) {
                    window.getSelection().removeAllRanges();
                }
                
                var activeEl = document.activeElement;
                if (activeEl) {
                    var tagName = activeEl.nodeName.toLowerCase();
                    activeEl.selectionStart = activeEl.selectionEnd;
                }
            }
        }
        
        function onLongPress() {
            timer = null;
            if (touchEvent) {
                clearSelection();
                $<onLongPressActivated>(touchEvent);
            }
        };

        window.addEventListener("touchstart", function(event) {
            if (!timer) {
                touchEvent = event;
                X = event.touches[0].clientX;
                Y = event.touches[0].clientY;
                timer = setTimeout(onLongPress, touchDuration);
            }
        }, event_options);
        
        window.addEventListener("touchmove", function(event) {
            if (timer) {
                var x = X - event.changedTouches[0].clientX;
                var y = Y - event.changedTouches[0].clientY;
                var distance = Math.sqrt((x * x) + (y * y));
                
                if (distance >= cancelDistance) {
                    clearTimeout(timer);
                    timer = null;
                }
            }
        }, event_options);
        
        window.addEventListener("touchend", function(event) {
            if (timer) {
                clearTimeout(timer);
                timer = null;
            }
        }, event_options);
        
        window.addEventListener("touchcancel", function(event) {
            if (timer) {
                clearTimeout(timer);
                timer = null;
            }
        }, event_options);
    }
    
    // MARK: ---------------------------------------
    
    function $<setupDetector>() {
        function $<notifyNodeSource>(node, src, mimeType) {
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
                $<sendMessage>({
                    "securitytoken": "$<security_token>",
                    "name": name,
                    "src": src,
                    "pageSrc": window.location.href,
                    "pageTitle": document.title,
                    "mimeType": mimeType,
                    "duration": clamp_duration(node.duration),
                    "detected": true
                });
            } else {
                var target = node;
                document.querySelectorAll('source').forEach(function(node) {
                    if (node.src !== "") {
                        if (node.closest('video') === target) {
                            $<sendMessage>({
                                "securitytoken": "$<security_token>",
                                "name": name,
                                "src": node.src,
                                "pageSrc": window.location.href,
                                "pageTitle": document.title,
                                "mimeType": mimeType,
                                "duration": clamp_duration(target.duration),
                    "detected": true
                            });
                        }
                        
                        if (node.closest('audio') === target) {
                            $<sendMessage>({
                                "securitytoken": "$<security_token>",
                                "name": name,
                                "src": node.src,
                                "pageSrc": window.location.href,
                                "pageTitle": document.title,
                                "mimeType": mimeType,
                                "duration": clamp_duration(target.duration),
                    "detected": true
                            });
                        }
                    }
                });
            }
        }

        function $<notifyNode>(node) {
            $<notifyNodeSource>(node, node.src, node.type);
        }

        function $<observeNode>(node) {
            if (node.observer == null || node.observer === undefined) {
                node.observer = new MutationObserver(function (mutations) {
                    $<notifyNode>(node);
                });
                node.observer.observe(node, { attributes: true, attributeFilter: ["src"] });
                $<notifyNode>(node);

                node.addEventListener('loadedmetadata', function() {
                    $<notifyNode>(node);
                });
            }
        }

        function $<observeDocument>(node) {
            if (node.observer == null || node.observer === undefined) {
                node.observer = new MutationObserver(function (mutations) {
                    mutations.forEach(function (mutation) {
                        mutation.addedNodes.forEach(function (node) {
                            if (node.constructor.name == "HTMLVideoElement") {
                                $<observeNode>(node);
                            }
                            else if (node.constructor.name == "HTMLAudioElement") {
                                $<observeNode>(node);
                            }
                        });
                    });
                });
                node.observer.observe(node, { subtree: true, childList: true });
            }
        }

        function $<observeDynamicElements>(node) {
            var original = node.createElement;
            node.createElement = function (tag) {
                if (tag === 'audio' || tag === 'video') {
                    var result = original.call(node, tag);
                    $<observeNode>(result);
                    $<notifyNode>(result);
                    return result;
                }
                return original.call(node, tag);
            };
        }

        function $<getAllVideoElements>() {
            return document.querySelectorAll('video');
        }

        function $<getAllAudioElements>() {
            return document.querySelectorAll('audio');
        }

        function $<onReady>(fn) {
            if (document.readyState === "complete" || document.readyState === "interactive") {
                setTimeout(fn, 1);
            } else {
                document.addEventListener("DOMContentLoaded", fn);
            }
        }
        
        function $<observePage>() {
            $<observeDocument>(document);
            $<observeDynamicElements>(document);

            $<onReady>(function() {
                $<getAllVideoElements>().forEach(function(node) {
                    $<observeNode>(node);
                });

                $<getAllAudioElements>().forEach(function(node) {
                    $<observeNode>(node);
                });
            });
        }

        $<observePage>();
    }
    
    
    // MARK: -----------------------------
    
    $<setupLongPress>();
    $<setupDetector>();
});
