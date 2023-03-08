//
//  File.swift
//  
//
//  Created by Brandon on 2023-03-06.
//

import Foundation
import AVFoundation
import MobileCoreServices

private extension URL {
  var withMediaScheme: URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return self
    }
    
    if let scheme = components.scheme {
      components.scheme = "\(scheme)-chunked"
    }
    
    return components.url ?? self
  }
  
  var removingMediaScheme: URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return self
    }
    
    if let scheme = components.scheme {
      components.scheme = scheme.replacingOccurrences(of: "-chunked$", with: "", options: .regularExpression)
    }
    
    return components.url ?? self
  }
}

private protocol MediaRequestProcessor {
  func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest)
}

private class MediaRequest: NSObject, MediaRequestProcessor {
  private var data = Data()
  private let queue = DispatchQueue(label: "com.ranged.media-request", qos: .utility)
  private var loadingRequest: AVAssetResourceLoadingRequest
  private var response: URLResponse?
  
  private lazy var session: URLSession = {
    return URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue().then {
      $0.maxConcurrentOperationCount = 1
    })
  }()
  
  deinit {
    if !loadingRequest.isFinished && !loadingRequest.isCancelled {
      loadingRequest.finishLoading(with: nil)
    }
    
    cancel()
  }
  
  init(request: AVAssetResourceLoadingRequest) {
    self.loadingRequest = request
    guard let url = self.loadingRequest.request.url?.removingMediaScheme else {
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
  
  func cancel() {
    session.invalidateAndCancel()
  }
}

extension MediaRequest: URLSessionTaskDelegate {
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if loadingRequest.isFinished || loadingRequest.isCancelled {
      session.invalidateAndCancel()
      return
    }
    
    if let error = error {
      loadingRequest.finishLoading(with: error)
    } else {
      loadingRequest.finishLoading()
    }
    
    session.finishTasksAndInvalidate()
  }
}

extension MediaRequest: URLSessionDataDelegate {
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.data = data
      self.processRequest(response: self.response, data: self.data, loadingRequest: self.loadingRequest)
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { return }
      
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
      infoRequest.isByteRangeAccessSupported = true

      if let mimeType = response.mimeType {
        infoRequest.contentType = UTType(mimeType: mimeType)?.identifier
      } else {
        infoRequest.contentType = response.mimeType ?? "video/mp4"
      }

      infoRequest.contentLength = response.expectedContentLength
      if let contentRange = ((response as? HTTPURLResponse)?.allHeaderFields["Content-Range"] as? String)?.suffix(while: { return $0 != "/" }) {
        infoRequest.contentLength = Int64(contentRange) ?? response.expectedContentLength
      }

      loadingRequest.dataRequest?.respond(with: data)
      loadingRequest.finishLoading()
    }
  }
}

private class DataRequest: MediaRequest {
  private var totalData = 0
  
  override func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    guard !loadingRequest.isFinished && !loadingRequest.isCancelled else { return }
    if let dataRequest = loadingRequest.dataRequest {
      totalData += data.count
      
      if totalData > 0 {
        dataRequest.respond(with: data)
      }
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
    self.streamURL = url.withMediaScheme
    super.init()
  }
}

extension RangedResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    guard resourceLoader.delegate === self else { return false }
    guard let url = loadingRequest.request.url?.removingMediaScheme else { return false }
    
    if url.isFileURL {
      if loadingRequest.contentInformationRequest != nil {
        self.request = InfoRequest(request: loadingRequest)
      } else {
        guard let dataRequest = loadingRequest.dataRequest else { return false }
        
        let requestedOffset = dataRequest.requestedOffset
        let requestedLength = dataRequest.requestedLength
        
        let chunkSize = 1024 * 1024 * 1024
        let chunks = requestedLength / chunkSize
        let lastChunk = requestedLength % chunkSize
        
        do {
          let fileHandle = try FileHandle(forReadingFrom: url)
          try fileHandle.seek(toOffset: UInt64(requestedOffset))

          for _ in 0..<chunks {
            let data = try fileHandle.read(upToCount: chunkSize)
            dataRequest.respond(with: data!)
          }

          if lastChunk > 0 {
            let data = try fileHandle.read(upToCount: lastChunk)
            dataRequest.respond(with: data!)
          }
          
          try fileHandle.close()
          loadingRequest.finishLoading()
        } catch {
          loadingRequest.finishLoading(with: error)
          return false
        }
      }
      return true
    }

    if loadingRequest.contentInformationRequest != nil {
      self.request = InfoRequest(request: loadingRequest)
    } else {
      self.request = DataRequest(request: loadingRequest)
    }
    
    return true
  }
  
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
    self.request?.cancel()
    self.request = nil
  }
}
