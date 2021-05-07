/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

'use strict';

Object.defineProperty(window.__firefox__, '$<search-backup>', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
        id: 1,
        resolution_handlers: {},
        resolve(id, data, error) {
            if (error && window.__firefox__.$<search-backup>.resolution_handlers[id].reject) {
                window.__firefox__.$<search-backup>.resolution_handlers[id].reject(error);
            } else if (window.__firefox__.$<search-backup>.resolution_handlers[id].resolve) {
                window.__firefox__.$<search-backup>.resolution_handlers[id].resolve(data);
            } else if (window.__firefox__.$<search-backup>.resolution_handlers[id].reject) {
                window.__firefox__.$<search-backup>.resolution_handlers[id].reject(new Error("Invalid Data!"));
            } else {
                console.log("Invalid Promise ID: ", id);
            }
            
            delete window.__firefox__.$<search-backup>.resolution_handlers[id];
        },
        sendMessage(method_id, data) {
            return new Promise((resolve, reject) => {
               window.__firefox__.$<search-backup>.resolution_handlers[method_id] = { resolve, reject };
               webkit.messageHandlers.SearchBackup.postMessage({'data': data,
                                                                'method_id': method_id});
           });
        }
    }
});

 Object.defineProperty(navigator, 'brave', {
    enumerable: false,
    configurable: true,
    writable: false,
     value: {
        fetchBackupResults(query, language, country, geo) {
            return window.__firefox__.$<search-backup>.sendMessage(1, { "query": query, "language": language, "country": country, "geo": geo})
        }
    }
  });

const brave = {};

Object.defineProperty(brave, 'search', {
enumerable: false,
configurable: true,
writable: false,
    value: {
    isBraveSearchDefault() {
        return window.__firefox__.$<search-backup>.sendMessage(2);
    },

    setBraveSearchDefault() {
        return window.__firefox__.$<search-backup>.sendMessage(3);
    }
}
});
