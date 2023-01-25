// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import Combine
import BraveCore

actor FilterListCustomURLDownloader: ObservableObject {
  /// A formatter that is used to format a version number
  private let fileVersionDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy.MM.dd.HH.mm.ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    return dateFormatter
  }()
  
  static let shared = FilterListCustomURLDownloader()
  
  /// The resource downloader that downloads our resources
  private let resourceDownloader: ResourceDownloader
  /// Fetch content blocking tasks per filter list
  private var fetchTasks: [ResourceDownloader.Resource: Task<Void, Error>]
  
  init(networkManager: NetworkManager = NetworkManager()) {
    self.resourceDownloader = ResourceDownloader(networkManager: networkManager)
    self.fetchTasks = [:]
  }
  
  func loadCachedFilterLists() async {
    await CustomFilterListStorage.shared.loadCachedFilterLists()
    
    await CustomFilterListStorage.shared.filterListsURLs.asyncConcurrentForEach { customURL in
      await self.handleUpdate(to: customURL, isEnabled: customURL.setting.isEnabled)
      
      // Always fetch this resource so it's ready if the user enables it.
      await self.startFetching(filterListCustomURL: customURL)
    }
  }
  
  private func handle(downloadResult: ResourceDownloaderStream.DownloadResult, for filterListCustomURL: FilterListCustomURL) async {
    let uuid = await filterListCustomURL.setting.uuid
    let hasCache = await ContentBlockerManager.shared.hasCache(for: .customFilterList(uuid: uuid))
    
    // Compile this rule list if we haven't already or if the file has been modified
    if !hasCache || downloadResult.isModified {
      do {
        let filterSet = try String(contentsOf: downloadResult.fileURL, encoding: .utf8)
        let jsonRules = AdblockEngine.contentBlockerRules(fromFilterSet: filterSet)
        
        try await ContentBlockerManager.shared.compile(
          encodedContentRuleList: jsonRules,
          for: .customFilterList(uuid: uuid),
          options: .all
        )
      } catch {
        ContentBlockerManager.log.error(
          "Failed to convert custom filter list to content blockers: \(error.localizedDescription)"
        )
      }
    }
      
    // Add/remove the resource depending on if it is enabled/disabled
    if await filterListCustomURL.setting.isEnabled {
      let version = fileVersionDateFormatter.string(from: downloadResult.date)
      
      await AdBlockEngineManager.shared.add(
        resource: AdBlockEngineManager.Resource(type: .ruleList, source: .filterListURL(uuid: uuid)),
        fileURL: downloadResult.fileURL, version: version
      )
    } else {
      await AdBlockEngineManager.shared.removeResources(
        for: .filterListURL(uuid: uuid)
      )
    }
  }
  
  @MainActor func handleUpdate(to filterListCustomURL: FilterListCustomURL, isEnabled: Bool) async {
    if isEnabled {
      let resource = filterListCustomURL.setting.resource
      
      do {
        if let downloadResult = try ResourceDownloaderStream.downloadResult(for: resource) {
          await self.handle(downloadResult: downloadResult, for: filterListCustomURL)
        }
      } catch {
        assertionFailure()
      }
    } else {
      // We need to remove this resource if we disable this filter list
      // But we will keep the compiled rule lists since we can remove them from the web-view.
      await AdBlockEngineManager.shared.removeResources(
        for: .filterListURL(uuid: filterListCustomURL.setting.uuid)
      )
    }
  }
  
  /// Start fetching the resource for the given filter list
  func startFetching(filterListCustomURL: FilterListCustomURL) async {
    let resource = await filterListCustomURL.setting.resource
    
    guard fetchTasks[resource] == nil else {
      // We're already fetching for this filter list
      return
    }
    
    fetchTasks[resource] = Task {
      do {
        for try await result in await self.resourceDownloader.downloadStream(for: resource) {
          switch result {
          case .success(let downloadResult):
            // Update the data for UI purposes
            await CustomFilterListStorage.shared.update(
              filterListId: filterListCustomURL.id,
              with: .success(downloadResult.date)
            )
            
            // Handle the successful result so we parse the content blockers
            await self.handle(
              downloadResult: downloadResult,
              for: filterListCustomURL
            )
          case .failure(let error):
            // We don't want to keep refetching these types of failures
            let hardFailureCodes = [URLError.Code.badURL, .appTransportSecurityRequiresSecureConnection, .fileIsDirectory, .unsupportedURL]
            if let urlError = error as? URLError, hardFailureCodes.contains(urlError.code) {
              throw urlError
            }
            
            await CustomFilterListStorage.shared.update(
              filterListId: filterListCustomURL.id,
              with: .failure(error)
            )
          }
        }
      } catch is CancellationError {
        self.fetchTasks.removeValue(forKey: resource)
      } catch {
        self.fetchTasks.removeValue(forKey: resource)
        
        await CustomFilterListStorage.shared.update(
          filterListId: filterListCustomURL.id,
          with: .failure(error)
        )
      }
    }
  }
  
  /// Cancel all fetching tasks for the given filter list
  func stopFetching(filterListCustomURL: FilterListCustomURL) async {
    let resource = await filterListCustomURL.setting.resource
    fetchTasks[resource]?.cancel()
    fetchTasks.removeValue(forKey: resource)
  }
}

extension CustomFilterListSetting {
  @MainActor var resource: ResourceDownloader.Resource {
    return .customFilterListURL(uuid: uuid, externalURL: externalURL)
  }
}
