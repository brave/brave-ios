// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import WebKit
import MobileCoreServices
import YubiKit
import Data

public class PlaylistMimeTypeDetector {
    private(set) var mimeType: String = ""
    private(set) var fileExtension: String = ""
    
    init(mimeType: String) {
        self.mimeType = mimeType
        
        let mimeTypeMap = [
            "video/webm": "webm",
            "application/ogg": "ogg",
            "audio/x-wav": "wav",
            "video/x-msvideo": "avi",
            "audio/mpeg": "mp4",
            "audio/flac": "flac",
            "video/mp4": "mp4",
            "application/x-mpegURL": "mpg",
            "application/vnd.apple.mpegurl": "mpg"
        ]
        
        self.fileExtension = mimeTypeMap[mimeType] ?? "mpg"
    }
    
    init(data: Data) {
        // Assume mpg by default. If it can't play, it will fail anyway..
        // AVPlayer REQUIRES that you give a file extension no matter what and will refuse to determine the extension for you without an
        // AVResourceLoaderDelegate :S
        
        guard data.count > 4 else {
            mimeType = "application/x-mpegURL" // application/vnd.apple.mpegurl
            fileExtension = "mpg"
            return
        }
        
        let bytes = [UInt8](data)
        if scan(data: bytes, header: [0x1A, 0x45, 0xDF, 0xA3]) {
            mimeType = "video/webm"
            fileExtension = "webm"
            return
        }
        
        if scan(data: bytes, header: [0x4F, 0x67, 0x67, 0x53]) {
            mimeType = "application/ogg"
            fileExtension = "ogg"
            return
        }
        
        if scan(data: bytes, header: [0x52, 0x49, 0x46, 0x46]) {
            if [UInt8](data.subdata(in: 4..<5))[0] == 57 {
                mimeType = "audio/x-wav"
                fileExtension = "wav"
            } else {
                mimeType = "video/x-msvideo"
                fileExtension = "avi"
            }
            return
        }
        
        if scan(data: bytes, header: [0xFF, 0xFB]) || scan(data: bytes, header: [0x49, 0x44, 0x33]) {
            mimeType = "audio/mpeg"
            fileExtension = "mp4"
            return
        }
        
        if scan(data: bytes, header: [0x49, 0x44, 0x33]) {
            mimeType = "audio/mpeg"
            fileExtension = "mp4"
            return
        }
        
        if scan(data: bytes, header: [0x66, 0x4C, 0x61, 0x43]) {
            mimeType = "audio/flac"
            fileExtension = "flac"
            return
        }
        
        if scan(data: [UInt8](bytes[4..<bytes.count]), header: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56]) {
            mimeType = "video/mp4"
            fileExtension = "mp4"
            return
        }
        
        if scan(data: [UInt8](bytes[4..<bytes.count]), header: [0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D]) {
            mimeType = "video/mp4"
            fileExtension = "mp4"
            return
        }
        
        if scan(data: [UInt8](bytes[4..<bytes.count]), header: [0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32]) {
            mimeType = "video/mp4"
            fileExtension = "mp4"
            return
        }
        
        mimeType = "application/x-mpegURL" // application/vnd.apple.mpegurl
        fileExtension = "mpg"
    }
    
    private func scan(data: [UInt8], header: [UInt8]) -> Bool {
        if data.count < header.count {
            return false
        }
        
        for i in 0..<header.count where data[i] != header[i] {
            return false
        }
        return true
    }
}

class PlaylistWebLoader: UIView, WKNavigationDelegate {
    private let tab = Tab(configuration: WKWebViewConfiguration().then {
        $0.processPool = WKProcessPool()
        $0.preferences = WKPreferences()
        $0.preferences.javaScriptCanOpenWindowsAutomatically = false
        $0.allowsInlineMediaPlayback = true
        $0.ignoresViewportScaleLimits = true
        $0.mediaTypesRequiringUserActionForPlayback = []
    }, type: .private).then {
        $0.createWebview()
        $0.webView?.scrollView.layer.masksToBounds = true
    }
    
    private var handler: (PlaylistInfo?) -> Void = { _ in }
    private var handlerDidExecute = false
    
    init(handler: @escaping (PlaylistInfo?) -> Void) {
        super.init(frame: .zero)

        guard let webView = tab.webView else {
            handlerDidExecute = true
            handler(nil)
            return
        }
        
        self.handler = { [weak self] in
            self?.handlerDidExecute = true
            handler($0)
        }
        
        self.addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        webView.navigationDelegate = self
        tab.contentBlocker.setupTabTrackingProtection()
        tab.addContentScript(tab.contentBlocker, name: ContentBlockerHelper.name(), sandboxed: false)
        tab.addContentScript(FingerprintingProtection(tab: tab), name: FingerprintingProtection.name(), sandboxed: false)
        tab.addContentScript(WindowRenderHelperScript(tab: tab), name: WindowRenderHelperScript.name(), sandboxed: false)
        tab.addContentScript(PlaylistHelper(tab: tab), name: PlaylistHelper.name(), sandboxed: false)
        tab.addContentScript(PlaylistWebLoaderContentHelper(self), name: PlaylistWebLoaderContentHelper.name(), sandboxed: false)
        
        let script: WKUserScript? = {
            guard let path = Bundle.main.path(forResource: "PlaylistDetector", ofType: "js"), let source = try? String(contentsOfFile: path) else {
                return nil
            }

            return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }()
        
        if let script = script {
            tab.webView?.configuration.userContentController.addUserScript(script)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeFromSuperview()
    }
    
    func load(url: URL) {
        guard let webView = tab.webView else { return }
        webView.frame = self.window?.bounds ?? .zero
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0))
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.handler(nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Fail safe for if a script fails or web-view somehow fails to load,
        // Then we have a timeout where it will notify the playlist that an error occurred
        // This happens when the WebView is already finished loading anyway!
        // We use a 30-second timeout because it isn't possible to know when a page is FULL loaded..
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if !self.handlerDidExecute {
                self.handler(nil)
            }
        }
    }
    
    private class PlaylistWebLoaderContentHelper: TabContentScript {
        private weak var webLoader: PlaylistWebLoader?
        private var playlistItems = Set<String>()
        
        init(_ webLoader: PlaylistWebLoader) {
            self.webLoader = webLoader
        }
        
        static func name() -> String {
            return "PlaylistWebLoader"
        }
        
        func scriptMessageHandlerName() -> String? {
            return "playlistCacheLoader"
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
            guard let item = PlaylistInfo.from(message: message),
                  item.detected else {
                webLoader?.handler(nil)
                return
            }
            
            // For now, we ignore base64 video mime-types loaded via the `data:` scheme.
            if item.duration <= 0.0 && !item.detected || item.src.isEmpty || item.src.hasPrefix("data:") || item.src.hasPrefix("blob:") {
                webLoader?.handler(nil)
                return
            }
            
            // We have to create an AVURLAsset here to determine if the item is playable
            // because otherwise it will add an invalid item to playlist that can't be played.
            // IE: WebM videos aren't supported so can't be played.
            // Therefore we shouldn't prompt the user to add to playlist.
            if let url = URL(string: item.src), !AVURLAsset(url: url).isPlayable {
                webLoader?.handler(nil)
                return
            }
            
            if !playlistItems.contains(item.src) {
                playlistItems.insert(item.src)
                
                webLoader?.handler(item)
            }
            
            // This line MAY cause problems.. because some websites have a loading delay for the source of the media item
            // If the second we receive the src, we reload the page by doing the below HTML,
            // It may not have received all info necessary to play the item such as MetadataInfo
            // For now it works 100% of the time and it is safe to do it. If we come across such a website, that causes problems,
            // we'll need to find a different way of forcing the WebView to STOP loading metadata in the background
            DispatchQueue.main.async {
                self.webLoader?.tab.webView?.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
            }
        }
    }
}
