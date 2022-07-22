//
//  SwiftUIView.swift
//  
//
//  Created by Brandon on 2022-07-21.
//

import SwiftUI
import CoreData
import Shared
import BraveUI
import DesignSystem
import BraveShared
import Data

@available(iOS, deprecated: 15.0, renamed: "SwiftUI.AsyncImage")
public struct AsyncImage<Content: View>: View {
  @StateObject private var loader: ImageLoader
  
  private let url: URL?
  private let scale: CGFloat
  private let transaction: Transaction
  private let render: (AsyncImagePhase) -> Content
  
  public init(url: URL?, scale: CGFloat = 1) where Content == Image {
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    _loader = StateObject(wrappedValue: ImageLoader())
    self.render = { $0.image ?? Image("") }
  }

  init<ContentView: View, PlaceHolder: View>(url: URL, scale: CGFloat = 1, @ViewBuilder content: @escaping (Image) -> ContentView, @ViewBuilder placeholder: @escaping () -> PlaceHolder) where Content == _ConditionalContent<ContentView, PlaceHolder> {
      
    self.url = url
    self.scale = scale
    self.transaction = Transaction()
    _loader = StateObject(wrappedValue: ImageLoader())
    
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
    _loader = StateObject(wrappedValue: ImageLoader())
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

private class PlaylistThumbnailImageLoader: ObservableObject {
  @Published var image: UIImage?

  private let renderer = PlaylistThumbnailRenderer()
  private let fetcher = FavIconImageRenderer()
  private var webLoader: PlaylistWebLoader?

  func load(assetUrl: String) {
    loadImage(url: assetUrl, isFavIcon: false)
  }

  func load(favIconURL: String) {
    loadImage(url: favIconURL, isFavIcon: true)
  }

  func load(pageURL: String) {
    guard let url = URL(string: pageURL), !pageURL.isEmpty else {
      self.image = nil
      return
    }
    
    webLoader = PlaylistWebLoader(
      certStore: nil,
      handler: { [weak self] newItem in
        guard let self = self else { return }
        defer {
          // Destroy the web loader when the callback is complete.
          self.webLoader?.removeFromSuperview()
          self.webLoader = nil
        }

        if let newItem = newItem, URL(string: newItem.src) != nil {
          self.load(assetUrl: newItem.src)
        } else {
          self.image = nil
        }
      }
    ).then {
      UIApplication.shared.keyWindow?.insertSubview($0, at: 0)
    }

    webLoader?.load(url: url)
  }

  private func loadImage(url: String, isFavIcon: Bool) {
    guard !url.isEmpty, let assetUrl = URL(string: url) else {
      self.image = nil
      return
    }
    
    renderer.loadThumbnail(
      assetUrl: isFavIcon ? nil : assetUrl,
      favIconUrl: isFavIcon ? assetUrl : nil,
      completion: { [weak self] image in
        self?.image = image
      })
  }
}

private struct PlaylistFolderImage: View {
  let item: PlaylistInfo

  static let cornerRadius = 5.0
  private static let favIconSize = 16.0
  private var title: String?

  @StateObject private var thumbnailLoader = PlaylistThumbnailImageLoader()
  @StateObject private var favIconLoader = PlaylistThumbnailImageLoader()

  init(item: PlaylistInfo) {
    self.item = item
  }

  var body: some View {
    Image(uiImage: thumbnailLoader.image ?? .init())
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.black)
      .overlay(
        LinearGradient(
          colors: [.clear, .black],
          startPoint: .top,
          endPoint: .bottom)
      )
      .overlay(
        VStack(alignment: .leading) {
          Image(uiImage: favIconLoader.image ?? .init())
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .frame(
              width: PlaylistFolderImage.favIconSize,
              height: PlaylistFolderImage.favIconSize
            )
            .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
            .redacted(reason: favIconLoader.image == nil ? .placeholder : [])

          Spacer()
        }.padding(5.0), alignment: .topLeading
      )
      .clipShape(RoundedRectangle(cornerRadius: PlaylistFolderImage.cornerRadius, style: .continuous))
      .onAppear {
        thumbnailLoader.load(assetUrl: item.src)
        favIconLoader.load(favIconURL: item.pageSrc)
      }
  }
}

private class ViewModel: ObservableObject {
  @Published
  private(set) var item: PlaylistSharedFolderModel
  
  @Published
  var folderExists: Bool
  
  @Published
  var isLoading: Bool

  init(item: PlaylistSharedFolderModel, folderExists: Bool) {
    self.item = item
    self.folderExists = folderExists
    self.isLoading = true
  }
  
  private func fetchMediaItemInfo(item: PlaylistSharedFolderModel) async -> [PlaylistInfo] {
    
    @Sendable @MainActor
    func fetchTask(item: PlaylistInfo) async -> PlaylistInfo {
      await withCheckedContinuation { continuation in
        var webLoader: PlaylistWebLoader?
        webLoader = PlaylistWebLoader(
          certStore: nil,
          handler: { newItem in
            if let newItem = newItem {
              PlaylistManager.shared.getAssetDuration(item: newItem) { duration in
                let item = PlaylistInfo(name: item.name,
                                   src: newItem.src,
                                   pageSrc: newItem.pageSrc,
                                   pageTitle: item.pageTitle,
                                   mimeType: newItem.mimeType,
                                   duration: duration ?? newItem.duration,
                                   detected: newItem.detected,
                                   dateAdded: newItem.dateAdded,
                                   tagId: item.tagId)
                
                // Destroy the web loader when the callback is complete.
                webLoader?.removeFromSuperview()
                webLoader = nil
                continuation.resume(returning: item)
              }
            } else {
              // Destroy the web loader when the callback is complete.
              webLoader?.removeFromSuperview()
              webLoader = nil
              continuation.resume(returning: item)
            }
          }
        ).then {
          UIApplication.shared.keyWindow?.insertSubview($0, at: 0)
        }

        if let url = URL(string: item.pageSrc) {
          webLoader?.load(url: url)
        } else {
          webLoader = nil
        }
      }
    }

    return await withTaskGroup(of: PlaylistInfo.self, returning: [PlaylistInfo].self) { group in
      item.mediaItems.forEach { item in
        group.addTask {
          return await fetchTask(item: item)
        }
      }
      
      var result = [PlaylistInfo]()
      for await value in group {
        result.append(value)
      }
      return result
    }
  }
  
  func fetchPlaylist() {
    Task { @MainActor in
      guard let playlistURL = URL(string: "http://127.0.0.1:5005/playlist/\(item.playlistId)") else {
        return
      }
      
      self.isLoading = true
      let (data, _) = try await NetworkManager().dataRequest(with: playlistURL)
      var item = try JSONDecoder().decode(PlaylistSharedFolderModel.self, from: data)
      
      item.mediaItems = await fetchMediaItemInfo(item: item)
      self.item = item
      self.isLoading = false
    }
  }
  
  func addLocalFolder() {
    // Create a local shared folder
    PlaylistFolder.addFolder(title: self.item.folderName,
                             sharedFolderId: self.item.playlistId) { uuid in
      
      // Add the items to the folder
      PlaylistItem.addItems(self.item.mediaItems, folderUUID: uuid) {
        // Items were added
        self.item.mediaItems.forEach {
          // Download items
          PlaylistManager.shared.download(item: $0)
        }
        
        self.folderExists = true
      }
    }
  }
}

private struct MenuButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .foregroundColor(Color(configuration.isPressed ? .braveOrange : .bravePrimary))
      .background(Color(configuration.isPressed ? .secondaryBraveBackground : .braveBackground))
      .opacity(configuration.isPressed ? 1.0 : 0.75)
      .clipShape(Capsule())
  }
}

struct PlaylistFolderSharingView: View {
  @ObservedObject
  private var model: ViewModel
  var dismissAction: (() -> Void)?
  
  fileprivate init(item: ViewModel) {
    self._model = .init(wrappedValue: item)
  }

  var body: some View {
    List {
      AsyncImage(url: model.item.folderImage) { image in
        image.resizable()
          .aspectRatio(contentMode: .fit)
      } placeholder: {
        ProgressView()
      }
      .frame(minWidth: UIScreen.main.bounds.width, minHeight: 280.0, alignment: .center)
      .listRowInsets(.zero)
      .listRowBackground(Color.black)

      HStack(alignment: .center) {
        VStack(alignment: .leading) {
          Text(model.item.folderName)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(Color(.bravePrimary))
            .multilineTextAlignment(.leading)
            .redacted(reason: model.isLoading ? .placeholder : [])
          
          Text(model.item.creatorName.isEmpty ? "PlaceHolderName" : "By \(model.item.creatorName)")
            .font(.footnote)
            .foregroundColor(Color(.braveLabel))
            .multilineTextAlignment(.leading)
            .redacted(reason: model.isLoading ? .placeholder : [])
        }
        
        Spacer()
        
        if !model.folderExists {
          Button(action: {
            model.addLocalFolder()
          }) {
            if !model.isLoading {
              Text("+ Add")
                .font(.subheadline.bold())
                .foregroundColor(Color(.bravePrimary))
            }
          }
          .buttonStyle(BraveFilledButtonStyle(size: .normal))
          .disabled(model.isLoading)
          .redacted(reason: model.isLoading ? .placeholder : [])
        } else {
          Menu {
            Button(action: {
              model.fetchPlaylist()
            }) {
              HStack {
                Text("Sync Now")
                  .font(.body)
                  .foregroundColor(Color(.bravePrimary))
                Spacer()
                Image(uiImage: UIImage(named: "playlist_sync", in: .current, compatibleWith: nil)!)
              }
            }
            .buttonStyle(MenuButtonStyle())
            
//            Button(action: {}) {
//              HStack {
//                Text("Edit")
//                  .font(.body)
//                  .foregroundColor(Color(.bravePrimary))
//                Spacer()
//                Image(braveSystemName: "brave.edit")
//              }
//            }
//
//            Button(action: {}) {
//              HStack {
//                Text("Rename")
//                  .font(.body)
//                  .foregroundColor(Color(.bravePrimary))
//                Spacer()
//                Image(uiImage: UIImage(named: "playlist_rename_folder", in: .current, compatibleWith: nil)!)
//              }
//            }
            
            Button(action: {
              model.item.mediaItems.forEach({
                PlaylistManager.shared.deleteCache(item: $0)
              })
            }) {
              HStack {
                Text("Remove Offline Data")
                  .font(.body)
                  .foregroundColor(Color(.bravePrimary))
                Spacer()
                Image(uiImage: UIImage(named: "playlist_delete_download", in: .current, compatibleWith: nil)!)
              }
            }
            
            Button(action: {
              if let folder = PlaylistFolder.getSharedFolder(folderId: model.item.playlistId) {
                PlaylistManager.shared.delete(folder: folder)
                model.folderExists = false
              }
            }) {
              HStack {
                Text("Delete Playlist")
                  .font(.body)
                  .foregroundColor(Color.red)
                Spacer()
                Image(uiImage: UIImage(named: "playlist_delete_item", in: .current, compatibleWith: nil)!)
                  .foregroundColor(Color.red)
              }
            }
          } label: {
            Label("", systemImage: "ellipsis")
              .foregroundColor(Color(.bravePrimary))
          }
        }
      }
      .listRowInsets(EdgeInsets(top: 14.0, leading: 15.0, bottom: 5.0, trailing: 15.0))
      .listRowBackground(Color.clear)
      
      let items = model.isLoading ? (0..<5).map { _ in
        PlaylistInfo(pageSrc: "")
      } : model.item.mediaItems
      
      ForEach(items) { mediaItem in
        HStack(alignment: .center) {
          PlaylistFolderImage(item: mediaItem)
            .frame(width: 64 * 1.46875, height: 64.0,
                   alignment: .center)
          
          VStack(alignment: .leading) {
            Text(model.isLoading ? "Placeholder Title\nPlaceholder Title Second Line" : mediaItem.pageTitle)
              .font(.callout)
              .fontWeight(.medium)
              .foregroundColor(Color(.bravePrimary))
              .multilineTextAlignment(.leading)
              .redacted(reason: mediaItem.pageTitle.isEmpty ? .placeholder : [])
            
            Text(formatter.string(from: mediaItem.duration) ?? "N/A")
              .font(.footnote)
              .foregroundColor(Color(.secondaryBraveLabel))
              .multilineTextAlignment(.leading)
              .redacted(reason: model.isLoading ? .placeholder : [])
          }
          
          Spacer()
        }
        .listRowInsets(EdgeInsets(top: 5.0, leading: 15.0, bottom: 5.0, trailing: 15.0))
        .listRowBackground(Color.clear)
      }
    }
    .listStyle(.plain)
    .background(Color(.secondaryBraveBackground).ignoresSafeArea())
    .onAppear {
      UITableView.appearance().separatorColor = .clear
      UITableView.appearance().separatorInset = UIEdgeInsets(top: 0.0, left: UIScreen.main.bounds.width + 1, bottom: 0.0, right: -( UIScreen.main.bounds.width + 1))
    }
    .navigationTitle("Playlist")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(Strings.done) {
          dismissAction?()
        }
        .foregroundColor(Color(.braveOrange))
      }
    }
    .environment(\.colorScheme, .dark)
  }
  
  private let formatter = DateComponentsFormatter().then {
    $0.allowedUnits = [.day, .hour, .minute, .second]
    $0.unitsStyle = .abbreviated
    $0.maximumUnitCount = 2
  }
}

#if DEBUG
struct PlaylistFolderSharingView_Previews: PreviewProvider {
  static var previews: some View {
    let json = """
    {
      "version": "1",
      "playlistId": "BrandonT",
      "foldername": "Music List",
      "folderimage": "https://i.ytimg.com/vi/UsdGgRL1xHc/hqdefault.jpg",
      "creatorname": "CP24",
      "creatorlink": "https://twitter.com/CP24",
      "updateat": "1647913642",
      "mediaitems" : [
        {
          "mediaitemid": "E10217DF-A138-4F45-88C2-965BB03053CE",
          "title": "We Don't Talk About Bruno (From \\"Encanto\\")",
          "url": "https://www.youtube.com/watch?v=bvWRMAU6V-c"
        },
        {
          "mediaitemid": "38FD0115-B389-4A6E-B3C9-9081A42EB7AF",
          "title": "Jessica Darrow - Surface Pressure",
          "url": "https://www.youtube.com/watch?v=tQwVKr8rCYw"
        },
        {
          "mediaitemid": "6F9551CC-4211-4ED9-9048-CCF13504BF47",
          "title": "Snoop Dogg and Kevin Hart React to Island Boys",
          "url": "https://www.youtube.com/watch?v=PKYHaO0ZrH8"
        },
        {
          "mediaitemid": "ac07383e-4742-4781-923f-739e6aa2e1b0",
          "title": "Journey - Separate Ways (Worlds Apart) (Official Video - 1983)",
          "url": "https://www.youtube.com/watch?v=LatorN4P9aA"
        },
        {
          "mediaitemid": "c9468d6f-4fe3-4769-9f32-4adec6b7dea9",
          "title": "Passion Fruit - Drake (Guitar Cover)",
          "url": "https://www.youtube.com/watch?v=afMXqp5ZGVE"
        }
      ]
    }
    """
    
    let model = try! JSONDecoder().decode(PlaylistSharedFolderModel.self, from: json.data(using: .utf8)!)
    
    PlaylistFolderSharingView(item: ViewModel(item: model, folderExists: false))
  }
}
#endif

class PlaylistFolderSharingController: UIHostingController<PlaylistFolderSharingView> {

  private let networkManager = NetworkManager()
  private var model: ViewModel
  
  init(item: PlaylistSharedFolderModel, folderExists: Bool) {
    self.model = ViewModel(item: item, folderExists: folderExists)
    super.init(rootView: PlaylistFolderSharingView(item: self.model))
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    model.fetchPlaylist()
    
    rootView.dismissAction = { [weak self] in
      self?.dismiss(animated: true)
    }
  }
}
