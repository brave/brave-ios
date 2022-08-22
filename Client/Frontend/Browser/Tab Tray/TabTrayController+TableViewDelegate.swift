// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import BraveShared
import Data
import UIKit

extension TabTrayController: UITableViewDataSource, UITableViewDelegate, TabSyncHeaderViewDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    sessionList.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.hiddenSections.contains(section) {
      return 0
    }
    
    return sessionList[safe: section]?.tabs.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath) as TwoLineTableViewCell

    if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
      cell.separatorInset = .zero
    }
    
    configureCell(cell, atIndexPath: indexPath)

    return cell
  }
  
  func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
    guard let cell = cell as? TwoLineTableViewCell else { return }

    guard let distantTab = sessionList[safe: indexPath.section]?.tabs[safe: indexPath.row] else {
      return
    }

    cell.do {
      $0.backgroundColor = .clear
      $0.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
      $0.setLines(distantTab.title, detailText: distantTab.url.absoluteString)

      $0.imageView?.contentMode = .scaleAspectFit
      $0.imageView?.image = FaviconFetcher.defaultFaviconImage
      $0.imageView?.layer.borderColor = BraveUX.faviconBorderColor.cgColor
      $0.imageView?.layer.borderWidth = BraveUX.faviconBorderWidth
      $0.imageView?.layer.cornerRadius = 6
      $0.imageView?.layer.cornerCurve = .continuous
      $0.imageView?.layer.masksToBounds = true

      // TODO: Remove Domain creation and load FavIcon method swap the method with brave-core fetch #5312
      let domain = Domain.getOrCreate(
        forUrl: distantTab.url,
        persistent: !PrivateBrowsingManager.shared.isPrivateBrowsing)

      if let url = domain.url?.asURL {
        cell.imageView?.loadFavicon(
          for: url,
          domain: domain,
          fallbackMonogramCharacter: distantTab.title?.first,
          shouldClearMonogramFavIcon: false,
          cachedOnly: true)
      } else {
        cell.imageView?.clearMonogramFavicon()
        cell.imageView?.image = FaviconFetcher.defaultFaviconImage
      }
    }
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let sectionDetails = sessionList[safe: section] else {
      return nil
    }
    
    var deviceTypeImage: UIImage?
    
    switch sectionDetails.deviceType {
    case .phone, .tablet:
      deviceTypeImage = UIImage(systemName: "ipad.and.iphone")
    case .win, .linux, .mac:
      deviceTypeImage = UIImage(systemName: "laptopcomputer")
    default:
      deviceTypeImage = UIImage(systemName: "laptopcomputer.and.iphone")
    }
        
    let headerView = tableView.dequeueReusableHeaderFooter() as TabSyncHeaderView

    headerView.do {
      $0.imageIconView.image = deviceTypeImage?.template
      $0.titleLabel.text = sectionDetails.name
      if let modifiedTime = sectionDetails.modifiedTime {
        $0.descriptionLabel.text = modifiedTime.formattedSyncSessionPeriodDate
      }
      $0.section = section
      $0.delegate = self
    }
         
    return headerView
  }
  
  func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
    false
  }

  func toggleSection(_ header: TabSyncHeaderView, section: Int) {
    func indexPathsForSection() -> [IndexPath] {
      var indexPaths = [IndexPath]()

      if let itemCount = sessionList[safe: section]?.tabs.count {
        for row in 0..<itemCount {
          indexPaths.append(IndexPath(row: row, section: section))
        }
      }

      return indexPaths
    }

    if hiddenSections.contains(section) {
      hiddenSections.remove(section)
      tabSyncView.tableView.insertRows(at: indexPathsForSection(), with: .fade)
    } else {
      hiddenSections.insert(section)
      tabSyncView.tableView.deleteRows(at: indexPathsForSection(), with: .fade)
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let distantTab = sessionList[safe: indexPath.section]?.tabs[safe: indexPath.row] else {
      return
    }
    
    tabTraySearchController.isActive = false

    if let url = URL(string: distantTab.url.absoluteString) {
      dismiss(animated: true) {
        self.toolbarUrlActionsDelegate?.openInNewTab(url, isPrivate: false)
      }
    }

    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}

extension Date {
  enum TimePeriodOffset {
    case today, yesterday, lastWeek, lastMonth

    var period: Int {
      switch self {
        case .today: return 0
        case .yesterday: return -1
        case .lastWeek: return -7
        case .lastMonth: return -31
      }
    }
  }
  
  var formattedSyncSessionPeriodDate: String {
    let hourFormatter = DateFormatter().then {
      $0.locale = .current
      $0.dateFormat = "HH:mm a"
    }
    
    let hourDayFormatter = DateFormatter().then {
      $0.locale = .current
      $0.dateFormat = "EEEE HH:mm a"
    }
    
    let fullDateFormatter = DateFormatter().then {
      $0.locale = .current
      $0.dateFormat = "HH:mm a MM-dd-yyyy"
    }
        
    if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.today.period)) ==
        ComparisonResult.orderedDescending {
      return String(format: Strings.OpenTabs.openTabsItemLastSyncedTodayTitle, hourFormatter.string(from: self))
    } else if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.yesterday.period)) ==
                ComparisonResult.orderedDescending {
      return String(format: Strings.OpenTabs.openTabsItemLastSyncedYesterdayTitle, hourFormatter.string(from: self))
    } else if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.lastWeek.period)) ==
                ComparisonResult.orderedDescending {
      return String(format: Strings.OpenTabs.openTabsItemLastSyncedLastWeekTitle, hourDayFormatter.string(from: self))
    }
    
    return String(format: Strings.OpenTabs.openTabsItemLastSyncedFullTitle, fullDateFormatter.string(from: self))
  }
  
  var formattedActivePeriodDate: String {
    if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.today.period)) ==
        ComparisonResult.orderedDescending {
      return Strings.OpenTabs.activePeriodDeviceTodayTitle
    } else if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.yesterday.period)) ==
                ComparisonResult.orderedDescending {
      return Strings.OpenTabs.activePeriodDeviceYesterdayTitle
    } else if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.lastWeek.period)) ==
                ComparisonResult.orderedDescending {
      return Strings.OpenTabs.activePeriodDeviceThisWeekTitle
    } else if compare(getCurrentDateWith(dayOffset: TimePeriodOffset.lastMonth.period)) ==
                ComparisonResult.orderedDescending {
      return Strings.OpenTabs.activePeriodDeviceThisMonthTitle
    }
      
    let dateComponents = Calendar(identifier: .gregorian).dateComponents([.day], from: self, to: Date())
      
    return String(format: Strings.OpenTabs.activePeriodDeviceDaysAgoTitle, (dateComponents.day ?? 0))
  }
  
  private func getCurrentDateWith(dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let nowComponents = calendar.dateComponents(
      [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day], from: Date())

    guard let today = calendar.date(from: nowComponents) else {
      return Date()
    }

    return (calendar as NSCalendar).date(
      byAdding: NSCalendar.Unit.day, value: dayOffset, to: today, options: []) ?? Date()
  }

}
