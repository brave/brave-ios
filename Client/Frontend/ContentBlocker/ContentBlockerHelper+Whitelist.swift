/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

private let log = Logger.browserLogger

struct WhitelistedDomains {
    var domainSet = Set<String>() {
        didSet {
            domainRegex = domainSet.compactMap { wildcardContentBlockerDomainToRegex(domain: "*" + $0) }
        }
    }

    private(set) var domainRegex = [NSRegularExpression]()
}

@available(iOS 11.0, *)
extension ContentBlockerHelper {

    static func whitelistFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            log.error("Failed to get doc dir for whitelist file.")
            return nil
        }
        return dir.appendingPathComponent("whitelist")
    }

    // Get the whitelist domain array as a JSON fragment that can be inserted at the end of a blocklist.
    static func whitelistAsJSON() -> String {
        if ContentBlockerHelper.whitelistedDomains.domainSet.isEmpty {
            return ""
        }
        // Note that * is added to the front of domains, so foo.com becomes *foo.com
        let list = "'*" + ContentBlockerHelper.whitelistedDomains.domainSet.joined(separator: "','*") + "'"
        return ", {'action': { 'type': 'ignore-previous-rules' }, 'trigger': { 'url-filter': '.*', 'if-domain': [\(list)] }}".replacingOccurrences(of: "'", with: "\"")
    }

    static func whitelist(enable: Bool, url: URL, completion: (() -> Void)?) {
        guard let domain = whitelistableDomain(fromUrl: url) else { return }

        if enable {
            whitelistedDomains.domainSet.insert(domain)
        } else {
            whitelistedDomains.domainSet.remove(domain)
        }

        updateWhitelist(completion: completion)
    }

    static func clearWhitelist(completion: (() -> Void)?) {
        whitelistedDomains.domainSet = Set<String>()
        updateWhitelist(completion: completion)
    }
    
    private static func updateWhitelist(completion: (() -> Void)?) {
        removeAllRulesInStore {
            compileListsNotInStore().uponQueue(.main) {
                completion?()
                NotificationCenter.default.post(name: .ContentBlockerTabSetupRequired, object: nil)
            }
        }

        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return }
        if ContentBlockerHelper.whitelistedDomains.domainSet.isEmpty {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        let list = ContentBlockerHelper.whitelistedDomains.domainSet.joined(separator: "\n")
        do {
            try list.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            log.error("Failed to save whitelist file")
        }
    }
    // Ensure domains used for whitelisting are standardized by using this function.
    static func whitelistableDomain(fromUrl url: URL) -> String? {
        guard let domain = url.host, !domain.isEmpty else {
            return nil
        }
        return domain
    }

    static func isWhitelisted(url: URL) -> Bool {
        guard let domain = whitelistableDomain(fromUrl: url) else {
            return false
        }
        return whitelistedDomains.domainSet.contains(domain)
    }

    static func readWhitelistFile() -> [String]? {
        guard let fileURL = whitelistFileURL() else { return nil }
        let text = try? String(contentsOf: fileURL, encoding: .utf8)
        if let text = text, !text.isEmpty {
            return text.components(separatedBy: .newlines)
        }

        return nil
    }
}
