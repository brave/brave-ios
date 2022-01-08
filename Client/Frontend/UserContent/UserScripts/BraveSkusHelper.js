// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

'use strict';

Object.defineProperty(window.__firefox__, '$<brave-skus-helper>', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: {
        id: 1,
        resolution_handlers: {},
        resolve(id, data, error) {
            if (error && window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].reject) {
                window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].reject(error);
            } else if (window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].resolve) {
                window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].resolve(data);
            } else if (window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].reject) {
                window.__firefox__.$<brave-skus-helper>.resolution_handlers[id].reject(new Error("Invalid Data!"));
            } else {
                console.log("Invalid Promise ID: ", id);
            }
            
            delete window.__firefox__.$<brave-skus-helper>.resolution_handlers[id];
        },
        sendMessage(method_id, data) {
            return new Promise((resolve, reject) => {
               window.__firefox__.$<brave-skus-helper>.resolution_handlers[method_id] = { resolve, reject };
               webkit.messageHandlers.BraveSkusHelper.postMessage({ 'securitytoken': '$<security_token>',
                                                                    'method_id': method_id, 
                                                                    data: data});
           });
        }
    }
});

// FIXME: Any way to secure it better?
window.chrome = {};

Object.defineProperty(window.chrome, 'braveSkus', {
enumerable: false,
configurable: true,
writable: false,
    value: {
    refresh_order(orderId) {
        return window.__firefox__.$<brave-skus-helper>.sendMessage(1, orderId);
    },
    fetch_order_credentials(orderId) {
        return window.__firefox__.$<brave-skus-helper>.sendMessage(2, orderId);
    },
    prepare_credentials_presentation(domain) {
        return window.__firefox__.$<brave-skus-helper>.sendMessage(3, domain);
    },
    credential_summary(domain) {
        return window.__firefox__.$<brave-skus-helper>.sendMessage(4, domain);
    }
}
});
