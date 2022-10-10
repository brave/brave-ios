/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger

private enum ReaderModeMessageType: String {
  case stateChange = "ReaderModeStateChange"
  case pageEvent = "ReaderPageEvent"
  case contentParsed = "ReaderContentParsed"
}

private enum ReaderPageEvent: String {
  case pageShow = "PageShow"
}

enum ReaderModeState: String {
  case available = "Available"
  case unavailable = "Unavailable"
  case active = "Active"
}

enum ReaderModeTheme: Int {
  case light
  case dark
  case sepia
  case black
  
  var styleName: String {
    switch self {
    case .light:
      return "light"
    case .dark:
      return "dark"
    case .sepia:
      return "sepia"
    case .black:
      return "black"
    }
  }

  var backgroundColor: UIColor {
    switch self {
    case .light:
      return .white
    case .dark:
      return .darkGray
    case .sepia:
      return .init(rgb: 0xf0e6dc)  // Light Beige
    case .black:
      return .black
    }
  }
  
  static var `default`: Self { .light }
}

enum ReaderModeFontType: Int {
  case serif
  case sansSerif
  
  var fontAssetName: String {
    switch self {
    case .serif:
      return "serif"
    case .sansSerif:
      return "sans-serif"
    }
  }
  
  static var `default`: Self { .serif }
}

enum ReaderModeFontSize: Int {
  case size1 = 1
  case size2 = 2
  case size3 = 3
  case size4 = 4
  case size5 = 5
  case size6 = 6
  case size7 = 7
  case size8 = 8
  case size9 = 9
  case size10 = 10
  case size11 = 11
  case size12 = 12
  case size13 = 13

  func isSmallest() -> Bool {
    return self == ReaderModeFontSize.size1
  }

  func smaller() -> ReaderModeFontSize {
    if isSmallest() {
      return self
    } else {
      return ReaderModeFontSize(rawValue: self.rawValue - 1)!
    }
  }

  func isLargest() -> Bool {
    return self == ReaderModeFontSize.size13
  }

  static var `default`: ReaderModeFontSize {
    var category: UIContentSizeCategory?
    DispatchQueue.main.async {
      category = UIApplication.shared.preferredContentSizeCategory
    }
    
    guard let category = category else { return .size5 }
    
    switch category {
    case .extraSmall:
      return .size1
    case .small:
      return .size2
    case .medium:
      return .size3
    case .large:
      return .size5
    case .extraLarge:
      return .size7
    case .extraExtraLarge:
      return .size9
    case .extraExtraExtraLarge:
      return .size12
    default:
      return .size5
    }
  }

  func bigger() -> ReaderModeFontSize {
    if isLargest() {
      return self
    } else {
      return ReaderModeFontSize(rawValue: self.rawValue + 1)!
    }
  }
}

struct ReaderModeStyle {
  var theme: ReaderModeTheme
  var fontType: ReaderModeFontType
  var fontSize: ReaderModeFontSize
  
  /// Converts this structure to a [String: Int] dictionary so it can be saved in Preferences.
  var toPreferences: [String: Int] {
    return ["theme": theme.rawValue,
            "fontType": fontType.rawValue,
            "fontSize": fontSize.rawValue]
  }
  
  static var `default`: Self {
    return .init(theme: ReaderModeTheme.default,
                 fontType: ReaderModeFontType.default,
                 fontSize: ReaderModeFontSize.default)
  }

  /// Encode the style to a JSON dictionary that can be passed to ReaderMode.js
  var asJSON: String {
    let styleJSON =
    """
    { \
    "theme": "\(theme.styleName)", \
    "fontType": "\(fontType.fontAssetName)", \
    "fontSize": "\(fontSize.rawValue)" \
    }
    """
    
    return styleJSON
  }

  /// Encode the style to a dictionary that can be stored in the profile
  func encodeAsDictionary() -> [String: Int] {
    return ["theme": theme.rawValue, "fontType": fontType.rawValue, "fontSize": fontSize.rawValue]
  }

  init(theme: ReaderModeTheme, fontType: ReaderModeFontType, fontSize: ReaderModeFontSize) {
    self.theme = theme
    self.fontType = fontType
    self.fontSize = fontSize
  }
  
  /// Initialize the style from a dictionary,. If the dictionary can't be parsed returns default style settings instead.
  init(dict: [String: Int]) {
    guard let themeRawValue = dict["theme"],
          let fontTypeRawValue = dict["fontType"],
          let fontSizeRawValue = dict["fontSize"],
          let theme = ReaderModeTheme(rawValue: themeRawValue),
          let fontType = ReaderModeFontType(rawValue: fontTypeRawValue),
          let fontSize = ReaderModeFontSize(rawValue: fontSizeRawValue) else {
      
      self.theme = ReaderModeTheme.default
      self.fontType = ReaderModeFontType.default
      self.fontSize = ReaderModeFontSize.`default`
      return
    }

    self.theme = theme
    self.fontType = fontType
    self.fontSize = fontSize
  }
}

/// This struct captures the response from the Readability.js code.
struct ReadabilityResult: Codable {
  let content: String
  let title: String?
  let credits: String?
  
  private enum CodingKeys: String, CodingKey {
    case content
    case title
    case credits = "byline"
  }
  
  /// Returns a ReadabilityResult from a json object.
  static func from(json: Any) -> Self? {
    do {
      let data = try JSONSerialization.data(withJSONObject: json)
      return try JSONDecoder().decode(ReadabilityResult.self, from: data)
    } catch {
      log.warning("Failed to decode ReadabilityResult: \(error)")
      return nil
    }
  }

  /// Returns a ReadabilityResult from a json string.
  static func from(string: String) -> Self? {
    do {
      guard let data = string.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
        return nil
      }
      
      return Self.from(json: object)
    } catch {
      log.error("Failed to initialize json from a string: \(error)")
      return nil
    }
  }

  func toJSONString() -> String? {
    do {
      let data = try JSONEncoder().encode(self)
      guard let json = String(data: data, encoding: .utf8) else {
        return nil
      }
      
      return json
    } catch {
      assertionFailure("Failed to encode readable result data: \(error)")
      return nil
    }
  }
}

/// Delegate that contains callbacks that we have added on top of the built-in WKWebViewDelegate
protocol ReaderModeScriptHandlerDelegate: AnyObject {
  func readerMode(_ readerMode: ReaderModeScriptHandler, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab)
  func readerMode(_ readerMode: ReaderModeScriptHandler, didDisplayReaderizedContentForTab tab: Tab)
  func readerMode(_ readerMode: ReaderModeScriptHandler, didParseReadabilityResult readabilityResult: ReadabilityResult, forTab tab: Tab)
}

let ReaderModeNamespace = "window.__firefox__.reader"

class ReaderModeScriptHandler: TabContentScript {
  weak var delegate: ReaderModeScriptHandlerDelegate?

  fileprivate weak var tab: Tab?
  var state: ReaderModeState = ReaderModeState.unavailable
  fileprivate var originalURL: URL?

  required init(tab: Tab) {
    self.tab = tab
  }
  
  static let scriptName = "ReaderModeScript"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "readerModeMessageHandler"
  static let scriptSandbox: WKContentWorld = .defaultClient
  static let userScript: WKUserScript? = nil

  fileprivate func handleReaderPageEvent(_ readerPageEvent: ReaderPageEvent) {
    switch readerPageEvent {
    case .pageShow:
      if let tab = tab {
        delegate?.readerMode(self, didDisplayReaderizedContentForTab: tab)
      }
    }
  }

  fileprivate func handleReaderModeStateChange(_ state: ReaderModeState) {
    self.state = state
    guard let tab = tab else {
      return
    }
    delegate?.readerMode(self, didChangeReaderModeState: state, forTab: tab)
  }

  fileprivate func handleReaderContentParsed(_ readabilityResult: ReadabilityResult) {
    guard let tab = tab else {
      return
    }
    delegate?.readerMode(self, didParseReadabilityResult: readabilityResult, forTab: tab)
  }

  func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: (Any?, String?) -> Void) {
    defer { replyHandler(nil, nil) }
    
    if !verifyMessage(message: message, securityToken: UserScriptManager.securityToken) {
      assertionFailure("Missing required security token.")
      return
    }
    
    guard let body = message.body as? [String: AnyObject] else {
      return
    }

    if let msg = body["data"] as? Dictionary<String, Any> {
      if let messageType = ReaderModeMessageType(rawValue: msg["Type"] as? String ?? "") {
        switch messageType {
        case .pageEvent:
          if let readerPageEvent = ReaderPageEvent(rawValue: msg["Value"] as? String ?? "Invalid") {
            handleReaderPageEvent(readerPageEvent)
          }
        case .stateChange:
          if let readerModeState = ReaderModeState(rawValue: msg["Value"] as? String ?? "Invalid") {
            handleReaderModeStateChange(readerModeState)
          }
        case .contentParsed:
          guard let json = msg["Value"], let result = ReadabilityResult.from(json: json) else { return }
          handleReaderContentParsed(result)
        }
      }
    }
  }

  var style: ReaderModeStyle = .default {
    didSet {
      if state == ReaderModeState.active {
        tab?.webView?.evaluateSafeJavaScript(functionName: "\(ReaderModeNamespace).setStyle",
                                             args: [style.asJSON],
                                             contentWorld: Self.scriptSandbox,
                                             escapeArgs: false) { (object, error) -> Void in
          return
        }
      }
    }
  }

  static func cache(for tab: Tab?) -> ReaderModeCache {
    switch TabType.of(tab) {
    case .regular:
      return DiskReaderModeCache.sharedInstance
    case .private:
      return MemoryReaderModeCache.sharedInstance
    }
  }

}
