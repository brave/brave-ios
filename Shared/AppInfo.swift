/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class AppInfo {
    /// Return the main application bundle. If this is called from an extension, the containing app bundle is returned.
    open static var applicationBundle: Bundle {
        let bundle = Bundle.main
        switch bundle.bundleURL.pathExtension {
        case "app":
            return bundle
        case "appex":
            // .../Client.app/PlugIns/SendTo.appex
            return Bundle(url: bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent())!
        default:
            fatalError("Unable to get application Bundle (Bundle.main.bundlePath=\(bundle.bundlePath))")
        }
    }

    open static var displayName: String {
        return applicationBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
    }

    open static var appVersion: String {
        return applicationBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    open static var buildNumber: String {
        return applicationBundle.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as! String
    }

    open static var majorAppVersion: String {
        return appVersion.components(separatedBy: ".").first!
    }

    /// Return the shared container identifier (also known as the app group) to be used with for example background
    /// http requests. It is the base bundle identifier with a "group." prefix.
    open static var sharedContainerIdentifier: String {
        var bundleIdentifier = baseBundleIdentifier
        if bundleIdentifier == "com.brave.ios.FennecEnterprise" {
            // Bug 1373726 - Base bundle identifier incorrectly generated for Nightly builds
            // This can be removed when we are able to fix the app group in the developer portal
            bundleIdentifier = "com.brave.ios.Fennec.enterprise"
        }
        return "group." + bundleIdentifier
    }

    /// Return the keychain access group.
    open static func keychainAccessGroupWithPrefix(_ prefix: String) -> String {
        var bundleIdentifier = baseBundleIdentifier
        if bundleIdentifier == "com.brave.ios.FennecEnterprise" {
            // Bug 1373726 - Base bundle identifier incorrectly generated for Nightly builds
            // This can be removed when we are able to fix the app group in the developer portal
            bundleIdentifier = "com.brave.ios.Fennec.enterprise"
        }
        return prefix + "." + bundleIdentifier
    }

    /// Return the base bundle identifier.
    ///
    /// This function is smart enough to find out if it is being called from an extension or the main application. In
    /// case of the former, it will chop off the extension identifier from the bundle since that is a suffix not part
    /// of the *base* bundle identifier.
    open static var baseBundleIdentifier: String {
        let bundle = Bundle.main
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as! String
        let baseBundleIdentifier = bundle.bundleIdentifier!
        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0..<components.count-1].joined(separator: ".")
        }
        return baseBundleIdentifier
    }

    // Return the MozWhatsNewTopic key from the Info.plist
    open static var whatsNewTopic: String? {
        return Bundle.main.object(forInfoDictionaryKey: "MozWhatsNewTopic") as? String
    }

    // Return whether the currently executing code is running in an Application
    open static var isApplication: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundlePackageType") as! String == "APPL"
    }
}
