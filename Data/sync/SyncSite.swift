/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public final class SyncSite {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    private enum SerializationKeys: String, CodingKey {
        case customTitle
        case title
        case favicon
        case location
        case creationTime
        case lastAccessedTime
    }
    
    // MARK: Properties
    public var customTitle: String?
    public var title: String?
    public var favicon: String?
    public var location: String?
    public var creationTime: Int?
    public var lastAccessedTime: Int?
    
    public var creationNativeDate: Date? {
        return Date.fromTimestamp(Timestamp(creationTime ?? 0))
    }
    
    public var lastAccessedNativeDate: Date? {
        return Date.fromTimestamp(Timestamp(lastAccessedTime ?? 0))
    }
    
    public convenience init() {
        self.init(object: [:])
    }
    
    public required init(object: [String: AnyObject]) {
        customTitle = object[SerializationKeys.customTitle.rawValue] as? String
        title = object[SerializationKeys.title.rawValue] as? String
        favicon = object[SerializationKeys.favicon.rawValue] as? String
        location = object[SerializationKeys.location.rawValue] as? String
        creationTime = object[SerializationKeys.creationTime.rawValue] as? Int
        lastAccessedTime = object[SerializationKeys.lastAccessedTime.rawValue] as? Int
    }
    
    /// Generates description of the object in the form of a NSDictionary.
    ///
    /// - returns: A Key value pair containing all valid values in the object.
    public func dictionaryRepresentation() -> [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        if let value = customTitle { dictionary[SerializationKeys.customTitle.rawValue] = value as AnyObject }
        if let value = title { dictionary[SerializationKeys.title.rawValue] = value as AnyObject }
        if let value = favicon { dictionary[SerializationKeys.favicon.rawValue] = value as AnyObject }
        if let value = location { dictionary[SerializationKeys.location.rawValue] = value as AnyObject }
        if let value = creationTime { dictionary[SerializationKeys.creationTime.rawValue] = value as AnyObject }
        if let value = lastAccessedTime { dictionary[SerializationKeys.lastAccessedTime.rawValue] = value as AnyObject }
        return dictionary
    }
    
}
