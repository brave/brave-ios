// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import BraveUI
import Introspect
import Data

public struct PlaylistCoreDataContainerView: View {
  struct ViewWithContext: View {
    @FetchRequest(entity: PlaylistFolder.entity(), sortDescriptors: [
      NSSortDescriptor(keyPath: \PlaylistFolder.order, ascending: true),
      NSSortDescriptor(keyPath: \PlaylistFolder.dateAdded, ascending: false),
    ]) var folders: FetchedResults<PlaylistFolder>
    
    var body: some View {
      PlaylistContainerView(folders: folders.map(Folder.from))
    }
  }
  
  public init() {}
  
  public var body: some View {
    ViewWithContext()
      .environment(\.managedObjectContext, DataController.swiftUIContext)
  }
}

/// Controls displaying Playlist content on any display size
///
/// On a compact-width layout we have the following structure:
///   - The list of playlists folder is at the root of the navigation stack
///   - The player & folder contents exist in one screen pushed onto the stack.
///     - The folder contents lives as a drawer that is draggable up and down
///     - Dragging this drawer up and down can change the player & player controls based on stopping points
///   - The PiP button will sit in the player controls between the speed and sleep timer
///   - Create playlist button is in the navigation bar
///
/// On a regular-width layout we have the following structure:
///   - The list of playlist folders will exist in a sidebar whos visibility can be toggled
///   - The PiP button will sit in the navigation bar
///   - Create playlist button is at the bottom of the folders list
///   - If the width exceeds some threshold (i.e. in landscape orientation), then:
///     - When selecting a folder, the contents list which would usually live in the drawer in compact-width
///       scenarios will now be pushed into the sidebar
///     - The main navigation stack only contains the player
///   - Else:
///     - A sidebar can be toggled to be visible but it will only ever contain the folder list
///     - The folder list will be displayed as a drawer under the player controls, _but_ that drawer is not
///       draggable.
///
///  When transitioning between the two states we have to reset the selected folders since they don't
///  maintain the same navigation stack.
public struct PlaylistContainerView: View {
  public var folders: [Folder]
  
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.dismiss) private var dismiss
  @State private var orientation: UIInterfaceOrientation = .unknown
  
  @State private var isSidebarVisible: Bool = false
  
  @State private var selectedFolderID: Folder.ID?
  @State private var sidebarFolderItemsPresented: Bool = false
  @State private var selectedItemID: Item.ID?
  
  public init(folders: [Folder]) {
    self.folders = folders
    self._selectedFolderID = State(wrappedValue: folders.first?.id)
  }
  
  private var selectedFolder: Folder? {
    folders.first(where: { $0.id == self.selectedFolderID })
  }
  
  private var closeButton: some View {
    Button {
      dismiss()
    } label: {
      Image(braveSystemName: "leo.close")
    }
  }
  
  private var editFolderMenu: some View {
    Menu {
      Button { } label: {
        Label("Edit", braveSystemImage: "leo.folder.exchange")
      }
      Button { } label: {
        Label("Rename", braveSystemImage: "leo.edit.box")
      }
      Button { } label: {
        Label("Remove Offline Data", braveSystemImage: "leo.cloud.off")
      }
      Button(role: .destructive) { } label: {
        Label("Delete", braveSystemImage: "leo.trash")
      }
    } label: {
      Image(braveSystemName: "leo.more.horizontal")
    }
  }
  
  public var body: some View {
    let _ = Self._printChanges()
    NavigationView {
      switch horizontalSizeClass {
      case .regular:
        // iPad layout, iPhone Max phones in landscape
        HStack(spacing: 0) {
          if orientation.isLandscape || isSidebarVisible {
            HStack(spacing: 0) {
              NavigationView {
                PlaylistFolderListView(
                  folders: folders,
                  sharedFolders: [],
                  selectedFolderID: Binding(get: { selectedFolderID }, set: { newValue in
                    selectedFolderID = newValue
                    sidebarFolderItemsPresented = true
                  })
                )
                  .osAvailabilityModifiers { content in
                    if #available(iOS 16.0, *) {
                      content.toolbar(.hidden, for: .navigationBar)
                    } else {
                      content
                    }
                  }
                  .background {
                    if orientation.isLandscape {
                      NavigationLink(isActive: $sidebarFolderItemsPresented) {
                        if let selectedFolder {
                          VStack(spacing: 0) {
                            PlaylistItemHeaderView(folder: selectedFolder)
                            PlaylistItemListView(folder: selectedFolder, selectedItemId: selectedItemID)
                              .background(Color(.braveBackground))
                          }
                          .osAvailabilityModifiers { content in
                            if #available(iOS 16.0, *) {
                              content.toolbar(.hidden, for: .navigationBar)
                            } else {
                              content
                            }
                          }
                        }
                      } label: {
                        Color.clear
                      }
                      .accessibilityHidden(true)
                    }
                  }
              }
              .navigationViewStyle(.stack)
              .frame(width: 280)
              .frame(maxHeight: .infinity)
            }
            .transition(.move(edge: .leading))
            .overlay {
              Divider()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .ignoresSafeArea()
            }
          }
          PlaylistView(folder: selectedFolder, orientation: orientation)
        }
        .animation(.default, value: orientation.isLandscape || isSidebarVisible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Playlists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            if !orientation.isLandscape {
              Button {
                isSidebarVisible.toggle()
              } label: {
                Image(systemName: "sidebar.left")
              }
            } else {
              if sidebarFolderItemsPresented {
                Button {
                  sidebarFolderItemsPresented = false
                } label: {
                  Text("Playlists")
                }
              }
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
              Button { } label: {
                Image(braveSystemName: "leo.picture.in-picture")
              }
              if selectedFolderID != nil {
                editFolderMenu
              }
              closeButton
            }
          }
        }
        .osAvailabilityModifiers { content in
          if #available(iOS 16.0, *) {
            content
              .toolbarBackground(.visible, for: .navigationBar)
              .toolbarBackground(Color(.braveBackground), for: .navigationBar)
          } else {
            content.introspectViewController { controller in
              let appearance: UINavigationBarAppearance = {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundEffect = nil
                return appearance
              }()
              controller.navigationItem.standardAppearance = appearance
              controller.navigationItem.compactAppearance = appearance
              controller.navigationItem.scrollEdgeAppearance = appearance
            }
          }
        }
      case .compact:
        PlaylistFolderListView(folders: folders, sharedFolders: [], selectedFolderID: $selectedFolderID)
          .background {
            NavigationLink(isActive: Binding(get: { selectedFolderID != nil }, set: { if !$0 { selectedFolderID = nil } })) {
              PlaylistView(folder: selectedFolder, orientation: orientation)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(selectedFolder?.title ?? "Playlist")
                .toolbar {
                  HStack {
                    editFolderMenu
                    closeButton
                  }
                  .tint(Color.white)
                }
                .osAvailabilityModifiers { content in
                  if #available(iOS 16.0, *) {
                    content
                      .toolbarColorScheme(.dark, for: .navigationBar)
                      .toolbarBackground(.visible, for: .navigationBar)
                  } else {
                    content
                      .introspectViewController { controller in
                        let appearance: UINavigationBarAppearance = {
                          let appearance = UINavigationBarAppearance()
                          appearance.configureWithTransparentBackground()
                          appearance.backgroundEffect = nil
                          appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                          appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                          appearance.backButtonAppearance = UIBarButtonItemAppearance(style: .plain).then {
                            $0.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                          }
                          return appearance
                        }()
                        controller.navigationItem.standardAppearance = appearance
                        controller.navigationItem.compactAppearance = appearance
                        controller.navigationItem.scrollEdgeAppearance = appearance
                      }
                  }
                }
            } label: {
              Color.clear
                .accessibilityHidden(true)
            }
          }
      default:
        EmptyView()
      }
    }
    .navigationViewStyle(.stack)
    .background {
      OrientationWatcher(orientation: $orientation)
        .accessibilityHidden(true)
    }
    .onChange(of: horizontalSizeClass) { [oldValue=horizontalSizeClass] newValue in
      if oldValue == .compact, newValue == .regular, selectedFolderID == nil {
        // Reset the selected folder ID when moving from compact folder list to regular which always displays
        // the player
        selectedFolderID = folders.first?.id
      }
    }
  }
}

public struct OrientationWatcher: UIViewControllerRepresentable {
  @Binding var orientation: UIInterfaceOrientation
  
  public func makeUIViewController(context: Context) -> some UIViewController {
    OrientationWatcherViewController(orientation: $orientation)
  }
  
  public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
  }
}

class OrientationWatcherViewController: UIViewController {
  @Binding var orientation: UIInterfaceOrientation
  
  init(orientation: Binding<UIInterfaceOrientation>) {
    self._orientation = orientation
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
  
  private func updateOrientation() {
    if let interfaceOrientation = currentScene?.interfaceOrientation {
      orientation = interfaceOrientation
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateOrientation()
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    updateOrientation()
  }
}

public struct PlayerView: View {
  public var orientation: UIInterfaceOrientation
  
  @State private var isControlsVisible: Bool = true
  
  public var body: some View {
    if #available(iOS 16.0, *) {
      (orientation.isPortrait ? AnyLayout(VStackLayout()) : AnyLayout(ZStackLayout(alignment: .bottom))) {
        Color.clear
          .aspectRatio(16/9, contentMode: .fit)
          .overlay {
            LinearGradient(braveGradient: .gradient03) // Video player?
          }
          .clipped()
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxHeight: .infinity)
          .onTapGesture {
            withAnimation(.interactiveSpring) {
              isControlsVisible.toggle()
            }
          }
        if orientation.isPortrait || orientation.isLandscape && isControlsVisible {
          ControlView(title: "")
            .padding(.vertical, 24)
            .contentShape(Rectangle())
            .background {
              if orientation.isLandscape {
                PartialRoundedRectangle(cornerRadius: 10, corners: [.topLeft, .topRight])
                  .fill(Material.bar)
                  .colorScheme(.dark)
                  .ignoresSafeArea()
                  .transition(.opacity.animation(.default))
              }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
    } else {
      Color.clear
        .overlay {
          LinearGradient(braveGradient: .gradient03) // Video player?
        }
        .clipped()
        .aspectRatio(16/9, contentMode: .fit)
        .fixedSize(horizontal: false, vertical: true)
      ControlView(title: "")
        .padding(.vertical, 24)
        .contentShape(Rectangle())
    }
  }
}

public struct PlayerBackgroundView: View {
  public var body: some View {
    ZStack {
      // Thumbnail or some representation of the video
      LinearGradient(braveGradient: .gradient03)
      VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
    }
    .ignoresSafeArea()
  }
}

public struct PlaylistView: View {
  public var folder: Folder?
  var orientation: UIInterfaceOrientation
  
  @State private var selectedFolderID: Folder.ID?
  @State private var selectedItemID: Item.ID?
  @State private var offset: CGFloat = 0
  @State private var drawerHeight: CGFloat = 0
  @State private var screenHeight: CGFloat = 0
  @State private var listHeight: CGFloat = 0
  @GestureState private var isDragging: Bool = false
  @State private var startHeight: CGFloat?
  
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
//  private var selectedFolder: Folder? {
//    folders.first(where: { $0.id == self.selectedFolderID })
//  }
  
//  public init(folders: [Folder], initiallySelectedFolder: Folder.ID? = nil) {
//    self.folders = folders
//    // This will only work the first time the view is created.
//    self._selectedFolderID = State(wrappedValue: initiallySelectedFolder)
//  }
  
  var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .global)
      .updating($isDragging, body: { _, state, _ in
        state = true
      })
      .onChanged { (value: DragGesture.Value) in
        if startHeight == nil {
          startHeight = drawerHeight
        }
        drawerHeight = min(screenHeight, startHeight! - value.translation.height)
      }
      .onEnded { (value: DragGesture.Value) in
        let endHeight = startHeight! - value.predictedEndTranslation.height
        startHeight = nil
        let stopPoints = [0, 0.75, 1.0].map { screenHeight * $0 }
        let ranges = stopPoints.enumerated().reduce(into: [(Range<Double>, Int)](), {
          if $1.offset == stopPoints.count - 1 {
            $0.append(($1.element..<CGFloat.infinity, $1.offset))
          } else {
            let nextElement = stopPoints[$1.offset+1]
//            let halfPoint = $1.element + ((nextElement - $1.element) / 2.0)
//            $0.append(($1.element..<halfPoint, $1.offset))
//            $0.append((halfPoint..<nextElement, $1.offset+1))
            $0.append(($1.element..<nextElement, $1.offset))
          }
        })
        withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0.0, initialVelocity: value.velocity.height / screenHeight)) {
          if let index = ranges.first(where: { $0.0.contains(endHeight)})?.1 {
            let screenRelativeHeight = stopPoints[index] / screenHeight
            drawerHeight = listHeight + (screenRelativeHeight * (screenHeight - listHeight))
          } else {
            drawerHeight = listHeight
          }
        }
      }
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      PlayerView(orientation: orientation)
      if orientation == .portrait {
        Color.clear
          .frame(minHeight: 100)
          .background {
            GeometryReader { proxy in
              Color.clear
                .onAppear {
                  listHeight = proxy.size.height
                  drawerHeight = listHeight
                }
                .onChange(of: proxy.size.height) { newValue in
                  listHeight = newValue
                  if !isDragging {
                    drawerHeight = listHeight
                  }
                }
            }
          }
          .overlay(alignment: .bottom) {
            if let folder, orientation.isPortrait {
              VStack(spacing: 0) {
                VStack(spacing: 0) {
                  // Grabber
                  Capsule()
                    .opacity(0.3)
                    .frame(width: 32, height: 4)
                    .padding(.top, 6)
                  PlaylistItemHeaderView(folder: folder)
                }
                .frame(maxWidth: .infinity)
                .background(Color(.braveBackground))
                .clipShape(PartialRoundedRectangle(cornerRadius: drawerHeight == screenHeight ? 0 : 10, corners: [.topLeft, .topRight]))
                .contentShape(PartialRoundedRectangle(cornerRadius: drawerHeight == screenHeight ? 0 : 10, corners: [.topLeft, .topRight]))
                .simultaneousGesture(dragGesture)
                
                PlaylistItemListView(folder: folder, selectedItemId: selectedItemID)
                  .background(Color(.braveBackground))
              }
              .frame(height: drawerHeight)
            }
          }
      }
    }
    .frame(maxHeight: .infinity)
    .background {
      GeometryReader { proxy in
        Color.clear
          .onAppear { screenHeight = proxy.size.height }
          .onChange(of: proxy.size.height) { newValue in
            screenHeight = newValue
          }
      }
    }
    .background(PlayerBackgroundView())
  }
}

@available(iOS, introduced: 13.0, obsoleted: 16.0, message: "Use UnevenRoundedRectangle")
struct PartialRoundedRectangle: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath)
  }
}

// These definitions can be removed once we move to Xcode 15
#if swift(<5.9)
extension DragGesture.Value {
  /// This version of `velocity` is found the iOS 17 SDK's SwiftUI swiftinterface file and
  /// is backported to iOS 13
  public var velocity: CGSize {
    let predicted = predictedEndLocation
    return CGSize(
      width: 4.0 * (predicted.x - location.x),
      height: 4.0 * (predicted.y - location.y)
    )
  }
}

extension SwiftUI.Animation {
  /// This version of `interpolatingSpring` is found the iOS 17 SDK's SwiftUI swiftinterface
  /// file and is backported to iOS 13
  public static func interpolatingSpring(
    duration: TimeInterval = 0.5,
    bounce: Double = 0.0,
    initialVelocity: Swift.Double = 0.0
  ) -> SwiftUI.Animation {
    func springStiffness(response: Double) -> Double {
      if response <= 0 {
        return .infinity
      } else {
        let freq = (2.0 * Double.pi) / response
        return freq * freq
      }
    }
    func springDamping(fraction: Double, stiffness: Double) -> Double {
      let criticalDamping = 2 * stiffness.squareRoot()
      return criticalDamping * fraction
    }
    func springDampingFraction(bounce: Double) -> Double {
      (bounce < 0.0) ? 1.0 / (bounce + 1.0) : 1.0 - bounce
    }
    let stiffness = springStiffness(response: duration)
    let fraction = springDampingFraction(bounce: bounce)
    let damping = springDamping(fraction: fraction, stiffness: stiffness)
    return interpolatingSpring(
      stiffness: stiffness,
      damping: damping,
      initialVelocity: initialVelocity
    )
  }
}
#endif

#if DEBUG
struct PlaylistView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    PlaylistContainerView(folders: [.init(id: PlaylistFolder.savedFolderUUID, title: "Play Later", items: (0..<10).map { i in
        .init(id: "\(i)", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
    })])
//    Color.black.fullScreenCover(isPresented: .constant(true)) {
//      NavigationView {
//        PlaylistView(folders: [.init(id: "1", title: "Play Later", items: (0..<10).map { i in
//            .init(id: "\(i)", dateAdded: .now, duration: 1204, source: URL(string: "https://brave.com")!, name: "I’m Dumb and Spent $7,000 on the New Mac Pro", pageSource: URL(string: "https://brave.com")!)
//        })], initiallySelectedFolder: "1")
//      }
//    }
  }
}
#endif
