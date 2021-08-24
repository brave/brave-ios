// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Shared
import SwiftKeychainWrapper

class LoginDetailsViewController: LoginAuthViewController {
    
    // MARK: UX
    
    struct LoginDetailUX {
        static let InfoRowHeight: CGFloat = 58
        static let DeleteRowHeight: CGFloat = 44
        static let SeparatorHeight: CGFloat = 84
    }
    
    // MARK: ItemType
    
    enum InfoItem: Int {
        case websiteItem
        case usernameItem
        case passwordItem
        case lastModifiedSeparator
        case deleteItem

        var indexPath: IndexPath {
            return IndexPath(row: rawValue, section: 0)
        }
    }
    
    // MARK: Private
    
    private let profile: Profile
    private weak var websiteField: UITextField?
    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    
    private var loginEntry: Login {
        didSet {
            tableView.reloadData()
        }
    }
    private var isEditingFieldData: Bool = false {
        didSet {
            if isEditingFieldData != oldValue {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: Lifecycle

    init(profile: Profile, loginEntry: Login) {
        self.loginEntry = loginEntry
        self.profile = profile
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.do {
            $0.title = URL(string: loginEntry.hostname)?.baseDomain ?? ""
            $0.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        }

        tableView.do {
            $0.accessibilityIdentifier = "Login Details"
            $0.tableFooterView = UIView()
            $0.estimatedRowHeight = 44.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardHelper.defaultHelper.addDelegate(self)
    }
}

// MARK: TableViewDataSource - TableViewDelegate

extension LoginDetailsViewController {

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0
    }
}

// MARK: Actions

extension LoginDetailsViewController {
    @objc func edit() {
        
    }
}

// MARK: KeyboardHelperDelegate

extension LoginDetailsViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}
