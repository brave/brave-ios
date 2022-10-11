// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit

/// The data for the current web-page which is needed for loading and executing privacy scripts
///
/// Since frames may be loaded as the user scrolls which may need additional scripts to be injected,
/// We cache information about frames in order to prevent excessive reloading of scripts.
struct PageData {
  typealias FrameEvaluation = (frameInfo: WKFrameInfo, source: String)
  
  /// The url of the page (i.e. main frame)
  let mainFrameURL: URL
  
  /// A list of pending frames that are loaded for this web-page
  ///
  /// We need this information in order to execute scripts on a per-frame basis once navigation is comitted and finished
  var frameEvaluations: [URL: [FrameEvaluation]] = [:]
  
  /// A list of all currently available subframes for this current page
  /// These are loaded dyncamically as the user scrolls through the page
  var allSubframeURLs: Set<URL> = []
  
  /// Check if we upgraded to https and if so we need to update the url of frame evaluations
  mutating func upgradeFrameEvaluations(forResponseURL responseURL: URL) {
    if var components = URLComponents(url: responseURL, resolvingAgainstBaseURL: false), components.scheme == "https" {
      components.scheme = "http"
      if frameEvaluations[responseURL] == nil, let downgradedURL = components.url {
        frameEvaluations[responseURL] = frameEvaluations[downgradedURL]
      }
    }
  }
  
  /// Return all subframe user scripts that are already known for this page.
  ///
  /// Since we may load more frames as we scroll we have to cache the subframe urls so we don't reload scripts too often on page reloads.
  private func makeSubframeEngineScripts() -> Set<UserScriptType> {
    let scriptTypes = allSubframeURLs.flatMap { url -> [UserScriptType] in
      do {
        return try makeSubframeScripts(for: url)
      } catch {
        assertionFailure()
        return []
      }
    }
    
    return Set(scriptTypes)
  }
  
  private func makeSubframeScripts(for url: URL) throws -> [UserScriptType] {
    let sources = try AdBlockStats.shared.makeEngineScriptSouces(for: url)
    
    return sources.generalScripts.map { source -> UserScriptType in
      return .engineSubframeScript(url: url, source: source)
    }
  }
  
  mutating func makeUserScriptTypes(for navigationAction: WKNavigationAction, options: UserScriptHelper.DomainScriptOptions) -> Set<UserScriptType> {
    if navigationAction.targetFrame?.isMainFrame == false, let url = navigationAction.request.url {
      // We need to add any non-main frame urls to our site data
      // We will need this to construct all non-main frame scripts
      allSubframeURLs.insert(url)
    }
    
    var scriptTypes = UserScriptHelper.getUserScriptTypes(
      for: navigationAction, options: options
    )
    
    let additionalTypes = makeSubframeEngineScripts()
    scriptTypes.formUnion(additionalTypes)
    
    return scriptTypes
  }
  
  mutating func makeAdditionalScriptTypes(for navigationResponse: WKNavigationResponse) -> Set<UserScriptType>? {
    // We also add subframe urls in case a frame upgraded to https
    guard !navigationResponse.isForMainFrame, let url = navigationResponse.response.url, !allSubframeURLs.contains(url) else {
      return nil
    }
    
    // This probably means that one of the subframe urls was upgraded to https
    allSubframeURLs.insert(url)
    
    do {
      return try Set(makeSubframeScripts(for: url))
    } catch {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }
}
