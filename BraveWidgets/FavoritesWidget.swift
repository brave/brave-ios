// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WidgetKit
import SwiftUI
import Shared
import BraveShared

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FavoritesWidget", provider: FavoritesProvider()) { entry in
            FavoritesView(entry: entry)
        }
        .configurationDisplayName(Strings.Widgets.favoritesWidgetTitle)
        .description(Strings.Widgets.favoritesWidgetDescription)
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct FavoriteEntry: TimelineEntry {
    var date: Date
    var favorites: [WidgetFavorite]
}

private struct FavoritesProvider: TimelineProvider {
    typealias Entry = FavoriteEntry
    
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), favorites: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let favorites = FavoritesWidgetData.loadWidgetData() ?? []
        completion(Entry(date: Date(), favorites: favorites))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let favorites = FavoritesWidgetData.loadWidgetData() ?? []
        completion(Timeline(entries: [Entry(date: Date(), favorites: favorites)], policy: .never))
    }
}

private struct FaviconImage: View {
    var image: UIImage
    var contentMode: UIView.ContentMode
    
    var body: some View {
        switch contentMode {
        case .scaleToFill, .scaleAspectFit, .scaleAspectFill:
            Image(uiImage: image)
                .resizable()
        default:
            Image(uiImage: image)
                .resizable()
                .frame(width: 44, height: 44)
        }
    }
}

private struct NoFavoritesFoundView: View {
    var body: some View {
        VStack {
            Image("brave-icon")
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(Strings.Widgets.noFavoritesFound)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding()
    }
}

private struct FavoritesView: View {
    var entry: FavoriteEntry
    
    var body: some View {
        Group {
            if entry.favorites.isEmpty {
                NoFavoritesFoundView()
            } else {
                FavoritesGridView(entry: entry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondaryBraveBackground))
    }
}

private struct FavoritesGridView: View {
    var entry: FavoriteEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var numberOfRows: Int {
        switch widgetFamily {
        case .systemMedium:
            return 2
        case .systemLarge:
            return 4
        case .systemSmall, .systemExtraLarge:
            assertionFailure("widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var verticalSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 8
        case .systemLarge:
            return 22
        case .systemSmall, .systemExtraLarge:
            assertionFailure("widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var horizontalSpacing: CGFloat {
        switch widgetFamily {
        case .systemMedium:
            return 18
        case .systemLarge:
            return 18
        case .systemSmall, .systemExtraLarge:
            assertionFailure("widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var itemShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: widgetFamily == .systemMedium ? 16 : 12, style: .continuous)
    }
    
    func favorite(atRow row: Int, column: Int) -> WidgetFavorite? {
        let favorites = entry.favorites
        let index = (row * 4) + column
        if index < favorites.count {
            return favorites[safe: index]
        }
        return nil
    }
    
    @Environment(\.pixelLength) var pixelLength
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            ForEach(0..<numberOfRows) { row in
                HStack(spacing: horizontalSpacing) {
                    ForEach(0..<4) { column in
                        if let favorite = favorite(atRow: row, column: column) {
                            Link(destination: favorite.url, label: {
                                Group {
                                    if let attributes = favorite.favicon, let image = attributes.image {
                                        FaviconImage(image: image, contentMode: attributes.contentMode)
                                            .padding(attributes.includePadding ? 4 : 0)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color(attributes.backgroundColor ?? .clear))
                                    } else {
                                        Text(verbatim: favorite.url.baseDomain?.first?.uppercased() ?? "")
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .font(.system(size: 36))
                                            .background(Color.white)
                                    }
                                }
                                .clipShape(itemShape)
                                .background(Color(UIColor.braveBackground).opacity(0.05).clipShape(itemShape))
                                .overlay(
                                    itemShape
                                        .strokeBorder(Color(UIColor.braveBackground).opacity(0.1), lineWidth: pixelLength)
                                )
                            })
                        } else {
                            itemShape
                                .fill(.clear)
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                }
            }
        }
        .padding(8)
        .padding(widgetFamily == .systemLarge ? 4 : 0)
    }
}

// MARK: - Preview

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(entry: .init(date: Date(), favorites: []))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        FavoritesView(entry: .init(date: Date(), favorites: [
            // TODO: Fill with favorites.
        ]))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        FavoritesView(entry: .init(date: Date(), favorites: []))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
