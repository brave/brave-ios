// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import SDWebImage

class WalletWebImageManager: ObservableObject {
  /// loaded image, note when progressive loading, this will published multiple times with different partial image
  @Published public var image: UIImage?
  /// loaded image data, may be nil if hit from memory cache. This will only published once loading is finished
  @Published public var imageData: Data?
  /// loading error
  @Published public var error: Error?
  
  var manager = SDWebImageManager.shared
  var url: URL?
  var options: SDWebImageOptions
  
  init(url: URL?, options: SDWebImageOptions = []) {
    self.url = url
    self.options = options
  }
  
  func load() {
    manager.loadImage(with: url, options: options, progress: nil, completed: { [weak self] image, data, error, _, finished, _ in
      guard let self = self else { return }
      self.image = image
      self.error = error
      if finished {
        self.imageData = data
      }
    })
  }
}

struct WalletWebImage: View {
 
  @ObservedObject var imageManager: WalletWebImageManager
  
  var placeholder: AnyView?
  
  init(url: URL?, options: SDWebImageOptions = []) {
    self.imageManager = WalletWebImageManager(url: url, options: options)
  }
  
  var body: some View {
    Group {
      if let image = imageManager.image {
        Image(uiImage: image)
      } else {
        Group {
          if let placeholder = placeholder {
            placeholder
          } else {
            EmptyView()
          }
        }
        .onAppear {
          if imageManager.imageData == nil {
            imageManager.load()
          }
        }
      }
    }
  }
}

extension WalletWebImage {
  public func placeholder<T>(@ViewBuilder _ content: () -> T) -> WalletWebImage where T: View {
    var result = self
    result.placeholder = AnyView(content())
    return result
  }
}
