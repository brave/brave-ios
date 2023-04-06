// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import WidgetKit
import Strings
import BraveShared
import Intents
import BraveWidgetsModels

struct ShortcutsWidget: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: "ShortcutsWidget", intent: ShortcutsConfigurationIntent.self,
      provider: ShortcutProvider()
    ) { entry in
      ShortcutsView(slots: entry.shortcutSlots)
        .unredacted()
    }
    .configurationDisplayName(Strings.Widgets.shortcutsWidgetTitle)
    .description(Strings.Widgets.shortcutsWidgetDescription)
    .supportedFamilies([.systemMedium])
  }
}

private struct ShortcutEntry: TimelineEntry {
  var date: Date
  var shortcutSlots: [WidgetShortcut]
}

private struct ShortcutProvider: IntentTimelineProvider {
  typealias Intent = ShortcutsConfigurationIntent
  typealias Entry = ShortcutEntry
  func getSnapshot(
    for configuration: Intent, in context: Context,
    completion: @escaping (ShortcutEntry) -> Void
  ) {
    let entry = ShortcutEntry(
      date: Date(),
      shortcutSlots: [
        configuration.slot1,
        configuration.slot2,
        configuration.slot3,
      ]
    )
    completion(entry)
  }

  func placeholder(in context: Context) -> ShortcutEntry {
    .init(
      date: Date(),
      shortcutSlots: context.isPreview ? [] : [.playlist, .newPrivateTab, .bookmarks])
  }

  func getTimeline(
    for configuration: Intent, in context: Context,
    completion: @escaping (Timeline<ShortcutEntry>) -> Void
  ) {
    let entry = ShortcutEntry(
      date: Date(),
      shortcutSlots: [
        configuration.slot1,
        configuration.slot2,
        configuration.slot3,
      ]
    )
    completion(.init(entries: [entry], policy: .never))
  }
}

private struct ShortcutLink<Content: View>: View {
  var url: String
  var text: String
  var image: Content

  init(url: String, text: String, @ViewBuilder image: () -> Content) {
    self.url = url
    self.text = text
    self.image = image()
  }

  var body: some View {
    if let url = URL(string: url) {
      Link(
        destination: url,
        label: {
          VStack(spacing: 8) {
            image
              .imageScale(.large)
              .font(.system(size: 20))
              .frame(height: 24)
            Text(verbatim: text)
              .font(.system(size: 13, weight: .medium))
              .multilineTextAlignment(.center)
          }
          .padding(8)
          .foregroundColor(Color(UIColor.braveLabel))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            Color(UIColor.braveBackground)
              .clipShape(ContainerRelativeShape())
          )
        })
    } else {
      EmptyView()
    }
  }
}

extension WidgetShortcut {
  var displayString: String {
    switch self {
    case .unknown:
      assertionFailure()
      return ""
    case .newTab:
      return Strings.Widgets.shortcutsNewTabButton
    case .newPrivateTab:
      return Strings.Widgets.shortcutsPrivateTabButton
    // Reusing localized strings for few items here.
    case .bookmarks:
      return Strings.bookmarksMenuItem
    case .history:
      return Strings.historyMenuItem
    case .downloads:
      return Strings.downloadsMenuItem
    case .playlist:
      // We usually use `Brave Playlist` to describe this feature.
      // Here we try to be more concise and use 'Playlist' word only.
      return Strings.Widgets.shortcutsPlaylistButton
    case .search:
      return Strings.Widgets.searchShortcutTitle
    case .wallet:
      return Strings.Widgets.walletShortcutTitle
    case .scanQRCode:
      return Strings.QRCode
    case .braveNews:
      return Strings.BraveNews.braveNews
    @unknown default:
      assertionFailure()
      return ""
    }
  }

  var image: Image {
    switch self {
    case .unknown:
      assertionFailure()
      return Image(systemName: "xmark.octagon")
    case .newTab:
      return Image(braveSystemName: "brave.plus")
    case .newPrivateTab:
      return Image(braveSystemName: "brave.sunglasses")
    case .bookmarks:
      return Image(braveSystemName: "brave.book")
    case .history:
      return Image(braveSystemName: "brave.history")
    case .downloads:
      return Image(braveSystemName: "brave.arrow.down.to.line")
    case .playlist:
      return Image(braveSystemName: "brave.playlist")
    case .search:
      return Image(braveSystemName: "brave.magnifyingglass")
    case .wallet:
      return Image(braveSystemName: "brave.wallet")
    case .scanQRCode:
      return Image(braveSystemName: "brave.qr-code")
    case .braveNews:
      return Image(braveSystemName: "brave.newspaper")
    @unknown default:
      assertionFailure()
      return Image(systemName: "xmark.octagon")
    }
  }
}

private struct ShortcutsView: View {
  var slots: [WidgetShortcut]

  var body: some View {
    VStack(spacing: 8) {
      // TODO: Would be nice to export handling this url to `BraveShared`.
      // Now it's hardcoded here and in `NavigationRouter`.
      if let url = URL(string: "\(BraveUX.appURLScheme)://shortcut?path=0") {
        Link(
          destination: url,
          label: {
            Label {
              Text(Strings.Widgets.shortcutsEnterURLButton)
            } icon: {
              Image("brave-logo-no-bg-small")
            }
            .foregroundColor(Color(UIColor.braveLabel))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
              Color(UIColor.braveBackground)
                .clipShape(ContainerRelativeShape())
            )
          })
      }
      HStack(spacing: 8) {
        ForEach(slots, id: \.self) { shortcut in
          ShortcutLink(
            url: "\(BraveUX.appURLScheme)://shortcut?path=\(shortcut.rawValue)",
            text: shortcut.displayString,
            image: {
              shortcut.image
            })
        }
      }
      .frame(maxHeight: .infinity)
    }
    .padding(8)
    .background(Color(UIColor.secondaryBraveBackground))
  }
}

// MARK: - Previews

#if DEBUG
struct ShortcutsWidget_Previews: PreviewProvider {
  static var previews: some View {
    ShortcutsView(slots: [.newTab, .newPrivateTab, .bookmarks])
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    ShortcutsView(slots: [.downloads, .history, .playlist])
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    ShortcutsView(slots: [.wallet, .search, .scanQRCode])
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
#endif
