/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import CoreData
import Foundation
import Shared

private let log = Logger.browserLogger

public final class Device: NSManagedObject, Syncable, CRUD {
    
    // Check if this can be nested inside the method
    static var sharedCurrentDevice: Device?
    
    // Assign on parent model via CD
    @NSManaged public var isSynced: Bool
    
    @NSManaged public var created: Date?
    @NSManaged public var isCurrentDevice: Bool
    @NSManaged public var deviceDisplayId: String?
    @NSManaged public var syncDisplayUUID: String?
    @NSManaged public var name: String?
    
    // Device is subtype of prefs 🤢
    public var recordType: SyncRecordType = .prefs
    
    // Just a facade around the displayId, for easier access and better CD storage
    var deviceId: [Int]? {
        get { return SyncHelpers.syncUUID(fromString: deviceDisplayId) }
        set(value) { deviceDisplayId = SyncHelpers.syncDisplay(fromUUID: value) }
    }
    
    public static func frc() -> NSFetchedResultsController<Device> {
        let context = DataController.viewContext
        let fetchRequest = NSFetchRequest<Device>()
        fetchRequest.entity = Device.entity(context: context)
        
        let currentDeviceSort = NSSortDescriptor(key: "isCurrentDevice", ascending: false)
        fetchRequest.sortDescriptors = [currentDeviceSort]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                          sectionNameKeyPath: nil, cacheName: nil)
    }
    
    public class func add(name: String?, isCurrent: Bool = false) {
        DataController.performTask { context in
            let device = Device(entity: Device.entity(context: context), insertInto: context)
            device.created = Date()
            device.syncUUID = SyncCrypto.uniqueSerialBytes(count: 16)
            device.name = name
            device.isCurrentDevice = isCurrent
        }
    }
    
    /// Returns a current device and assings it to a shared variable.
    public static func currentDevice(context: NSManagedObjectContext? = nil) -> Device? {
        if sharedCurrentDevice == nil {
            let predicate = NSPredicate(format: "isCurrentDevice == true")
            sharedCurrentDevice = first(where: predicate, context: context)
        } else if context != nil, let sharedDevice = sharedCurrentDevice {
            sharedCurrentDevice = context?.object(with: sharedDevice.objectID) as? Device
        }
        
        return sharedCurrentDevice
    }
    
    public func remove(save: Bool = true, sendToSync: Bool = true) {
        guard let context = managedObjectContext else { return }
        
        if sendToSync {
            Sync.shared.sendSyncRecords(action: .delete, records: [self])
        }
        
        if isCurrentDevice {
            Sync.shared.leaveSyncGroup(sendToSync: false)
        } else {
            context.delete(self)
            if save { DataController.save(context: context) }
        }
    }
    
    public class func deleteAll() {
        sharedCurrentDevice = nil
        Device.deleteAll(includesPropertyValues: false)
    }
    
    // BRAVE TODO:
    /*
    public class func deviceSettings(profile: Profile) -> [SyncDeviceSetting]? {
        // Building settings off of device objects
        
        let deviceSettings = Device.all()?.map {
            // Even if no 'real' title, still want it to show up in list
            return SyncDeviceSetting(profile: profile, device: $0)
        }
        
        return deviceSettings
    }
    */
}

// MARK: - Syncable methods
extension Device {
    public static func createResolvedRecord(rootObject root: SyncRecord?, save: Bool,
                                            context: NSManagedObjectContext) {
        
        // No guard, let bleed through to allow 'empty' devices (e.g. local)
        let root = root as? SyncDevice
        
        let syncUUID = root?.objectId ?? SyncCrypto.uniqueSerialBytes(count: 16)
        
        var device: Device?
        if let syncDisplayUUID = SyncHelpers.syncDisplay(fromUUID: syncUUID) {
            // There can't be more than two device with the same syncUUID.
            // A race condition could sometimes happen while getting two `Sync.resolvedSyncRecords` callbacks at the same time.
            // Fixing issue #692 should help with it, until then we do a simple guard and disallow adding another device with the same syncUUID.
            let predicate = NSPredicate(format: "syncDisplayUUID == %@", syncDisplayUUID)
            device = Device.first(where: predicate, context: context)
        }
        
        if device == nil {
            device = Device(entity: Device.entity(context: context), insertInto: context)
            device?.created = root?.syncNativeTimestamp ?? Date()
            device?.syncUUID = syncUUID
        }
        
        // Due to race conditions, there is a chance that we will get for example a different device name
        // in insert(insead of update). Updating the Device regardless of whether it's already present.
        device?.updateResolvedRecord(root, context: context)
        
        if save {
            DataController.save(context: context)
        }
    }
    
    public func updateResolvedRecord(_ record: SyncRecord?, context: NSManagedObjectContext? = nil) {
        guard let root = record as? SyncDevice else { return }
        self.name = root.name
        self.deviceId = root.deviceId
        created = record?.syncNativeTimestamp
        
        // No save currently
    }
    
    public func deleteResolvedRecord(save: Bool, context: NSManagedObjectContext?) {
        remove(save: save, sendToSync: false)
    }
    
    // This should be abstractable
    public func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
        return SyncDevice(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
    }
}
