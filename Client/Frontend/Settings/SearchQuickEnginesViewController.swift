// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared

private let log = Logger.browserLogger

// MARK: - SearchQuickEnginesViewController

class SearchQuickEnginesViewController: UITableViewController {
    
    // MARK: UX
    
    struct UX {
        static let iconSize = CGSize(
            width: OpenSearchEngine.preferredIconSize,
            height: OpenSearchEngine.preferredIconSize)
        
        static let headerHeight: CGFloat = 44
    }
    
    // MARK: Constants
    
    struct Constants {
        static let sectionHeaderIdentifier = "sectionHeaderIdentifier"
        static let quickSearchEngineRowIdentifier = "quickSearchEngineRowIdentifier"
    }
    
    private var searchEngines: SearchEngines
    private let profile: Profile
    
    // MARK: Lifecycle
    
    init(profile: Profile) {
        self.profile = profile
        self.searchEngines = profile.searchEngines
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.quickSearchEngines

        tableView.do {
            $0.isEditing = true
            $0.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Constants.sectionHeaderIdentifier)
            $0.register(UITableViewCell.self, forCellReuseIdentifier: Constants.quickSearchEngineRowIdentifier)
        }

        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: UX.headerHeight))
        tableView.tableFooterView = footer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    // MARK: TableViewDataSource - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchEngines.orderedEngines.count - 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView =
                tableView.dequeueReusableHeaderFooterView(withIdentifier: Constants.sectionHeaderIdentifier) as? SettingsTableSectionHeaderFooterView else {
            return UITableViewHeaderFooterView()
        }
                
        headerView.titleLabel.text = Strings.quickSearchEngines
        return headerView
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var engine: OpenSearchEngine?

        // The default engine is not a quick search engine.
        let index = indexPath.item + 1
        engine = searchEngines.orderedEngines[safe: index]
        
        let toggle = UISwitch().then {
            $0.tag = index
            $0.addTarget(self, action: #selector(didToggleEngine), for: .valueChanged)
            if let searchEngine = engine {
                $0.isOn = searchEngines.isEngineEnabled(searchEngine)
            }
        }
        
        let searchEngineCell = tableView.dequeueReusableCell(withIdentifier: Constants.quickSearchEngineRowIdentifier, for: indexPath).then {
            $0.showsReorderControl = true
            $0.editingAccessoryView = toggle
            $0.selectionStyle = .none
            $0.separatorInset = .zero
            $0.textLabel?.text = engine?.displayName
            $0.textLabel?.adjustsFontSizeToFitWidth = true
            $0.textLabel?.minimumScaleFactor = 0.5
            $0.imageView?.image = engine?.image.createScaled(UX.iconSize)
            $0.imageView?.layer.cornerRadius = 4
            $0.imageView?.layer.masksToBounds = true
        }

        return searchEngineCell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UX.headerHeight
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt indexPath: IndexPath, to newIndexPath: IndexPath) {
        // The first engine (default engine) is not shown in the list, so the indices are off-by-1.
        let index = indexPath.item + 1
        let newIndex = newIndexPath.item + 1
        let engine = searchEngines.orderedEngines.remove(at: index)
        
        searchEngines.orderedEngines.insert(engine, at: newIndex)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Actions

extension SearchQuickEnginesViewController {
    
    @objc func didToggleEngine(_ toggle: UISwitch) {
        let engine = searchEngines.orderedEngines[toggle.tag]
        
        if toggle.isOn {
            searchEngines.enableEngine(engine)
        } else {
            searchEngines.disableEngine(engine)
        }
    }
}
