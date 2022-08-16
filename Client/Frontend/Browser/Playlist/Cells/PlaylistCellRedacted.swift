// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import CoreData
import Shared
import BraveUI
import DesignSystem
import BraveShared
import Data

@available(iOS, deprecated: 15.0, renamed: "SwiftUI.AsyncImage")
public struct AsyncImage<Content: View>: View {
  @StateObject private var loader = ImageLoader()
  
  private let url: URL?
  private let scale: CGFloat
  private let transaction: Transaction
  private let render: (AsyncImagePhase) -> Content
  
  public init(url: URL?, scale: CGFloat = 1) where Content == Image {
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    self.render = { $0.image ?? Image("") }
  }

  init<ContentView: View, PlaceHolder: View>(url: URL, scale: CGFloat = 1, @ViewBuilder content: @escaping (Image) -> ContentView, @ViewBuilder placeholder: @escaping () -> PlaceHolder) where Content == _ConditionalContent<ContentView, PlaceHolder> {
      
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    
    self.render = { phase -> _ConditionalContent<ContentView, PlaceHolder> in
      if let image = phase.image {
        return ViewBuilder.buildEither(first: content(image))
      } else {
        return ViewBuilder.buildEither(second: placeholder())
      }
    }
  }
  
  public init(url: URL?, scale: CGFloat = 1, transaction: Transaction = Transaction(), @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
    self.url = url
    self.scale = scale
    self.transaction = transaction
    self.render = content
  }

  public var body: some View {
    render(loader.phase)
      .onAppear {
        loader.load(url, scale: scale, transaction: transaction)
      }
      .onChange(of: url) { url in
        loader.load(url, scale: scale, transaction: transaction)
      }
  }
  
  private class ImageLoader: ObservableObject {
    @Published var phase: AsyncImagePhase
    
    init() {
      self.phase = .empty
    }
      
    func load(_ url: URL?, scale: CGFloat, transaction: Transaction) {
      guard let url = url, !url.absoluteString.isEmpty else {
        withTransaction(transaction) {
          self.phase = .empty
        }
        return
      }
      
      let session = URLSession(configuration: .ephemeral)
      Task { @MainActor in
        do {
          let (data, _) = try await session.dataRequest(with: url)
          withTransaction(transaction) {
            if let image = UIImage(data: data, scale: scale) {
              self.phase = .success(Image(uiImage: image))
            } else {
              self.phase = .empty
            }
          }
        } catch {
          self.phase = .failure(error)
        }
      }
    }
  }
  
  public enum AsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)

    public var image: Image? {
      switch self {
      case .empty, .failure: return nil
      case .success(let image): return image
      }
    }
    
    public var error: Error? {
      switch self {
      case .empty, .success: return nil
      case .failure(let error): return error
      }
    }
  }
}

private struct PlaylistRedactedHeaderView: View {
  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading) {
        Text("PlaylistTitlePlaceholder" /* Placeholder */)
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: .placeholder)
          .shimmer(true)
        
        Text("CreatorName" /* Placeholder */)
          .font(.footnote)
          .foregroundColor(Color(.braveLabel))
          .multilineTextAlignment(.leading)
          .redacted(reason: .placeholder)
          .shimmer(true)
      }
      
      Spacer()
      
      Button("+ Add" /* Placeholder */, action: {})
        .buttonStyle(BraveFilledButtonStyle(size: .normal))
        .disabled(true)
        .redacted(reason: .placeholder)
        .shimmer(true)
    }
    .padding()
    .frame(height: 80.0, alignment: .center)
    .background(Color(.braveBackground))
    .environment(\.colorScheme, .dark)
  }
}

private struct PlaylistCellRedactedView: View {
  var body: some View {
    HStack(alignment: .center) {
      Image("")
        .resizable()
        .frame(width: 64.0 * 1.47, height: 64.0, alignment: .center)
        .aspectRatio(contentMode: .fit)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .continuous))
        .shimmer(true)
      
      VStack(alignment: .leading) {
        Text("Placeholder Title\nPlaceholder Title Second Line")
          .font(.callout)
          .fontWeight(.medium)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: .placeholder)
          .shimmer(true)
        
        Text("Placeholder SubTitle")
          .font(.callout)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: .placeholder)
          .shimmer(true)
        
        Text("00:00")
          .font(.footnote)
          .foregroundColor(Color(.secondaryBraveLabel))
          .multilineTextAlignment(.leading)
          .redacted(reason: .placeholder)
          .shimmer(true)
      }
      
      Spacer()
    }
    .padding()
    .frame(height: 80.0, alignment: .center)
    .background(Color(.braveBackground))
    .environment(\.colorScheme, .dark)
  }
}

class PlaylistRedactedHeader: UITableViewHeaderFooterView {
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    
    let hostingController = UIHostingController(rootView: PlaylistRedactedHeaderView())
    contentView.addSubview(hostingController.view)
    hostingController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class PlaylistCellRedacted: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    let hostingController = UIHostingController(rootView: PlaylistCellRedactedView())
    contentView.addSubview(hostingController.view)
    hostingController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
