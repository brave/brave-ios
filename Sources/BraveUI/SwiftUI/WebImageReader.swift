// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import SDWebImage

public protocol WebImageDownloaderType: AnyObject {
  func downloadImage(url: URL) async -> (UIImage?, Error?)
  func imageFromData(data: Data) async -> UIImage?
}

struct WebImageDownloaderKey: EnvironmentKey {
  static var defaultValue: WebImageDownloaderType = SDWebImageManager.shared
}

extension EnvironmentValues {
  public var webImageDownloader: WebImageDownloaderType {
    get { self[WebImageDownloaderKey.self] }
    set { self[WebImageDownloaderKey.self] = newValue }
  }
}

extension SDWebImageManager: WebImageDownloaderType {
  @MainActor public func downloadImage(url: URL) async -> (UIImage?, Error?) {
    var operation: SDWebImageCombinedOperation?
    return await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        operation = loadImage(with: url, progress: nil) { image, _, error, _, _, _ in
          continuation.resume(returning: (image, error))
        }
      }
    } onCancel: { [operation] in
      operation?.cancel()
    }
  }
  
  public func imageFromData(data: Data) async -> UIImage? {
    SDImageCodersManager.shared.decodedImage(with: data)
  }
}

public struct WebImageReader<Content: View>: View {
  var url: URL
  
  @Environment(\.webImageDownloader) private var imageDownloader: WebImageDownloaderType
  
  @State private var image: UIImage?
  @State private var error: Error?

  private var content: (_ image: UIImage?, _ error: Error?) -> Content

  public init(
    url: URL,
    @ViewBuilder content: @escaping (_ image: UIImage?, _ error: Error?) -> Content
  ) {
    self.content = content
    self.url = url
  }

  public var body: some View {
    content(image, error)
      .id(url)
      .task {
        if url.absoluteString.hasPrefix("data:image/"),
           let dataString = url.absoluteString.separatedBy(",").last,
           let data = Data(base64Encoded: dataString, options: .ignoreUnknownCharacters) {
          image = await imageDownloader.imageFromData(data: data)
        } else {
          (image, error) = await imageDownloader.downloadImage(url: url)
        }
      }
  }
}
