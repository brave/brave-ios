// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CoreData
import BraveShared

extension BrowserViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateWidgetFavoritesData()
    }
    
    func updateWidgetFavoritesData() {
        guard let frc = widgetBookmarksFRC else { return }
        try? frc.performFetch()
        if let favs = frc.fetchedObjects {
            let group = DispatchGroup()
            var favData: [WidgetFavorite] = []
            favs.prefix(16).forEach { fav in
                if let url = fav.url?.asURL {
                    group.enter()
                    let fetcher = FaviconFetcher(siteURL: url, kind: .largeIcon)
                    widgetFaviconFetchers.append(fetcher)
                    fetcher.load { _, attributes in
                        favData.append(.init(url: url, favicon: attributes, order: Int(fav.order)))
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) { [self] in
                widgetFaviconFetchers.removeAll()
                FavoritesWidgetData.updateWidgetData(favData)
            }
        }
    }
}
