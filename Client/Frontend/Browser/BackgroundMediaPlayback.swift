// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared
import WebKit

private let log = Logger.browserLogger

class BackgroundMediaHandler {
    private var canCleanup = false
    private var isActive = false
    private var shutdownRequested = false
    private weak var profile: Profile?
    
    init(profile: Profile) {
        self.profile = profile
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            log.error(error)
        }
    }
    
    deinit {
        deactivateBackgroundPlayback()
    }
    
    func activateBackgroundPlayback() {
        if isActive {
            return
        }
        
        isActive = true
    }
    
    func deactivateBackgroundPlayback() {
        if !isActive {
            return
        }
        
        isActive = false
        
        if shutdownRequested {
            shutdownRequested = false
            
            profile?.shutdown()
        }
    }
    
    func requestShutdown() {
        defer { shutdownRequested = true }
        if isActive {
            return
        }
        
        if UIApplication.shared.applicationState == .background {
            return
        }
        
        profile?.shutdown()
    }
}

class BackgroundMediaPlayback: TabContentScript {
    fileprivate weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String {
        return "BackgroundMediaPlayback"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "backgroundMediaPlayback"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let response = message.body as? String {
            debugPrint(response)
            log.info(response)
        } else {
            log.info(message.description)
        }
    }
}
