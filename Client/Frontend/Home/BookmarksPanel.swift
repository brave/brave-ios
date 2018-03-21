/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

// MARK: - Placeholder strings for Bug 1232810.

let deleteWarningTitle = NSLocalizedString("This folder isn’t empty.", tableName: "BookmarkPanelDeleteConfirm", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteWarningDescription = NSLocalizedString("Are you sure you want to delete it and its contents?", tableName: "BookmarkPanelDeleteConfirm", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteCancelButtonLabel = NSLocalizedString("Cancel", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
let deleteDeleteButtonLabel = NSLocalizedString("Delete", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label for the button that deletes a folder and all of its children.")

// Placeholder strings for Bug 1248034
let emptyBookmarksText = NSLocalizedString("Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")

// MARK: - UX constants.

private struct BookmarksPanelUX {
    static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    static let BookmarkFolderChevronSize: CGFloat = 20
    static let BookmarkFolderChevronLineWidth: CGFloat = 2.0
    static let BookmarkFolderTextColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
    static let BookmarkFolderBGColor = UIColor.Defaults.GreyA.withAlphaComponent(0.3)
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemTextColor = UIColor.gray
    static let WelcomeScreenItemWidth = 170
    static let SeparatorRowHeight: CGFloat = 0.5
    static let IconSize: CGFloat = 23
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    var bookmarksFRC: NSFetchedResultsController<NSFetchRequestResult>?
    var parentFolders = [BookmarkMO]()
    var currentFolder: BookmarkMO? = nil
    var refreshControl: UIRefreshControl?

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(BookmarksPanel.longPress(_:)))
    }()
    fileprivate lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    fileprivate let BookmarkFolderCellIdentifier = "BookmarkFolderIdentifier"
    fileprivate let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorIdentifier"
    fileprivate let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"

    init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BookmarksPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)

        self.tableView.register(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.register(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
        self.tableView.register(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
    }
    
    convenience init(folder: BookmarkMO?) {
        self.init()
        
        self.currentFolder = folder
        //self.title = folder?.displayTitle ?? Strings.Bookmarks
        self.bookmarksFRC = BookmarkMO.frc(parentFolder: folder)
        self.bookmarksFRC?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: NotificationMainThreadContextSignificantlyChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addGestureRecognizer(longPressRecognizer)

        self.tableView.accessibilityIdentifier = "Bookmarks List"
        
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl!)
        
        reloadData()
    }
    
    override func reloadData() {
        
        do {
            try self.bookmarksFRC?.performFetch()
        } catch let error as NSError {
            print(error.description)
        }
        
        super.reloadData()
        
        self.refreshControl?.endRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl?.addTarget(self, action: #selector(BookmarksPanel.refreshBookmarks), for: .valueChanged)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshControl?.removeTarget(self, action: #selector(BookmarksPanel.refreshBookmarks), for: .valueChanged)
    }

    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            self.reloadData()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }
    
    @objc fileprivate func refreshBookmarks() {
        self.reloadData()
    }

    fileprivate func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white

        let logoImageView = UIImageView(image: UIImage(named: "emptyBookmarks"))
        overlayView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = emptyBookmarksText
        welcomeLabel.textAlignment = NSTextAlignment.center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = BookmarksPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp.bottom).offset(BookmarksPanelUX.WelcomeScreenPadding)
            make.width.equalTo(BookmarksPanelUX.WelcomeScreenItemWidth)
        }
        
        return overlayView
    }

    fileprivate func updateEmptyPanelState() {
        if bookmarksFRC?.fetchedObjects?.count == 0 && currentFolder != nil {
            if self.emptyStateOverlayView.superview == nil {
                self.view.addSubview(self.emptyStateOverlayView)
                self.view.bringSubview(toFront: self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp.makeConstraints { make -> Void in
                    make.edges.equalTo(self.tableView)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }
    
    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == UIGestureRecognizerState.began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarksFRC?.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        if let cell = cell as? BookmarkFolderTableViewCell {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Don't show a header for the root
        if bookmarksFRC?.fetchedObjects == nil || parentFolders.isEmpty {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BookmarkFolderHeaderViewIdentifier) as? BookmarkFolderTableViewHeader else { return nil }

        // register as delegate to ensure we get notified when the user interacts with this header
        if header.delegate == nil {
            header.delegate = self
        }

        if parentFolders.count == 1 {
            header.textLabel?.text = NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
        } else if let parentFolder = parentFolders.last {
            header.textLabel?.text = parentFolder.title
        }

        return header
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let it = self.source?.current[indexPath.row], it is BookmarkSeparator {
//            return BookmarksPanelUX.SeparatorRowHeight
//        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root. If there's no root (i.e. source == nil), we'll also show no header.
        if bookmarksFRC?.fetchedObjects == nil || parentFolders.isEmpty {
            return 0
        }

        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? BookmarkFolderTableViewHeader {
            // for some reason specifying the font in header view init is being ignored, so setting it here
            header.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

//    override func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
//        // Show a full-width border for cells above separators, so they don't have a weird step.
//        // Separators themselves already have a full-width border, but let's force the issue
//        // just in case.
//        let this = self.source?.current[indexPath.row]
//        if (indexPath.row + 1) < (self.source?.current.count)! {
//            let below = self.source?.current[indexPath.row + 1]
//            if this is BookmarkSeparator || below is BookmarkSeparator {
//                return true
//            }
//        }
//        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
//    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let bookmark = bookmarksFRC?.object(at: indexPath) as? BookmarkMO else { return }

        if !bookmark.isFolder {
            if tableView.isEditing {
                //show editing view for bookmark item
                
            }
            else {
                if let url = bookmark.url {
                    homePanelDelegate?.homePanel(self, didSelectURLString: url, visitType: VisitType.bookmark)
                    LeanPlumClient.shared.track(event: .openedBookmark)
                }
            }
        } else {
            if tableView.isEditing {
                //show editing view for bookmark item
                
            }
            else {
                let nextController = BookmarksPanel(folder: bookmark)
                nextController.homePanelDelegate = self.homePanelDelegate
                
                self.navigationController?.pushViewController(nextController, animated: true)
            }
        }
    }
    
    fileprivate func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let bookmark = bookmarksFRC?.object(at: indexPath) as? BookmarkMO else { return }
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.text = bookmark.displayTitle ?? bookmark.url
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        
        if !bookmark.isFolder {
            if let faviconMO = bookmark.domain?.favicon, let urlString = faviconMO.url, let url = URL(string: urlString), url.scheme == "asset" {
                cell.imageView?.image = UIImage(named: url.host!)
            } else {
                cell.imageView?.layer.borderColor = BookmarksPanelUX.IconBorderColor.cgColor
                cell.imageView?.layer.borderWidth = BookmarksPanelUX.IconBorderWidth
//                let bookmarkURL = URL(string: bookmark.url!)
//                cell.imageView?.setIcon(bookmark.domain?.favicon, forURL: bookmarkURL, completed: { (color, url) in
//                    if bookmarkURL == url {
//                        cell.imageView?.image = cell.imageView?.image?.createScaled(CGSize(width: BookmarksPanelUX.IconSize, height: BookmarksPanelUX.IconSize))
//                        cell.imageView?.backgroundColor = color
//                        cell.imageView?.contentMode = .center
//                    }
//                })
            }
        }
        else {
            cell.imageView?.image = UIImage(named: "context_open")
        }
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    private func editingStyleforRow(atIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return editingStyleforRow(atIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [AnyObject]? {
        guard let bookmark = bookmarksFRC?.object(at: indexPath) as? BookmarkMO else { return nil }
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { (action, indexPath) in
            
            func delete() {
                DataManager.shared.mainThreadContext.delete(bookmark as NSManagedObject)
            }
            
            if let children = bookmark.children, !children.isEmpty {
                let alert = UIAlertController(title: "Delete Folder?", message: "This will delete all folders and bookmarks inside. Are you sure you want to continue?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Yes, Delete", style: UIAlertActionStyle.destructive) { action in
                    delete()
                })
                
                self.present(alert, animated: true, completion: nil)
            } else {
                delete()
            }
        })
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit", handler: { (action, indexPath) in
//            self.showEditBookmarkController(tableView, indexPath: indexPath)
        })
        
        return [deleteAction, editAction]
    }

    func pinTopSite(_ site: Site) {
        _ = profile.history.addPinnedTopSite(site).value
    }
}

extension BookmarksPanel: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
//        guard let bookmark = bookmarksFRC?.object(at: indexPath) as? BookmarkMO, let url = bookmark.url else { return nil }
//        let site = Site(url: url, title: bookmark.displayTitle ?? url, bookmarked: true, guid: bookmark.guid)
//        site.icon = bookmark.favicon
//        return site
        return nil
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, homePanelDelegate: homePanelDelegate) else { return nil }

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            self.pinTopSite(site)
        })

        actions.append(pinTopSite)
        
        let removeAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
            guard let bookmark = self.bookmarksFRC?.object(at: indexPath) as? BookmarkMO else { return }
            DataManager.shared.mainThreadContext.delete(bookmark as NSManagedObject)
        })
        actions.append(removeAction)
        
        return actions
    }
}

private protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    fileprivate func didSelectHeader() {
        _ = self.navigationController?.popViewController(animated: true)
    }
}

class BookmarkFolderTableViewCell: TwoLineTableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = BookmarksPanelUX.BookmarkFolderBGColor
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.tintColor = BookmarksPanelUX.BookmarkFolderTextColor

        imageView?.image = UIImage(named: "bookmarkFolder")
        accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        separatorInset = UIEdgeInsets.zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class BookmarkFolderTableViewHeader: UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    lazy var bottomBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookmarkFolderTableViewHeader.viewWasTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(chevron.snp.right).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.right.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func viewWasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }
}

extension BookmarksPanel : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            configureCell(cell, atIndexPath: indexPath)
        case .insert:
            guard let path = newIndexPath else {
                return
            }
            tableView.insertRows(at: [path], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else {
                return
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .move:
            break
        }
    }
}
