// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.


var $<backgroundMediaPlaybackController> = (function() {
    var didHookVisibilityState = false;
    var isBackgroundPlayEnabled = false;
    var autoRestartPlaying = false;

    var _maskedState = Object.getOwnPropertyDescriptor(Document.prototype, 'visibilityState') ||
        Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'visibilityState');

    function hookMediaPlayerStates() {
        if (!didHookVisibilityState) {
            didHookVisibilityState = true;

            if (_maskedState && _maskedState.configurable) {
                Object.defineProperty(document, 'visibilityState', {
                    get: function () {
                        if (enabled) {
                            return "visible";
                        }
                        return _maskedState.get.call(document);
                    }
                });
            }
            
            Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
                get: function () {
                    return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
                }
            });
        }
    }

    function setBackgroundMediaPlayback(enabled) {
        isBackgroundPlayEnabled = enabled;
    }
    
    function isTabPlaying() {
        var videoElements = [].slice.call(getVideoElements());
        return videoElements.some(function (vid) {
            return vid.playing
        });
    }

    function checkVideoNode(node) {
        if (node.constructor.name == "HTMLVideoElement") {
            hookVideoFunctions();
        }
    }

    function hookVideoFunctions() {
        getVideoElements().forEach(function (item) {
            item.removeEventListener('pause', pauseVideo);
            item.addEventListener('pause', pauseVideo, false);
        });
    }

    function pauseVideo() {
        if (isBackgroundPlayEnabled && autoRestartPlaying) {
            autoRestartPlaying = false;
            this.play();
        }
    }

    function pauseAllVideos() {
        getVideoElements().forEach(function (item) {
            item.pause();
        });
    }

    function setAutoRestarts(enabled) {
        autoRestartPlaying = enabled;
    }

    function getVideoElements() {
        return document.querySelectorAll('video')
    }

    function didEnterBackground() {
        if (!isBackgroundPlayEnabled) {
            pauseAllVideos();
        } else if (isTabPlaying()) {
            setAutoRestarts(true);
        }
    }

    var observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (node) {
                checkVideoNode(node);
            });
        });
    });
    observer.observe(document, {subtree: true, childList: true });
    hookMediaPlayerStates();
    hookVideoFunctions();

    return {
        setBackgroundMediaPlayback: setBackgroundMediaPlayback,
        pauseAllVideos: pauseAllVideos,
        didEnterBackground: didEnterBackground
    };
})();
