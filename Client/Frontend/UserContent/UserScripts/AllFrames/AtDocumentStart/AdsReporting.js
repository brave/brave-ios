/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

if (webkit.messageHandlers.adsMediaReporting) {
    install();
}

function install() {
  function sendMessage(playing) {
    webkit.messageHandlers.adsMediaReporting.postMessage(playing);
  }

  let originalPlay = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function() {
    this.addEventListener('playing', function() {
      sendMessage(true)
    });
    this.addEventListener('pause', function() {
      sendMessage(false)
    });
    return originalPlay.apply(this, arguments);
  }
}
