/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import CoreData
import Foundation
import Shared

public class Device: NSManagedObject, Syncable {
    
    // Check if this can be nested inside the method
    private static var sharedCurrentDevice: Device?
    
    // Assign on parent model via CD
    @NSManaged var isSynced: Bool
    
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
    
    // FIXME: Sync
    /*
    public class func deviceSettings(profile: Profile) -> [SyncDeviceSetting]? {
        // Building settings off of device objects
        let deviceSettings: [SyncDeviceSetting]? = (Device.get(predicate: nil, context: DataController.shared.workerContext) as? [Device])?.map {
            // Even if no 'real' title, still want it to show up in list
            return SyncDeviceSetting(profile: profile, device: $0)
        }
        return deviceSettings
    }
    */
    
    // This should be abstractable
    public func asDictionary(deviceId: [Int]?, action: Int?) -> [String: Any] {
        return SyncDevice(record: self, deviceId: deviceId, action: action).dictionaryRepresentation()
    }
    
    public static func add(rootObject root: SyncRecord?, save: Bool, sendToSync: Bool, context: NSManagedObjectContext) -> Syncable? {
        
        // No guard, let bleed through to allow 'empty' devices (e.g. local)
        let root = root as? SyncDevice

        let device = Device(entity: Device.entity(context: context), insertInto: context)
        
        device.created = root?.syncNativeTimestamp ?? Date()
        // FIXME: Sync
        // device.syncUUID = root?.objectId ?? SyncCrypto.shared.uniqueSerialBytes(count: 16)

        device.update(syncRecord: root)
        
        if save {
            DataManager.saveContext(context: context)
        }
        
        return device
    }
    
    class func add(save: Bool = false, context: NSManagedObjectContext) -> Device? {
        return add(rootObject: nil, save: save, sendToSync: false, context: context) as? Device
    }
    
    public func update(syncRecord record: SyncRecord?) {
        guard let root = record as? SyncDevice else { return }
        self.name = root.name
        self.deviceId = root.deviceId
        
        // No save currently
    }
    
    static func currentDevice() -> Device? {
        
        if sharedCurrentDevice == nil {
            let context = DataManager.shared.workerContext
            // Create device
            let predicate = NSPredicate(format: "isCurrentDevice = YES")
            // Should only ever be one current device!
            var localDevice: Device? = get(predicate: predicate, context: context)?.first
            
            if localDevice == nil {
                // Create
                localDevice = add(context: context)
                localDevice?.isCurrentDevice = true
                DataManager.saveContext(context: context)
            }
            
            sharedCurrentDevice = localDevice
        }
        return sharedCurrentDevice
    }
    
    class func deleteAll(completionOnMain: ()->()) {
        let context = DataManager.shared.workerContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = Device.entity(context: context)
            fetchRequest.includesPropertyValues = false
            do {
                let results = try context.fetch(fetchRequest)
                for result in results {
                    context.delete(result as! NSManagedObject)
                }
                
            } catch {
                let fetchError = error as NSError
                print(fetchError)
            }

            // Destroy handle to local device instance, otherwise it is locally retained and will throw console errors
            sharedCurrentDevice = nil
            
            DataManager.saveContext(context: context)
        }
    }
    
}
