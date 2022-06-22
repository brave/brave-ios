// Copyright 2021 The Brave Authors. All rights reserved.
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
      $0.backgroundColor = UIColor.clear
      $0.setLines(distantTab.title, detailText: distantTab.url.absoluteString)

      $0.imageView?.contentMode = .scaleAspectFit
      $0.imageView?.image = FaviconFetcher.defaultFaviconImage
      $0.imageView?.layer.borderColor = BraveUX.faviconBorderColor.cgColor
      $0.imageView?.layer.borderWidth = BraveUX.faviconBorderWidth
      $0.imageView?.layer.cornerRadius = 6
      $0.imageView?.layer.cornerCurve = .continuous
      $0.imageView?.layer.masksToBounds = true

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
    SiteTableViewControllerUX.headerHeight
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    SiteTableViewControllerUX.rowHeight
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let sectionDetails = sessionList[safe: section] else {
      return nil
    }
    
    let headerView = tableView.dequeueReusableHeaderFooter() as TabSyncHeaderView
    
    headerView.do {
      $0.titleLabel.text = "\(sectionDetails.name ?? "") \(sectionDetails.modifiedTime?.description ?? "")"
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
        self.toolbarUrlActionsDelegate?.select(url: url, visitType: .typed)
      }
    }

    tableView.deselectRow(at: indexPath, animated: true)
  }
}
