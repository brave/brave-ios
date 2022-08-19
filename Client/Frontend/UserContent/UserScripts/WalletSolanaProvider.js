// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

(function() {
  if (window.isSecureContext) {
    function post(method, payload) {
      return new Promise((resolve, reject) => {
        webkit.messageHandlers.$<handler>.postMessage({
          "securitytoken": "$<security_token>",
          "method": method,
          "args": JSON.stringify(payload)
        })
        .then(resolve, (errorJSON) => {
          try {
            reject(JSON.parse(errorJSON))
          } catch(e) {
            reject(errorJSON)
          }
        })
      })
    }
    const provider = {
      value: {
        /* Properties */
        isPhantom: true,
        isBraveWallet: true,
        isConnected: false,
        publicKey: null,
        /* Methods */
        connect: function(payload) {
          if (payload == undefined) {
            return post('connect', {})
          } else {
            return post('connect', payload)
          }
        },
        disconnect: function(payload) {
          return post('disconnect', payload)
        },
        signAndSendTransaction: function(payload) {
          return post('signAndSendTransaction', payload)
        },
        signMessage: function(payload) {
          return post('signMessage', payload)
        },
        request: function(args) /* -> Promise<unknown> */  {
          return post('request', args)
        },
          /* Deprecated */
        signTransaction: function(payload) {
          return post('signTransaction', payload)
        },
          /* Deprecated */
        signAllTransactions: function(payload) {
          return post('signAllTransactions', payload)
        },
      }
    }
    Object.defineProperty(window, 'solana', provider);
    Object.defineProperty(window, 'braveSolana', provider);
    Object.defineProperty(window, '_brave_solana', {
      value: {},
      writable: false
    });
  }
})();
