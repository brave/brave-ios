// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

var allowBackgroundPlayback = true;
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
})

var videoElements = [];

function pauseAll() {
     console.log("pauseAll");
        console.log(videoElements);
    videoElements.forEach(function(item, index, array) {
        item.pause();
    });
}

function isTabPlaying() {
    if (videoElements.some(function(vid) {
            return vid.playing
        })) {
        return true;
    }
    return false;
}

var autoRestart = false;

function didEnterBackground() {
    console.log("didEnterBackground");
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

document.querySelectorAll('video').forEach(function(item, index, array) {
                                           console.log("Adding Listener for video");
    item.addEventListener('playing', function() {
                          console.log("Playing");
        if (!videoElements.includes(this)) {
                          console.log("Added");
            videoElements.push(this);
        }
    }, false);

    item.addEventListener('pause', function() {
                          console.log("Paused");
                          console.log(_maskedState.get.call(document));
        if (_maskedState.get.call(document) == "hidden" && autoRestart && allowBackgroundPlayback) {
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
