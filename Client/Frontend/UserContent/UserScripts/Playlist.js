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
    
    function $<setupLongPress>() {
        Object.defineProperty(window, '$<onLongPressActivated>', {
          value:
            function(localX, localY) {
                var target = document.elementFromPoint(localX, localY);
                var targetVideo = target ? target.closest("video") : null;
                var targetAudio = target ? target.closest("audio") : null;

                // Video or Audio might have some sort of overlay..
                // Like player controls for pause/play, etc..
                // So we search for video/audio elements relative to touch position.
                if (!targetVideo && !targetAudio) {
                    var touchX = localX + window.scrollX;
                    var touchY = localY + window.scrollY;
                
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
        });
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

        /*function $<observeDynamicElements>(node) {
            var original = node.createElement;
            node.createElement = function (tag) {
                if (tag === 'audio' || tag === 'video') {
                    var result = original.call(node, tag);
                    $<notifyNode>(result);
                    return result;
                }
                return original.call(node, tag);
            };
            
            var originalAppend = Node.prototype.appendChild;
            Node.prototype.appendChild = function(child) {
                if (child.constructor.name == "HTMLVideoElement" || child.constructor.name == "HTMLAudioElement") {
                    var result = originalAppend.call(this, child);
                    $<notifyNode>(result);
                    return result;
                }
                
                return originalAppend.call(this, child);
            }
        }*/

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
            //$<observeDynamicElements>(document);

            
            Object.defineProperty(HTMLVideoElement.prototype, 'src', {
                enumerable: true,
                configurable: false,
                get: function(){
                    return this.getAttribute('src')
                },
                set: function(value) {
                    this.setAttribute('src', value);
                    $<notifyNode>(this);
                }
            });
            
            Object.defineProperty(HTMLAudioElement.prototype, 'src', {
                enumerable: true,
                configurable: false,
                get: function(){
                    return this.getAttribute('src')
                },
                set: function(value) {
                    this.setAttribute('src', value);
                    $<notifyNode>(this);
                }
            });
        }

        $<observePage>();
    }
    
    
    // MARK: -----------------------------
    
    $<setupLongPress>();
    $<setupDetector>();
});
