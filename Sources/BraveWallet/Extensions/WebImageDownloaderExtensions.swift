// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveCore
import BraveUI

extension BraveCore.WebImageDownloader: WebImageDownloaderType {
  @MainActor public func downloadImage(url: URL) async -> (UIImage?, Error?) {
    return await withCheckedContinuation { continuation in
      downloadImage(url) { image, httpResponseCode, _ in
        var error: Error?
        if httpResponseCode < 200 || httpResponseCode > 299 {
          error = NSError(domain: "com.brave.ios.BraveWallet.failed-to-load-image", code: 0)
        }
        continuation.resume(returning: (image, error))
      }
    }
  }
  
  @MainActor public func imageFromData(data: Data) async -> UIImage? {
    WebImageDownloader.image(from: data)
  }
}
