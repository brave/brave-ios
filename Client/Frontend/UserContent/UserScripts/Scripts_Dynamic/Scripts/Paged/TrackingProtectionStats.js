/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

window.__firefox__.execute(function($) {
  const messageHandler = '$<message_handler>';

  let sendMessage = $(function(urlString, resourceType) {
    if (urlString) {
      try {
        let resourceURL = new URL(urlString, window.location.href)
        $.postNativeMessage(messageHandler, {
          "securityToken": SECURITY_TOKEN,
          "data": {
            resourceURL: resourceURL.href,
            sourceURL: window.location.href,
            resourceType: resourceType
          }
        });
      } catch (error) {
        console.error(error)
      }
    }
  });

  let onLoadNativeCallback = $(function() {
    // Send back the sources of every script and image in the DOM back to the host application.
    [].slice.apply(document.scripts).forEach(function(el) { sendMessage(el.src, "script"); });
    [].slice.apply(document.images).forEach(function(el) {
      // If the image's natural width is zero, then it has not loaded so we
      // can assume that it may have been blocked.
      if (el.naturalWidth === 0) {
        sendMessage(el.src, "image");
      }
    });
  });

  let mutationObserver = null;
  let injectStatsTracking = $(function() {
    window.addEventListener("load", onLoadNativeCallback, false);

    // -------------------------------------------------
    // Send ajax requests URLs to the host application
    // -------------------------------------------------
    let xhrProto = XMLHttpRequest.prototype;
    const originalOpen = xhrProto.open;
    const originalSend = xhrProto.send;

    xhrProto.open = $(function(method, url) {
      // Blocked async XMLHttpRequest are handled via RequestBlocking.js
      // We only handle sync requests
      this._shouldTrack = arguments[2] !== undefined && !arguments[2]
      this._url = url;
      return originalOpen.apply(this, arguments);
    });

    xhrProto.send = function(body) {
      if (this._url === undefined || !this._shouldTrack) {
        return originalSend.apply(this, arguments);
      }

      // Only attach the `error` event listener once for this
      // `XMLHttpRequest` instance.
      if (this._tpErrorHandler) {
        return originalSend.apply(this, arguments);
      }
      
      // If this `XMLHttpRequest` instance fails to load, we
      // can assume it has been blocked.
      this._tpErrorHandler = $(function() {
        sendMessage(this._url, "xmlhttprequest");
      });
      
      this.addEventListener("error", this._tpErrorHandler);
      return originalSend.apply(this, arguments);
    }

    // -------------------------------------------------
    // Detect when new sources get set on Image and send them to the host application
    // -------------------------------------------------
    const originalImageSrc = Object.getOwnPropertyDescriptor(Image.prototype, "src");
    delete Image.prototype.src;
    
    Object.defineProperty(Image.prototype, "src", {
      get: $(function() {
        return originalImageSrc.get.call(this);
      }),
      set: $(function(value) {
        originalImageSrc.set.call(this, value);
        
        // Only attach the `error` event listener once for this
        // Image instance.
        if (this._tpErrorHandler) {
          return
        }
        
        // If this `Image` instance fails to load, we can assume
        // it has been blocked.
        this._tpErrorHandler = $(function() {
          sendMessage(this.src, "image");
        });
        
        this.addEventListener("error", this._tpErrorHandler);
      }),
      enumerable: true,
      configurable: true
    });

    // -------------------------------------------------
    // Listen to when new <script> elements get added to the DOM
    // and send the source to the host application
    // -------------------------------------------------
    mutationObserver = new MutationObserver($(function(mutations) {
      mutations.forEach($(function(mutation) {
        mutation.addedNodes.forEach($(function(node) {
          // Only consider `<script src="*">` elements.
          if (node.tagName !== "SCRIPT" || !node.src) {
            return
          }
          
          // Send all scripts that are added, we won't add it to the stats unless script blocking is enabled anyways
          sendMessage(node.src, "script");
        }));
      }));
    }));

    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true
    });
  });

  injectStatsTracking();
});
