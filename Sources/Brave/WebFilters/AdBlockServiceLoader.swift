// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// This class assists in loading local files from brave core
class AdBlockServiceLoader {
  /// Start loading files from the adblock service
  public static func loadLocalFiles(from adBlockService: AdblockService) {
    Task {
      for await folderURL in await adBlockService.localFilesStream {
        loadDebounceRules(fromFolderURL: folderURL)
      }
    }
  }
  
  /// Attempt to load the debounce rules
  private static func loadDebounceRules(fromFolderURL folderURL: URL) {
    let fileURL = folderURL.appendingPathComponent("1/debounce", conformingTo: .json)
    
    do {
      let data = try Data(contentsOf: fileURL)
      try DebouncingService.shared.setup(withRulesJSON: data)
    } catch {
      ContentBlockerManager.log.error("Failed to setup debounce rules: \(error.localizedDescription)")
    }
  }
}

private extension AdblockService {
  /// Stream the URL updates to the brave-core local files install directory
  @MainActor var localFilesStream: AsyncStream<URL> {
    return AsyncStream { continuation in
      registerLocalFilesComponent { folderPath in
        guard let folderPath = folderPath else {
          assertionFailure()
          return
        }
        
        let folderURL = URL(fileURLWithPath: folderPath)
        continuation.yield(folderURL)
      }
      
      continuation.onTermination = { @Sendable _ in
        // TODO: Unregister
      }
    }
  }
}
