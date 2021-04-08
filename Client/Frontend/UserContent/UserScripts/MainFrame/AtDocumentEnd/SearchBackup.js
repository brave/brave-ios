/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

'use strict';

Object.defineProperty(window.__firefox__, 'search_backup', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
        id: 1,
        resolution_handlers: {},
        resolve(id, data, error) {
            if (error && window.__firefox__.search_backup.resolution_handlers[id].reject) {
                window.__firefox__.search_backup.resolution_handlers[id].reject(error);
            } else if (window.__firefox__.search_backup.resolution_handlers[id].resolve) {
                window.__firefox__.search_backup.resolution_handlers[id].resolve(data);
            } else if (window.__firefox__.search_backup.resolution_handlers[id].reject) {
                window.__firefox__.search_backup.resolution_handlers[id].reject(new Error("Invalid Data!"));
            } else {
                console.log("Invalid Promise ID: ", id);
            }
            
            delete window.__firefox__.search_backup.resolution_handlers[id];
        },
        sendMessage(data) {
            return new Promise((resolve, reject) => {
               const p_id = 'id' + ++window.__firefox__.search_backup.id;
               window.__firefox__.search_backup.resolution_handlers[p_id] = { resolve, reject };
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
            return window.__firefox__.search_backup.sendMessage({ "query": query, "language": language, "country": country, "geo": geo})
        }
    }
  });
