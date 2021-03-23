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

// IANA List of Audio types: https://www.iana.org/assignments/media-types/media-types.xhtml#audio
// IANA List of Video types: https://www.iana.org/assignments/media-types/media-types.xhtml#video
// APPLE List of UTI types: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

public class PlaylistMimeTypeDetector {
    private(set) var mimeType: String?
    private(set) var fileExtension: String? // When nil, assume `mpg` format.
    
    init(url: URL) {
        let possibleFileExtension = url.pathExtension
        if let supportedExtension = knownFileExtensions.first(where: { $0.lowercased() == possibleFileExtension }) {
            self.fileExtension = supportedExtension
            self.mimeType = mimeTypeMap.first(where: { $0.value == supportedExtension })?.key
        }
    }
    
    init(mimeType: String) {
        self.mimeType = mimeType
        self.fileExtension = mimeTypeMap[mimeType.lowercased()]
    }
    
    init(data: Data) {
        // Assume mpg by default. If it can't play, it will fail anyway..
        // AVPlayer REQUIRES that you give a file extension no matter what and will refuse to determine the extension for you without an
        // AVResourceLoaderDelegate :S
        
        if findHeader(offset: 0, data: data, header: [0x1A, 0x45, 0xDF, 0xA3]) {
            mimeType = "video/webm"
            fileExtension = "webm"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x1A, 0x45, 0xDF, 0xA3]) {
            mimeType = "video/matroska"
            fileExtension = "mkv"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x4F, 0x67, 0x67, 0x53]) {
            mimeType = "application/ogg"
            fileExtension = "ogg"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x52, 0x49, 0x46, 0x46]) &&
            findHeader(offset: 8, data: data, header: [0x57, 0x41, 0x56, 0x45]) {
            mimeType = "audio/x-wav"
            fileExtension = "wav"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0xFF, 0xFB]) ||
            findHeader(offset: 0, data: data, header: [0x49, 0x44, 0x33]) {
            mimeType = "audio/mpeg"
            fileExtension = "mp4"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x66, 0x4C, 0x61, 0x43]) {
            mimeType = "audio/flac"
            fileExtension = "flac"
            return
        }
        
        if findHeader(offset: 4, data: data, header: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x53, 0x4E, 0x56]) ||
            findHeader(offset: 4, data: data, header: [0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6F, 0x6D]) ||
            findHeader(offset: 4, data: data, header: [0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32]) ||
            findHeader(offset: 0, data: data, header: [0x33, 0x67, 0x70, 0x35]) {
            mimeType = "video/mp4"
            fileExtension = "mp4"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x00, 0x00, 0x00, 0x1C, 0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x56]) {
            mimeType = "video/x-m4v"
            fileExtension = "m4v"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70]) {
            mimeType = "video/quicktime"
            fileExtension = "mov"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x52, 0x49, 0x46, 0x46]) &&
            findHeader(offset: 8, data: data, header: [0x41, 0x56, 0x49]) {
            mimeType = "video/x-msvideo"
            fileExtension = "avi"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9]) {
            mimeType = "video/x-ms-wmv"
            fileExtension = "wmv"
            return
        }
        
        // Maybe
        if findHeader(offset: 0, data: data, header: [0x00, 0x00, 0x01]) {
            mimeType = "video/mpeg"
            fileExtension = "mpg"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x49, 0x44, 0x33]) ||
            findHeader(offset: 0, data: data, header: [0xFF, 0xFB]) {
            mimeType = "audio/mpeg"
            fileExtension = "mp3"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x4D, 0x34, 0x41, 0x20]) ||
            findHeader(offset: 4, data: data, header: [0x66, 0x74, 0x79, 0x70, 0x4D, 0x34, 0x41]) {
            mimeType = "audio/m4a"
            fileExtension = "m4a"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x23, 0x21, 0x41, 0x4D, 0x52, 0x0A]) {
            mimeType = "audio/amr"
            fileExtension = "amr"
            return
        }
        
        if findHeader(offset: 0, data: data, header: [0x46, 0x4C, 0x56, 0x01]) {
            mimeType = "video/x-flv"
            fileExtension = "flv"
            return
        }
        
        mimeType = "application/x-mpegURL" // application/vnd.apple.mpegurl
        fileExtension = nil
    }
    
    private func findHeader(offset: Int, data: Data, header: [UInt8]) -> Bool {
        if offset < 0 || data.count < offset + header.count {
            return false
        }
        
        return [UInt8](data[offset..<(offset + header.count)]) == header
    }
    
    public func supportedAudioFileTypes() -> [String] {
        return AVURLAsset.audiovisualTypes().map({ $0.rawValue })
    }
    
    public func supportedAudioMimeTypes() -> [String] {
        return AVURLAsset.audiovisualMIMETypes()
    }
    
    private let knownFileExtensions = [
        "mov",
        "qt",
        "mp4",
        "m4v",
        "m4a",
        "m4b", // DRM protected
        "m4p", // DRM protected
        "3gp",
        "3gpp",
        "sdv",
        "3g2",
        "3gp2",
        "caf",
        "wav",
        "wave",
        "bwf",
        "aif",
        "aiff",
        "aifc",
        "cdda",
        "amr",
        "mp3",
        "au",
        "snd",
        "ac3",
        "eac3",
        "flac",
        "aac",
        "mp2",
        "pls",
        "avi",
        "webm",
        "ogg",
        "mpg",
        "mpg4",
        "mpeg",
        "mpg3",
        "wma",
        "wmv",
        "swf",
        "flv",
        "mng",
        "asx",
        "asf",
        "mkv"
    ]
    
    private let mimeTypeMap = [
        "audio/x-wav": "wav",
        "audio/vnd.wave": "wav",
        "audio/aacp": "aacp",
        "audio/mpeg3": "mp3",
        "audio/mp3": "mp3",
        "audio/x-caf": "caf",
        "audio/mpeg": "mp3", //mpg3
        "audio/x-mpeg3": "mp3",
        "audio/wav": "wav",
        "audio/flac": "flac",
        "audio/x-flac": "flac",
        "audio/mp4": "mp4",
        "audio/x-mpg": "mp3", //maybe mpg3
        "audio/scpls": "pls",
        "audio/x-aiff": "aiff",
        "audio/usac": "eac3",  // Extended AC3
        "audio/x-mpeg": "mp3",
        "audio/wave": "wav",
        "audio/x-m4r": "m4r",
        "audio/x-mp3": "mp3",
        "audio/amr": "amr",
        "audio/aiff": "aiff",
        "audio/3gpp2": "3gp2",
        "audio/aac": "aac",
        "audio/mpg": "mp3", //mpg3
        "audio/mpegurl": "mpg", // actually .m3u8, .m3u HLS stream
        "audio/x-m4b": "m4b",
        "audio/x-m4p": "m4p",
        "audio/x-scpls": "pls",
        "audio/x-mpegurl": "mpg", // actually .m3u8, .m3u HLS stream
        "audio/x-aac": "aac",
        "audio/3gpp": "3gp",
        "audio/basic": "au",
        "audio/au": "au",
        "audio/snd": "snd",
        "audio/x-m4a": "m4a",
        "audio/x-realaudio": "ra",
        "video/3gpp2": "3gp2",
        "video/quicktime": "mov",
        "video/mp4": "mp4",
        "video/mp4v": "mp4",
        "video/mpg": "mpg",
        "video/mpeg": "mpeg",
        "video/x-mpg": "mpg",
        "video/x-mpeg": "mpeg",
        "video/avi": "avi",
        "video/x-m4v": "m4v",
        "video/mp2t": "ts",
        "application/vnd.apple.mpegurl": "mpg", // actually .m3u8, .m3u HLS stream
        "video/3gpp": "3gp",
        "text/vtt": "vtt",  // Subtitles format
        "application/mp4": "mp4",
        "application/x-mpegurl": "mpg", // actually .m3u8, .m3u HLS stream
        "video/webm": "webm",
        "application/ogg": "ogg",
        "video/msvideo": "avi",
        "video/x-msvideo": "avi",
        "video/x-ms-wmv": "wmv",
        "video/x-ms-wma": "wma",
        "application/x-shockwave-flash": "swf",
        "video/x-flv": "flv",
        "video/x-mng": "mng",
        "video/x-ms-asx": "asx",
        "video/x-ms-asf": "asf",
        "video/matroska": "mkv"
    ]
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
