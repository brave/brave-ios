/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct SiteTableViewControllerUX {
    static let headerHeight = CGFloat(32)
    static let rowHeight = CGFloat(44)
    static let headerFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
    static let headerTextMargin = CGFloat(16)
}

class SiteTableViewHeader: UITableViewHeaderFooterView {
    let titleLabel = UILabel()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        titleLabel.textColor = .braveLabel

        contentView.addSubview(titleLabel)

        // A table view will initialize the header with CGSizeZero before applying the actual size. Hence, the label's constraints
        // must not impose a minimum width on the content view.
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(SiteTableViewControllerUX.headerTextMargin).priority(999)
            make.right.equalTo(contentView).offset(-SiteTableViewControllerUX.headerTextMargin).priority(999)
            make.left.greaterThanOrEqualTo(contentView) // Fallback for when the left space constraint breaks
            make.right.lessThanOrEqualTo(contentView) // Fallback for when the right space constraint breaks
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 * Provides base shared functionality for site rows and headers.
 */
@objcMembers
class SiteTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    fileprivate let CellIdentifier = "CellIdentifier"
    fileprivate let HeaderIdentifier = "HeaderIdentifier"
    var profile: Profile! {
        didSet {
            reloadData()
        }
    }

    var data = [Site]()
    var tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SiteTableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.register(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)
        tableView.layoutMargins = .zero
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .braveBackground
        tableView.separatorColor = .braveSeparator
        tableView.accessibilityIdentifier = "SiteTable"
        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    func reloadData() {
        self.tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
            cell.separatorInset = .zero
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderIdentifier)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteTableViewControllerUX.headerHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SiteTableViewControllerUX.rowHeight
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
}
