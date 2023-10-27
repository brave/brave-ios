// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared
import Shared
import Strings
import BraveShields

class PlayerUtils {
  private static let youtubePrefix = "youtube"
  
  static func makeBravePlayerURL(from url: URL) -> URL? {
    guard let videoInfo = prefixAndVideoID(from: url) else { return nil }
    guard let encodedID = videoInfo.videoID.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }
    return makeBravePlayerURL(prefix: videoInfo.prefix, videoID: encodedID, authenticate: true)
  }
  
  static func makeBravePlayerURL(prefix: String, videoID: String, authenticate: Bool) -> URL? {
    return BraveSchemeHandler.createURL(
      host: .player, path: "/\(prefix)/\(videoID)", authenticate: authenticate
    )
  }
  
  /// Extract a youtube video id to be used in the brave player
  static func prefixAndVideoID(from url: URL) -> (prefix: String, videoID: String)? {
    guard url.isWebPage(), let baseDomain = url.baseDomain else { return nil }
    let youTubeURLs: Set<String> = ["youtube.com", "m.youtube.com", "youtu.be"]
    
    guard youTubeURLs.contains(baseDomain),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let id = components.queryItems?.first(where: { $0.name == "v" })?.value 
    else {
      return nil
    }
    
    return (youtubePrefix, id)
  }
  
  static func loadPlayerData(for playerURL: URL) throws -> Data? {
    let youtubeID = playerURL.lastPathComponent
    let removedIDURL = playerURL.deletingLastPathComponent()
    guard youtubePrefix == removedIDURL.lastPathComponent else { return nil }
    
    guard let filePath = Bundle.module.path(forResource: "Player", ofType: "html") else {
      assertionFailure()
      return nil
    }
    
    var html = try String(contentsOfFile: filePath)
      .replacingOccurrences(of: "%YOUTUBE_VIDEO_ID%", with: youtubeID)
      .replacingOccurrences(of: "%BRAVE_PLAYER_TITLE%", with: Strings.Shields.bravePlayer)
      .replacingOccurrences(of: "%PLAYER_LABEL%", with: Strings.Shields.bravePlayerPlayerText)
      .replacingOccurrences(of: "%PLAYER_LOGO_ALT_TEXT%", with: Strings.Shields.bravePlayerLogoAltText)
    
    if #available(iOS 16.0, *) {
      html = html.replacingOccurrences(of: "<html lang=\"en\">", with: "<html lang=\"\(Locale.current.language.minimalIdentifier)\">")
    }
    
    return html.data(using: .utf8)
  }
}
