// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

window.__firefox__.includeOnce("WindowRenderHelper", function() {
  Object.defineProperty(window.__firefox__, "$<windowRenderHelper>", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: Object.freeze({
      "resizeWindow": function () {
          var evt = document.createEvent('UIEvents');
          evt.initUIEvent('resize', true, false, window, 0);
          window.dispatchEvent(evt);
      },
      
      "addDocumentStateListener": function () {
        document.addEventListener('readystatechange', (function(){
            let eventHandler = function(e) {
                if (e.target.readyState === "interactive") {
                    //Used for debugging in Safari development tools to know what the state of the page is.
                    //Not needed while in use because we only care about JSON messages and not state.
                    window.__firefox__.$<windowRenderHelper>.resizeWindow();
                }

                if (e.target.readyState === "complete") {
                    //Used for debugging in Safari development tools to know what the state of the page is.
                    //Not needed while in use because we only care about JSON messages and not state.
                    window.__firefox__.$<windowRenderHelper>.resizeWindow();
                }
            }
          
            eventHandler.toString = function() {
                return "function() {\n\t[native code]\n}";
            }
          
            return eventHandler;
        })());
      }
    })
  })

  window.__firefox__.$<windowRenderHelper>.addDocumentStateListener();
});
