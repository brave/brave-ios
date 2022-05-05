import SwiftUI

public protocol WalletFavIconRenderer {
  func loadIcon(siteURL: URL, persistent: Bool, completion: ((UIImage?) -> Void)?)
}

public class UnimplementedFaviconRenderer: WalletFavIconRenderer {
  public func loadIcon(siteURL: URL, persistent: Bool, completion: ((UIImage?) -> Void)?) {
    fatalError()
  }
}

public struct FaviconRendererKey: EnvironmentKey {
  public static var defaultValue: WalletFavIconRenderer = UnimplementedFaviconRenderer()
}

public extension EnvironmentValues {
  var faviconRenderer: WalletFavIconRenderer {
    get { self[FaviconRendererKey.self] }
    set { self[FaviconRendererKey.self] = newValue }
  }
}

class FaviconLoader: ObservableObject {
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
  @ObservedObject private var loader: FaviconLoader
  var url: URL?
  private var content: (_ image: UIImage?) -> Content
  
  init(
    url: URL?,
    loader: FaviconLoader,
    @ViewBuilder content: @escaping (_ image: UIImage?) -> Content
  ) {
    self.loader = loader
    self.url = url
    self.content = content
  }
  
  var body: some View {
    content(loader.image)
      .onAppear {
        loader.load(url, transaction: Transaction())
      }
      .onChange(of: url) { newValue in
        loader.load(newValue, transaction: Transaction())
      }
  }
}
