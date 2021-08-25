// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import Shared
import SwiftKeychainWrapper

private let log = Logger.browserLogger

class LoginInfoViewController: LoginAuthViewController {
    
    // MARK: UX
    
    struct UX {
        static let informationRowHeight: CGFloat = 58
        static let createdRowHeight: CGFloat = 66
        static let standardItemHeight: CGFloat = 44
    }
    
    // MARK: Section
    
    enum Section: Int, CaseIterable {
        case information
        case createdDate
        case delete
    }
    
    // MARK: ItemType
    
    enum InfoItem: Int, CaseIterable {
        case websiteItem
        case usernameItem
        case passwordItem
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
    
    private var formattedCreationDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(loginEntry.timeCreated / 1_000_000))
        let dateFormatter = DateFormatter().then {
            $0.locale = .current
            $0.dateFormat = "EEEE, MMM d, yyyy"
        }

        return dateFormatter.string(from: date)
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
            $0.register(CenteredButtonCell.self)
            $0.registerHeaderFooter(SettingsTableSectionHeaderFooterView.self)
            $0.tableFooterView = SettingsTableSectionHeaderFooterView(
                frame: CGRect(width: tableView.bounds.width, height: 1.0))
            $0.estimatedRowHeight = 44.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardHelper.defaultHelper.addDelegate(self)
    }
}

// MARK: TableViewDataSource - TableViewDelegate

extension LoginInfoViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooter() as SettingsTableSectionHeaderFooterView
        headerView.titleLabel.text = "LOGIN DETAILS"
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == Section.information.rawValue ? UX.standardItemHeight : 1.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            case Section.information.rawValue:
                switch indexPath.row {
                    case InfoItem.websiteItem.rawValue:
                        return UITableViewCell()
                    case InfoItem.usernameItem.rawValue:
                        return UITableViewCell()
                    case InfoItem.passwordItem.rawValue:
                        return UITableViewCell()
                    default:
                        fatalError("No cell available for index path: \(indexPath)")
                }
            case Section.createdDate.rawValue:
                let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
            
                cell.do {
                    $0.textLabel?.text = "Created \(formattedCreationDate)"
                    $0.tintColor = .secondaryBraveLabel
                    $0.selectionStyle = .none
                    $0.backgroundColor = .secondaryBraveBackground
                }
                return cell
            case Section.delete.rawValue:
                let cell = tableView.dequeueReusableCell(for: indexPath) as CenteredButtonCell
                cell.do {
                    $0.textLabel?.text = "Delete"
                    $0.tintColor = .braveOrange
                }
                return cell
            default:
                fatalError("No cell available for index path: \(indexPath)")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case Section.information.rawValue:
                return InfoItem.allCases.count
            default:
                return 1
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case Section.information.rawValue:
                return UX.informationRowHeight
            case Section.createdDate.rawValue:
                return UX.createdRowHeight
            case Section.delete.rawValue:
                return UX.standardItemHeight
            default:
                return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
            case Section.delete.rawValue:
                deleteLogin()
            default:
                if !isEditingFieldData {
                    showActionMenu(for: indexPath)
                }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: Actions

extension LoginInfoViewController {
    @objc private func edit() {
        
    }
    
    private func showActionMenu(for indexPath: IndexPath) {
        if indexPath.section == Section.createdDate.rawValue || indexPath.row == Section.delete.rawValue {
            return
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? LoginInfoTableViewCell else {
            return
        }
        cell.becomeFirstResponder()
        
        UIMenuController.shared.showMenu(from: tableView, rect: cell.frame)
    }
    
    private func deleteLogin() {

    }
}

// MARK: KeyboardHelperDelegate

extension LoginInfoViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: LoginInfoTableViewCellDelegate

extension LoginInfoViewController: LoginInfoTableViewCellDelegate {
    func shouldReturnAfterEditingTextField(_ cell: LoginInfoTableViewCell) -> Bool {
        return false
    }
    
    func canPerform(action: Selector, for cell: LoginInfoTableViewCell) -> Bool {
        return false
    }
    
    func didSelectOpenAndFill(_ cell: LoginInfoTableViewCell) {
        
    }
    
    func textFieldDidChange(_ cell: LoginInfoTableViewCell) {
        
    }
    
    func textFieldDidEndEditing(_ cell: LoginInfoTableViewCell) {
        
    }
}

