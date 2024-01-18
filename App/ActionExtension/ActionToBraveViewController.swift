// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import os.log

class ActionToBraveViewController: UIViewController {
  private struct Scheme {
    private enum SchemeType {
      case url, query
    }

    private let type: SchemeType
    private let urlOrQuery: String

    init?(item: NSSecureCoding) {
      if let text = item as? String {
        urlOrQuery = text
        type = .query
      } else if let url = (item as? URL)?.absoluteString {
        urlOrQuery = url
        type = .url
      } else {
        return nil
      }
    }

    var schemeUrl: URL? {
      var components = URLComponents()
      let queryItem: URLQueryItem

      components.scheme = Bundle.main.infoDictionary?["BRAVE_URL_SCHEME"] as? String ?? "brave"

      switch type {
      case .url:
        /// The first URL found within this String, or nil if no URL is found
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: urlOrQuery, options: [], range: NSRange(location: 0, length: urlOrQuery.count)),
              let range = Range(match.range, in: urlOrQuery),
              let queryURL = URL(string: String(urlOrQuery[range]))?.absoluteString else {
          
          return nil
        }
        
        components.host = "open-url"
        queryItem = URLQueryItem(name: "url", value: queryURL)
      case .query:
        components.host = "search"
        queryItem = URLQueryItem(name: "q", value: urlOrQuery)
      }

      components.queryItems = [queryItem]
      return components.url
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
      
    // Get the item[s] for handling from the extension context
    for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
      for provider in item.attachments ?? [] {
        
        provider.loadItem(forTypeIdentifier: provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) ?
                          UTType.url.identifier : UTType.text.identifier) { item, error in
          DispatchQueue.main.async {
            guard let item = item, let schemeUrl = Scheme(item: item)?.schemeUrl else {
              self.done()
              return
            }
            
            self.openBrowser(with: schemeUrl)
          }
        }
        
        break
      }
    }
  }

  func done() {
    // Return any edited content to the host app
    // In this case empty
    extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
  }
    
  private func openBrowser(with url: URL) {
    var responder = self as UIResponder?
    
    while let strongResponder = responder {
      let selector = sel_registerName("openURL:")
      if strongResponder.responds(to: selector) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
          Thread.detachNewThreadSelector(selector, toTarget: strongResponder, with: (url as NSURL))
        }
      }
      responder = strongResponder.next
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.done()
    }
  }
}
