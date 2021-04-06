/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 'use strict'

Object.defineProperty(window, 'brave_ios', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
        id: 1,
        resolution_handlers: {},
        resolve(id, data, error) {
            if (error && window.brave_ios.resolution_handlers[id].reject) {
                window.brave_ios.resolution_handlers[id].reject(error);
            } else if (window.brave_ios.resolution_handlers[id].resolve) {
                window.brave_ios.resolution_handlers[id].resolve(data);
            } else if (window.brave_ios.resolution_handlers[id].reject) {
                window.brave_ios.resolution_handlers[id].reject(new Error("Invalid Data!"));
            } else {
                console.log("Invalid Promise ID: ", id);
            }
            
            delete window.brave_ios.resolution_handlers[id];
        },
        sendMessage(data) {
            return new Promise((resolve, reject) => {
               const p_id = 'id' + ++window.brave_ios.id;
               window.brave_ios.resolution_handlers[p_id] = { resolve, reject };
               webkit.messageHandlers.SearchBackup.postMessage({'securitytoken': SECURITY_TOKEN,
                                                                'data': data,
                                                                'id': p_id});
           });
        }
    }
});

 Object.defineProperty(window, 'chrome', {
    enumerable: false,
    configurable: true,
    writable: false,
     value: {
        fetchBackupResults(query, language, country, geo) {
            return window.brave_ios.sendMessage({ "query": query, "language": language, "country": country, "geo": geo})
        }
    }
  });
