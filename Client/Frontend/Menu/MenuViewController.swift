// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

class MenuViewController: UITableViewController {
    
    enum MenuButtons: Int {
        case bookmarks, history, settings, share
        
        var title: String {
            switch self {
            case .bookmarks: return "Bookmarks"
            case .history: return "History"
            case .settings: return "Settings"
            case .share: return "Share with..."
            }
        }
        
        var icon: UIImage {
            switch self {
            case .bookmarks: return #imageLiteral(resourceName: "menu-add-bookmark")
            case .history: return #imageLiteral(resourceName: "menu-history")
            case .settings: return #imageLiteral(resourceName: "menu-settings")
            case .share: return #imageLiteral(resourceName: "nav-share")
            }
        }
        
        // TODO: Remove when we can use Swift 4.2/`CaseIterable`
        static let allCases: [MenuButtons] = [.bookmarks, .history, .settings, .share]
    }
    
    let bvc: BrowserViewController
    
    init(bvc: BrowserViewController) {
        self.bvc = bvc

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
        case MenuButtons.share.rawValue: openShareSheet()
            
        default:
            assertionFailure("No cell with \(cell.tag) tag.")
        }
    }
    
    func openBookmarks() {
        let vc = BookmarksViewController(folder: nil, isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openHistory() {
        let vc = HistoryViewController(isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .done, target: nc, action: #selector(SettingsNavigationController.done))
        
        dismiss(animated: true)
        bvc.present(nc, animated: true)
    }
    
    func openSettings() {
        let vc = SettingsViewController(profile: bvc.profile, tabManager: bvc.tabManager)
        
        let nc = SettingsNavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .formSheet
        
        nc.navigationBar.topItem?.leftBarButtonItem =
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
        return MenuButtons.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let button = MenuButtons.allCases[indexPath.row]
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
