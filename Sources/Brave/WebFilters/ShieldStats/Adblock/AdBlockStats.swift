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
  public static let shared = AdBlockStats()
  
  /// An object containing the basic information to allow us to compile an engine
  struct LazyFilterListInfo {
    let filterListInfo: CachedAdBlockEngine.FilterListInfo
    let isAlwaysAggressive: Bool
  }

  /// A list of filter list info that are available for compilation. This information is used for lazy loading.
  private(set) var availableFilterLists: [CachedAdBlockEngine.Source: LazyFilterListInfo]
  /// The info for the resource file. This is a shared file used by all filter lists that contain scriplets. This information is used for lazy loading.
  private(set) var resourcesInfo: CachedAdBlockEngine.ResourcesInfo?
  /// Adblock engine for general adblock lists.
  private(set) var cachedEngines: [CachedAdBlockEngine.Source: CachedAdBlockEngine]
  /// The queue that ensures that engines are compiled in series since they can be coming from all kinds of async tasks
  private let serialQueue = DispatchQueue(label: "com.brave.AdBlockStats.\(UUID().uuidString)")
  
  /// Return all the critical sources
  ///
  /// Critical sources are those that are enabled and are "on" by default. Giving us the most important sources.
  /// Used for memory managment so we know which filter lists to disable upon a memory warning
  @MainActor var criticalSources: [CachedAdBlockEngine.Source] {
    var enabledSources: [CachedAdBlockEngine.Source] = [.adBlock]
    enabledSources.append(contentsOf: FilterListStorage.shared.ciriticalSources)
    return enabledSources
  }
  
  @MainActor var enabledSources: [CachedAdBlockEngine.Source] {
    var enabledSources: [CachedAdBlockEngine.Source] = [.adBlock]
    enabledSources.append(contentsOf: FilterListStorage.shared.enabledSources)
    enabledSources.append(contentsOf: CustomFilterListStorage.shared.enabledSources)
    return enabledSources
  }

  init() {
    cachedEngines = [:]
    availableFilterLists = [:]
  }
  
  /// Handle memory warnings by freeing up some memory
  func didReceiveMemoryWarning() async {
    cachedEngines.values.forEach({ $0.clearCaches() })
    await removeDisabledEngines()
  }
  
  /// Create and add an engine from the given resources.
  /// If an engine already exists for the given source, it will be replaced.
  ///
  /// - Note: This method will ensure syncronous compilation
  public func compile(
    filterListInfo: CachedAdBlockEngine.FilterListInfo, resourcesInfo: CachedAdBlockEngine.ResourcesInfo, isAlwaysAggressive: Bool
  ) throws {
    try serialQueue.sync {
      guard needsCompilation(for: filterListInfo, resourcesInfo: resourcesInfo) else {
        // Ensure we only compile if we need to. This prevents two lazy loads from recompiling
        return
      }
      
      let engine = try CachedAdBlockEngine.compile(
        filterListInfo: filterListInfo, resourcesInfo: resourcesInfo, isAlwaysAggressive: isAlwaysAggressive
      )
      
      add(engine: engine)
    }
  }
  
  /// Add a new engine to the list.
  /// If an engine already exists for the same source, it will be replaced instead.
  private func add(engine: CachedAdBlockEngine) {
    cachedEngines[engine.filterListInfo.source] = engine
    updateIfNeeded(resourcesInfo: engine.resourcesInfo)
    updateIfNeeded(filterListInfo: engine.filterListInfo, isAlwaysAggressive: engine.isAlwaysAggressive)
    ContentBlockerManager.log.debug("Added engine for \(engine.filterListInfo.debugDescription)")
  }
  
  /// Add or update `filterListInfo` if it is a newer version. This information is used for lazy loading.
  func updateIfNeeded(filterListInfo: CachedAdBlockEngine.FilterListInfo, isAlwaysAggressive: Bool) {
    if let existingLazyInfo = availableFilterLists[filterListInfo.source] {
      guard filterListInfo.version > existingLazyInfo.filterListInfo.version else { return }
    }
    
    availableFilterLists[filterListInfo.source] = LazyFilterListInfo(
      filterListInfo: filterListInfo, isAlwaysAggressive: isAlwaysAggressive
    )
  }
  
  /// Add or update `resourcesInfo` if it is a newer version. This information is used for lazy loading.
  func updateIfNeeded(resourcesInfo: CachedAdBlockEngine.ResourcesInfo) {
    guard self.resourcesInfo == nil || resourcesInfo.version > self.resourcesInfo!.version else { return }
    self.resourcesInfo = resourcesInfo
  }
  
  /// Remove an engine for the given source.
  func removeEngine(for source: CachedAdBlockEngine.Source) {
    if let filterListInfo = cachedEngines[source]?.filterListInfo {
      ContentBlockerManager.log.debug("Removed engine for \(filterListInfo.debugDescription)")
    }
    
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
      removeEngine(for: source)
    }
  }
  
  /// Remove all engines that have disabled sources
  func ensureEnabledEngines() async {
    do {
      for source in await Set(enabledSources) {
        guard cachedEngines[source] == nil else { continue }
        guard let availableFilterList = availableFilterLists[source] else { continue }
        guard let resourcesInfo = self.resourcesInfo else { continue }
        
        do {
          try compile(
            filterListInfo: availableFilterList.filterListInfo,
            resourcesInfo: resourcesInfo,
            isAlwaysAggressive: availableFilterList.isAlwaysAggressive
          )
        } catch {
          // Ignore this error
        }
        
        // Sleep for 1ms. This drastically reduces memory usage without much impact to usability
        try await Task.sleep(nanoseconds: 1000000)
      }
    } catch {
      // Ignore cancellation errors
    }
  }
  
  /// Tells us if this source should be eagerly loaded.
  ///
  /// Eagerness is determined by several factors:
  /// * If the source represents a fitler list or a custom filter list, it is eager if it is enabled
  /// * If the source represents the `adblock` default filter list, it is always eager regardless of shield settings
  func isEagerlyLoaded(source: CachedAdBlockEngine.Source) async -> Bool {
    return await enabledSources.contains(source)
  }
  
  /// Tells us if an engine needs compilation if it's missing or if its resources are outdated
  func needsCompilation(for filterListInfo: CachedAdBlockEngine.FilterListInfo, resourcesInfo: CachedAdBlockEngine.ResourcesInfo) -> Bool {
    if let cachedEngine = cachedEngines[filterListInfo.source] {
      return cachedEngine.filterListInfo.version < filterListInfo.version
        && cachedEngine.resourcesInfo.version < resourcesInfo.version
    } else {
      return true
    }
  }
  
  /// Checks the general and regional engines to see if the request should be blocked
  func shouldBlock(requestURL: URL, sourceURL: URL, resourceType: AdblockEngine.ResourceType, isAggressiveMode: Bool) async -> Bool {
    let sources = await self.enabledSources
    return await cachedEngines(for: sources).asyncConcurrentMap({ cachedEngine in
      return await cachedEngine.shouldBlock(
        requestURL: requestURL,
        sourceURL: sourceURL,
        resourceType: resourceType,
        isAggressiveMode: isAggressiveMode
      )
    }).contains(where: { $0 })
  }
  
  /// This returns all the user script types for the given frame
  func makeEngineScriptTypes(frameURL: URL, isMainFrame: Bool, domain: Domain) async -> Set<UserScriptType> {
    // Add any engine scripts for this frame
    return await cachedEngines(for: domain).enumerated().asyncMap({ index, cachedEngine -> Set<UserScriptType> in
      do {
        return try await cachedEngine.makeEngineScriptTypes(
          frameURL: frameURL, isMainFrame: isMainFrame, domain: domain, index: index
        )
      } catch {
        assertionFailure()
        return []
      }
    }).reduce(Set<UserScriptType>(), { partialResult, scriptTypes in
      return partialResult.union(scriptTypes)
    })
  }
  
  /// Returns all appropriate engines for the given domain
  @MainActor func cachedEngines(for domain: Domain) async -> [CachedAdBlockEngine] {
    let sources = enabledSources(for: domain)
    return await cachedEngines(for: sources)
  }
  
  /// Return all the cached engines for the given sources. If any filter list is not yet loaded, it will be lazily loaded
  private func cachedEngines(for sources: [CachedAdBlockEngine.Source]) -> [CachedAdBlockEngine] {
    return sources.compactMap { source -> CachedAdBlockEngine? in
      return cachedEngines[source]
    }
  }
  
  /// Returns all the models for this frame URL
  func cosmeticFilterModels(forFrameURL frameURL: URL, domain: Domain) async -> [CosmeticFilterModelTuple] {
    return await cachedEngines(for: domain).asyncConcurrentCompactMap { cachedEngine -> CosmeticFilterModelTuple? in
      do {
        guard let model = try await cachedEngine.cosmeticFilterModel(forFrameURL: frameURL) else {
          return nil
        }
        return (cachedEngine.isAlwaysAggressive, model)
      } catch {
        assertionFailure()
        return nil
      }
    }
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
