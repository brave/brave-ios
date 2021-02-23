// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//

import Foundation
import CoreData

extension PlaylistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistItem> {
        return NSFetchRequest<PlaylistItem>(entityName: "PlaylistItem")
    }

    @NSManaged public var cachedData: Data?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var duration: Float
    @NSManaged public var mediaSrc: String?
    @NSManaged public var mimeType: String?
    @NSManaged public var name: String?
    @NSManaged public var pageSrc: String?
    @NSManaged public var pageTitle: String?

}
