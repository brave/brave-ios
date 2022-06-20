// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import BraveUI

extension TabTrayController {

  class TabSyncContainerView: UIView {
    
    // MARK: UX

    struct UX {
      static let sectionTopPadding: CGFloat = 5
      static let siteTableCellIdentifier = "SiteTableCellIdentifier"
      static let siteTableHeaderIdentifier = "SiteTableHeaderIdentifier"
    }

    var tableView = UITableView()

    override init(frame: CGRect) {
      super.init(frame: frame)

      backgroundColor = .braveBackground
      
      addSubview(tableView)
      tableView.snp.makeConstraints { make in
        make.edges.equalTo(self)
      }

      tableView.do {
        $0.register(
          SiteTableViewCell.self,
          forCellReuseIdentifier: UX.siteTableCellIdentifier)
        $0.register(
          SiteTableViewHeader.self,
          forHeaderFooterViewReuseIdentifier: UX.siteTableHeaderIdentifier)
        $0.layoutMargins = .zero
        $0.backgroundColor = .secondaryBraveBackground
        $0.separatorColor = .braveSeparator
        $0.accessibilityIdentifier = "SyncedTabsTable"
        $0.cellLayoutMarginsFollowReadableWidth = false
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
          $0.sectionHeaderTopPadding = UX.sectionTopPadding
        }
        #endif
      }

      // Set an empty footer to prevent empty cells from appearing in the list.
      tableView.tableFooterView = UIView()
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
  }
}
