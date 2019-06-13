// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Storage
import Shared

class MenuViewController: UITableViewController {
    
    private struct UX {
        static let rowHeight: CGFloat = 45
        static let separatorColor = UIColor(white: 0.0, alpha: 0.1)
        static let topBottomInset: CGFloat = 5
    }
    
    private enum MenuButtons: Int, CaseIterable {
        case bookmarks, history, settings, add, share
        
        var title: String {
            switch self {
            case .bookmarks: return Strings.BookmarksMenuItem
            case .history: return Strings.HistoryMenuItem
            case .settings: return Strings.SettingsMenuItem
            case .add: return Strings.AddToMenuItem
            case .share: return Strings.ShareWithMenuItem
            }
        }
        
        var icon: UIImage {
            switch self {
            case .bookmarks: return #imageLiteral(resourceName: "menu_bookmarks")
            case .history: return #imageLiteral(resourceName: "menu-history")
            case .settings: return #imageLiteral(resourceName: "menu-settings")
            case .add: return #imageLiteral(resourceName: "menu-add-bookmark")
            case .share: return #imageLiteral(resourceName: "nav-share")
            }
        }
    }
    
    private let bvc: BrowserViewController
    private let tab: Tab?
    
    private lazy var visibleButtons: [MenuButtons] = {
        let allButtons = MenuButtons.allCases
        
        // Don't show url buttons if there is no url to pick(like on home screen)
        var allWithoutUrlButtons = allButtons
        allWithoutUrlButtons.removeAll { $0 == .add || $0 == .share }
        
        guard let url = tab?.url, !url.isLocal else { return allWithoutUrlButtons }
        return allButtons
    }()
    
    // MARK: - Init
    
    init(bvc: BrowserViewController, tab: Tab?) {
        self.bvc = bvc
        self.tab = tab

        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UX.separatorColor
        tableView.rowHeight = UX.rowHeight
        
        tableView.contentInset = UIEdgeInsets(top: UX.topBottomInset, left: 0,
                                              bottom: UX.topBottomInset, right: 0)
        
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
        
        // Hide separator line of the last cell.
        tableView.tableFooterView =
            UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        // TODO: Make the background view transparent with alpha 0.6
        // simple setting its alpha doesn't seem to work.
        tableView.backgroundColor = #colorLiteral(red: 0.9529411765, green: 0.9529411765, blue: 0.9647058824, alpha: 1)
        
        let size = CGSize(width: 200, height: UIScreen.main.bounds.height)
        
        let fit = view.systemLayoutSizeFitting(
            size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultHigh
        )
        
        preferredContentSize = CGSize(width: fit.width, height: fit.height + UX.topBottomInset * 2)
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        guard let button = MenuButtons(rawValue: cell.tag) else {
            assertionFailure("No cell with \(cell.tag) tag.")
            return
        }
        
        switch button {
        case .bookmarks: openBookmarks()
        case .history: openHistory()
        case .settings: openSettings()
        case .add: openAddBookmark()
        case .share: openShareSheet()
        }
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
        cell.backgroundColor = .clear
        
        return cell
    }
    
    // MARK: - Actions
    
    private enum DoneButtonPosition { case left, right }
    private typealias DoneButton = (style: UIBarButtonItem.SystemItem, position: DoneButtonPosition)
    
    private func open(_ viewController: UIViewController, doneButton: DoneButton) {
        let nav = SettingsNavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .formSheet
        
        let button = UIBarButtonItem(barButtonSystemItem: doneButton.style, target: nav, action: #selector(SettingsNavigationController.done))
        
        switch doneButton.position {
        case .left: nav.navigationBar.topItem?.leftBarButtonItem = button
        case .right: nav.navigationBar.topItem?.rightBarButtonItem = button
        }
        
        dismissView()
        bvc.present(nav, animated: true)
    }
    
    private func openBookmarks() {
        let vc = BookmarksViewController(folder: nil, isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        vc.toolbarUrlActionsDelegate = bvc
        
        open(vc, doneButton: DoneButton(style: .done, position: .right))
    }
    
    private func openAddBookmark() {
        guard let title = tab?.displayTitle, let url = tab?.url?.absoluteString else { return }
        
        let mode = BookmarkEditMode.addBookmark(title: title, url: url)
        let vc = AddEditBookmarkTableViewController(mode: mode)
        
        open(vc, doneButton: DoneButton(style: .cancel, position: .left))

    }
    
    private func openHistory() {
        let vc = HistoryViewController(isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing)
        vc.toolbarUrlActionsDelegate = bvc
        
        open(vc, doneButton: DoneButton(style: .done, position: .right))
    }
    
    private func openSettings() {
        let vc = SettingsViewController(profile: bvc.profile, tabManager: bvc.tabManager)
        open(vc, doneButton: DoneButton(style: .done, position: .right))
    }
    
    private func openShareSheet() {
        dismissView()
        bvc.tabToolbarDidPressShare()
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }
}

// MARK: - PopoverContentComponent

extension MenuViewController: PopoverContentComponent {
    var extendEdgeIntoArrow: Bool { return false }
}
