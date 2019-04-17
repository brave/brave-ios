// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Storage
import Shared

class MenuViewController: UITableViewController {
    
    enum MenuButtons: Int {
        case bookmarks, history, settings, add, share
        
        var title: String {
            switch self {
            case .bookmarks: return "Bookmarks"
            case .history: return "History"
            case .settings: return "Settings"
            case .add: return "Add to..."
            case .share: return "Share with..."
            }
        }
        
        var icon: UIImage {
            switch self {
            case .bookmarks: return #imageLiteral(resourceName: "menu-add-bookmark")
            case .history: return #imageLiteral(resourceName: "menu-history")
            case .settings: return #imageLiteral(resourceName: "menu-settings")
            case .add: return #imageLiteral(resourceName: "menu-add-bookmark")
            case .share: return #imageLiteral(resourceName: "nav-share")
            }
        }
        
        // TODO: Remove when we can use Swift 4.2/`CaseIterable`
        static let allCases: [MenuButtons] = [.bookmarks, .history, .settings, .add, .share]
    }
    
    let bvc: BrowserViewController
    let tab: Tab?
    
    lazy var visibleButtons: [MenuButtons] = {
        let allButtons = MenuButtons.allCases
        
        var allWithoutAddButton = allButtons
        allWithoutAddButton.removeAll { $0 == .add || $0 == .share }
        
        guard let url = tab?.url, !url.isLocal else { return allWithoutAddButton }
        return allButtons
    }()
    
    init(bvc: BrowserViewController, tab: Tab?) {
        self.bvc = bvc
        self.tab = tab

        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let size = CGSize(width: 200, height: tableView.rect(forSection: 0).height)
        
        preferredContentSize = size
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        switch cell.tag {
        case MenuButtons.bookmarks.rawValue: openBookmarks()
        case MenuButtons.history.rawValue: openHistory()
        case MenuButtons.settings.rawValue: openSettings()
        case MenuButtons.add.rawValue: openAddBookmark()
        case MenuButtons.share.rawValue: openShareSheet()
            
        default:
            assertionFailure("No cell with \(cell.tag) tag.")
        }
    }
    
    func openBookmarks() {
        let vc = BookmarksViewController(folder: nil, isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        vc.toolbarUrlActionsDelegate = bvc
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openAddBookmark() {
        
        guard let title = tab?.displayTitle, let url = tab?.url?.absoluteString else { return }
        
        let mode = AddEditBookmarkTableViewController.Mode.newBookmark(title: title, url: url)
        
        let vc = AddEditBookmarkTableViewController(mode: mode)
        //vc.toolbarUrlActionsDelegate = bvc
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .cancel, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openHistory() {
        let vc = HistoryViewController(isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        vc.toolbarUrlActionsDelegate = bvc
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openSettings() {
        let vc = SettingsViewController(profile: bvc.profile, tabManager: bvc.tabManager)
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openShareSheet() { 
        dismiss(animated: true)
        bvc.tabToolbarDidPressShare()
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleButtons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let button = visibleButtons[indexPath.row]
        let cell = UITableViewCell()
        
        cell.textLabel?.text = button.title
        cell.imageView?.image = button.icon
        cell.tag = button.rawValue
        
        return cell
    }
}

extension MenuViewController: PopoverContentComponent {
    var isPanToDismissEnabled: Bool { return false }

}
