/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import BraveShared
import Combine
import BraveCore
import Data
import os.log

/// This object holds on to our adblock engines and returns information needed for stats tracking as well as some conveniences
/// for injected scripts needed during web navigation and cosmetic filters models needed by the `SelectorsPollerScript.js` script.
public actor AdBlockStats {
  typealias CosmeticFilterModelTuple = (isAlwaysAggressive: Bool, model: CosmeticFilterModel)
  
  struct LazyFilterListInfo {
    let filterListInfo: CachedAdBlockEngine.FilterListInfo
    let isAlwaysAggressive: Bool
  }
  
  public static let shared = AdBlockStats()
  
  /// A list of filter list info that should be compiled
  private(set) var availableFilterLists: [CachedAdBlockEngine.Source: LazyFilterListInfo]
  /// The info for the resource file
  private var resourcesInfo: CachedAdBlockEngine.ResourcesInfo?
  /// Adblock engine for general adblock lists.
  private var cachedEngines: [CachedAdBlockEngine.Source: CachedAdBlockEngine]
  /// The queue that ensures that engines are compiled in series 
  ///
  /// Since they can be coming from all kinds of async tasks, we us a queue to ensure they are compiled one by one
  private let serialQueue = DispatchQueue(label: "com.brave.AdBlockStats.\(UUID().uuidString)")
  
  /// Return all the critical sources
  ///
  /// Critical sources are those that are enabled and are "on" by default. 
  /// Giving us the most important sources.
  /// Used for memory managment so we know which filter lists to disable upon a memory warning
  @MainActor var criticalSources: [CachedAdBlockEngine.Source] {
    var enabledSources: [CachedAdBlockEngine.Source] = [.adBlock]
    enabledSources.append(contentsOf: FilterListStorage.shared.ciriticalSources)
    return enabledSources
  }
  
  /// These are all the sources that are enabled according to the users settings.
  /// Some sources such as `adBlock` is always deemed to be enabled as other mechanisms are in place to disable this filter list
  @MainActor var enabledSources: [CachedAdBlockEngine.Source] {
    var enabledSources: [CachedAdBlockEngine.Source] = [.adBlock]
    enabledSources.append(contentsOf: FilterListStorage.shared.enabledSources)
    enabledSources.append(contentsOf: CustomFilterListStorage.shared.enabledSources)
    return enabledSources
  }
  
  /// Return the current number of compiled engines
  var numberOfEngines: Int {
    return cachedEngines.count
  }
  
  /// Return the current number of available filter list infos which will be used for lazy loading of engines
  var numberOfAvailableFilterLists: Int {
    return availableFilterLists.count
  }

  init() {
    cachedEngines = [:]
    availableFilterLists = [:]
  }
  
  /// Handle memory warnings by freeing up some memory
  func didReceiveMemoryWarning() async {
    ContentBlockerManager.log.debug("Low memory warning")
    cachedEngines.values.forEach({ $0.clearCaches() })
    
    // When we get a memory warning, we need to clear some engines.
    let sources = await Set(criticalSources)
    
    for source in cachedEngines.keys {
      if sources.contains(source) { continue }
      cachedEngines.removeValue(forKey: source)
    }
  }
  
  /// Create and add an engine from the given filter list info.
  /// If an engine already exists for the given source, it will be replaced.
  /// The stored `resourcesInfo` will be used. If it is not available, it will be added to a list to be lazily loaded.
  ///
  /// - Note: This method will ensure syncronous compilation
  public func compile(
    filterListInfo: CachedAdBlockEngine.FilterListInfo, isAlwaysAggressive: Bool
  ) throws {
    guard let resourcesInfo = self.resourcesInfo else {
      // If we don't have the resources info, yet available, lets add it to the lazily loaded list
      updateIfNeeded(filterListInfo: filterListInfo, isAlwaysAggressive: isAlwaysAggressive)
      return
    }
    
    try compile(filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: isAlwaysAggressive)
  }
  
  /// Create and add an engine from the given resources.
  /// If an engine already exists for the given source, it will be replaced.
  ///
  /// - Note: This method will ensure syncronous compilation
  public func compile(
    filterListInfo: CachedAdBlockEngine.FilterListInfo, resourcesInfo: CachedAdBlockEngine.ResourcesInfo, isAlwaysAggressive: Bool
  ) throws {
    updateIfNeeded(resourcesInfo: resourcesInfo)
    
    try serialQueue.sync {
      guard needsCompilation(for: filterListInfo) else {
        // Ensure we only compile if we need to. This prevents two lazy loads from recompiling
        return
      }
      
      let engine = try CachedAdBlockEngine.compile(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: isAlwaysAggressive
      )
      
      add(engine: engine)
    }
  }
  
  /// Create and add an engine from the given resources.
  /// If an engine already exists for the given source, it will be replaced.
  ///
  /// - Warning: This method will **not**  ensure syncronous compilation. Use this sparingly.
  public func compileAsync(
    filterListInfo: CachedAdBlockEngine.FilterListInfo, resourcesInfo: CachedAdBlockEngine.ResourcesInfo, isAlwaysAggressive: Bool
  ) async throws {
    updateIfNeeded(resourcesInfo: resourcesInfo)
    try await Task.detached {
      let engine = try CachedAdBlockEngine.compile(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: isAlwaysAggressive
      )
      
      await self.add(engine: engine)
    }.value  
  }
  
  /// Add a new engine to the list.
  /// If an engine already exists for the same source, it will be replaced instead.
  private func add(engine: CachedAdBlockEngine) {
    cachedEngines[engine.filterListInfo.source] = engine
    updateIfNeeded(filterListInfo: engine.filterListInfo, isAlwaysAggressive: engine.isAlwaysAggressive)
    ContentBlockerManager.log.debug("Added engine for \(engine.filterListInfo.debugDescription)")
  }
  
  /// Add or update `filterListInfo` if it is a newer version. This is used for lazy loading.
  func updateIfNeeded(filterListInfo: CachedAdBlockEngine.FilterListInfo, isAlwaysAggressive: Bool) {
    if let existingLazyInfo = availableFilterLists[filterListInfo.source] {
      guard filterListInfo.version > existingLazyInfo.filterListInfo.version else { return }
    }
    
    availableFilterLists[filterListInfo.source] = LazyFilterListInfo(
      filterListInfo: filterListInfo, isAlwaysAggressive: isAlwaysAggressive
    )
  }
  
  /// Add or update `resourcesInfo` if it is a newer version. This is used for lazy loading.
  func updateIfNeeded(resourcesInfo: CachedAdBlockEngine.ResourcesInfo) {
    guard self.resourcesInfo == nil || resourcesInfo.version > self.resourcesInfo!.version else { return }
    self.resourcesInfo = resourcesInfo
  }
  
  /// Remove an engine for the given source.
  func removeEngine(for source: CachedAdBlockEngine.Source) {
    cachedEngines.removeValue(forKey: source)
  }
  
  /// Remove all the engines
  func removeAllEngines() {
    cachedEngines.removeAll()
  }
  
  /// Remove all engines that have disabled sources
  func removeDisabledEngines() async {
    let sources = await Set(enabledSources)
    
    for source in cachedEngines.keys {
      guard !sources.contains(source) else { continue }
      cachedEngines.removeValue(forKey: source)
    }
  }
  
  /// Tells us if an engine needs compilation based on the info provided
  func needsCompilation(for filterListInfo: CachedAdBlockEngine.FilterListInfo) -> Bool {
    guard let resourcesInfo = self.resourcesInfo else { return false }
    
    if let cachedEngine = cachedEngines[filterListInfo.source] {
      return cachedEngine.filterListInfo.version < filterListInfo.version
        && cachedEngine.resourcesInfo.version < resourcesInfo.version
    } else {
      return true
    }
  }
  
  /// Tells us if this source should be eagerly loaded.
  ///
  /// Eagerness is determined by several factors:
  /// * If the source represents a fitler list or a custom filter list, it is eager if it is enabled
  /// * If the source represents the `adblock` default filter list, it is always eager regardless of shield settings
  @MainActor func isEagerlyLoaded(source: CachedAdBlockEngine.Source) -> Bool {
    return enabledSources.contains(source)
  }
  
  /// Checks the general and regional engines to see if the request should be blocked
  func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType, isAggressiveMode: Bool, domain: Domain) async -> Bool {
    return await cachedEngines(for: domain).contains(where: { cachedEngine in
      return cachedEngine.shouldBlock(
        requestURL: requestURL,
        sourceURL: sourceURL,
        resourceType: resourceType,
        isAggressiveMode: isAggressiveMode
      )
    })
  }
  
  /// This returns all the user script types for the given frame
  func makeEngineScriptTypes(frameURL: URL, isMainFrame: Bool, domain: Domain) async -> Set<UserScriptType> {
    // Add any engine scripts for this frame
    return await cachedEngines(for: domain).enumerated().map({ index, cachedEngine -> Set<UserScriptType> in
      do {
        return try cachedEngine.makeEngineScriptTypes(
          frameURL: frameURL, isMainFrame: isMainFrame, index: index
        )
      } catch {
        assertionFailure()
        return []
      }
    }).reduce(Set<UserScriptType>(), { partialResult, scriptTypes in
      return partialResult.union(scriptTypes)
    })
  }
  
  /// Returns all the models for this frame URL
  func cosmeticFilterModels(forFrameURL frameURL: URL, domain: Domain) async -> [CosmeticFilterModelTuple] {
    return await cachedEngines(for: domain).compactMap { cachedEngine -> CosmeticFilterModelTuple? in
      do {
        guard let model = try cachedEngine.cosmeticFilterModel(forFrameURL: frameURL) else {
          return nil
        }
        return (cachedEngine.isAlwaysAggressive, model)
      } catch {
        assertionFailure()
        return nil
      }
    }
  }
  
  @MainActor func cachedEngines(for domain: Domain) async -> [CachedAdBlockEngine] {
    let sources = enabledSources(for: domain)
    return await cachedEngines(for: sources)
  }
  
  /// Return all the cached engines for the given sources. 
  /// If any filter list is not yet loaded, it will be lazily loaded
  func cachedEngines(for sources: [CachedAdBlockEngine.Source]) async -> [CachedAdBlockEngine] {
    let criticalSources = await Set(self.criticalSources)
    let sortedSources = sources.sorted(by: { criticalSources.contains($0) && !criticalSources.contains($1) })
    
    return await sortedSources.asyncCompactMap { source -> CachedAdBlockEngine? in
      do {
        return try await cachedEngine(for: source)
      } catch {
        ContentBlockerManager.log.error("Failed to get engine")
        return nil
      }
    }
  }
  
  /// Give us the cached engine for the source.
  /// If the engine is not yet compiled it will be loaded and returned, 
  /// allowing for lazy loading of filter lists
  private func cachedEngine(for source: CachedAdBlockEngine.Source) async throws -> CachedAdBlockEngine? {
    if let engine = self.compiledCachedEngine(for: source) { return engine }
    guard let lazyInfo = availableFilterLists[source] else { return nil }
    
    // Try to recompile it if it doesnt exist
    try compile(
      filterListInfo: lazyInfo.filterListInfo,
      isAlwaysAggressive: lazyInfo.isAlwaysAggressive
    )
    
    return self.compiledCachedEngine(for: source)
  }
  
  /// Give us the cached engine for the source.
  /// Nothing will be compiled if the engine is not already loaded
  private func compiledCachedEngine(for source: CachedAdBlockEngine.Source) -> CachedAdBlockEngine? {
    return cachedEngines[source]
  }
  
  /// Give us all the enabled sources for the given domain
  @MainActor private func enabledSources(for domain: Domain) -> [CachedAdBlockEngine.Source] {
    let enabledSources = self.enabledSources
    return enabledSources.filter({ $0.isEnabled(for: domain )})
  }
}

private extension FilterListStorage {
  /// Gives us source representations of all the critical filter lists
  ///
  /// Critical filter lists are those that are enabled and are "on" by default. Giving us the most important filter lists.
  /// Used for memory managment so we know which filter lists to disable upon a memory warning
  @MainActor var ciriticalSources: [CachedAdBlockEngine.Source] {
    return filterLists.compactMap { filterList -> CachedAdBlockEngine.Source? in
      guard filterList.isEnabled else { return nil }
      guard FilterList.defaultOnComponentIds.contains(filterList.entry.componentId) else { return nil }
      return .filterList(componentId: filterList.entry.componentId)
    }
  }
  
  /// Gives us source representations of all the enabled filter lists
  @MainActor var enabledSources: [CachedAdBlockEngine.Source] {
    if !filterLists.isEmpty {
      return filterLists.compactMap { filterList -> CachedAdBlockEngine.Source? in
        guard filterList.isEnabled else { return nil }
        return .filterList(componentId: filterList.entry.componentId)
      }
    } else {
      // We may not have the filter lists loaded yet. In which case we load the settings
      return allFilterListSettings.compactMap { setting -> CachedAdBlockEngine.Source? in
        guard setting.isEnabled else { return nil }
        guard let componentId = setting.componentId else { return nil }
        return .filterList(componentId: componentId)
      }
    }
  }
}

private extension CustomFilterListStorage {
  /// Gives us source representations of all the enabled custom filter lists
  @MainActor var enabledSources: [CachedAdBlockEngine.Source] {
    return filterListsURLs.compactMap { filterList -> CachedAdBlockEngine.Source? in
      guard filterList.setting.isEnabled else { return nil }
      return .filterListURL(uuid: filterList.setting.uuid)
    }
  }
}

private extension CachedAdBlockEngine.Source {
  /// Returns a boolean indicating if the engine is enabled for the given domain.
  ///
  /// This is determined by checking the source of the engine and checking the appropriate shields.
  @MainActor func isEnabled(for domain: Domain) -> Bool {
    switch self {
    case .adBlock, .filterList, .filterListURL:
      // This engine source type is enabled only if shields are enabled
      // for the given domain
      return domain.isShieldExpected(.AdblockAndTp, considerAllShieldsOption: true)
    }
  }
}
