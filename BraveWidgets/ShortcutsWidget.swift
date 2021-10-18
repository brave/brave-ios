// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import WidgetKit
import BraveShared
import Intents

struct ShortcutEntry: TimelineEntry {
    var date: Date
    var shortcutSlots: [WidgetShortcut]
}

struct ShortcutProvider: IntentTimelineProvider {
    typealias Intent = ShortcutsConfigurationIntent
    typealias Entry = ShortcutEntry
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (ShortcutEntry) -> Void) {
        let entry = ShortcutEntry(
            date: Date(),
            shortcutSlots: [
                configuration.slot1,
                configuration.slot2,
                configuration.slot3
            ]
        )
        completion(entry)
    }
    func placeholder(in context: Context) -> ShortcutEntry {
        .init(date: Date(), shortcutSlots: [.newTab, .newPrivateTab, .bookmarks])
    }
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<ShortcutEntry>) -> Void) {
        let entry = ShortcutEntry(
            date: Date(),
            shortcutSlots: [
                configuration.slot1,
                configuration.slot2,
                configuration.slot3
            ]
        )
        completion(.init(entries: [entry], policy: .never))
    }
}

struct ShortcutsWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "ShortcutsWidget", intent: ShortcutsConfigurationIntent.self, provider: ShortcutProvider()) { entry in
            ShortcutsView(slots: entry.shortcutSlots)
        }
        .configurationDisplayName("Shortcuts")
        .description("")
        .supportedFamilies([.systemMedium])
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
        Link(destination: URL(string: url)!, label: {
            VStack(spacing: 8) {
                image
                    .imageScale(.large)
                    .font(Font.system(.body).bold())
                    .frame(height: 24)
                Text(verbatim: text)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.white
                    .opacity(0.2)
                    .clipShape(ContainerRelativeShape())
            )
        })
    }
}

extension WidgetShortcut {
    var displayString: String {
        switch self {
        case .unknown:
            fatalError()
        case .newTab:
            return "New Tab"
        case .newPrivateTab:
            return "Private Tab"
        case .bookmarks:
            return "Bookmarks"
        case .history:
            return "History"
        case .downloads:
            return "Downloads"
        case .toggleVPN:
            return "Toggle VPN"
        case .braveToday:
            return "Brave Today"
        }
    }
    var image: Image {
        switch self {
        case .unknown:
            fatalError()
        case .newTab:
            return Image(uiImage: UIImage(named: "brave.plus")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        case .newPrivateTab:
            return Image(uiImage: UIImage(named: "brave.shades")!.template)
//            return Image(uiImage: UIImage(named: "brave.shades")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        case .bookmarks:
            return Image(uiImage: UIImage(named: "menu_bookmarks")!.template)
        case .history:
            return Image(uiImage: UIImage(named: "brave.history")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        case .downloads:
            return Image(uiImage: UIImage(named: "brave.downloads")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        case .toggleVPN:
            return Image(uiImage: UIImage(named: "brave.vpn")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        case .braveToday:
            return Image(uiImage: UIImage(named: "brave.today")!.applyingSymbolConfiguration(.init(font: .systemFont(ofSize: 20)))!.template)
        }
    }
}

struct ShortcutsView: View {
    var slots: [WidgetShortcut]
    
    var body: some View {
        VStack(spacing: 8) {
            Link(destination: URL(string: "brave://shortcut?path=0")!, label: {
                Label("Search or enter address", systemImage: "magnifyingglass")
                    .labelStyle(IconOnlyLabelStyle())
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Color.white
                            .opacity(0.2)
                            .clipShape(ContainerRelativeShape())
                    )
            })
            HStack(spacing: 8) {
                ForEach(slots, id: \.self) { shortcut in
                    ShortcutLink(
                        url: "brave://shortcut?path=\(shortcut.rawValue)",
                        text: shortcut.displayString,
                        image: {
                            shortcut.image
                        })
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(8)
        .background(
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(UIColor(rgb: 0xF73A1C)),
                        Color(UIColor(rgb: 0xBF14A2))
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct ShortcutsWidget_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsView(slots: [.newTab, .newPrivateTab, .bookmarks])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        ShortcutsView(slots: [.downloads, .history, .toggleVPN])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        ShortcutsView(slots: [.braveToday])
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
