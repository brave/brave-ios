/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import CoreData

private let log = Logger.browserLogger

protocol SyncRecordProtocol {
    associatedtype CoreDataParallel: Syncable
//    var CoredataParallel: NSManagedObject.Type?
    
}

public class SyncRecord: SyncRecordProtocol {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case objectId
        case deviceId
        case action
        case objectData
        case syncTimestamp
    }
    
    // MARK: Properties
    var objectId: [Int]?
    var deviceId: [Int]?
    var action: Int?
    var objectData: SyncObjectDataType?
    
    var syncTimestamp: Int?
    
//    var CoredataParallel: Syncable.Type?
    typealias CoreDataParallel = Device
    
    convenience init() {
        self.init(object: [:])
    }
    
    /// Converts server format for storing timestamp(integer) to Date
    var syncNativeTimestamp: Date? {
        guard let syncTimestamp = syncTimestamp else { return nil }
        
        return Date.fromTimestamp(Timestamp(syncTimestamp))
    }
    
    // Would be nice to make this type specific to class
    required init(record: Syncable?, deviceId: [Int]?, action: Int?) {
        
        self.objectId = record?.syncUUID
        self.deviceId = deviceId
        self.action = action
        
        // TODO: Move to SyncObjectDataType enum
//        self.objectData = [Syncable.Type: SyncObjectDataType] = [Bookmark.self: .Bookmark][self.Type]
        self.objectData = .Bookmark
        
        // TODO: Need object type!!
        
        // Initially, a record should have timestamp set to now.
        // It should then be updated from resolved-sync-records callback.
        let timeStamp = (record?.created ?? Date()).timeIntervalSince1970
        syncTimestamp = Int(timeStamp)
    }
    
    required public init(object: [String: AnyObject]) {
        // objectId can come in two different formats
        objectId = object[SerializationKeys.objectId.rawValue] as? [Int]
        deviceId = object[SerializationKeys.deviceId.rawValue] as? [Int]
        action = object[SerializationKeys.action.rawValue] as? Int
        
        if let item = (object[SerializationKeys.objectData.rawValue] as? String) {
            objectData = SyncObjectDataType(rawValue: item)
        }
        
        self.syncTimestamp = object[SerializationKeys.syncTimestamp.rawValue] as? Int
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        // Override to use string value instead of array, to be uniform to CD
        if let value = objectId { dictionary[SerializationKeys.objectId.rawValue] = value }
        if let value = deviceId { dictionary[SerializationKeys.deviceId.rawValue] = value }
        if let value = action { dictionary[SerializationKeys.action.rawValue] = value }
        if let value = objectData { dictionary[SerializationKeys.objectData.rawValue] = value.rawValue }
        if let value = syncTimestamp { dictionary[SerializationKeys.syncTimestamp.rawValue] = value }
        return dictionary
    }
}

// Uses same mappings above, but for arrays
extension SyncRecordProtocol where Self: SyncRecord {
    
    static func syncRecords(_ rootJSON: [[String: Any]]?) -> [Self]? {
        return rootJSON?.map {
            return self.init(object: $0.mapValues({ $0 as AnyObject }))
        }
    }
    
    static func syncRecords(_ rootJSON: [String: Any]) -> [Self]? {
        return self.syncRecords([rootJSON])
    }
}

