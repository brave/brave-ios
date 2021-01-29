// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WidgetKit
import SwiftUI
import Shared
import BraveShared

struct FavoriteEntry: TimelineEntry {
    var date: Date
    var favorites: [WidgetFavorite]?
}

struct FavoritesProvider: TimelineProvider {
    typealias Entry = FavoriteEntry
    
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), favorites: [])
    }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let favorites = FavoritesWidgetData.loadWidgetData()
        completion(Entry(date: Date(), favorites: favorites))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let favorites = FavoritesWidgetData.loadWidgetData()
        completion(Timeline(entries: [Entry(date: Date(), favorites: favorites)], policy: .never))
    }
}

struct FaviconImage: View {
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

struct NoFavoritesFoundView: View {
    var body: some View {
        VStack {
            Image("brave-icon")
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text("Please open Brave to view your favorites here")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding()
    }
}

struct FavoritesView: View {
    var entry: FavoriteEntry
    
    var body: some View {
        Group {
            if entry.favorites == nil {
                NoFavoritesFoundView()
            } else {
                FavoritesGridView(entry: entry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(red: 59.0/255.0, green: 62.0/255.0, blue: 79.0/255.0, alpha: 1.0)))
    }
}

struct FavoritesGridView: View {
    var entry: FavoriteEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var numberOfRows: Int {
        switch widgetFamily {
        case .systemMedium:
            return 2
        case .systemLarge:
            return 4
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
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
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
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
        case .systemSmall:
            assertionFailure("systemSmall widget family isn't supported")
            return 0
        @unknown default:
            return 0
        }
    }
    
    var itemShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: widgetFamily == .systemMedium ? 16 : 12, style: .continuous)
    }
    
    func favorite(atRow row: Int, column: Int) -> WidgetFavorite? {
        guard let favorites = entry.favorites else { return nil }
        let index = (row * 4) + column
        if index < favorites.count {
            return favorites[index]
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
                                .background(Color.black.opacity(0.05).clipShape(itemShape))
                                .overlay(
                                    itemShape
                                        .strokeBorder(Color.black.opacity(0.1), lineWidth: pixelLength)
                                )
                            })
                        } else {
                            itemShape
                                .fill(Color.black.opacity(0.05))
                                .overlay(
                                    itemShape
                                        .strokeBorder(Color.black.opacity(0.2), lineWidth: pixelLength)
                                )
                                .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                }
            }
        }
//        .border(Color.red)
        .padding(8)
        .padding(widgetFamily == .systemLarge ? 4 : 0)
//        .border(Color.black)
    }
}

struct FavoritesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FavoritesWidget", provider: FavoritesProvider()) { entry in
            FavoritesView(entry: entry)
        }
        .configurationDisplayName("Favorites")
        .description("Your favorite sites")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(entry: .init(date: Date(), favorites: nil))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        FavoritesView(entry: .init(date: Date(), favorites: [
//            .init(url: URL(string: "https://brave.com")!, faviconAttributes: <#T##FaviconAttributes?#>)
        ]))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        FavoritesView(entry: .init(date: Date(), favorites: []))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
