// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Shared

public class PlayerHandler: InternalSchemeResponse {
  public static let path = InternalURL.Path.player.rawValue
  
  public init() {}
  
  public func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
    guard let url = request.url,
          let internalURL = InternalURL(url),
          let youtubeURL = internalURL.extractedUrlParam,
          let youtubeID = PlayerUtils.youTubeVideoID(from: youtubeURL) else { return nil }
    let response = InternalSchemeHandler.response(forUrl: internalURL.url)
    guard let path = Bundle.module.path(forResource: "Player", ofType: "html")
    else {
      return nil
    }
    
    guard var html = try? String(contentsOfFile: path) else {
      assert(false)
      return nil
    }
    
    let variables = [
      "YOUTUBE_VIDEO_ID": youtubeID,
    ]
    
    variables.forEach { (arg, value) in
      html = html.replacingOccurrences(of: "%\(arg)%", with: value)
    }
    
    guard let data = html.data(using: .utf8) else {
      return nil
    }
    
    return (response, data)
  }
}
