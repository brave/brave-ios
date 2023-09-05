// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

window.__firefox__.execute(function($, $Object) {
  
if (window.isSecureContext) {
  function post(method, payload) {
    let postMessage = $(function(message) {
      return $.postNativeMessage('$<message_handler>', message);
    });
    
    return new Promise($((resolve, reject) => {
      postMessage({
        "securityToken": SECURITY_TOKEN,
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
    }));
  }
  
  var EventEmitter = require('events');
  var BraveWeb3ProviderEventEmitter = new EventEmitter();
  
  const provider = {value: {}};
  $Object.defineProperty(window, 'ethereum', provider);
  $Object.defineProperty(window, 'braveEthereum', provider);
  // When using `$Object.defineProperties` & setting `writable: false` we cannot
  // update properties using `evaluateSafeJavaScript` / `updateEthereumProperties`.
  // `chainId`, `networkVersion`, `selectedAddress` differ from desktop (are
  // writable) because need to update in `updateEthereumProperties`
  $Object.defineProperties(window.ethereum, {
    chainId: {
      value: undefined,
      writable: true, // writable so `updateEthereumProperties()` can update.
    },
    networkVersion: {
      value: undefined,
      writable: true, // writable so `updateEthereumProperties()` can update.
    },
    selectedAddress: {
      value: true,
      writable: true, // writable so `updateEthereumProperties()` can update.
    },
    isBraveWallet: {
      value: true,
      writable: false,
    },
    isMetaMask: {
      value: true,
      writable: true, // https://github.com/brave/brave-browser/issues/22213
    },
    request: {
      value: $(function (args) /* -> Promise<unknown> */  {
        return post('request', args)
      }),
      writable: false,
    },
    isConnected: {
      value: $(function() /* -> bool */ {
        return true;
      }),
      writable: false
    },
    enable: {
      value: $(function() /* -> void */ {
        return post('enable', {})
      }),
      writable: false,
    },
    // ethereum.sendAsync(payload: JsonRpcRequest, callback: JsonRpcCallback): void;
    sendAsync: {
      value: $(function(payload, callback) {
        post('sendAsync', payload)
          .then((response) => {
            callback(null, response)
          })
          .catch((response) => {
            callback(response, null)
          })
      }),
      writable: false,
    },
    /*
    Available overloads for send:
      ethereum.send(payload: JsonRpcRequest, callback: JsonRpcCallback): void;
      ethereum.send(method: string, params?: Array<unknown>): Promise<JsonRpcResponse>;
    */
    send: {
      value: $(function(
        methodOrPayload /* : string or JsonRpcRequest */,
        paramsOrCallback /*  : Array<unknown> or JsonRpcCallback */
      ) {
        var payload = {
          method: '',
          params: {}
        }
        if (typeof methodOrPayload === 'string') {
          payload.method = methodOrPayload
          payload.params = paramsOrCallback
          return post('send', payload)
        } else {
          payload.params = methodOrPayload
          if (paramsOrCallback != undefined) {
            post('send', payload)
              .then((response) => {
                paramsOrCallback(null, response)
              })
              .catch((response) => {
                paramsOrCallback(response, null)
              })
          } else {
            // Unsupported usage of send
            throw TypeError('Insufficient number of arguments.')
          }
        }
      }),
      writable: true, // https://github.com/brave/brave-browser/issues/25078
    },
    on: {
      value: BraveWeb3ProviderEventEmitter.on,
      writable: false,
    },
    emit: {
      value: BraveWeb3ProviderEventEmitter.emit,
      writable: false,
    },
    removeListener: {
      value: BraveWeb3ProviderEventEmitter.removeListener,
      writable: false,
    },
    removeAllListeners: {
      value: BraveWeb3ProviderEventEmitter.removeAllListeners,
      writable: false,
    },
  });
}
  
});
