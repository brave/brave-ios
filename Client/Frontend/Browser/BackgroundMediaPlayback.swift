// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import Shared
import BraveShared
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
    private weak var tab: Tab?
    
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
    
    static func pauseAllMedia(for webview: WKWebView) {
        let token = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
        webview.evaluateJavaScript("BMPC\(token).pauseAllVideos()", completionHandler: nil)
    }
    
    static func didEnterBackround(for webview: WKWebView) {
        let token = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
        webview.evaluateJavaScript("BMPC\(token).didEnterBackground()", completionHandler: nil)
    }
    
    static func setMediaBackgroundPlayback(for webview: WKWebView) {
        let isBackgroundPlaybackEnabled = Preferences.General.allowBackgroundMediaPlayback.value
        
        let token = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
        webview.evaluateJavaScript("BMPC\(token).setBackgroundMediaPlayback(\(isBackgroundPlaybackEnabled));", completionHandler: nil)
    }
}
