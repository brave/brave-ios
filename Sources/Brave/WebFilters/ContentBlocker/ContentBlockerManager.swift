// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
@preconcurrency import WebKit
import Data
import Shared
import BraveShared
import os.log

/// A class that aids in the managment of rule lists on the rule store.
actor ContentBlockerManager {
  struct CompileOptions: OptionSet {
    let rawValue: Int
    
    static let stripContentBlockers = CompileOptions(rawValue: 1 << 0)
    static let punycodeDomains = CompileOptions(rawValue: 1 << 1)
    static let `default`: CompileOptions = []
    static let all: CompileOptions = [.stripContentBlockers, .punycodeDomains]
  }
  // TODO: Use a proper logger system once implemented and adblock files are moved to their own module(#5928).
  /// Logger to use for debugging.
  static let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "adblock")
  
  enum CompileError: Error {
    case noRuleListReturned(identifier: String)
    case couldNotPunycodeDomains(identifier: String)
    case couldNotStripCosmeticFilters(identifier: String)
  }
  
  public enum GenericBlocklistType: Hashable, CaseIterable {
    case blockAds
    case blockCookies
    case blockTrackers
    
    var bundledFileName: String {
      switch self {
      case .blockAds: return "block-ads"
      case .blockCookies: return "block-cookies"
      case .blockTrackers: return "block-trackers"
      }
    }
  }
  
  /// An object representing the type of block list
  public enum BlocklistType: Hashable {
    case generic(GenericBlocklistType)
    case filterList(uuid: String)
    case customFilterList(uuid: String)
    
    var identifier: String {
      switch self {
      case .generic(let type):
        return ["stored-type", type.bundledFileName].joined(separator: "-")
      case .filterList(let uuid):
        return ["filter-list", uuid].joined(separator: "-")
      case .customFilterList(let uuid):
        return ["custom-filter-list", uuid].joined(separator: "-")
      }
    }
  }
  
  public static var shared = ContentBlockerManager()
  /// The store in which these rule lists should be compiled
  let ruleStore: WKContentRuleListStore
  /// We cached the rule lists so that we can return them quicker if we need to
  private var cachedRuleLists: [String: WKContentRuleList]
  
  init(ruleStore: WKContentRuleListStore = .default()) {
    self.ruleStore = ruleStore
    self.cachedRuleLists = [:]
  }
  
  /// Loads the rule lists and add them to the cache
  public func loadCaches() async {
    let availableIdentifiers = await ruleStore.availableIdentifiers()
    
    for identifier in availableIdentifiers ?? [] {
      do {
        let ruleList = try await ruleStore.contentRuleList(forIdentifier: identifier)
        cachedRuleLists[identifier] = ruleList
      } catch {
        // assertionFailure()
      }
    }
  }
  
  /// Remove all rule lists minus the given valid types.
  /// Should be used only as a cleanup once during launch to get rid of unecessary/old data.
  /// This is mostly for custom filter lists a user may have added.
  public func cleaupInvalidRuleLists(validTypes: Set<BlocklistType>) async {
    await cachedRuleLists.asyncConcurrentForEach { identifier, ruleList in
      guard !validTypes.contains(where: { $0.identifier == identifier }) else { return }
      
      do {
        try await self.removeRuleList(forIdentifier: identifier)
      } catch {
        assertionFailure()
      }
    }
  }
  
  /// Compile the given resource and store it in cache for the given blocklist type
  func compile(encodedContentRuleList: String, for type: BlocklistType, options: CompileOptions = .default) async throws {
    var encodedContentRuleList = encodedContentRuleList
    
    if options.contains(.stripContentBlockers) {
      guard let convertedContentRuleList = try await stripCosmeticFilters(encodedContentRuleList: encodedContentRuleList) else {
        throw CompileError.couldNotStripCosmeticFilters(identifier: type.identifier)
      }
      
      encodedContentRuleList = convertedContentRuleList
    }
    
    if options.contains(.punycodeDomains) {
      guard let convertedContentRuleList = try await punycodeConversion(encodedContentRuleList: encodedContentRuleList) else {
        throw CompileError.couldNotPunycodeDomains(identifier: type.identifier)
      }
      
      encodedContentRuleList = convertedContentRuleList
    }
    
    let ruleList = try await ruleStore.compileContentRuleList(forIdentifier: type.identifier, encodedContentRuleList: encodedContentRuleList)
    
    guard let ruleList = ruleList else {
      throw CompileError.noRuleListReturned(identifier: type.identifier)
    }
    
    self.cachedRuleLists[type.identifier] = ruleList
    
    #if DEBUG
    ContentBlockerManager.log.debug("Compiled rule list `\(type.identifier)`")
    #endif
  }
  
  /// Remove the rule list for the blocklist type
  func removeRuleList(for type: BlocklistType) async throws {
    try await removeRuleList(forIdentifier: type.identifier)
  }
  
  /// Checks if the rule list for this type is cached
  func hasCache(for type: BlocklistType) -> Bool {
    return cachedRuleLists[type.identifier] != nil
  }
  
  /// Load a rule list from the rule store and return it. Will use cached results if they exist
  func ruleList(for type: BlocklistType) async throws -> WKContentRuleList? {
    if let ruleList = cachedRuleLists[type.identifier] { return ruleList }
    let ruleList = try await ruleStore.contentRuleList(forIdentifier: type.identifier)
    self.cachedRuleLists[type.identifier] = ruleList
    return ruleList
  }
  
  /// Load a rule list from the rule store and return it. Will not use cached results
  func loadRuleList(for type: BlocklistType) async throws -> WKContentRuleList? {
    let ruleList = try await ruleStore.contentRuleList(forIdentifier: type.identifier)
    self.cachedRuleLists[type.identifier] = ruleList
    return ruleList
  }
  
  /// Compiles the bundled file for the given generic type
  /// - Warning: This may replace any downloaded versions with the bundled ones in the rulestore
  /// for example, the `adBlock` rule type may replace the `genericContentBlockingBehaviors` downloaded version.
  func compileBundledRuleList(for genericType: GenericBlocklistType) async throws {
    guard let fileURL = Bundle.module.url(forResource: genericType.bundledFileName, withExtension: "json") else {
      assertionFailure("A bundled file shouldn't fail to load")
      return
    }
    
    let encodedContentRuleList = try String(contentsOf: fileURL)
    try await compile(encodedContentRuleList: encodedContentRuleList, for: .generic(genericType))
  }
  
  /// Return the valid generic types for the given domain
  @MainActor public func validGenericTypes(for domain: Domain) -> Set<GenericBlocklistType> {
    guard !domain.areAllShieldsOff else { return [] }
    var results = Set<GenericBlocklistType>()

    // Get domain specific rule types
    if domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true) {
      results = results.union([.blockAds, .blockTrackers])
    }
    
    // Get global rule types
    if Preferences.Privacy.blockAllCookies.value {
      results.insert(.blockCookies)
    }
    
    return results
  }
  
  /// Return the enabled blocklist types for the given domain
  @MainActor func validBlocklistTypes(for domain: Domain) -> Set<BlocklistType> {
    guard !domain.areAllShieldsOff else { return [] }
    
    // Get the generic types
    let genericTypes = validGenericTypes(for: domain)
    
    let genericRuleLists = genericTypes.map { genericType -> BlocklistType in
      return .generic(genericType)
    }
    
    // Get rule lists for filter lists
    let filterLists = FilterListResourceDownloader.shared.filterLists
    let additionalRuleLists = filterLists.compactMap { filterList -> BlocklistType? in
      guard filterList.isEnabled else { return nil }
      return .filterList(uuid: filterList.uuid)
    }
    
    // Get rule lists for custom filter lists
    let customFilterLists = CustomFilterListStorage.shared.filterListsURLs
    let customRuleLists = customFilterLists.compactMap { customURL -> BlocklistType? in
      guard customURL.setting.isEnabled else { return nil }
      return .customFilterList(uuid: customURL.setting.uuid)
    }
    
    return Set(genericRuleLists).union(additionalRuleLists).union(customRuleLists)
  }
  
  /// Return the enabled rule types for this domain and the enabled settings.
  /// It will attempt to return cached results if they exist otherwise it will attempt to load results from the rule store
  public func ruleLists(for domain: Domain) async -> Set<WKContentRuleList> {
    let validBlocklistTypes = await self.validBlocklistTypes(for: domain)
    
    return await Set(validBlocklistTypes.asyncConcurrentCompactMap({ blocklistType -> WKContentRuleList? in
      do {
        return try await self.ruleList(for: blocklistType)
      } catch {
        return nil
      }
    }))
  }
  
  /// Remove the rule list for the
  private func removeRuleList(forIdentifier identifier: String) async throws {
    self.cachedRuleLists.removeValue(forKey: identifier)
    try await ruleStore.removeContentRuleList(forIdentifier: identifier)
  }
  
  private func stripCosmeticFilters(encodedContentRuleList: String) async throws -> String? {
    guard let blocklistData = encodedContentRuleList.data(using: .utf8) else {
      assertionFailure()
      return encodedContentRuleList
    }
    
    guard let jsonArray = try JSONSerialization.jsonObject(with: blocklistData) as? [[String: Any]] else {
      return String(bytes: blocklistData, encoding: .utf8)
    }
    
    let updatedArray = await jsonArray.asyncConcurrentCompactMap { dictionary in
      guard let actionDictionary = dictionary["action"] as? [String: Any] else {
        return dictionary
      }
      
      // Filter out with any dictionaries with `selector` actions
      if actionDictionary["selector"] != nil {
        return nil
      } else {
        return dictionary
      }
    }
    
    #if DEBUG
    let count = jsonArray.count - updatedArray.count
    ContentBlockerManager.log.debug("Filtered out \(count) content blocker")
    #endif
    
    let modifiedData = try JSONSerialization.data(withJSONObject: updatedArray)
    return String(bytes: modifiedData, encoding: .ascii)
  }
  
  private func punycodeConversion(encodedContentRuleList: String) async throws -> String? {
    guard let blocklistData = encodedContentRuleList.data(using: .utf8) else {
      assertionFailure()
      return encodedContentRuleList
    }
    
    guard var jsonArray = try JSONSerialization.jsonObject(with: blocklistData) as? [[String: Any]] else {
      return String(bytes: blocklistData, encoding: .utf8)
    }

    await jsonArray.enumerated().asyncConcurrentForEach({ index, dictionary in
      guard var triggerObject = dictionary["trigger"] as? [String: Any] else {
        return
      }
      
      if let domainArray = triggerObject["if-domain"] as? [String] {
        triggerObject["if-domain"] = self.punycodeConversion(domains: domainArray)
      }
      
      if let domainArray = triggerObject["unless-domain"] as? [String] {
        triggerObject["unless-domain"] = self.punycodeConversion(domains: domainArray)
      }
      
      jsonArray[index]["trigger"] = triggerObject
    })
    
    let modifiedData = try JSONSerialization.data(withJSONObject: jsonArray)
    return String(bytes: modifiedData, encoding: .ascii)
  }
  
  private func punycodeConversion(domains: [String]) -> [String] {
    return domains.compactMap { domain -> String? in
      guard domain.allSatisfy({ $0.isASCII }) else {
        return NSURL(idnString: domain)?.absoluteString
      }
      
      return domain
    }
  }
}
