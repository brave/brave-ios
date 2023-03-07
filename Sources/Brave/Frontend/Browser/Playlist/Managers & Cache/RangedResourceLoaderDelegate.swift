//
//  File.swift
//  
//
//  Created by Brandon on 2023-03-06.
//

import Foundation
import AVFoundation
import MobileCoreServices

private protocol MediaRequestProcessor {
  func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest)
}

private class MediaRequest: NSObject, MediaRequestProcessor {
  private var data = Data()
  var totalData = Data()
  private let queue = DispatchQueue(label: "com.ranged.media-request", qos: .utility)
  private var loadingRequest: AVAssetResourceLoadingRequest
  private var response: URLResponse?
  
  private lazy var session: URLSession = {
    return URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue().then {
      $0.maxConcurrentOperationCount = 1
    })
  }()
  
  deinit {
    session.finishTasksAndInvalidate()
  }
  
  init(request: AVAssetResourceLoadingRequest) {
    self.loadingRequest = request
    guard let requestURL = loadingRequest.request.url,
          var components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
      super.init()
      return
    }
    
    components.scheme = String("\(components.scheme ?? "")".prefix(while: { $0 != "-" }))
    guard let url = components.url else {
      super.init()
      return
    }
    
    let offset = loadingRequest.dataRequest?.requestedOffset ?? 0
    let length = Int64(loadingRequest.dataRequest?.requestedLength ?? 1)
    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
    request.setValue("bytes=\(offset)-\(offset + length - 1)", forHTTPHeaderField: "Range")
    loadingRequest.request.allHTTPHeaderFields?.forEach({
      request.setValue($0.value, forHTTPHeaderField: $0.key)
    })
    
    super.init()
    session.dataTask(with: request).resume()
  }

  func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    fatalError("NOT IMPLEMENTED!")
  }
}

extension MediaRequest: URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if !loadingRequest.isFinished && !loadingRequest.isCancelled {
      loadingRequest.finishLoading(with: error)
    }
    
    if let error = error {
      print(error)
      session.invalidateAndCancel()
    } else {
      session.finishTasksAndInvalidate()
    }
  }
}

extension MediaRequest: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    queue.sync {
      self.data = data
      self.totalData.append(data)
      self.processRequest(response: self.response, data: self.data, loadingRequest: self.loadingRequest)
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    queue.sync {
      self.response = response
      self.processRequest(response: self.response, data: self.data, loadingRequest: self.loadingRequest)
    }
    completionHandler(.allow)
  }
}

private class InfoRequest: MediaRequest {
  override func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    guard !loadingRequest.isFinished && !loadingRequest.isCancelled else { return }
    if let infoRequest = loadingRequest.contentInformationRequest, let response = response {
      loadingRequest.response = response

      if let mimeType = response.mimeType {
        infoRequest.contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() as? String
      }

      if infoRequest.contentType == nil {
        infoRequest.contentType = response.mimeType ?? "video/mp4"
      }
      infoRequest.contentLength = response.expectedContentLength
      infoRequest.isByteRangeAccessSupported = true

      if let contentRange = ((response as? HTTPURLResponse)?.allHeaderFields["Content-Range"] as? String)?.suffix(while: { return $0 != "/" }) {
        infoRequest.contentLength = Int64(contentRange) ?? response.expectedContentLength
      }

      loadingRequest.dataRequest?.respond(with: data)
      loadingRequest.finishLoading()
    }
  }
}

private class DataRequest: MediaRequest {
  override func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    guard !loadingRequest.isFinished && !loadingRequest.isCancelled else { return }
    if let dataRequest = loadingRequest.dataRequest {
      dataRequest.respond(with: data)
      
//      if respond(to: dataRequest) {
//        loadingRequest.finishLoading()
//      }
    }
  }
}

class RangedResourceLoaderDelegate: NSObject {
  private static let scheme = "chunked"
  private let url: URL
  public let streamURL: URL
  private var request: MediaRequest?
  
  let queue = DispatchQueue(label: "com.ranged.resource-delegate", qos: .utility)
  private var requests = [AVAssetResourceLoadingRequest]()

  init(url: URL) {
    self.url = url

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      self.streamURL = url
      super.init()
      return
    }

    components.scheme = "\(components.scheme ?? "")-\(Self.scheme)"
    guard let streamURL = components.url else {
      self.streamURL = url
      super.init()
      return
    }

    self.streamURL = streamURL
    super.init()
  }
}

extension RangedResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    guard resourceLoader.delegate === self else { return false }

    if loadingRequest.contentInformationRequest != nil {
      self.request = InfoRequest(request: loadingRequest)
    } else {
      self.request = DataRequest(request: loadingRequest)
    }
    
    return true
  }
  
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
    guard let index = self.requests.firstIndex(of: loadingRequest) else { return }
    self.requests.remove(at: index)
  }
}
