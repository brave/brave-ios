// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import SDWebImage
import BraveCore

public protocol WebImageDownloaderType: AnyObject {
  func downloadImage(url: URL?) async -> UIImage?
  func imageFromData(data: Data) -> UIImage?
}

struct WebImageDownloaderKey: EnvironmentKey {
  static var defaultValue: WebImageDownloaderType? = SDWebImageManager.shared
}

extension EnvironmentValues {
  public var webImageDownloader: WebImageDownloaderType? {
    get { self[WebImageDownloaderKey.self] }
    set { self[WebImageDownloaderKey.self] = newValue }
  }
}

extension SDWebImageManager: WebImageDownloaderType {
  @MainActor public func downloadImage(url: URL?) async -> UIImage? {
    return await withCheckedContinuation { continuation in
      loadImage(with: url, progress: nil) { image, _, _, _, _, _ in
        continuation.resume(returning: image)
      }
    }
  }
  
  public func imageFromData(data: Data) -> UIImage? {
    SDImageCodersManager.shared.decodedImage(with: data)
  }
}

extension BraveCore.WebImageDownloader: WebImageDownloaderType {
  @MainActor public func downloadImage(url: URL?) async -> UIImage? {
    if let url {
      return await withCheckedContinuation { continuation in
        downloadImage(url) { image, _, _ in
          continuation.resume(returning: image)
        }
      }
    }
    return nil
  }
  
  public func imageFromData(data: Data) -> UIImage? {
    WebImageDownloader.image(from: data)
  }
}

public struct WebImageReader<Content: View>: View {
  var url: URL?
  
  @Environment(\.webImageDownloader) private var imageDownloader: WebImageDownloaderType?
  
  @State private var image: UIImage?

  private var content: (_ image: UIImage?) -> Content

  public init(
    url: URL?,
    @ViewBuilder content: @escaping (_ image: UIImage?) -> Content
  ) {
    self.content = content
    self.url = url
  }

  public var body: some View {
    content(image)
      .onAppear {
        if let urlString = url?.absoluteString {
          if urlString.hasPrefix("data:image/"), let dataString = urlString.separatedBy(",").last, let data = Data(base64Encoded: dataString, options: .ignoreUnknownCharacters) {
            image = imageDownloader?.imageFromData(data: data)
          } else {
            Task { @MainActor in
              image = await imageDownloader?.downloadImage(url: url)
            }
          }
        }
      }
  }
}
