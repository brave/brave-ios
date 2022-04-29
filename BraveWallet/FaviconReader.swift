import SwiftUI

public protocol WalletFavIconRenderer {
  func loadIcon(siteURL: URL, persistent: Bool, completion: ((UIImage?) -> Void)?)
}

class ImageLoader: ObservableObject {
  @Published var image: UIImage?
  private var renderer: WalletFavIconRenderer
  
  init(renderer: WalletFavIconRenderer) {
    self.image = nil
    self.renderer = renderer
  }
  
  func load(_ url: URL?, transaction: Transaction) {
    guard let url = url else { return }
    renderer.loadIcon(siteURL: url, persistent: true) { [weak self] image in
      withTransaction(transaction) {
        self?.image = image
      }
    }
  }
}

struct FaviconReader<Content: View>: View {
  @ObservedObject private var loader: ImageLoader
  var url: URL?
  private let transaction: Transaction
  private var content: (_ image: UIImage?) -> Content
  
  init(
    url: URL?,
    imageLoader: ImageLoader,
    @ViewBuilder content: @escaping (_ image: UIImage?) -> Content
  ) {
    self.loader = imageLoader
    self.url = url
    self.transaction = Transaction()
    self.content = content
  }
  
  var body: some View {
    content(loader.image)
      .onAppear {
        loader.load(url, transaction: transaction)
      }
      .onChange(of: url) { newValue in
        loader.load(newValue, transaction: transaction)
      }
  }
}
