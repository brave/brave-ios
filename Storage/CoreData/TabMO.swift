/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreData
import Shared

class TabMO: NSManagedObject {
    
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var syncUUID: String?
    @NSManaged var order: Int16
    @NSManaged var urlHistorySnapshot: NSArray? // array of strings for urls
    @NSManaged var urlHistoryCurrentIndex: Int16
    @NSManaged var screenshot: Data?
    @NSManaged var isSelected: Bool
    @NSManaged var isClosed: Bool
    @NSManaged var isPrivate: Bool
    
}

