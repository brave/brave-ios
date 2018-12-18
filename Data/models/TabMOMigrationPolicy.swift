// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import CoreData

class TabMOMigrationPolicy: NSEntityMigrationPolicy {

    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        // In 1.6.6 we included private tabs in CoreData (temporarely) until the user did one of the following:
        //  - Cleared private data
        //  - Exited Private Mode
        //  - The app was terminated (bug)
        // However due to a bug, some private tabs remain in the container. Since 1.7 removes `isPrivate` from TabMO,
        // we must dismiss any records that are private tabs during migration from Model7
        if let isPrivate = sInstance.value(forKey: "isPrivate") as? Bool, isPrivate {
            return
        }
        try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
    }
}
