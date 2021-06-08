// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import JavaScriptCore
import WebKit

enum JavascriptError: Error {
    case invalid
}

extension WKUserScript {
    public class func createInDefaultContentWorld(source: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly: Bool) -> WKUserScript {
        if #available(iOS 14.0, *) {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly, in: .defaultClient)
        } else {
            return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
        }
    }
}

public extension WKWebView {
    func generateJavascriptFunctionString(functionName: String, args: [Any], escapeArgs: Bool = true) -> (javascript: String, error: Error?) {
        let context = JSContext()

        var sanitizedArgs: [String] = []
        var error: Error?

        args.forEach {
            
            
            if !escapeArgs {
                sanitizedArgs.append("\($0)")
                return
            }
            
            // :pj: i added it, does not seem to help
            let arg = "\($0)"
                .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
                .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
            
            context?.exceptionHandler = { context, exception in
                if exception != nil {
                    error = JavascriptError.invalid
                }
            }
            context?.evaluateScript("JSON.parse('\"\(arg)\"')")
            sanitizedArgs.append("'\(String(describing: arg).encodingHTMLEntities())'")
            return
        }
        
        return ("\(functionName)(\(sanitizedArgs.joined(separator: ", ")))", error)
    }

    func evaluateSafeJavaScript(functionName: String, args: [Any] = [], sandboxed: Bool = true, escapeArgs: Bool = true, asFunction: Bool = true, completion: ((Any?, Error?) -> Void)? = nil) {
        var javascript = functionName
        
        if asFunction {
            let js = generateJavascriptFunctionString(functionName: functionName, args: args, escapeArgs: escapeArgs)
            if js.error != nil {
                if let completionHandler = completion {
                    completionHandler(nil, js.error)
                }
                return
            }
            javascript = js.javascript
        }
        if #available(iOS 14.0, *), sandboxed {
            // swiftlint:disable:next safe_javascript
            evaluateJavaScript(javascript, in: nil, in: .defaultClient) { result  in
                switch result {
                    case .success(let value):
                        completion?(value, nil)
                    case .failure(let error):
                        completion?(nil, error)
                }
            }
        } else {
            // swiftlint:disable:next safe_javascript
            evaluateJavaScript(javascript) { data, error  in
                completion?(data, error)
            }
        }
    }
}

extension String {
    /// Encode HTMLStrings
    fileprivate func encodingHTMLEntities() -> String {
       return self
        .replacingOccurrences(of: "&", with: "&amp;", options: .literal)
        .replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
        .replacingOccurrences(of: "'", with: "&#39;", options: .literal)
        .replacingOccurrences(of: "<", with: "&lt;", options: .literal)
        .replacingOccurrences(of: ">", with: "&gt;", options: .literal)
        .replacingOccurrences(of: "`", with: "&lsquo;", options: .literal)
    }
}

