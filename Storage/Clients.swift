/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public struct RemoteClient: Equatable {
    public let guid: GUID?
    public let modified: Timestamp

    public let name: String
    public let type: String?
    public let os: String?
    public let version: String?
    public let fxaDeviceId: String?
    
    let protocols: [String]?

    let appPackage: String?
    let application: String?
    let formfactor: String?
    let device: String?

    // Requires a valid ClientPayload (: CleartextPayloadJSON: [String: Any]).
    public init(json: [String: Any], modified: Timestamp) {
        self.guid = json["id"] as? String
        self.modified = modified
        self.name = json["name"] as? String ?? ""
        self.type = json["type"] as? String

        self.version = json["version"] as? String
        self.protocols = json["protocols"] as? [String]
        self.os = json["os"] as? String
        self.appPackage = json["appPackage"] as? String
        self.application = json["application"] as? String
        self.formfactor = json["formfactor"] as? String
        self.device = json["device"] as? String
        self.fxaDeviceId = json["fxaDeviceId"] as? String
    }

    public init(guid: GUID?, name: String, modified: Timestamp, type: String?, formfactor: String?, os: String?, version: String?, fxaDeviceId: String?) {
        self.guid = guid
        self.name = name
        self.modified = modified
        self.type = type
        self.formfactor = formfactor
        self.os = os
        self.version = version
        self.fxaDeviceId = fxaDeviceId

        self.device = nil
        self.appPackage = nil
        self.application = nil
        self.protocols = nil
    }
}

// TODO: should this really compare tabs?
public func ==(lhs: RemoteClient, rhs: RemoteClient) -> Bool {
    return lhs.guid == rhs.guid &&
        lhs.name == rhs.name &&
        lhs.modified == rhs.modified &&
        lhs.type == rhs.type &&
        lhs.formfactor == rhs.formfactor &&
        lhs.os == rhs.os &&
        lhs.version == rhs.version &&
        lhs.fxaDeviceId == rhs.fxaDeviceId
}

extension RemoteClient: CustomStringConvertible {
    public var description: String {
        return "<RemoteClient GUID: \(guid ?? "nil"), name: \(name), modified: \(modified), type: \(type ?? "nil"), formfactor: \(formfactor ?? "nil"), OS: \(os ?? "nil"), version: \(version ?? "nil"), fxaDeviceId: \(fxaDeviceId ?? "nil")>"
    }
}
