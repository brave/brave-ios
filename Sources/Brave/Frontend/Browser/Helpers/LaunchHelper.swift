// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Preferences
import BraveShields
import os

/// This class helps to prepare the browser during launch by ensuring the state of managers, resources and downloaders before performing additional tasks.
public actor LaunchHelper {
  public static let shared = LaunchHelper()
  static let signpost = OSSignposter(logger: ContentBlockerManager.log)
  private let currentBlocklistVersion: Float = 1.0
  
  /// Get the last version the user launched this application. This allows us to know what to re-compile.
  public var lastBlocklistVersion = Preferences.Option<Float?>(
    key: "launch_helper.last-launch-version", default: nil
  )
  
  private var loadTask: Task<(), Never>?
  private var areAdBlockServicesReady = true
  
  /// This method prepares the ad-block services one time so that multiple scenes can benefit from its results
  /// This is particularly important since we use a shared instance for most of our ad-block services.
  public func prepareAdBlockServices(adBlockService: AdblockService) async {
    
  }
  
  /// Return the blocking modes we need to pre-compile on first launch.
  private func getFirstLaunchBlocklistModes() -> Set<ContentBlockerManager.BlockingMode> {
    guard let version = self.lastBlocklistVersion.value else {
      // If we don't have version, this is our first launch
      return ShieldPreferences.blockAdsAndTrackingLevel.firstLaunchBlockingModes
    }
    
    if version < currentBlocklistVersion {
      // We updated something and require things to be re-compiled
      return ShieldPreferences.blockAdsAndTrackingLevel.firstLaunchBlockingModes
    } else {
      // iOS caches content blockers. We only need to pre-compile things the first time (on first launch).
      // Since we didn't change anything and we know this isn't a first launch, we can return an empty set
      // So that subsequent relaunches are much faster
      return []
    }
  }
  
  /// Perform tasks that don't need to block the initial load (things that can happen happily in the background after the first page loads
  private func performPostLoadTasks(adBlockService: AdblockService, loadedBlockModes: Set<ContentBlockerManager.BlockingMode>) {
    
  }
  
  /// Get all possible types of blocklist types available in this app, this includes actual and potential types
  /// This is used to delete old filter lists so that we clean up old stuff
  @MainActor private func getAllValidBlocklistTypes() -> Set<ContentBlockerManager.BlocklistType> {
    return FilterListStorage.shared
      // All filter lists blocklist types
      .validBlocklistTypes
      // All generic types
      .union(
        ContentBlockerManager.GenericBlocklistType.allCases.map { .generic($0) }
      )
      // All custom filter list urls
      .union(
        CustomFilterListStorage.shared.filterListsURLs.map { .customFilterList(uuid: $0.setting.uuid) }
      )
  }
}

private extension FilterListStorage {
  /// Return all the blocklist types that are valid for filter lists.
  var validBlocklistTypes: Set<ContentBlockerManager.BlocklistType> {
    if filterLists.isEmpty {
      // If we don't have filter lists yet loaded, use the settings
      return Set(allFilterListSettings.compactMap { setting in
        guard let componentId = setting.componentId else { return nil }
        return .filterList(
          componentId: componentId,
          isAlwaysAggressive: setting.isAlwaysAggressive
        )
      })
    } else {
      // If we do have filter lists yet loaded, use them as they are always the most up to date and accurate
      return Set(filterLists.map { filterList in
        return .filterList(
          componentId: filterList.entry.componentId, 
          isAlwaysAggressive: filterList.isAlwaysAggressive
        )
      })
    }
  }
}
private extension ShieldLevel {
  /// Return a list of first launch content blocker modes that MUST be precompiled during launch
  var firstLaunchBlockingModes: Set<ContentBlockerManager.BlockingMode> {
    switch self {
    case .standard, .disabled:
      // Disabled setting may be overriden per domain so we need to treat it as standard
      // Aggressive needs to be included because some filter lists are aggressive only
      return [.general, .standard, .aggressive]
    case .aggressive:
      // If we have aggressive mode enabled, we never use standard
      // (until we allow domain specific aggressive mode)
      return [.general, .aggressive]
    }
  }
}
