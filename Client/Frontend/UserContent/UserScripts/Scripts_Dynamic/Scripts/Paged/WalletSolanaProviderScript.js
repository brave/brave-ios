// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

window.__firefox__.execute(function($, $Object) {
  if (window.isSecureContext) {
    let post = $(function(method, payload, completion) {
      let postMessage = $(function(message) {
        return $.postNativeMessage('$<message_handler>', message);
      });

      return new Promise($((resolve, reject) => {
        postMessage({
          "securityToken": SECURITY_TOKEN,
          "method": method,
          "args": JSON.stringify(payload, (key, value) => {
            /* JSON.stringify will convert Uint8Array to a dictionary, f we convert to an array we get a list. */
            return value instanceof Uint8Array ? Array.from(value) : value;
          })
        })
        .then(
            (result) => {
              if (completion == undefined) {
                resolve($.extensiveFreeze(result));
              } else {
                completion($.extensiveFreeze(result), resolve);
              }
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
      }))
    })
    /* <solanaWeb3.Transaction> ->
      {transaction: <solanaWeb3.Transaction>,
       serializedMessage: <base58 encoded string>,
       signatures: [{publicKey: <base58 encoded string>, signature: <Buffer>}]} */
    let convertTransaction = $(function(transaction) {
      const serializedMessage = transaction.serializeMessage();
      const signatures = transaction.signatures;
      let convertSignaturePubkeyTuple = $(function(signaturePubkeyTuple) {
        const obj = $Object.create(null, undefined);
        obj.publicKey = signaturePubkeyTuple.publicKey.toBase58();
        obj.signature = signaturePubkeyTuple.signature;
        return $.deepFreeze(obj);
      })
      const signaturesMapped = signatures.map(convertSignaturePubkeyTuple);
      const object = $Object.create(null, undefined);
      object.transaction = transaction;
      object.serializedMessage = serializedMessage;
      object.signatures = signaturesMapped;
      return $.deepFreeze(object);
    })
    let createTransaction = $(function(serializedTx) {
      return $.extensiveFreeze($<walletSolanaNameSpace>.solanaWeb3.Transaction.from(new Uint8Array(serializedTx)))
    })
    const provider = {
      value: {
        /* Properties */
        isPhantom: true,
        isBraveWallet: true,
        isConnected: false,
        publicKey: null,
        /* Methods */
        connect: $(function(payload) { /* -> {publicKey: solanaWeb3.PublicKey} */
          function completion(publicKey, resolve) {
            /* convert `<base58 encoded string>` -> `{publicKey: <solanaWeb3.PublicKey>}` */
            const result = $Object.create(null, undefined);
            result.publicKey = new $<walletSolanaNameSpace>.solanaWeb3.PublicKey(publicKey);
            resolve($.extensiveFreeze(result));
          }
          return post('connect', payload, completion)
        }),
        disconnect: $(function(payload) { /* -> Promise<{}> */
          return post('disconnect', payload)
        }),
        signAndSendTransaction: $(function(...payload) { /* -> Promise<{publicKey: <base58 encoded string>, signature: <base58 encoded string>}> */
          const object = convertTransaction(payload[0]);
          object.sendOptions = payload[1];
          return post('signAndSendTransaction', object)
        }),
        signMessage: $(function(...payload) { /* -> Promise{publicKey: <solanaWeb3.PublicKey>, signature: <Uint8Array>}> */
          function completion(result, resolve) {
            /* convert `{publicKey: <base58 encoded string>, signature: <[UInt8]>}}` ->
             `{publicKey: <solanaWeb3.PublicKey>, signature: <Uint8Array>}` */
            const parsed = JSON.parse(result);
            const publicKey = parsed["publicKey"]; /* base58 encoded pubkey */
            const signature = parsed["signature"]; /* array of uint8 */
            const obj = $Object.create(null, undefined);
            obj.publicKey = new $<walletSolanaNameSpace>.solanaWeb3.PublicKey(publicKey);
            obj.signature = new Uint8Array(signature);
            resolve($.extensiveFreeze(obj));
          }
          return post('signMessage', payload, completion)
        }),
        request: $(function(args) /* -> Promise<unknown> */  {
          if (args["method"] == 'connect') {
            function completion(publicKey, resolve) {
              /* convert `<base58 encoded string>` -> `{publicKey: <solanaWeb3.PublicKey>}` */
              const result = $Object.create(null, undefined);
              result.publicKey = $(new $<walletSolanaNameSpace>.solanaWeb3.PublicKey(publicKey));
              resolve($.extensiveFreeze(result));
            }
            return post('request', args, completion)
          }
          return post('request', args)
        }),
        /* Deprecated */
        signTransaction: $(function(transaction) { /* -> Promise<solanaWeb3.Transaction> */
          const object = convertTransaction(transaction);
          function completion(serializedTx, resolve) {
            /* Convert `<[UInt8]>` -> `solanaWeb3.Transaction` */
            const result = createTransaction(serializedTx);
            resolve($.extensiveFreeze(result));
          }
          return post('signTransaction', object, completion)
        }),
        /* Deprecated */
        signAllTransactions: $(function(transactions) { /* -> Promise<[solanaWeb3.Transaction]> */
          const objects = transactions.map(convertTransaction);
          function completion(serializedTxs, resolve) {
            /* Convert `<[[UInt8]]>` -> `[<solanaWeb3.Transaction>]` */
            const result = serializedTxs.map(createTransaction);
            resolve($.extensiveFreeze(result));
          }
          return post('signAllTransactions', objects, completion)
        }),
      }
    }
    $Object.defineProperty(window, 'solana', provider);
    $Object.defineProperty(window, 'braveSolana', provider);
  }
});
