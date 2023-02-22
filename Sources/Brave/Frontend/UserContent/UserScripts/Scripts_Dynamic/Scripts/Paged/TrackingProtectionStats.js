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

  let originalOpen = null;
  let originalSend = null;
  let originalImageSrc = null;
  let mutationObserver = null;

  let injectStatsTracking = $(function(enabled) {
    // This enable/disable section is a change from the original Focus iOS version.
    if (enabled) {
      if (originalOpen) {
        return;
      }
      window.addEventListener("load", onLoadNativeCallback, false);
    } else {
      window.removeEventListener("load", onLoadNativeCallback, false);

      if (originalOpen) { // if one is set, then all the enable code has run
        XMLHttpRequest.prototype.open = originalOpen;
        XMLHttpRequest.prototype.send = originalSend;
        Image.prototype.src = originalImageSrc;
        mutationObserver.disconnect();

        originalOpen = originalSend = originalImageSrc = mutationObserver = null;
      }
      return;
    }

    // -------------------------------------------------
    // Send ajax requests URLs to the host application
    // -------------------------------------------------
    var xhrProto = XMLHttpRequest.prototype;
    if (!originalOpen) {
      originalOpen = xhrProto.open;
      originalSend = xhrProto.send;
    }

    xhrProto.open = $(function(method, url) {
      // Blocked async XMLHttpRequest are handled via RequestBlocking.js
      // We only handle sync requests
      this._shouldTrack = arguments[2] !== undefined && !arguments[2]
      this._url = url;
      return originalOpen.apply(this, arguments);
    }, /*overrideToString=*/false);

    xhrProto.send = $(function(body) {
      if (this._url === undefined || !this._shouldTrack) {
        return originalSend.apply(this, arguments);
      }
      
      // Only attach the `error` event listener once for this
      // `XMLHttpRequest` instance.
      if (!this._tpErrorHandler) {
        // If this `XMLHttpRequest` instance fails to load, we
        // can assume it has been blocked.
        this._tpErrorHandler = $(function() {
          sendMessage(this._url, "xmlhttprequest");
        });
        this.addEventListener("error", this._tpErrorHandler);
      }
      return originalSend.apply(this, arguments);
    }, /*overrideToString=*/false);

    // -------------------------------------------------
    // Detect when new sources get set on Image and send them to the host application
    // -------------------------------------------------
    if (!originalImageSrc) {
      originalImageSrc = Object.getOwnPropertyDescriptor(Image.prototype, "src");
    }
    delete Image.prototype.src;
    Object.defineProperty(Image.prototype, "src", {
      get: $(function() {
        return originalImageSrc.get.call(this);
      }),
      set: $(function(value) {
        // Only attach the `error` event listener once for this
        // Image instance.
        if (!this._tpErrorHandler) {
          // If this `Image` instance fails to load, we can assume
          // it has been blocked.
          this._tpErrorHandler = $(function() {
            sendMessage(this.src, "image");
          });
          this.addEventListener("error", this._tpErrorHandler);
        }

        originalImageSrc.set.call(this, value);
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
          if (node.tagName === "SCRIPT" && node.src) {
            // Send all scripts that are added, we won't add it to the stats unless script blocking is enabled anyways
            sendMessage(node.src, "script");
          }
        }));
      }));
    }));

    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true
    });
  });

  injectStatsTracking(true);
});
