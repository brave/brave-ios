// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveUI
import Shared

class BraveTodayAddSourceResultsViewController: UITableViewController {
    
    let feedDataSource: FeedDataSource
    let searchedURL: URL
    let locations: [RSSFeedLocation]
    var sourcesAdded: ((Set<RSSFeedLocation>) -> Void)?
    
    private var selectedLocations: Set<RSSFeedLocation>
    
    init(dataSource: FeedDataSource,
         searchedURL: URL,
         rssFeedLocations: [RSSFeedLocation],
         sourcesAdded: ((Set<RSSFeedLocation>) -> Void)?
    ) {
        self.feedDataSource = dataSource
        self.searchedURL = searchedURL
        self.locations = rssFeedLocations
        self.selectedLocations = Set(rssFeedLocations)
        self.sourcesAdded = sourcesAdded
        
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    private lazy var doneButton = UIBarButtonItem(
        title: "Add",
        style: .done,
        target: self,
        action: #selector(tappedAdd)
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = searchedURL.baseDomain
        
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = doneButton
        
        tableView.register(FeedLocationCell.self)
    }
    
    @objc private func tappedAdd() {
        // Add selected sources to feed
        for location in selectedLocations {
            feedDataSource.addRSSFeedLocation(location)
        }
        sourcesAdded?(selectedLocations)
        dismiss(animated: true)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let location = locations[safe: indexPath.row],
           let cell = tableView.cellForRow(at: indexPath) as? FeedLocationCell {
            if selectedLocations.remove(location) == nil {
                selectedLocations.insert(location)
            }
            cell.accessoryType = selectedLocations.contains(location) ? .checkmark : .none
            doneButton.isEnabled = !selectedLocations.isEmpty
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let location = locations[safe: indexPath.row] else {
            assertionFailure()
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as FeedLocationCell
        cell.textLabel?.text = location.title
        cell.detailTextLabel?.text = location.url.absoluteString
        cell.accessoryType = selectedLocations.contains(location) ? .checkmark : .none
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locations.count
    }
}

private class FeedLocationCell: UITableViewCell, TableViewReusable {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}
