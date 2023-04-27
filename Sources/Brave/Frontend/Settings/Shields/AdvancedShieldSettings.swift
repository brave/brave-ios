// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Combine
import BraveCore
import BraveNews
import Preferences
import Data
import os

@MainActor class AdvancedShieldsSettings: ObservableObject {
  struct ClearableSetting: Identifiable {
    enum ClearableType: String {
      case history, cache, cookiesAndCache, passwords, downloads, braveNews, playlistCache, playlistData, recentSearches
    }
    
    var id: ClearableType
    var clearable: Clearable
    var isEnabled: Bool
  }
  
  @Published var cookieConsentBlocking: Bool {
    didSet {
      FilterListStorage.shared.enableFilterList(
        for: FilterList.cookieConsentNoticesComponentID, isEnabled: cookieConsentBlocking
      )
    }
  }
  @Published var blockMobileAnnoyances: Bool {
    didSet {
      FilterListStorage.shared.enableFilterList(
        for: FilterList.mobileAnnoyancesComponentID, isEnabled: blockMobileAnnoyances
      )
    }
  }
  @Published var isP3AEnabled: Bool {
    didSet {
      p3aUtilities.isP3AEnabled = isP3AEnabled
    }
  }
  
  @Published var clearableSettings: [ClearableSetting]
  
  private var subscriptions: [AnyCancellable] = []
  private let p3aUtilities: BraveP3AUtils
  private let tabManager: TabManager
  
  init(profile: Profile, tabManager: TabManager, feedDataSource: FeedDataSource, historyAPI: BraveHistoryAPI, p3aUtilities: BraveP3AUtils) {
    self.p3aUtilities = p3aUtilities
    self.tabManager = tabManager
    self.isP3AEnabled = p3aUtilities.isP3AEnabled
    cookieConsentBlocking = FilterListStorage.shared.isEnabled(
      for: FilterList.cookieConsentNoticesComponentID
    )
    
    blockMobileAnnoyances = FilterListStorage.shared.isEnabled(
      for: FilterList.mobileAnnoyancesComponentID
    )
    
    var clearableSettings = [
      ClearableSetting(id: .history, clearable: HistoryClearable(historyAPI: historyAPI), isEnabled: true),
      ClearableSetting(id: .cache, clearable: CacheClearable(), isEnabled: true),
      ClearableSetting(id: .cookiesAndCache, clearable: CookiesAndCacheClearable(), isEnabled: true),
      ClearableSetting(id: .passwords, clearable: PasswordsClearable(profile: profile), isEnabled: true),
      ClearableSetting(id: .downloads, clearable: DownloadsClearable(), isEnabled: true),
      ClearableSetting(id: .braveNews, clearable: BraveNewsClearable(feedDataSource: feedDataSource), isEnabled: true),
      ClearableSetting(id: .playlistCache, clearable: PlayListCacheClearable(), isEnabled: false),
      ClearableSetting(id: .playlistData, clearable: PlayListDataClearable(), isEnabled: false),
      ClearableSetting(id: .recentSearches, clearable: RecentSearchClearable(), isEnabled: true)
    ]
    
    let savedToggles = Preferences.Privacy.clearPrivateDataToggles.value
    
    // Ensure if we ever add an option to the list of clearables we don't crash
    if savedToggles.count == clearableSettings.count {
      for index in 0..<clearableSettings.count {
        clearableSettings[index].isEnabled = savedToggles[index]
      }
    }
    
    self.clearableSettings = clearableSettings
    
    FilterListStorage.shared.$filterLists
      .receive(on: DispatchQueue.main)
      .sink { filterLists in
        for filterList in filterLists {
          switch filterList.entry.componentId {
          case FilterList.cookieConsentNoticesComponentID:
            if filterList.isEnabled != self.cookieConsentBlocking {
              self.cookieConsentBlocking = filterList.isEnabled
            }
          case FilterList.mobileAnnoyancesComponentID:
            if filterList.isEnabled != self.blockMobileAnnoyances {
              self.blockMobileAnnoyances = filterList.isEnabled
            }
          default:
            continue
          }
        }
      }
      .store(in: &subscriptions)
  }
  
  @MainActor func clearPrivateData(_ clearables: [Clearable]) async {
    @Sendable func _clear(_ clearables: [Clearable], secondAttempt: Bool = false) async {
      await withThrowingTaskGroup(of: Void.self) { group in
        for clearable in clearables {
          group.addTask {
            try await clearable.clear()
          }
        }
        do {
          for try await _ in group { }
        } catch {
          if !secondAttempt {
            Logger.module.error("Private data NOT cleared successfully")
            try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 500)
            await _clear(clearables, secondAttempt: true)
          } else {
            Logger.module.error("Private data NOT cleared after 2 attempts")
          }
        }
      }
    }

    let clearAffectsTabs = clearables.contains { item in
      return item is CacheClearable || item is CookiesAndCacheClearable
    }

    let historyCleared = clearables.contains { $0 is HistoryClearable }

    if clearAffectsTabs {
      DispatchQueue.main.async {
        self.tabManager.allTabs.forEach({ $0.reload() })
      }
    }

    @Sendable func _toggleFolderAccessForBlockCookies(locked: Bool) {
      if Preferences.Privacy.blockAllCookies.value, FileManager.default.checkLockedStatus(folder: .cookie) != locked {
        FileManager.default.setFolderAccess([
          (.cookie, locked),
          (.webSiteData, locked),
        ])
      }
    }

    try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 1)
    
    // Reset Webkit configuration to remove data from memory
    if clearAffectsTabs {
      self.tabManager.resetConfiguration()
      // Unlock the folders to allow clearing of data.
      _toggleFolderAccessForBlockCookies(locked: false)
    }
    
    await _clear(clearables)
    if clearAffectsTabs {
      self.tabManager.allTabs.forEach({ $0.reload() })
    }
    
    if historyCleared {
      self.tabManager.clearTabHistory()
      
      // Clearing Tab History should clear Recently Closed
      RecentlyClosed.removeAll()
      
      // Donate Clear Browser History for suggestions
      let clearBrowserHistoryActivity = ActivityShortcutManager.shared.createShortcutActivity(type: .clearBrowsingHistory)
      // TODO: @JS How do I handle this?
      //self.userActivity = clearBrowserHistoryActivity
      clearBrowserHistoryActivity.becomeCurrent()
    }
    
    _toggleFolderAccessForBlockCookies(locked: true)
  }
}
