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
  
  /// List of all bundled content blockers.
  /// Regional lists are downloaded on fly and not included here.
  private static var bundledLists: Set<ContentBlockerManager.GenericBlocklistType> = [
    .blockTrackers, .blockCookies
  ]
  
  /// All the different resources this downloader handles
  static let handledResources: [BraveS3Resource] = [
    .genericContentBlockingBehaviors, .generalCosmeticFilters, .debounceRules
  ]
  
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
  /// All the resources that this downloader handles
  

  init(networkManager: NetworkManager = NetworkManager()) {
    self.resourceDownloader = ResourceDownloader(networkManager: networkManager)
  }
  
  /// Load the cached data and await the results
  public func loadCachedData() async {
    // Compile bundled blocklists
    // but only for those that are not replaced by a downloaded version.
    // Below we will handle downloaded resources
    await Self.bundledLists.asyncConcurrentForEach { genericType in
      do {
        try await ContentBlockerManager.shared.compileBundledRuleList(for: genericType)
      } catch {
        assertionFailure("A bundled file should not fail to compile")
      }
    }
    
    // Here we load downloaded resources if we need to
    await Self.handledResources.asyncConcurrentForEach { resource in
      await self.loadCachedData(for: resource)
    }
  }

  /// Start fetching resources
  public func startFetching() {
    let fetchInterval = AppConstants.buildChannel.isPublic ? 6.hours : 10.minutes
    
    for resource in Self.handledResources {
      startFetching(resource: resource, every: fetchInterval)
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
  
  /// Load cached data for the given resource. Ensures this is done on the MainActor
  private func loadCachedData(for resource: BraveS3Resource) async {
    do {
      if let downloadResult = try ResourceDownloaderStream.downloadResult(for: resource) {
        await handle(downloadResult: downloadResult, for: resource)
      } else {
        switch resource {
        case .genericContentBlockingBehaviors:
          do {
            // This is a special case which we load a bundled file if the downloaded file is not present
            try await ContentBlockerManager.shared.compileBundledRuleList(for: .blockAds)
          } catch {
            assertionFailure("A bundled file should not fail to compile")
            ContentBlockerManager.log.error("Failed to compile bundled content blocker resource: \(error.localizedDescription)")
          }
          
        default:
          // No special handling if these files are not downloaded
          // But ensure that this is only triggered for handled resource
          // We should have never triggered this method for resources that are outside
          // of the handled resources list
          assert(Self.handledResources.contains(resource))
        }
      }
    } catch {
      assertionFailure()
    }
  }
  
  /// Handle the downloaded file url for the given resource
  private func handle(downloadResult: ResourceDownloaderStream<BraveS3Resource>.DownloadResult, for resource: BraveS3Resource) async {
    let version = fileVersionDateFormatter.string(from: downloadResult.date)
    
    switch resource {
    case .generalCosmeticFilters:
      await AdBlockEngineManager.shared.add(
        resource: AdBlockEngineManager.Resource(type: .dat, source: .cosmeticFilters),
        fileURL: downloadResult.fileURL,
        version: version
      )
      
    case .genericContentBlockingBehaviors:
      do {
        if !downloadResult.isModified {
          // If the file is not modified first we need to see if we already have a cached value loaded
          // We don't what to bother recompiling this file if we already loaded it
          guard try await ContentBlockerManager.shared.loadRuleList(for: .generic(.blockAds)) == nil else {
            // We don't want to recompile something that we alrady have loaded
            return
          }
        }
        
        guard let encodedContentRuleList = try ResourceDownloader.string(for: resource) else {
          assertionFailure("This file was downloaded successfully so it should not be nil")
          return
        }
        
        // try to compile
        try await ContentBlockerManager.shared.compile(
          encodedContentRuleList: encodedContentRuleList,
          for: .generic(.blockAds)
        )
      } catch {
        ContentBlockerManager.log.error("Failed to compile downloaded content blocker resource: \(error.localizedDescription)")
      }
      
    case .debounceRules:
      // We don't want to setup the debounce rules more than once for the same cached file
      guard downloadResult.isModified || DebouncingResourceDownloader.shared.matcher == nil else {
        return
      }
      
      do {
        guard let data = try ResourceDownloader<BraveS3Resource>.data(for: resource) else {
          assertionFailure("We just downloaded this file, how can it not be there?")
          return
        }
        
        try DebouncingResourceDownloader.shared.setup(withRulesJSON: data)
      } catch {
        ContentBlockerManager.log.error("Failed to setup debounce rules: \(error.localizedDescription)")
      }
      
    default:
      assertionFailure("Should not be handling this resource type")
    }
  }
}
