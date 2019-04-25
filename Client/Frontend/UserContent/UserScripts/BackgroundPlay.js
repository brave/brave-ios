// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
var allowBackgroundPlayback = $<allowBackgroundPlayback>;

if (allowBackgroundPlayback) {
    var _maskedState = Object.getOwnPropertyDescriptor(Document.prototype, 'visibilityState') ||
        Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'visibilityState');
    if (_maskedState && _maskedState.configurable) {
        Object.defineProperty(document, 'visibilityState', {
            get: function() {
                // Not returning null here as some websites don't have a check for cookie returning null, and may not behave properly
                if (allowBackgroundPlayback) {
                    return "visible";
                }
                return _maskedState.get.call(document);
            }
        });
    }

    Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
        get: function() {
            return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
        }
    });

    var videoElements = [];

    function isTabPlaying() {
        if (videoElements.some(function(vid) {
                return vid.playing
            })) {
            return true;
        }
        return false;
    }

    var timer

    let origAppend = Node.prototype.appendChild;
    Node.prototype.appendChild = function(n) {
        checkVideoNode(n);
        return origAppend.apply(this, [n]);
    }


    let origInsert = Node.prototype.insertBefore;
    Node.prototype.insertBefore = function(n1, n2) {
        checkVideoNode(n1);
        return origInsert.apply(this, [n1, n2]);
    }

    let checkVideoNode = function(n) {
        if (n.constructor.name == "HTMLVideoElement") {
            if (timer) {
                clearTimeout(timer);
            }
            timer = setTimeout(searchVideos, 1000);
        }
    }

    let searchVideos = function() {
        document.querySelectorAll('video').forEach(function(item, index, array) {
            item.addEventListener('playing', function() {
                if (!videoElements.includes(this)) {
                    videoElements.push(this);
                }
            }, false);

            item.addEventListener('pause', function() {
                if (autoRestart && allowBackgroundPlayback) {
                    autoRestart = false;
                    this.play();
                    return;
                }
                var index = videoElements.indexOf(this);
                if (index != -1) {
                    videoElements.splice(index, 1);
                }
            }, false);
        });
    }
    searchVideos();
}

function pauseAll() {
    document.querySelectorAll('video').forEach(function(item, index, array) {
        item.pause();
    });
}

var autoRestart = false;

function didEnterBackground() {
    if (!allowBackgroundPlayback) {
        pauseAll();
    } else if (isTabPlaying()) {
        autoRestart = true;
    }
}




//WIP Mute functions
//function muteAll() {
//    videoElements.forEach(function(item, index, array) {
//        item.muted = true;
//    });
//}
//
//function unMuteAll() {
//    videoElements.forEach(function(item, index, array) {
//                          item.muted = true;
//                          });
//}
