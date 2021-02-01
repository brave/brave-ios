/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import Shared

private let log = Logger.browserLogger

public final class Device: NSManagedObject, CRUD {
    
    // Check if this can be nested inside the method
    static var sharedCurrentDeviceId: NSManagedObjectID?
    
    // Assign on parent model via CD
    @NSManaged public var isSynced: Bool
    
    @NSManaged public var created: Date?
    @NSManaged public var isCurrentDevice: Bool
    @NSManaged public var deviceDisplayId: String?
    @NSManaged public var syncDisplayUUID: String?
    @NSManaged public var name: String?
    
    // MARK: - Public interface
    
    public static func frc() -> NSFetchedResultsController<Device> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<Device>()
        fetchRequest.entity = Device.entity(context: context)
        
        let currentDeviceSort = NSSortDescriptor(key: "isCurrentDevice", ascending: false)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [currentDeviceSort, nameSort]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public func remove() {
        removeInternal()
    }
}

// MARK: Internal implementations

extension Device {
    
    static func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: "Bookmark", in: context)!
    }
    
    /// Returns a current device and assings it to a shared variable.
    static func currentDevice(context: NSManagedObjectContext = DataController.viewContext) -> Device? {
        guard let deviceId = sharedCurrentDeviceId else {
            let predicate = NSPredicate(format: "isCurrentDevice == true")
            let device = first(where: predicate, context: context)
            sharedCurrentDeviceId = device?.objectID
            return device
        }
        
        do {
            return try context.existingObject(with: deviceId) as? Device
        } catch {
            log.error("Failed to fetch device: \(error)")
            return nil
        }
    }
    
    class func add(name: String?, isCurrent: Bool = false) {
        DataController.perform { context in
            let device = Device(entity: Device.entity(context: context), insertInto: context)
            device.created = Date()
            device.name = name
            device.isCurrentDevice = isCurrent
        }
    }
    
    func removeInternal(save: Bool = true, sendToSync: Bool = true) {
        guard let context = managedObjectContext else { return }
        
        context.delete(self)
        if save { DataController.save(context: context) }
    }
}
