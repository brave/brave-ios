// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import WebKit
import MobileCoreServices

private class MimeTypeDetector {
    private(set) var mimeType: String = ""
    private(set) var fileExtension: String = ""
    
    init(data: Data) {
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
        
        mimeType = "application/x-mpegURL"
        fileExtension = "mpg"
    }
    
    private func scan(data: [UInt8], header: [UInt8]) -> Bool {
        if data.count < header.count {
            return false
        }
        
        for i in 0..<header.count {
            if data[i] != header[i] {
                return false
            }
        }
        return true
    }
}

class PlaylistCacheLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionTaskDelegate {
    
    //private lazy var session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
    private var requests = Set<AVAssetResourceLoadingRequest>()
    private var cacheData = Data()
    private(set) var mimeType = String()
    
    override init() {
        super.init()
    }
    
    init(cacheData: Data, mimeType: String? = nil) {
        super.init()
        
        self.cacheData = cacheData
        self.mimeType = mimeType ?? MimeTypeDetector(data: cacheData).mimeType
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        requests.insert(loadingRequest)
        processPendingRequests()
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        requests.remove(loadingRequest)
    }

    func processPendingRequests() {
        let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(requests.compactMap {
            $0.contentInformationRequest?.contentType = self.mimeType
            $0.contentInformationRequest?.contentLength = Int64(self.cacheData.count)
            $0.contentInformationRequest?.isByteRangeAccessSupported = true
            
            if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                $0.finishLoading()
                return $0
            }
            return nil
        })
        
        _ = requestsFulfilled.map { self.requests.remove($0) }

    }
    
    func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let currentOffset = Int(dataRequest.currentOffset)
        let requestedLength = dataRequest.requestedLength
        
        if currentOffset <= cacheData.count {
            let bytesToRespond = min(cacheData.count - currentOffset, requestedLength)
            let data = cacheData.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
            dataRequest.respond(with: data)
            return cacheData.count >= requestedLength + requestedOffset
        }
        
        return false
    }

    private func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        /*if let request = dataTask.originalRequest, let url = request.url, let dataRequest = requests[url]?.dataRequest {
            let neededData = dataRequest.requestedLength - Int(dataRequest.currentOffset)
            if data.count >= neededData {
                if let contentInformationRequest = requests[url]?.contentInformationRequest, let mimeType = dataTask.response?.mimeType {
                    
                    contentInformationRequest.contentLength = dataTask.countOfBytesExpectedToReceive
                    if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() {
                        let contentType = contentType as String
                        contentInformationRequest.contentType = contentType
                        contentInformationRequest.isByteRangeAccessSupported = true
                    }
                    
                    dataRequest.respond(with: data.subdata(in: 0..<neededData + 1))
                }
            } else {
                dataRequest.respond(with: data)
            }
        }*/
    }
}

class PlaylistWebLoader: UIView, WKScriptMessageHandler, WKNavigationDelegate {
    private let webView = BraveWebView(frame: .zero, configuration: WKWebViewConfiguration().then {
        $0.processPool = WKProcessPool()
        
        let script: WKUserScript? = {
            guard let path = Bundle.main.path(forResource: "Playlist", ofType: "js"), let source = try? String(contentsOfFile: path) else {
                return nil
            }
            
            var alteredSource = source
            let token = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)
            alteredSource = alteredSource.replacingOccurrences(of: "$<videosSupportFullscreen>", with: "VSF\(token)", options: .literal)
            
            return WKUserScript(source: alteredSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        }()
        
        if let script = script {
            $0.userContentController.addUserScript(script)
        }
    }, isPrivate: true)
    
    private let handler: (PlaylistInfo?) -> Void
    
    init(handler: @escaping (PlaylistInfo?) -> Void) {
        self.handler = handler
        super.init(frame: .zero)
        self.addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        webView.navigationDelegate = self
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.userContentController.add(self, name: "playlistManager")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(url: URL) {
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0))
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        do {
            guard let item = try PlaylistInfo.from(message: message) else { return }
            if !item.src.isEmpty {
                handler(item)
            }
        } catch {
            handler(nil)
        }
        
        DispatchQueue.main.async {
            self.webView.loadHTMLString("<html><body>PlayList</body></html>", baseURL: nil)
            
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            self.webView.configuration.websiteDataStore.removeData(ofTypes: dataTypes,
                                                              modifiedSince: Date.distantPast,
                                                              completionHandler: {})
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        webView.configuration.websiteDataStore.removeData(ofTypes: dataTypes,
                                                          modifiedSince: Date.distantPast,
                                                          completionHandler: {})
        
        handler(nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        webView.configuration.websiteDataStore.removeData(ofTypes: dataTypes,
                                                          modifiedSince: Date.distantPast,
                                                          completionHandler: {})
    }
}
