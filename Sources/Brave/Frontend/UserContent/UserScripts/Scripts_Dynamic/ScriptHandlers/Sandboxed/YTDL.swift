//
//  File.swift
//  
//
//  Created by Brandon on 2023-03-03.
//

import Foundation
import JavaScriptCore
import BraveCore

extension JSContext {
  subscript(key: String) -> Any {
    get {
      return self.objectForKeyedSubscript(key) as Any
    }
    set {
      self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
    }
  }
  
  public static func bind(ctx: JSContext, thisObject: Any?, name: String, callback: @convention(c) (JSContextRef?, JSObjectRef?, JSObjectRef?, Int, UnsafePointer<JSValueRef?>?, UnsafeMutablePointer<JSValueRef?>?) -> JSValueRef?) -> JSValue {
    let funcName = name.isEmpty ? nil : JSStringCreateWithUTF8CString(name)
    let fnPtr = JSObjectMakeFunctionWithCallback(ctx.jsGlobalContextRef, funcName, callback)
    
    if let thisObject = thisObject, let funcName = funcName {
      JSObjectSetProperty(ctx.jsGlobalContextRef, JSValue(object: thisObject, in: ctx).jsValueRef, funcName, fnPtr, JSPropertyAttributes(kJSPropertyAttributeNone), nil)
    }
    
    if let funcName = funcName {
      JSStringRelease(funcName)
    }
    
    return fnPtr != nil ? JSValue(jsValueRef: fnPtr, in: ctx) : JSValue(undefinedIn: ctx)
  }
}

@objc
protocol JSConsoleExports: JSExport {
  static func log(_ msg: Any)
}

@objc
protocol JSURLSearchParamsExports: JSExport {
  func append(name: String, value: Any)
  func delete(name: String)
  func entries() -> [String: String]?
  func get(_ key: String) -> String?
  func set(_ key: String, _ value: String?)
  func toString() -> String
}

@objc
protocol JSURLExports: JSExport {
  var host: String { get }
  var hostname: String { get }
  var href: String { get }
  var origin: String { get }
  var password: String { get }
  var pathname: String { get }
  var port: String { get }
  var `protocol`: String { get }
  var search: String { get }
  var searchParams: JSURLSearchParams? { get }
  var username: String { get }
  func toString() -> String
}

class JSConsole: NSObject, JSConsoleExports {
  class func log(_ msg: Any) {
    print(msg)
  }
}

@objc
protocol JSTimeExports: JSExport {
  func setTimeout(_ callback: JSValue, _ ms: Double) -> String
  func clearTimeout(_ identifier: String)
  func setInterval(_ callback: JSValue, _ ms: Double) -> String
}

@objc
class JSTimer: NSObject, JSTimeExports {
  private var timers = [String: Timer]()

  func clearTimeout(_ identifier: String) {
    let timer = timers.removeValue(forKey: identifier)
    timer?.invalidate()
  }
  
  func setInterval(_ callback: JSValue, _ ms: Double) -> String {
    return createTimer(callback: callback, ms: ms, repeats: true)
  }

  func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
    return createTimer(callback: callback, ms: ms, repeats: false)
  }

  private func createTimer(callback: JSValue, ms: Double, repeats: Bool) -> String {
    let timeInterval  = ms / 1000.0
    let uuid = NSUUID().uuidString
    
    DispatchQueue.main.async(execute: {
      self.timers[uuid] = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: repeats, block: { timer in
        // let callback = timer.userInfo as? JSValue
        callback.call(withArguments: nil)
      })
    })
    return uuid
  }
}

@objc
protocol JSDocumentExports: JSExport {
  var body: Any { get }
  var style: Any? { get set }
  var contentWindow: Any { get }
  func createElement(_ element: String) -> Any
  func appendChild(_ child: Any)
  func removeChild(_ child: Any)
  func evaluateCode(_ dict: Any, _ code: String) -> Any?
}

class JSDocument: JSContext, JSDocumentExports {
  var body: Any { self }
  var style: Any?
  var contentWindow: Any { self }
  
  func createElement(_ element: String) -> Any {
    return self
  }
  
  func appendChild(_ child: Any) {}
  
  func removeChild(_ child: Any) {}
  
  func evaluateCode(_ dict: Any, _ code: String) -> Any? {
    return self.globalObject.invokeMethod("eval.call", withArguments: [dict, code])
  }
}

@objc
protocol JSXMLHttpRequestExports: JSExport {
  var response: Any? { get }
  var responseText: String? { get }
  var responseType: String? { get set }
  var onreadystatechange: JSValue? { get set }
  var onprogress: JSValue? { get set }
  var readyState: Int { get }
  var onload: JSValue? { get set }
  var onerror: JSValue? { get set }
  var status: Int { get }
  var statusText: String { get }
  var responseURL: String? { get }
//  var withCredentials: String? { get }
//  var overrideMimeType: function? { get }
  
  func `open`(_ method: String, _ url: String?, _ isAsync: Bool, _ user: String?, _ password: String?)
  func send(_ data: Any)
  func setRequestHeader(_ name: String, _ value: Any)
  func getAllResponseHeaders() -> String
  func getResponseHeader(_ name: String) -> String
}

@objc
class JSXMLHttpRequest: NSObject, JSXMLHttpRequestExports {
  private enum ReadyState: Int {
    case unsent = 0
    case open = 1
    case headers = 2
    case loading = 3
    case done = 4
  }
  
  private var supportedResponseType = "arraybuffer"
  
  private(set) var response: Any?
  private(set) var responseText: String?
  var responseType: String? {
    get { supportedResponseType }
    set { }
  }
  var onreadystatechange: JSValue?
  var onprogress: JSValue?
  private(set) var readyState: Int
  var onload: JSValue?
  var onerror: JSValue?
  private(set) var status: Int
  private(set) var statusText: String
  private(set) var responseURL: String?
//  private(set) var withCredentials: String?
//  private(set) var overrideMimeType: String?
  
  private var method: String?
  private var url: URL?
  private var isAsync: Bool
  private var headers = [AnyHashable: Any]()
  private var responseHeaders = [AnyHashable: Any]()
  
  override init() {
    readyState = ReadyState.unsent.rawValue
    status = 0
    statusText = ""
    isAsync = false
    super.init()
  }
  
  func `open`(_ method: String, _ url: String?, _ isAsync: Bool, _ user: String?, _ password: String?) {
    self.method = method
    self.url = URL(string: url ?? "")
    self.isAsync = isAsync
    self.readyState = ReadyState.open.rawValue  // TODO: Handle "undefined" user and pass
  }
  
  func send(_ data: Any) {
    let ctx = JSContext.current()
    var request = URLRequest(url: url!)
    
//    request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies(for: url!) ?? [])
    headers.compactMap({ key, value -> (String, String)? in
      guard let key = key as? String else { return nil }
      if let value = value as? JSValue {
        return (key, value.toString())
      }
      
      guard let value = value as? String else { return (key, "") }
      return (key, value)
    }).forEach({ key, value in
      request.setValue(value, forHTTPHeaderField: key)
    })
    
    request.httpBody = data as? Data ?? (data as? String)?.data(using: .utf8)
    request.httpMethod = method
    
    let session = URLSession(configuration: .ephemeral)
    session.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }
      
      self.readyState = ReadyState.loading.rawValue
      self.onreadystatechange?.call(withArguments: nil)
      
      DispatchQueue.main.async {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        if let error = error {
          print(error)
          self.onerror?.call(withArguments: nil)
          return
        }
        
        if httpResponse.statusCode != 200 {
          self.onerror?.call(withArguments: nil)
          return
        }
        
        //self.responseType = "arraybuffer"
        
//        let cookies = HTTPCookie.cookies(withResponseHeaderFields: httpResponse.allHeaderFields as? [String: String] ?? [:], for: httpResponse.url!)
//        HTTPCookieStorage.shared.setCookies(cookies, for: httpResponse.url!, mainDocumentURL: self.url)
        
        switch self.responseType ?? "text" {
        case "text":
          self.response = self.responseText
          
        case "arraybuffer", "moz-chunked-arraybuffer":
          let ptr: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: data!.count)
          data?.withUnsafeBytes { (contentsPtr: UnsafePointer<UInt8>) -> Void in
            _ = ptr.initialize(from: UnsafeBufferPointer(start: contentsPtr, count: data!.count))
          }
          
          var exception: JSValueRef?
          let deallocator: JSTypedArrayBytesDeallocator = { ptr, deallocatorContext in
            ptr?.deallocate()
          }

          let arrayBufferRef = JSObjectMakeArrayBufferWithBytesNoCopy(
              ctx?.jsGlobalContextRef,
              ptr.baseAddress,
              data!.count,
              deallocator,
              nil,
              &exception)
          if let exception = exception {
            print(JSValue(jsValueRef: exception, in: ctx).toString())
          }
          self.response = JSValue(jsValueRef: arrayBufferRef, in: ctx)
          
        case "json":
          self.response = try? JSONSerialization.jsonObject(with: data ?? Data(), options: [.mutableLeaves, .mutableContainers])
          break
          
        default:
          break
        }
        
        self.readyState = ReadyState.done.rawValue
        self.status = httpResponse.statusCode
        self.statusText = String(format: "%ld", httpResponse.statusCode)
        self.responseText = String(data: data ?? Data(), encoding: .utf8)
        self.responseURL = httpResponse.url?.absoluteString ?? ""
        
        self.responseHeaders = httpResponse.allHeaderFields
        self.onprogress?.call(withArguments: nil)
        self.onreadystatechange?.call(withArguments: nil)
        self.onload?.call(withArguments: nil)
      }
    }.resume()
    session.finishTasksAndInvalidate()
  }
  
  func setRequestHeader(_ name: String, _ value: Any) {
    headers[name] = value
  }
  
  func getAllResponseHeaders() -> String {
    var result = ""
    responseHeaders.forEach({ key, value in
      result += "\(key): \(value)\r\n"
    })
    return result
  }
  
  func getResponseHeader(_ name: String) -> String {
    return responseHeaders[name] as? String ?? ""
  }
}

class JSURLSearchParams: NSObject, JSURLSearchParamsExports {
  private weak var url: JSURL?
  
  required init(_ url: JSURL?) {
    self.url = url
  }
  
  func append(name: String, value: Any) {
    url?.value = url?.value?.addingQueryParameter(key: name, value: String(describing: value)) as? NSURL
  }
  
  func delete(name: String) {
    url?.value = url?.value?.replacingQueryParameter(key: name, value: "") as? NSURL
  }
  
  func entries() -> [String: String]? {
    return (url?.value as? URL)?.getQuery()
  }
  
  func get(_ key: String) -> String? {
    return url?.value?.valueForQueryParameter(key: key)
  }
  
  func set(_ key: String, _ value: String?) {
    if let value = value {
      url?.value = url?.value?.replacingQueryParameter(key: key, value: value) as? NSURL
    } else {
      self.delete(name: key)
    }
  }
  
  func toString() -> String {
    if let query = url?.value?.query {
      return query
    }
    return url?.value?.query ?? ""
  }
}

class JSURL: NSObject, JSURLExports {
  var value: NSURL?
  
  required init(ctx: JSContext, url: String, base: String?) {
    if let base = base, base != "undefined" {
      self.value = NSURL(string: url, relativeTo: URL(string: base))
    } else {
      self.value = NSURL(string: url)
    }
    
    super.init()
    
    JSValue(object: self, in: ctx).setValue("", forProperty: "hash")
  }
  
  var host: String {
    return value?.host ?? ""
  }
  
  var hostname: String {
    return value?.host ?? ""
  }
  
  var href: String {
    return value?.absoluteString ?? ""
  }
  
  var origin: String {
    return "\(`protocol`)//\(hostname)"
  }
  
  var password: String {
    return value?.password ?? ""
  }
  
  var pathname: String {
    return value?.path ?? ""
  }
  
  var port: String {
    if let port = value?.port {
      return "\(port)"
    }
    return ""
  }
  
  var `protocol`: String {
    if let scheme = value?.scheme {
      return "\(scheme):"
    }
    return ""
  }
  
  var search: String {
    if let query = value?.query {
      return "?\(query)"
    }
    return ""
  }
  
  var searchParams: JSURLSearchParams? {
    return JSURLSearchParams(self)
  }
  
  var username: String {
    return value?.user ?? ""
  }
  
  var isValid: Bool {
    value != nil
  }
  
  func toString() -> String {
    return value?.absoluteString ?? ""
  }
}

@objc
protocol JSErrorExports: JSExport {
  var value: JSValue { get }
}

class JSError: NSObject, Error, JSErrorExports {
  init(_ value: JSValue) {
    self.value = value
  }
  
  private(set) var value: JSValue
}

extension JSContext {
  private static var timer = JSTimer()
  
  static var plus: JSContext? {
    guard let ctx = JSContext() else {
      return nil
    }
    
    ctx.exceptionHandler = { context, exception in
      print("JS Error: \(String(describing: exception))")
    }
    
    ctx["console"] = JSConsole.self
    ctx["JSError"] = JSError.self
    
    let urlConstructor: @convention(block) (JSValue, JSValue?) -> JSURL = { url, base in
      if base?.isUndefined == true {
        return JSURL(ctx: ctx, url: url.toString(), base: nil)
      }
      return JSURL(ctx: ctx, url: url.toString(), base: base?.toString())
    }
    
    let xmlHttpRequestContructor: @convention(block) () -> JSXMLHttpRequest = {
      return JSXMLHttpRequest()
    }
    
    ctx["window"] = {}
    ctx["__timer__"] = JSContext.timer
    ctx["document"] = JSDocument()
    
    //ctx["__fetch__"] = unsafeBitCast(fetch, to: JSValue.self)  // TODO: Need to support: ReadableStream for `fetch` to work with ytdl

    ctx["URLSearchParams"] = JSURLSearchParams.self
    ctx["URL"] = unsafeBitCast(urlConstructor, to: JSValue.self)
    ctx["XMLHttpRequest"] = unsafeBitCast(xmlHttpRequestContructor, to: JSValue.self)

    ctx.evaluateScript("""
        function setTimeout(callback, ms) {
          return __timer__.setTimeout(callback, ms)
        }

        function clearTimeout(indentifier) {
          __timer__.clearTimeout(indentifier)
        }

        function setInterval(callback, ms) {
          return __timer__.setInterval(callback, ms)
        }
    
        window.setTimeout = setTimeout;
        window.clearTimeout = clearTimeout;
        window.setInterval = setInterval;
        window.Uint8Array = Uint8Array;
        window.URLSearchParams = URLSearchParams;
        window.XMLHttpRequest = XMLHttpRequest;
        window.document = document;
        window.eval = eval;
        window.location = {
          protocol: "https:"
        }
    
        document.eval = function(code) {
          var res = {};
          var keys = Object.keys(document);
          for (const key of keys) {
            res[key] = document[key];
          }
          
          document.evaluateCode(res, code);
        }
    """)
    
    return ctx
  }
}
