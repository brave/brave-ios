// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

var abc = Object.getOwnPropertyDescriptor(Document.prototype, 'visibilityState') ||
Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'visibilityState');
if (abc && abc.configurable) {
    Object.defineProperty(document, 'visibilityState', {
                          get: function() {
                          // Not returning null here as some websites don't have a check for cookie returning null, and may not behave properly
                          return "visible";
                          }
                          });
}
