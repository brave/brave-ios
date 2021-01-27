window.__firefox__.includeOnce("Playlist", function() {
    
    
    function notify(target, type) {
        if (target) {
            var name = target.title;
            if (name == null || typeof name == 'undefined' || name == "") {
                name = document.title;
            }
            
            if (target.src != "") {
                window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                            "name": name,
                                                                            "src": target.src,
                                                                            "pageSrc": window.location.href,
                                                                            "pageTitle": document.title,
                                                                            "mimeType": type,
                                                                            "duration": target.duration !== target.duration ? 0.0 : target.duration
                                                                            });
            }
            else {
                document.querySelectorAll('source').forEach(function(node) {
                    if (node.closest('video') === target) {
                        window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                    "name": name,
                                                                                    "src": target.src,
                                                                                    "pageSrc": window.location.href,
                                                                                    "pageTitle": document.title,
                                                                                    "mimeType": type,
                                                                                    "duration": target.duration !== target.duration ? 0.0 : target.duration
                                                                                    });
                    }
                    
                    if (node.closest('audio') === target) {
                        window.webkit.messageHandlers.playlistHelper.postMessage({
                                                                                    "name": name,
                                                                                    "src": target.src,
                                                                                    "pageSrc": window.location.href,
                                                                                    "pageTitle": document.title,
                                                                                    "mimeType": type,
                                                                                    "duration": target.duration !== target.duration ? 0.0 : target.duration
                                                                                    });
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
    
    setupLongPress();
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
