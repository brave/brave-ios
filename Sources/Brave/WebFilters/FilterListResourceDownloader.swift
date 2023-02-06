// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Combine
import Data
import BraveCore
import Shared
import BraveShared
import os.log

/// An object responsible for fetching filer lists resources from multiple sources
public class FilterListResourceDownloader {
  /// A shared instance of this class
  ///
  /// - Warning: You need to wait for `DataController.shared.initializeOnce()` to be called before using this instance
  public static let shared = FilterListResourceDownloader()
  
  /// Object responsible for getting component updates
  private var adBlockService: AdblockService?
  /// The filter list subscription
  private var filterListSubscription: AnyCancellable?
  /// Ad block service tasks per filter list UUID
  private var adBlockServiceTasks: [String: Task<Void, Error>]
  /// A marker that says if fetching has started
  private var startedFetching = false
  /// A list of loaded versions for the filter lists with the componentId as the key and version as the value
  private var loadedRuleListVersions: [String: String]
  
  /// A formatter that is used to format a version number
  private lazy var fileVersionDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy.MM.dd.HH.mm.ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter
  }()
  
  init() {
    self.adBlockServiceTasks = [:]
    self.adBlockService = nil
    self.loadedRuleListVersions = [:]
  }
  
  /// This loads the filter list settings from core data.
  /// It uses these settings and other stored properties to load the enabled general shields and filter lists.
  ///
  /// - Warning: This method loads filter list settings.
  /// You need to wait for `DataController.shared.initializeOnce()` to be called first before invoking this method
  public func loadFilterListSettingsAndCachedData() async {
    async let cachedFilterLists: Void = self.addEngineResourcesFromCachedFilterLists()
    async let cachedGeneralFilterList: Void = self.addEngineResourcesFromCachedGeneralFilterList()
    _ = await (cachedFilterLists, cachedGeneralFilterList)
  }
  
  /// This function adds engine resources to `AdBlockManager` from cached data representing the enabled filter lists.
  ///
  /// The filter lists are additional blocking content that can be added to the`AdBlockEngine` and as iOS content blockers.
  /// It represents the items found in the "Filter lists" section of the "Shields" menu.
  ///
  /// - Note: The content blockers for these filter lists are not loaded at this point. They are cached by iOS and there is no need to reload them.
  ///
  /// - Warning: This method loads filter list settings.
  /// You need to wait for `DataController.shared.initializeOnce()` to be called first before invoking this method
  private func addEngineResourcesFromCachedFilterLists() async {
    await FilterListStorage.shared.loadFilterListSettings()
    let filterListSettings = await FilterListStorage.shared.allFilterListSettings
      
    await filterListSettings.asyncConcurrentForEach { setting in
      guard await setting.isEnabled == true else { return }
      guard let componentId = await setting.componentId else { return }
      
      // Try to load the filter list folder. We always have to compile this at start
      guard let folderURL = await setting.folderURL, FileManager.default.fileExists(atPath: folderURL.path) else {
        return
      }
      
      // Because this is called during launch, we don't want to recompile content blockers.
      // This is because recompiling content blockers is too expensive and they are lazily loaded anyways.
      await self.loadShields(
        fromComponentId: componentId, folderURL: folderURL,
        relativeOrder: setting.order?.intValue ?? 0,
        loadContentBlockers: false
      )
    }
  }
  
  /// This function adds engine resources to `AdBlockManager` from the "general" filter list.
  ///
  /// The "general" filter list is a built in filter list that is added to the`AdBlockEngine` and as content blockers.
  /// It represents the "Block cross site trackers" toggle in the "Shields" menu.
  ///
  /// - Note: The content blockers for this "general" filter list are handled using the `AdBlockResourceDownloader` and are not loaded here at this point.
  private func addEngineResourcesFromCachedGeneralFilterList() async {
    guard let folderURL = await FilterListSetting.makeFolderURL(
      forFilterListFolderPath: Preferences.AppState.lastDefaultFilterListFolderPath.value
    ), FileManager.default.fileExists(atPath: folderURL.path) else {
      return
    }
    
    await addEngineResources(fromGeneralFilterListFolderURL: folderURL)
  }
  
  /// Start the adblock service to get updates to the `shieldsInstallPath`
  @MainActor public func start(with adBlockService: AdblockService) {
    self.adBlockService = adBlockService
    
    // Start listening to changes to the install url
    Task {
      for await folderURL in adBlockService.shieldsInstallURL {
        self.didUpdateShieldComponent(
          folderURL: folderURL,
          adBlockFilterLists: adBlockService.regionalFilterLists ?? []
        )
      }
    }
  }
  
  /// Invoked when shield components are loaded
  ///
  /// This function will start fetching data and subscribe publishers once if it hasn't already done so.
  @MainActor private func didUpdateShieldComponent(folderURL: URL, adBlockFilterLists: [AdblockFilterListCatalogEntry]) {
    if !startedFetching && !adBlockFilterLists.isEmpty {
      // This is the first time we load ad-block filters.
      // We need to perform some initial setup (but only do this once)
      startedFetching = true
      FilterListStorage.shared.loadFilterLists(from: adBlockFilterLists)
      
      self.subscribeToFilterListChanges()
      self.registerAllEnabledFilterLists()
    }
    
    // Store the folder path so we can load it from cache next time we launch quicker
    // than waiting for the component updater to respond, which may take a few seconds
    let folderSubPath = FilterListSetting.extractFolderPath(fromFilterListFolderURL: folderURL)
    Preferences.AppState.lastDefaultFilterListFolderPath.value = folderSubPath
    
    Task {
      await self.addEngineResources(fromGeneralFilterListFolderURL: folderURL)
    }
  }
  
  /// Load shields with the given `AdblockService` folder `URL`
  private func addEngineResources(fromGeneralFilterListFolderURL folderURL: URL) async {
    let version = folderURL.lastPathComponent
    await AdBlockEngineManager.shared.set(scripletResourcesURL: folderURL.appendingPathComponent("resources.json"))
    
    // Lets add these new resources
    await AdBlockEngineManager.shared.add(
      resource: AdBlockEngineManager.Resource(type: .dat, source: .adBlock),
      fileURL: folderURL.appendingPathComponent("rs-ABPFilterParserData.dat"),
      version: version
    )
  }
  
  /// Subscribe to the UI changes on the `filterLists` so that we can save settings and register or unregister the filter lists
  @MainActor private func subscribeToFilterListChanges() {
    // Subscribe to changes on the filter list states
    filterListSubscription = FilterListStorage.shared.$filterLists
      .sink { filterLists in
        DispatchQueue.main.async { [weak self] in
          for filterList in filterLists {
            self?.handleUpdate(to: filterList)
          }
        }
      }
  }
  
  /// Ensures settings are saved for the given filter list and that our publisher is aware of the changes
  @MainActor private func handleUpdate(to filterList: FilterList) {
    FilterListStorage.shared.handleUpdate(to: filterList)
    
    // Register or unregister the filter list depending on its toggle state
    if filterList.isEnabled {
      register(filterList: filterList)
    } else {
      unregister(filterList: filterList)
    }
  }
  
  /// Register all enabled filter lists
  @MainActor private func registerAllEnabledFilterLists() {
    for filterList in FilterListStorage.shared.filterLists {
      guard filterList.isEnabled else { continue }
      register(filterList: filterList)
    }
  }
  
  /// Register this filter list and start all additional resource downloads
  @MainActor private func register(filterList: FilterList) {
    guard adBlockServiceTasks[filterList.uuid] == nil else { return }
    guard let adBlockService = adBlockService else { return }
    guard let index = FilterListStorage.shared.filterLists.firstIndex(where: { $0.uuid == filterList.uuid }) else { return }

    adBlockServiceTasks[filterList.uuid] = Task { @MainActor in
      for await folderURL in adBlockService.register(filterList: filterList) {
        guard let folderURL = folderURL else { continue }
        
        await self.loadShields(
          fromComponentId: filterList.entry.componentId, folderURL: folderURL, relativeOrder: index,
          loadContentBlockers: true
        )
        
        // Save the downloaded folder for later (caching) purposes
        FilterListStorage.shared.set(folderURL: folderURL, forUUID: filterList.uuid)
      }
    }
  }
  
  /// Unregister, cancel all of its downloads and remove any `ContentBlockerManager` and `AdBlockEngineManager` resources for this filter list
  @MainActor private func unregister(filterList: FilterList) {
    adBlockServiceTasks[filterList.uuid]?.cancel()
    adBlockServiceTasks.removeValue(forKey: filterList.uuid)
    
    Task {
      await AdBlockEngineManager.shared.removeResources(
        for: .filterList(componentId: filterList.entry.componentId)
      )
    }
  }
  
  /// Handle the downloaded folder url for the given filter list. The folder URL should point to a `AdblockFilterList` resource
  /// This will also start fetching any additional resources for the given filter list given it is still enabled.
  private func loadShields(fromComponentId componentId: String, folderURL: URL, relativeOrder: Int, loadContentBlockers: Bool) async {
    // Check if we're loading the new or old component. The new component has a file `list.txt`
    // Which we check the presence of.
    let filterListURL = folderURL.appendingPathComponent("list.txt", conformingTo: .text)
    guard FileManager.default.fileExists(atPath: filterListURL.relativePath) else {
      // We are loading the old component from cache. We don't want this file to be loaded.
      // When we download the new component we will then add it. We can scrap the old one.
      return
    }
    
    let version = folderURL.lastPathComponent
    
    // Add or remove the filter list from the engine depending if it's been enabled or not
    if await FilterListStorage.shared.isEnabled(for: componentId) {
      await AdBlockEngineManager.shared.add(
        resource: AdBlockEngineManager.Resource(type: .ruleList, source: .filterList(componentId: componentId)),
        fileURL: filterListURL,
        version: version,
        relativeOrder: relativeOrder
      )
    } else {
      await AdBlockEngineManager.shared.removeResources(for: .filterList(componentId: componentId))
    }
    
    // Compile this rule list if we haven't already or if the file has been modified
    // We also don't load them if they are loading from cache because this will cost too much during launch
    if loadContentBlockers {
      await compileRuleListsIfNeeded(
        fromComponentId: componentId, filterListURL: filterListURL, version: version
      )
    }
  }
  
  // Compile rule lists but only if they are not already compiled or if the version changed
  private func compileRuleListsIfNeeded(fromComponentId componentId: String, filterListURL: URL, version: String) async {
    guard await needsRuleListCompilation(forComponentId: componentId, version: version) else {
      ContentBlockerManager.log.debug(
        "Rule list still valid for `\(componentId)`"
      )
      
      return
    }
    
    do {
      let filterSet = try String(contentsOf: filterListURL, encoding: .utf8)
      let jsonRules = AdblockEngine.contentBlockerRules(fromFilterSet: filterSet)
      
      try await ContentBlockerManager.shared.compile(
        encodedContentRuleList: jsonRules,
        for: .filterList(componentId: componentId),
        options: .all
      )
      
      loadedRuleListVersions[componentId] = version
    } catch {
      ContentBlockerManager.log.error(
        "Failed to convert filter list `\(componentId)` to content blockers: \(error.localizedDescription)"
      )
      #if DEBUG
      ContentBlockerManager.log.debug(
        "`\(componentId)`: \(filterListURL.absoluteString)"
      )
      #endif
    }
  }
  
  private func needsRuleListCompilation(forComponentId componentId: String, version: String) async -> Bool {
    if let loadedVersion = loadedRuleListVersions[componentId] {
      // if we know the loaded version we can just check it (optimization)
      return loadedVersion != version
    } else {
      // Otherwise we need to check the rule list version
      return await !ContentBlockerManager.shared.hasRuleList(for: .filterList(componentId: componentId))
    }
  }
}

/// Helpful extension to the AdblockService
private extension AdblockService {
  /// Stream the URL updates to the `shieldsInstallPath`
  ///
  /// - Warning: You should never do this more than once. Only one callback can be registered to the `shieldsComponentReady` callback.
  @MainActor var shieldsInstallURL: AsyncStream<URL> {
    return AsyncStream { continuation in
      if let folderPath = shieldsInstallPath {
        let folderURL = URL(fileURLWithPath: folderPath)
        continuation.yield(folderURL)
      }
      
      guard shieldsComponentReady == nil else {
        assertionFailure("You have already set the `shieldsComponentReady` callback. Setting this more than once replaces the previous callback.")
        return
      }
      
      shieldsComponentReady = { folderPath in
        guard let folderPath = folderPath else {
          return
        }
        
        let folderURL = URL(fileURLWithPath: folderPath)
        continuation.yield(folderURL)
      }
      
      continuation.onTermination = { @Sendable _ in
        self.shieldsComponentReady = nil
      }
    }
  }
  
  /// Register the filter list given by the uuid and streams its updates
  ///
  /// - Note: Cancelling this task will unregister this filter list from recieving any further updates
  @MainActor func register(filterList: FilterList) -> AsyncStream<URL?> {
    return AsyncStream { continuation in
      registerFilterListComponent(filterList.entry, useLegacyComponent: false) { folderPath in
        guard let folderPath = folderPath else {
          continuation.yield(nil)
          return
        }
        
        let folderURL = URL(fileURLWithPath: folderPath)
        continuation.yield(folderURL)
      }
      
      continuation.onTermination = { @Sendable _ in
        self.unregisterFilterListComponent(filterList.entry, useLegacyComponent: true)
      }
    }
  }
}
