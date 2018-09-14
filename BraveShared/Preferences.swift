/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/// An empty protocol simply here to force the developer to use a user defaults encodable value via generic constraint
public protocol UserDefaultsEncodable {}

/// The applications preferences container
///
/// Properties in this object should be of the the type `Option` with the object which is being
/// stored to automatically interact with `UserDefaults`
public class Preferences {
    /// The default `UserDefaults` that all `Option`s will use unless specified
    public static let defaultContainer = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
}

/// Defines an object which may watch a set of `Preference.Option`s
/// - note: @objc was added here due to a Swift compiler bug which doesn't allow a class-bound protocol
/// to act as `AnyObject` in a `AnyObject` generic constraint (i.e. `WeakList`)
@objc public protocol PreferencesObserver: class {
    /// A preference value was changed for some given preference key
    func preferencesDidChange(for key: String)
}

extension Preferences {
    final class DAU {
        static let lastLaunchInfo = Option<[Int?]?>(key: "dau.last-launch-info", default: nil)
        static let weekOfInstallation = Option<String?>(key: "dau.week-of-installation", default: nil)
        static let firstPingSuccess = Option<Bool>(key: "dau.first-ping", default: false)
    }
}

extension Preferences {
    
    /// An entry in the `Preferences`
    ///
    /// `ValueType` defines the type of value that will stored in the UserDefaults object
    public class Option<ValueType: UserDefaultsEncodable> {
        /// The list of observers for this option
        private let observers = WeakList<PreferencesObserver>()
        /// The UserDefaults container that you wish to save to
        private let container: UserDefaults
        /// The current value of this preference
        ///
        /// Upon setting this value, UserDefaults will be updated and any observers will be called
        public var value: ValueType {
            didSet {
                container.set(value, forKey: self.key)
                container.synchronize()
                
                let key = self.key
                observers.forEach {
                    $0.preferencesDidChange(for: key)
                }
            }
        }
        /// Adds `object` as an observer for this Option.
        public func observe(from object: PreferencesObserver) {
            observers.insert(object)
        }
        /// The key used for getting/setting the value in `UserDefaults`
        public let key: String
        /// Creates a preference
        public init(key: String, default: ValueType, container: UserDefaults = Preferences.defaultContainer) {
            self.key = key
            self.container = container
            value = (container.value(forKey: key) as? ValueType) ?? `default`
        }
    }
}

extension Optional: UserDefaultsEncodable where Wrapped: UserDefaultsEncodable {}
extension Bool: UserDefaultsEncodable {}
extension Int: UserDefaultsEncodable {}
extension UInt: UserDefaultsEncodable {}
extension Float: UserDefaultsEncodable {}
extension Double: UserDefaultsEncodable {}
extension String: UserDefaultsEncodable {}
extension URL: UserDefaultsEncodable {}
extension Data: UserDefaultsEncodable {}
extension Array: UserDefaultsEncodable where Element: UserDefaultsEncodable {}
extension Dictionary: UserDefaultsEncodable where Key: StringProtocol, Value: UserDefaultsEncodable {}

extension Preferences {
    /// Migrate a given key from `Prefs` into a specific option
    public class func migrate<T>(keyPrefix: String, key: String, to option: Preferences.Option<T>) {
        let userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)

        let profileKey = "\(keyPrefix)\(key)"
        // Have to do two checks because T may be an Optional, since object(forKey:) returns Any? it will succeed
        // as casting to T if T is Optional even if the key doesnt exist.
        let value = userDefaults?.object(forKey: profileKey)
        if value != nil, let value = value as? T {
            option.value = value
            userDefaults?.removeObject(forKey: profileKey)
        } else {
            Logger.browserLogger.info("Could not migrate legacy pref with key: \"\(profileKey)\".")
        }
    }
    
    public class func migrateBraveShared(keyPrefix: String) {
        // DAU
        migrate(keyPrefix: keyPrefix, key: "dau_stat", to: Preferences.DAU.lastLaunchInfo)
        migrate(keyPrefix: keyPrefix, key: "week_of_installation", to: Preferences.DAU.weekOfInstallation)
    }
}

