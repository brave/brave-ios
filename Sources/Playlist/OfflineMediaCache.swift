// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVFoundation

/// Handles the caching of media assets added to Playlist
public struct OfflineMediaCache {
  var activeSessions: () -> [Void /* DownloadSession */]
  var restoreSessions: () -> Void
  var stateForAsset: (URL) -> State
  var downloadAsset: (URL) -> AsyncStream<State>
  var deleteCache: (URL)
  var resetCache: () -> Void
  var availableDiskSpace: () -> Int64
  var totalDiskSpace: () -> Int64
  
  public enum State {
    case completed(URL)
    case downloading(progress: Float)
    case pending
  }
  
  /// Whether or not an asset is automatically cached upon adding it to playlist
  ///
  /// - Note: This legacy type's value is persisted so if case names are changed, ensure
  ///         the underlying `case` value remains the same as before
  public enum AutomaticCacheRule: String {
    /// The asset will automatically be downloaded to the users device if there is available space
    case on
    /// The asset will not be downloaded unless the user manually does so
    case off
    /// The asset will be downloaded automatically only if the user is connected to Wi-Fi
    case wifi
  }
}

extension OfflineMediaCache {
  
//  static var live: Self {
//    .init(
//      restoreSessions: <#T##() -> Void#>,
//      stateForAsset: <#T##(URL) -> State#>,
//      downloadAsset: <#T##(URL) -> AsyncStream<State>#>
//    )
//  }
}

private class DownloadSession: ObservableObject {
  
}

private class HLSDownloadDelegate: NSObject, AVAssetDownloadDelegate {
  
}

private class FileDownloadDelegate: NSObject, URLSessionDownloadDelegate {
  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    
  }
}
