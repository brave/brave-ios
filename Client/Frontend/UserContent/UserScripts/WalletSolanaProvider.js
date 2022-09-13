// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

(function($Object) {
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
    function postPublicKey(method, payload) {
      return new Promise((resolve, reject) => {
        webkit.messageHandlers.$<handler>.postMessage({
          "securitytoken": "$<security_token>",
          "method": method,
          "args": JSON.stringify(payload)
        })
        .then(
            (publicKey) => {
             /* Convert `publicKey` to `solanaWeb3.PublicKey`
               & wrap as {publicKey: solanaWeb3.PublicKey} for success response */
              const result = new Object();
              result.publicKey = window._brave_solana.createPublickey(publicKey);
              resolve(result)
            },
            (errorJSON) => {
              try {
                reject(JSON.parse(errorJSON))
              } catch(e) {
                reject(errorJSON)
              }
            }
          )
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
        connect: function(payload) { /* -> {publicKey: solanaWeb3.PublicKey} */
          return postPublicKey('connect', payload)
        },
        disconnect: function(payload) { /* -> Promise<{}> */
          return post('disconnect', payload)
        },
        signAndSendTransaction: function(...payload) { /* -> Promise<{publicKey: <base58 encoded string>, signature: <base58 encoded string>}> */
          const transaction = payload[0];
          const serializedMessage = transaction.serializeMessage();
          const signatures = transaction.signatures;
          function convertSignaturePubkeyPair(signaturePubkeyPair) {
            const obj = new Object();
            obj.publicKey = signaturePubkeyPair.publicKey.toBase58();
            obj.signature = signaturePubkeyPair.signature;
            return obj;
          }
          const signaturesMapped = signatures.map(convertSignaturePubkeyPair);
          const object = new Object();
          object.transaction = transaction;
          object.serializedMessage = serializedMessage;
          object.signatures = signaturesMapped;
          object.sendOptions = payload[1];
          return post('signAndSendTransaction', object)
        },
        signMessage: function(...payload) { /* -> Promise<{publicKey: <base58 encoded string>, signature: <base58 encoded string>}> */
          return post('signMessage', payload)
        },
        request: function(args) /* -> Promise<unknown> */  {
          if (args["method"] == 'connect') {
            return postPublicKey('request', args)
          }
          return post('request', args)
        },
        /* Deprecated */
        signTransaction: function(payload) { /* -> Promise<solanaWeb3.Transaction> */
          return post('signTransaction', payload)
        },
        /* Deprecated */
        signAllTransactions: function(payload) { /* -> Promise<[solanaWeb3.Transaction]> */
          return post('signAllTransactions', payload)
        },
      }
    }
    $Object.defineProperty(window, 'solana', provider);
    $Object.defineProperty(window, 'braveSolana', provider);
    $Object.defineProperty(window, '_brave_solana', {
      value: {},
      writable: false
    });
  }
})(Object);
