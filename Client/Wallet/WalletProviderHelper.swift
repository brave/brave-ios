// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import BraveCore

class WalletProviderHelper: TabContentScript {
    let tab: Tab
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String {
        return "walletProvider"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "walletProvider"
    }
    
    static func shouldInjectWalletProvider(_ completion: @escaping (Bool) -> Void) {
        BraveWallet.KeyringServiceFactory.get(privateMode: false)?
            .keyringInfo(BraveWallet.DefaultKeyringId, completion: { keyring in
                completion(keyring.isKeyringCreated)
            })
    }
    
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        enum MessageAction: String {
            case request
            case isConnected
            case enable
            case send
            case sendAsync
            case isUnlocked
        }
        
        guard let provider = tab.walletProvider,
              !message.frameInfo.securityOrigin.host.isEmpty, // Fail if there is no last committed URL yet
              message.frameInfo.isMainFrame, // Fail the request came from 3p origin
              JSONSerialization.isValidJSONObject(message.body),
              let body = message.body as? NSDictionary,
              let name = body["name"] as? String,
              let jsonPayload = body["args"] as? String,
              let action = MessageAction(rawValue: name) else {
            return
        }
        
        // The web page has communicated with `window.ethereum`, so we should show the wallet icon
        tab.isWalletIconVisible = true
        
        print("[WalletProvider] \(name): \(jsonPayload)")
        
        switch action {
        case .request:
            replyHandler(nil, nil)
            break
//            provider.request(jsonPayload, autoRetryOnNetworkChange: false) { result, string, response in
//                print(result, string, response)
//                replyHandler(string, nil)
//            }
        case .isConnected:
            replyHandler(nil, nil)
            break
        case .enable:
            provider.requestEthereumPermissions { accounts, error, errorMessage in
                if error != .success {
                    replyHandler(nil, errorMessage)
                    return
                }
                
                if accounts.isEmpty {
                    replyHandler(nil, "User rejected the request.")
                } else {
                    replyHandler(accounts, nil)
                }
            }
        case .send:
            replyHandler(nil, nil)
            break
        case .sendAsync:
            replyHandler(nil, nil)
            break
        case .isUnlocked:
            replyHandler(nil, nil)
            break
        }
    }
}
