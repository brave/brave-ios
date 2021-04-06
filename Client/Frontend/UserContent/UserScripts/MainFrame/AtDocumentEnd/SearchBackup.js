/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 'use strict'

 Object.defineProperty(window, 'chrome', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
        fetchBackupResults(query, language, country, geo) {
            webkit.messageHandlers.SearchBackup.postMessage({"securitytoken": SECURITY_TOKEN, "data": "messageData"});
            return new Promise(res => res(`sample html: ${query}, ${language}, ${country}, ${geo}`));
        }
    }
  })


//   Object.defineProperty(window, 'chrome', {
//     enumerable: false,
//     configurable: true,
//     writable: false,
//     value: Object.freeze({ 
//         fetchBackupResults = function(a, b, c) {
//             return new Promise(res => res(true));
//         }

//         //fetchBackupResults: () => new Promise(res => res(true))
//     })
//   })