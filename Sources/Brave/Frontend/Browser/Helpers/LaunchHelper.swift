// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

/// This class helps to prepare the browser during launch by ensuring the state of managers, resources and downloaders before performing additional tasks.
public actor LaunchHelper {
  public static let shared = LaunchHelper()
  private var loadTask: Task<(), Never>?
  private var areAdBlockServicesReady = false
  
  /// This method prepares the ad-block services one time so that multiple scenes can benefit from its results
  /// This is particularly important since we use a shared instance for most of our ad-block services.
  public func prepareAdBlockServices(adBlockService: AdblockService) async {
    // Check if ad-block services are already ready.
    // If so, we don't have to do anything
    guard !areAdBlockServicesReady else { return }
    
    // Check if we're still preparing the ad-block services
    // If so we await that task
    if let task = loadTask {
      return await task.value
    }
    
    // Otherwise prepare the services and await the task
    let task = Task {
      #if DEBUG
      let startTime = CFAbsoluteTimeGetCurrent()
      #endif
      
      // Load cached data
      // This is done first because compileResources need their results
      async let filterListCache: Void = FilterListResourceDownloader.shared.loadCachedData()
      async let adblockResourceCache: Void = AdblockResourceDownloader.shared.loadCachedAndBundledDataIfNeeded()
      _ = await (filterListCache, adblockResourceCache)
      
      // Compile some engines
      await AdBlockEngineManager.shared.compileResources()
      
      #if DEBUG
      let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
      ContentBlockerManager.log.debug("Adblock loaded: \(timeElapsed)s")
      #endif
      // This one is non-blocking
      performPostLoadTasks(adBlockService: adBlockService)
      areAdBlockServicesReady = true
    }
    
    // Await the task and wait for the results
    self.loadTask = task
    await task.value
    self.loadTask = nil
  }
  
  /// Perform tasks that don't need to block the initial load (things that can happen happily in the background after the first page loads
  private func performPostLoadTasks(adBlockService: AdblockService) {
    Task.detached(priority: .low) {
      await FilterListResourceDownloader.shared.start(with: adBlockService)
      await AdblockResourceDownloader.shared.reloadBundledOnlyData()
      await AdblockResourceDownloader.shared.startFetching()
      await AdBlockEngineManager.shared.startTimer()
      
      /// Cleanup rule lists so we don't have dead rule lists
      let validBlocklistTypes = await self.getAllValidBlocklistTypes()
      await ContentBlockerManager.shared.cleaupInvalidRuleLists(validTypes: validBlocklistTypes)
    }
  }
  
  /// Get all possible types of blocklist types available in this app, this includes actual and potential types
  /// This is used to delete old filter lists so that we clean up old stuff
  @MainActor private func getAllValidBlocklistTypes() -> Set<ContentBlockerManager.BlocklistType> {
    return FilterListResourceDownloader.shared.filterLists
      // All filter lists blocklist types
      .reduce(Set<ContentBlockerManager.BlocklistType>()) { partialResult, filterList in
        return partialResult.union([.filterList(uuid: filterList.uuid)])
      }
      // All generic types
      .union(
        ContentBlockerManager.GenericBlocklistType.allCases.map { .generic($0) }
      )
  }
}
