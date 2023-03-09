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

private class Session: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
  private let queue = DispatchQueue(label: "com.ranged.media-session", qos: .utility)
  private lazy var session: URLSession = {
    return URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue().then {
      $0.maxConcurrentOperationCount = 1
    })
  }()
  
  private class Request {
    private(set) var processor: (Data, URLResponse?, Error?) -> Void
    private(set) var response: URLResponse?
    private(set) var data: Data
    
    init(processor: @escaping (Data, URLResponse?, Error?) -> Void) {
      self.processor = processor
      self.response = nil
      self.data = Data()
    }
    
    func addData(_ data: Data) {
      self.data.append(data)
      processor(data, response, nil)
    }
    
    func addResponse(_ response: URLResponse) {
      self.response = response
      processor(data, response, nil)
    }
    
    func finish(with error: Error?) {
      processor(Data(), nil, error)
    }
  }
  
  private var tasks = [URLSessionTask: Request]()
  
  private override init() {
    super.init()
  }
  
  static let shared = Session()
  
  func removeAll() {
    queue.sync { [weak self] in
      guard let self = self else { return }
      self.tasks.forEach({
        $0.value.finish(with: nil)
      })
      
      self.tasks = [:]
    }
  }
  
  func addRequest(_ request: URLRequest, processor: @escaping (Data, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
    queue.sync { [weak self] in
      guard let self = self else { return nil }
      let task = self.session.dataTask(with: request)
      self.tasks[task] = Request(processor: processor)
      task.resume()
      return task
    }
  }
  
  func removeRequest(_ task: URLSessionDataTask) {
    queue.sync { [weak self] in
      guard let self = self else { return }
      self.tasks.removeValue(forKey: task)
      task.cancel()
    }
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    queue.async { [weak self] in
      guard let self = self else { return }
      if let request = self.tasks.removeValue(forKey: task) {
        request.finish(with: error)
      }
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    queue.async { [weak self] in
      guard let self = self else { return }
      if let request = self.tasks[dataTask] {
        request.addData(data)
      }
    }
  }
  
  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { return }
      if let request = self.tasks[dataTask] {
        request.addResponse(response)
      }
      
      completionHandler(.allow)
    }
  }
}

private class MediaRequest: NSObject, MediaRequestProcessor {
  private let queue = DispatchQueue(label: "com.ranged.media-request", qos: .utility)
  private var loadingRequest: AVAssetResourceLoadingRequest
  private var task: URLSessionDataTask?
  
  private let dateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    return dateFormatter
  }()
  
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
    
    if (url as NSURL).valueForQueryParameter(key: "clen") != nil, length != 2 {
      request.url = (url as NSURL).replacingQueryParameter(key: "range", value: "\(offset)-\(offset + length - 1)")
    }
    
    super.init()
    
    self.task = Session.shared.addRequest(request, processor: { [weak self] data, response, error in
      guard let self = self else { return }
      self.queue.async {
        if response == nil {
          self.finish(with: error)
          return
        }
        
        self.processRequest(response: response, data: data, loadingRequest: self.loadingRequest)
      }
    })
  }
  
  deinit {
    if !loadingRequest.isFinished && !loadingRequest.isCancelled {
      loadingRequest.finishLoading(with: nil)
    }
    
    if let task = task {
      Session.shared.removeRequest(task)
    }
  }

  func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    fatalError("NOT IMPLEMENTED!")
  }
  
  private func finish(with error: Error?) {
    if loadingRequest.isFinished || loadingRequest.isCancelled {
      return
    }
    
    if let error = error {
      loadingRequest.finishLoading(with: error)
    } else {
      loadingRequest.finishLoading()
    }
  }
  
  func format(date: String) -> Date? {
    return dateFormatter.date(from: date)
  }
  
  func isSame(as request: AVAssetResourceLoadingRequest) -> Bool {
    return loadingRequest === request
  }
}

private class InfoRequest: MediaRequest {
  override func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    guard !loadingRequest.isFinished && !loadingRequest.isCancelled && data.count > 0 else { return }
    
    if let infoRequest = loadingRequest.contentInformationRequest, let response = response {
      loadingRequest.response = response
      infoRequest.isByteRangeAccessSupported = false
      infoRequest.contentLength = response.expectedContentLength
      
      if #available(iOS 16.0, *) {
        infoRequest.isEntireLengthAvailableOnDemand = false
      }

      if let mimeType = response.mimeType {
        infoRequest.contentType = UTType(mimeType: mimeType)?.identifier
      } else {
        infoRequest.contentType = response.mimeType ?? "video/mp4"
      }

      if let response = response as? HTTPURLResponse {
        if let contentRange = response.value(forHTTPHeaderField: "Content-Range")?.suffix(while: { $0 != "/" }),
           let contentLength = Int64(contentRange) {
          infoRequest.contentLength = contentLength
        }
        
        if let expires = response.value(forHTTPHeaderField: "Expires") {
          infoRequest.renewalDate = format(date: expires)
        }
        
        if let acceptRanges = response.value(forHTTPHeaderField: "Accept-Ranges") {
          infoRequest.isByteRangeAccessSupported = acceptRanges == "bytes"
        }
        
        loadingRequest.dataRequest?.respond(with: data)
      } else {
        let offset = Int(loadingRequest.dataRequest?.requestedOffset ?? 0)
        let length = loadingRequest.dataRequest?.requestedLength ?? 0
        
        loadingRequest.dataRequest?.respond(with: data.subdata(in: offset..<(offset + length - 1)))
        loadingRequest.finishLoading()
      }
    }
  }
}

private class DataRequest: MediaRequest {
  private var totalData = 0
  
  override func processRequest(response: URLResponse?, data: Data, loadingRequest: AVAssetResourceLoadingRequest) {
    totalData += data.count
    guard !loadingRequest.isFinished && !loadingRequest.isCancelled, data.count > 0 else { return }
    
    if let dataRequest = loadingRequest.dataRequest {
      dataRequest.respond(with: data)

      if totalData >= dataRequest.requestedLength {
        loadingRequest.finishLoading()
      }
    }
  }
}

class RangedResourceLoaderDelegate: NSObject {
  private static let scheme = "chunked"
  private let url: URL
  public let streamURL: URL
  private var requests = [MediaRequest]()
  
  let queue = DispatchQueue(label: "com.ranged.resource-delegate", qos: .utility)

  init(url: URL) {
    self.url = url
    self.streamURL = url.withMediaScheme
    super.init()
  }
  
  static func destroy() {
    Session.shared.removeAll()
  }
}

extension RangedResourceLoaderDelegate: AVAssetResourceLoaderDelegate {
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    guard resourceLoader.delegate === self else { return false }
    guard let url = loadingRequest.request.url?.removingMediaScheme else { return false }
    
    if url.isFileURL {
      if loadingRequest.contentInformationRequest != nil {
        requests.append(InfoRequest(request: loadingRequest))
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
      requests.append(InfoRequest(request: loadingRequest))
    } else {
      requests.append(DataRequest(request: loadingRequest))
    }
    
    return true
  }
  
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
    return false
  }
  
  func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
    requests.removeAll(where: { $0.isSame(as: loadingRequest) })
  }
}
