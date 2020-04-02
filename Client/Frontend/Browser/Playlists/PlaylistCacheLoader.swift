// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation
import WebKit
import MobileCoreServices

class PlaylistCacheLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionTaskDelegate {
    
    private lazy var session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: .main)
    private var requests = [URL: AVAssetResourceLoadingRequest]()
    private var tasks = [URL: URLSessionDataTask]()
    private var cacheData = Data()
    
    override init() {
        super.init()
    }
    
    init(cacheData: Data) {
        self.cacheData = cacheData
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        if let url = loadingRequest.request.url {
            if !cacheData.isEmpty {
                loadingRequest.dataRequest?.respond(with: cacheData)
                loadingRequest.finishLoading()
                return true
            }
            
            let cache = Playlist.shared.getCache(item: PlaylistInfo(name: "", src: url.absoluteString, pageSrc: url.absoluteString, pageTitle: "", duration: 0.0))
            if !cache.isEmpty {
                loadingRequest.dataRequest?.respond(with: cache)
                loadingRequest.finishLoading()
                return true
            }
            
            requests.updateValue(loadingRequest, forKey: url)
            let task = session.dataTask(with: loadingRequest.request)
            tasks.updateValue(task, forKey: url)
            task.resume()
            return true
        }

        return false
    }
    
    private func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }

    private func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let request = dataTask.originalRequest, let url = request.url, let dataRequest = requests[url]?.dataRequest {
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
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let request = task.originalRequest, let url = request.url, let dataRequest = requests[url] {
            dataRequest.finishLoading(with: error)
        }
    }
}

class PlaylistWebLoader: UIView, WKScriptMessageHandler, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration().then {
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
    })
    
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
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handler(nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}
