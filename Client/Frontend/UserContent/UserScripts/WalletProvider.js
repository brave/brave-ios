// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

function post(from, functionArgs) {
  return webkit.messageHandlers.walletProvider.postMessage({
    name: from,
    args: JSON.stringify(functionArgs)
  });
}

Object.defineProperty(window, 'ethereum', {
  configurable: true,
  value: {
    chainId: undefined,
    networkVersion: undefined,
    selectedAddress: undefined,
    request: function () /* -> Promise<unknown> */  {
      return post.apply(null, ['request', arguments])
    },
    isConnected: function() /* -> bool */ {
      return post.apply(null, ['isConnected', arguments])
    },
    enable: function() /* -> ? */ {
      return post.apply(null, ['enable', arguments])
    },
    sendAsync: function() /* -> void */ {
      return post.apply(null, ['sendAsync', arguments])
    },
    send: function() /* -> Promise<JsonRpcResponse> */ {
      return post.apply(null, ['send', arguments])
    },
    isUnlocked: function() /* -> Promise<boolean> */ {
      return post.apply(null, ['isUnlocked', arguments])
    },
  }
});
