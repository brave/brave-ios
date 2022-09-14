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
          /* remove `Error: ` prefix. errorJSON=`Error: {code: 1, errorMessage: "Internal error"}` */
          const errorJSONString = new String(errorJSON);
          const errorJSONStringSliced = errorJSONString.slice(errorJSONString.indexOf('{'));
          try {
            reject(JSON.parse(errorJSONStringSliced))
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
              /* remove `Error: ` prefix. errorJSON=`Error: {code: 1, errorMessage: "Internal error"}` */
              const errorJSONString = new String(errorJSON);
              const errorJSONStringSliced = errorJSONString.slice(errorJSONString.indexOf('{'));
              try {
                reject(JSON.parse(errorJSONStringSliced))
              } catch(e) {
                reject(errorJSON)
              }
            }
          )
      })
    }
    function postTransaction(method, payload) {
      return new Promise((resolve, reject) => {
        webkit.messageHandlers.$<handler>.postMessage({
          "securitytoken": "$<security_token>",
          "method": method,
          "args": JSON.stringify(payload)
        })
        .then(
            (serializedTx) => {
              /* Convert `serializedTx` to `solanaWeb3.Transaction` */
              const result = window._brave_solana.createTransaction(serializedTx);
              resolve(result)
            },
            (errorJSON) => {
              /* remove `Error: ` prefix. errorJSON=`Error: {code: 1, errorMessage: "Internal error"}` */
              const errorJSONString = new String(errorJSON);
              const errorJSONStringSliced = errorJSONString.slice(errorJSONString.indexOf('{'));
              try {
                reject(JSON.parse(errorJSONStringSliced))
              } catch(e) {
                reject(errorJSON)
              }
            }
          )
      })
    }
    function postTransactions(method, payload) {
      return new Promise((resolve, reject) => {
        webkit.messageHandlers.$<handler>.postMessage({
          "securitytoken": "$<security_token>",
          "method": method,
          "args": JSON.stringify(payload)
        })
        .then(
            (serializedTxs) => {
              /* Convert `serializedTxs` to array of `solanaWeb3.Transaction` */
              const result = serializedTxs.map(window._brave_solana.createTransaction);
              resolve(result)
            },
            (errorJSON) => {
              /* remove `Error: ` prefix. errorJSON=`Error: {code: 1, errorMessage: "Internal error"}` */
              const errorJSONString = new String(errorJSON);
              const errorJSONStringSliced = errorJSONString.slice(errorJSONString.indexOf('{'));
              try {
                reject(JSON.parse(errorJSONStringSliced))
              } catch(e) {
                reject(errorJSON)
              }
            }
          )
      })
    }
    function convertTransaction(transaction) {
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
      return object;
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
          const object = convertTransaction(payload[0]);
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
        signTransaction: function(transaction) { /* -> Promise<solanaWeb3.Transaction> */
          const object = convertTransaction(transaction);
          return postTransaction('signTransaction', object)
        },
        /* Deprecated */
        signAllTransactions: function(transactions) { /* -> Promise<[solanaWeb3.Transaction]> */
          const objects = transactions.map(convertTransaction);
          return postTransactions('signAllTransactions', objects)
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
