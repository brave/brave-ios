// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Combine

enum AsyncImagePhase {
  // No image is loaded.
  case empty
  
  // An image succesfully loaded.
  case success(Image)
  
  // An image failed to load with an error.
  case failure(Error)
  
  // The loaded image, if any.
  var image: Image? {
    if case .success(let image) = self {
      return image
    }
    return nil
  }
  
  // The error that occurred when attempting to load an image, if any.
  var error: Error? {
    if case .failure(let error) = self {
      return error
    }
    return nil
  }
}

struct AsyncImage<Content: View>: View {
  @StateObject private var loader: ImageLoader
  
  private let url: URL?
  private let scale: CGFloat
  private let transaction: Transaction
  private let content: (AsyncImagePhase) -> Content

  init(url: URL?, scale: CGFloat = 1) where Content == Image {
    _loader = StateObject(wrappedValue: ImageLoader())
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    self.content = { $0.image ?? Image("") }
  }
  
  init(url: URL?, scale: CGFloat = 1, transaction: Transaction = Transaction(), content: @escaping (AsyncImagePhase) -> Content) {
    _loader = StateObject(wrappedValue: ImageLoader())
    self.url = url
    self.scale = scale
    self.transaction = transaction
    self.content = content
  }
  
  init<I, P>(url: URL?, scale: CGFloat = 1, content: @escaping (Image) -> I, placeholder: @escaping () -> P) where Content == _ConditionalContent<I, P>, I: View, P: View {
    _loader = StateObject(wrappedValue: ImageLoader())
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    self.content = { phase -> _ConditionalContent<I, P> in
      if let image = phase.image {
        return ViewBuilder.buildEither(first: content(image))
      } else {
        return ViewBuilder.buildEither(second: placeholder())
      }
    }
  }

  var body: some View {
    content(loader.phase)
      .onAppear {
        loader.load(url, scale: scale, transaction: transaction)
      }
      .onChange(of: url) { url in
        loader.load(url, scale: scale, transaction: transaction)
      }
  }
  
  private class ImageLoader: ObservableObject {
    @Published var phase: AsyncImagePhase = .empty
    private var cancellable: AnyCancellable?
    
    init() {
      self.phase = .empty
    }

    deinit {
      cancel()
    }
      
    func load(_ url: URL?, scale: CGFloat, transaction: Transaction) {
      guard let url = url else { return }
      
      cancellable = URLSession.shared.dataTaskPublisher(for: url)
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveCancel: { [weak self] in
          withTransaction(transaction) {
            self?.phase = .empty
          }
        })
        .sink(receiveCompletion: { [weak self] result in
          if case .failure(let error) = result {
            self?.phase = .failure(error)
          }
        }, receiveValue: { [weak self] result in
          withTransaction(transaction) {
            if let image = UIImage(data: result.data, scale: scale) {
              self?.phase = .success(Image(uiImage: image))
            } else {
              self?.phase = .empty
            }
          }
        })
    }

    func cancel() {
      cancellable?.cancel()
      cancellable = nil
    }
  }
}

#if DEBUG
struct AsyncImage_Previews: PreviewProvider {
  static var previews: some View {
    AsyncImage(url: URL(string: "https://brave.com/static-assets/images/cropped-brave_appicon_release-192x192.png"))
  }
}
#endif
