// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import Shared
import BraveShared
import os.log

/// A class responsible for downloading some generic ad-block resources
public actor AdblockResourceDownloader: Sendable {
  public static let shared = AdblockResourceDownloader()
  
  /// All the different resources this downloader handles
  static let handledResources: [BraveS3Resource] = [
    .genericContentBlockingBehaviors, .debounceRules
  ]
  
  /// A list of old resources that need to be deleted so as not to take up the user's disk space
  private static let deprecatedResources: [BraveS3Resource] = [.deprecatedGeneralCosmeticFilters]
  
  /// A formatter that is used to format a version number
  private let fileVersionDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy.MM.dd.HH.mm.ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter
  }()
  
  /// The resource downloader that will be used to download all our resoruces
  private let resourceDownloader: ResourceDownloader<BraveS3Resource>

  init(networkManager: NetworkManager = NetworkManager()) {
    self.resourceDownloader = ResourceDownloader(networkManager: networkManager)
  }
  
  /// Load the cached data and await the results
  public func loadCachedAndBundledDataIfNeeded() async {
    // Here we load downloaded resources if we need to
    await Self.handledResources.asyncConcurrentForEach { resource in
      do {
        // Check if we have cached results for the given resource
        if let cachedResult = try resource.cachedResult() {
          await self.handle(downloadResult: cachedResult, for: resource)
        }
      } catch {
        ContentBlockerManager.log.error(
          "Failed to load cached data for resource \(resource.cacheFileName): \(error)"
        )
      }
    }
    
    // Compile bundled blocklists but only if we don't have anything already loaded.
    await ContentBlockerManager.GenericBlocklistType.allCases.asyncConcurrentForEach { genericType in
      let blocklistType = ContentBlockerManager.BlocklistType.generic(genericType)
      let modes = await blocklistType.allowedModes.asyncFilter { mode in
        if await ContentBlockerManager.shared.hasRuleList(for: blocklistType, mode: mode) {
          ContentBlockerManager.log.debug("Rule list already compiled for `\(blocklistType.makeIdentifier(for: mode))`")
          return false
        } else {
          return true
        }
      }
      
      do {
        try await ContentBlockerManager.shared.compileBundledRuleList(for: genericType, modes: modes)
      } catch {
        assertionFailure("A bundled file should not fail to compile")
      }
    }
  }
  
  /// This reloads bundled data. This is needed in case the bundled data changed since last app update.
  /// This is done on the background to speed up launch time. We don't recompile downloadable resources.
  public func reloadBundledOnlyData() async {
    // Compile bundled blocklists for non-downloadable types in case they changed since
    // the last version
    await ContentBlockerManager.GenericBlocklistType.allCases.asyncConcurrentForEach { genericType in
      // This type of rule list is replaced by a downloaded version
      // We can't just recompile this type.
      guard genericType != .blockAds else { return }
       
      do {
        try await ContentBlockerManager.shared.compileBundledRuleList(for: genericType)
      } catch {
        assertionFailure("A bundled file should not fail to compile")
      }
    }
  }

  /// Start fetching resources
  public func startFetching() {
    let fetchInterval = AppConstants.buildChannel.isPublic ? 6.hours : 10.minutes
    
    for resource in Self.handledResources {
      startFetching(resource: resource, every: fetchInterval)
    }
    
    // Remove any old files
    // We can remove this code in some not-so-distant future
    for resource in Self.deprecatedResources {
      do {
        try resource.removeCacheFolder()
      } catch {
        ContentBlockerManager.log.error(
          "Failed to removed deprecated file \(resource.cacheFileName): \(error)"
        )
      }
    }
  }
  
  /// Start fetching the given resource at regular intervals
  private func startFetching(resource: BraveS3Resource, every fetchInterval: TimeInterval) {
    Task { @MainActor in
      for try await result in await self.resourceDownloader.downloadStream(for: resource, every: fetchInterval) {
        switch result {
        case .success(let downloadResult):
          await self.handle(downloadResult: downloadResult, for: resource)
        case .failure(let error):
          Logger.module.error("\(error.localizedDescription)")
        }
      }
    }
  }
  
  /// Handle the downloaded file url for the given resource
  private func handle(downloadResult: ResourceDownloader<BraveS3Resource>.DownloadResult, for resource: BraveS3Resource) async {
    let version = fileVersionDateFormatter.string(from: downloadResult.date)
    
    switch resource {
    case .genericContentBlockingBehaviors:
      let blocklistType = ContentBlockerManager.BlocklistType.generic(.blockAds)
      let modes = await blocklistType.allowedModes.asyncFilter { mode in
        if downloadResult.isModified { return true }
          
        if await ContentBlockerManager.shared.hasRuleList(for: blocklistType, mode: mode) {
          ContentBlockerManager.log.debug("Rule list already compiled for `\(blocklistType.makeIdentifier(for: mode))`")
          return false
        } else {
          return true
        }
      }
      
      do {
        guard !modes.isEmpty else { return }
        guard let encodedContentRuleList = try resource.downloadedString() else {
          assertionFailure("This file was downloaded successfully so it should not be nil")
          return
        }
        
        // try to compile
        try await ContentBlockerManager.shared.compile(
          encodedContentRuleList: encodedContentRuleList,
          for: .generic(.blockAds),
          modes: modes
        )
      } catch {
        ContentBlockerManager.log.error(
          "Failed to compile downloaded content blocker resource: \(error.localizedDescription)"
        )
      }
      
    case .debounceRules:
      // We don't want to setup the debounce rules more than once for the same cached file
      guard downloadResult.isModified || DebouncingService.shared.matcher == nil else {
        return
      }
      
      do {
        guard let data = try resource.downloadedData() else {
          assertionFailure("We just downloaded this file, how can it not be there?")
          return
        }
        
        try DebouncingService.shared.setup(withRulesJSON: data)
      } catch {
        ContentBlockerManager.log.error("Failed to setup debounce rules: \(error.localizedDescription)")
      }
      
    default:
      assertionFailure("Should not be handling this resource type")
    }
  }
}
