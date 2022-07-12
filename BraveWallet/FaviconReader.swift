import SwiftUI
import BraveShared

struct FaviconReader<Content: View>: View {
  let url: URL
  @State private var image: UIImage?
  private var content: (_ image: UIImage?) -> Content
  @State private var faviconTask: FaviconFetcher.Cancellable?

  init(
    url: URL,
    @ViewBuilder content: @escaping (_ image: UIImage?) -> Content
  ) {
    self.url = url
    self.content = content
  }
  
  var body: some View {
    content(image)
      .onAppear {
        load(url, transaction: Transaction())
      }
      .onChange(of: url) { newValue in
        load(newValue, transaction: Transaction())
      }
  }
  
  private func load(_ url: URL?, transaction: Transaction) {
    guard let url = url else { return }
    self.faviconTask = FaviconFetcher.loadIcon(url: url, kind: .largeIcon, persistent: true, completion: { favicon in
      withTransaction(transaction) {
        self.image = favicon?.image
      }
    })
  }
}
