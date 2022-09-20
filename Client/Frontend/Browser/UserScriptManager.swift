/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Data
import BraveCore
import BraveShared

private let log = Logger.browserLogger

class UserScriptManager {

  // Scripts can use this to verify the app –not js on the page– is calling into them.
  private static let securityToken = UUID()

  // Ensures that the message handlers cannot be invoked by the page scripts
  private static let messageHandlerToken = UUID()

  // String representation of messageHandlerToken
  public static let messageHandlerTokenString = UserScriptManager.messageHandlerToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)

  // String representation of securityToken
  public static let securityTokenString = UserScriptManager.securityToken.uuidString.replacingOccurrences(of: "-", with: "", options: .literal)

  private weak var tab: Tab?

  /// Whether cookie blocking is enabled
  var isCookieBlockingEnabled: Bool {
    didSet {
      if oldValue == isCookieBlockingEnabled { return }
      reloadUserScripts()
    }
  }

  /// Whether or not Playlist is enabled
  var isPlaylistEnabled: Bool {
    didSet {
      if oldValue == isPlaylistEnabled { return }
      reloadUserScripts()
    }
  }

  /// Whether or not the MediaSource API should be disabled for Playlists
  var isWebCompatibilityMediaSourceAPIEnabled: Bool {
    didSet {
      if oldValue == isWebCompatibilityMediaSourceAPIEnabled { return }
      reloadUserScripts()
    }
  }

  /// Whether or not the Media Background Playback is enabled
  var isMediaBackgroundPlaybackEnabled: Bool {
    didSet {
      if oldValue == isMediaBackgroundPlaybackEnabled { return }
      reloadUserScripts()
    }
  }

  /// Whether night mode is enabled for webview
  var isNightModeEnabled: Bool {
    didSet {
      if oldValue == isNightModeEnabled { return }
      reloadUserScripts()
    }
  }
  
  /// Whether deamp is enabled for webview
  var isDeAMPEnabled: Bool {
    didSet {
      guard oldValue != isDeAMPEnabled else { return }
      reloadUserScripts()
    }
  }
  
  /// Whether request blocking is enabled for webview
  var isRequestBlockingEnabled: Bool {
    didSet {
      guard oldValue != isRequestBlockingEnabled else { return }
      reloadUserScripts()
    }
  }

  // TODO: @JS Add other scripts to this list to avoid uneccesary calls to `reloadUserScripts()`
  /// Domain script types that are currently injected into the web-view. Will reloaded scripts if this set changes.
  ///
  /// We only `reloadUserScripts()` if any of these have changed. A set is used to ignore order and ensure uniqueness.
  /// This way we don't necessarily invoke `reloadUserScripts()` too often but only when necessary.
  ///
  var userScriptTypes: Set<UserScriptType> {
    didSet {
      guard oldValue != userScriptTypes else { return }
      
      #if DEBUG
      let oldValues = debugString(for: oldValue.sorted(by: { $0.order < $1.order }))
      let newValues = debugString(for: userScriptTypes.sorted(by: { $0.order < $1.order }))
      
      let scriptDebugData =
      """
      Set<UserScriptType>
      Old Values: [
      \(oldValues)
      ]
      New Values: [
      \(newValues)
      ]
      """
      
      ContentBlockerManager.log.debug("\(scriptDebugData, privacy: .public)")
      #endif
      
      reloadUserScripts()
    }
  }
  
  #if DEBUG
  private func debugString(for scriptTypes: [UserScriptType]) -> String {
    return scriptTypes.map({ scriptType in
      let nameString: String
      
      switch scriptType {
      case .domainUserScript:
        nameString = "domainUserScript(\(scriptType.sourceType.fileName))"
      case .nacl:
        nameString = "nacl"
      case .farblingProtection(let etld1):
        nameString = "farblingProtection(\(etld1))"
      case .siteStateListener:
        nameString = "siteStateListener"
      }
      
      return nameString
    }).joined(separator: "\n")
  }
  #endif

  public static func isMessageHandlerTokenMissing(in body: [String: Any]) -> Bool {
    guard let token = body["securitytoken"] as? String, token == UserScriptManager.messageHandlerTokenString else {
      return true
    }
    return false
  }

  init(
    tab: Tab,
    isCookieBlockingEnabled: Bool,
    isWebCompatibilityMediaSourceAPIEnabled: Bool,
    isMediaBackgroundPlaybackEnabled: Bool,
    isNightModeEnabled: Bool,
    isDeAMPEnabled: Bool,
    walletEthProviderJS: String?
  ) {
    self.tab = tab
    self.isCookieBlockingEnabled = isCookieBlockingEnabled
    self.isWebCompatibilityMediaSourceAPIEnabled = isWebCompatibilityMediaSourceAPIEnabled
    self.isPlaylistEnabled = true
    self.isMediaBackgroundPlaybackEnabled = isMediaBackgroundPlaybackEnabled
    self.isNightModeEnabled = isNightModeEnabled
    self.isDeAMPEnabled = isDeAMPEnabled
    self.userScriptTypes = []
    self.walletEthProviderJS = walletEthProviderJS
    self.isRequestBlockingEnabled = true
    
    reloadUserScripts()
  }

  // MARK: -

  private let packedUserScripts: [WKUserScript] = {
    [
      (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false, sandboxed: false),
      (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false, sandboxed: false),
      (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false, sandboxed: true),
      (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false, sandboxed: true),
      (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true, sandboxed: false),
      (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true, sandboxed: false),
      (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true, sandboxed: true),
      (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true, sandboxed: true),
    ].compactMap { arg in
      let (injectionTime, mainFrameOnly, sandboxed) = arg
      let name = (mainFrameOnly ? "MainFrame" : "AllFrames") + "AtDocument" + (injectionTime == .atDocumentStart ? "Start" : "End") + (sandboxed ? "Sandboxed" : "")
      if let path = Bundle.current.path(forResource: name, ofType: "js"),
        let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
        let wrappedSource = "(function() { const SECURITY_TOKEN = '\(UserScriptManager.messageHandlerTokenString)'; \(source) })()"

        return WKUserScript.create(
          source: wrappedSource,
          injectionTime: injectionTime,
          forMainFrameOnly: mainFrameOnly,
          in: sandboxed ? .defaultClient : .page)
      }
      return nil
    }
  }()

  private let cookieControlUserScript: WKUserScript? = {
    guard let path = Bundle.current.path(forResource: "CookieControl", ofType: "js"), let source: String = try? String(contentsOfFile: path) else {
      log.error("Failed to load cookie control user script")
      return nil
    }

    return WKUserScript.create(
      source: source,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false,
      in: .page)
  }()
  
  /// A script that detects if we're at an amp page and redirects the user to the original (canonical) version if available.
  ///
  /// - Note: This script is only a smaller part (2 of 3) of de-amping.
  /// The first part is handled by an ad-block rule and enabled via a `deAmpEnabled` boolean in `AdBlockStats`
  /// The third part is handled by debouncing amp links and handled by debouncing logic in `DebouncingResourceDownloader`
  private let deAMPUserScript: WKUserScript? = {
    return DeAmpHelper.userScript
  }()

  // PaymentRequestUserScript is injected at document start to handle
  // requests to payment APIs
  private let PaymentRequestUserScript: WKUserScript? = {
    return nil
  }()

  private let resourceDownloadManagerUserScript: WKUserScript? = {
    return ResourceDownloadManager.userScript
  }()

  private let WindowRenderHelperScript: WKUserScript? = {
    return WindowRenderHelper.userScript
  }()

  private let FullscreenHelperScript: WKUserScript? = {
    guard let path = Bundle.current.path(forResource: "FullscreenHelper", ofType: "js"), let source = try? String(contentsOfFile: path) else {
      log.error("Failed to load FullscreenHelper.js")
      return nil
    }

    return WKUserScript.create(
      source: source,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false,
      in: .page)
  }()

  private let PlaylistSwizzlerScript: WKUserScript? = {
    guard let path = Bundle.current.path(forResource: "PlaylistSwizzler", ofType: "js"),
      let source = try? String(contentsOfFile: path)
    else {
      log.error("Failed to load PlaylistSwizzler.js")
      return nil
    }

    return WKUserScript.create(
      source: source,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false,
      in: .page)
  }()

  private let PlaylistHelperScript: WKUserScript? = {
    return PlaylistHelper.userScript
  }()

  private let MediaBackgroundingScript: WKUserScript? = {
    guard let path = Bundle.current.path(forResource: "MediaBackgrounding", ofType: "js"), let source = try? String(contentsOfFile: path) else {
      log.error("Failed to load MediaBackgrounding.js")
      return nil
    }

    return WKUserScript.create(
      source: source,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false,
      in: .page)
  }()

  private let NightModeScript: WKUserScript? = {
    return NightModeHelper.userScript
  }()
  
  private let ReadyStateScript: WKUserScript? = {
    return ReadyStateScriptHelper.userScript
  }()

  private let walletEthProviderScript: WKUserScript? = {
    guard let path = Bundle.current.path(forResource: "WalletEthereumProvider", ofType: "js"),
          let source = try? String(contentsOfFile: path) else {
      return nil
    }
    
    var alteredSource = source
    
    let replacements = [
      "$<security_token>": UserScriptManager.securityTokenString,
      "$<handler>": "walletEthereumProvider_\(messageHandlerTokenString)",
    ]
    
    replacements.forEach({
      alteredSource = alteredSource.replacingOccurrences(of: $0.key, with: $0.value, options: .literal)
    })
    
    return WKUserScript.create(source: alteredSource,
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: true,
                               in: .page)
  }()

  private var walletEthProviderJS: String?
    
  public func reloadUserScripts() {
    tab?.webView?.configuration.userContentController.do {
      $0.removeAllUserScripts()
      // This has to be added before `packedUserScripts` because some scripts do
      // rewarding even if the request is blocked.
//      if isRequestBlockingEnabled, let script = requestBlockingUserScript {
//        $0.addUserScript(script)
//      }
      
      self.packedUserScripts.forEach($0.addUserScript)
      
      if isCookieBlockingEnabled, let script = cookieControlUserScript {
        $0.addUserScript(script)
      }

      if let script = resourceDownloadManagerUserScript {
        $0.addUserScript(script)
      }

      if let script = WindowRenderHelperScript {
        $0.addUserScript(script)
      }

      if let script = FullscreenHelperScript {
        $0.addUserScript(script)
      }

      if UIDevice.isIpad, isWebCompatibilityMediaSourceAPIEnabled, let script = PlaylistSwizzlerScript {
        $0.addUserScript(script)
      }

      if isPlaylistEnabled, let script = PlaylistHelperScript {
        $0.addUserScript(script)
      }

      if isMediaBackgroundPlaybackEnabled, let script = MediaBackgroundingScript {
        $0.addUserScript(script)
      }

      if isNightModeEnabled, let script = NightModeScript {
        $0.addUserScript(script)
      }
      
      if isDeAMPEnabled, let script = deAMPUserScript {
        $0.addUserScript(script)
      }
      
      if let script = ReadyStateScript {
        $0.addUserScript(script)
      }

      for userScriptType in userScriptTypes.sorted(by: { $0.order < $1.order }) {
        do {
          let script = try ScriptFactory.shared.makeScript(for: userScriptType)
          $0.addUserScript(script)
        } catch {
          assertionFailure("Should never happen. The scripts are packed in the project and loading/modifying should always be possible.")
          log.error(error)
        }
      }

      if let script = walletEthProviderScript,
         tab?.isPrivate == false,
         Preferences.Wallet.WalletType(rawValue: Preferences.Wallet.defaultEthWallet.value) == .brave {
        $0.addUserScript(script)
        if var providerJS = walletEthProviderJS {
          providerJS = """
            (function() {
              if (window.isSecureContext) {
                \(providerJS)
              }
            })();
            """
          $0.addUserScript(.init(source: providerJS, injectionTime: .atDocumentStart, forMainFrameOnly: true, in: .page))
        }
      }
    }
  }
}
