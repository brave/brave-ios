// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import CoreData
import Data
import Shared

private let log = Logger.browserLogger

class AddEditBookmarkTableViewController: UITableViewController {
    
    private struct UX {
        static let cellHeight: CGFloat = 44
        /// Adds empty space between tableView's top and a custom header view.
        static let headerTopInset = UIEdgeInsets(top: 36, left: 0, bottom: 0, right: 0)
    }
    
    private enum DataSourcePresentationMode {
        /// Showing currently selected save location.
        case currentSelection
        /// Showing a list of folders of which user can save the Bookmark to.
        case folderHierarchy
        
        /// Flips between presentation modes.
        mutating func toggle() {
            switch self {
            case .currentSelection: self = .folderHierarchy
            case .folderHierarchy: self = .currentSelection
            }
        }
    }
    
    // MARK: - View setup
    
    private lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem().then {
            $0.target = self
            $0.action = #selector(save)
            $0.title = Strings.saveButtonTitle
        }
        
        return button
    }()
    
    private lazy var bookmarkDetailsView: BookmarkFormFieldsProtocol = {
        switch mode {
        case .addBookmark(let title, let url):
            return BookmarkDetailsView(title: title, url: url)
        case .addFolder(let title):
            return FolderDetailsViewTableViewCell(title: title, viewHeight: UX.cellHeight)
        case .editBookmark(let bookmark), .editFavorite(let bookmark):
            return BookmarkDetailsView(title: bookmark.displayTitle, url: bookmark.url)
        case .editFolder(let folder):
            return FolderDetailsViewTableViewCell(title: folder.displayTitle, viewHeight: UX.cellHeight)
        }
    }()
    
    // MARK: - Special cells
    
    /// A non-regular folder cell. Raw value represents a tag value of the cell
    enum SpecialCell: Int {
        case favorites = 10
        case rootLevel = 11
        case addFolder = 12
    }
    
    private let folderCellTag = 13
    
    /// Returns a count of how many non-folder cells should be visible(depends on Mode state)
    private var specialButtonsCount: Int {
        switch mode {
        case .addFolder(_), .editFolder(_): return 1
        case .addBookmark(_, _), .editBookmark(_), .editFavorite(_): return 3
        }
    }
    
    private var rootLevelFolderCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_bookmarks")).then {
            $0.folderName.text = Strings.bookmarkRootLevelCellTitle
            $0.tag = SpecialCell.rootLevel.rawValue
            if case .rootLevel = saveLocation, presentationMode == .folderHierarchy {
                $0.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    private var favoritesCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_favorites")).then {
            $0.folderName.text = Strings.favoritesRootLevelCellTitle
            $0.tag = SpecialCell.favorites.rawValue
            if case .favorites = saveLocation, presentationMode == .folderHierarchy {
                $0.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    private var addNewFolderCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_new_folder"))
        
        cell.folderName.text = Strings.addFolderActionCellTitle
        cell.accessoryType = .disclosureIndicator
        cell.tag = SpecialCell.addFolder.rawValue
        
        return cell
    }
    
    // MARK: - Init
    
    private let frc: NSFetchedResultsController<Bookmark>
    private let mode: BookmarkEditMode
    
    private var presentationMode: DataSourcePresentationMode
    
    /// Currently selected save location.
    private var saveLocation: BookmarkSaveLocation
    
    init(mode: BookmarkEditMode) {
        self.mode = mode
        
        saveLocation = mode.initialSaveLocation
        presentationMode = .currentSelection
        frc = Bookmark.foldersFrc(excludedFolder: mode.folder)
        
        super.init(style: .grouped)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        frc.delegate = self
        
        title = mode.title
        navigationItem.rightBarButtonItem = saveButton

        tableView.rowHeight = UX.cellHeight
        tableView.contentInset = UX.headerTopInset
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Data needs to be reloaded here because when going back from creating a folder.
        // The currently selected folder might have been deleted, and UI needs to be updated.
        reloadData()
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView.tableHeaderView != nil { return }
        let header = bookmarkDetailsView
        header.delegate = self
        
        // This is a trick to get a self-sizing header view.
        header.setNeedsUpdateConstraints()
        header.updateConstraintsIfNeeded()
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height)
        var newFrame = header.frame
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let newSize = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        newFrame.size.height = newSize.height
        header.frame = newFrame
        tableView.tableHeaderView = header
    }
    
    // MARK: - Getting data
    
    /// Bookmark with a level of indentation
    private typealias IndentedFolder = (folder: Bookmark, indentationLevel: Int)
    
    /// Main data source
    private var sortedFolders = [IndentedFolder]()
    
    /// Sorts folders by their older and nesting level.
    /// Indentation level starts with 0, but level 0 is designed for special folders
    /// (root level bookamrks, favorites).
    private func sortFolders(parentID: NSManagedObjectID? = nil,
                             indentationLevel: Int = 1) -> [IndentedFolder] {
        guard let objects = frc.fetchedObjects else { return [] }
        
        let sortedObjects = objects.sorted(by: { $0.order < $1.order })
        
        var result = [IndentedFolder]()
        
        sortedObjects.filter { $0.parentFolder?.objectID == parentID }.forEach {
            result.append(($0, indentationLevel: indentationLevel))
            // Append children recursively
            result.append(contentsOf: sortFolders(parentID: $0.objectID,
                                                  indentationLevel: indentationLevel + 1))
        }
     
        return result
    }
    
    private func reloadData() {
        try? frc.performFetch()
        sortedFolders = sortFolders()
        
        // If the folder we want to save to was deleted, UI needs an update
        // and a fallback location.
        if saveLocation.folderExists == false {
            saveLocation = .rootLevel
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Saving data
    
    @objc func save() {
        func earlyReturn() {
            assertionFailure()
            dismiss(animated: true)
        }
        
        guard let title = bookmarkDetailsView.titleTextField.text else { return earlyReturn() }
        
        // Fallback to root level if save location doesn't exist anymore.
        if saveLocation.folderExists == false {
            saveLocation = .rootLevel
        }
        
        // Saving and udpating is slightly different for each mode.
        switch mode {
        case .addBookmark(_, _):
            guard let urlString = bookmarkDetailsView.urlTextField?.text,
                  let url = URL(string: urlString) ?? urlString.bookmarkletURL else {
                return earlyReturn()
            }
            
            switch saveLocation {
            case .rootLevel:
                Bookmark.add(url: url, title: title)
            case .favorites:
                Bookmark.addFavorite(url: url, title: title)
            case .folder(let folder):
                Bookmark.add(url: url, title: title, parentFolder: folder)
            }
        case .addFolder(_):
            switch saveLocation {
            case .rootLevel:
                Bookmark.addFolder(title: title)
            case .favorites:
                fatalError("Folders can't be saved to favorites")
            case .folder(let folder):
                Bookmark.addFolder(title: title, parentFolder: folder)
            }
        case .editBookmark(let bookmark):
            guard let urlString = bookmarkDetailsView.urlTextField?.text,
                let url = URL(string: urlString) ?? urlString.bookmarkletURL else {
                    return earlyReturn()
            }
            
            if !bookmark.existsInPersistentStore() { break }
            
            switch saveLocation {
            case .rootLevel:
                bookmark.updateWithNewLocation(customTitle: title, url: url.absoluteString, location: nil)
            case .favorites:
                bookmark.delete()
                Bookmark.addFavorite(url: url, title: title)
            case .folder(let folder):
                bookmark.updateWithNewLocation(customTitle: title, url: urlString, location: folder)
            }
            
        case .editFolder(let folder):
            if !folder.existsInPersistentStore() { break }
            
            switch saveLocation {
            case .rootLevel:
                folder.updateWithNewLocation(customTitle: title, url: nil, location: nil)
            case .favorites:
                fatalError("Folders can't be saved to favorites")
            case .folder(let folderSaveLocation):
                folder.updateWithNewLocation(customTitle: title, url: nil, location: folderSaveLocation)
            }
            
        case .editFavorite(let favorite):
            guard let urlString = bookmarkDetailsView.urlTextField?.text,
                let url = URL(string: urlString) ?? urlString.bookmarkletURL else {
                    return earlyReturn()
            }
            
            if !favorite.existsInPersistentStore() { break }
            
            switch saveLocation {
            case .rootLevel:
                favorite.delete()
                Bookmark.add(url: url, title: title)
            case .favorites:
                favorite.update(customTitle: title, url: url.absoluteString)
            case .folder(let folder):
                favorite.delete()
                Bookmark.add(url: url, title: title, parentFolder: folder)
            }
        }
        
        // If there are two or more children, we don't want to dismiss the whole view controller.
        // Example: we want to add a new folder while adding a bookmark, after adding a new folder
        // navigation should pop back to previous screen with the bookmark we add.
        if let nc = navigationController, nc.children.count > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch presentationMode {
        case .currentSelection: return 1 // show only selected save location
        case .folderHierarchy: return sortedFolders.count + specialButtonsCount
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch saveLocation {
        case .favorites: return Strings.favoritesLocationFooterText
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Strings.editBookmarkTableLocationHeader
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if presentationMode == .folderHierarchy {
            guard let tag = tableView.cellForRow(at: indexPath)?.tag else {
                log.error("No cell was found for index path: \(indexPath)")
                return
            }
            
            switch tag {
            case SpecialCell.favorites.rawValue: saveLocation = .favorites
            case SpecialCell.rootLevel.rawValue: saveLocation = .rootLevel
            case SpecialCell.addFolder.rawValue: showNewFolderVC()
            case folderCellTag:
                let folder = sortedFolders[indexPath.row - specialButtonsCount].folder
                saveLocation = .folder(folder: folder)
            default: assertionFailure("not supported tag was selected: \(tag)")
                
            }
        }
        
        // Toggling presentation mode
        // when in current selection: show a dropdown of folder hierarchy
        // when in folder hierarchy: the folder you tap will be the current selection
        presentationMode.toggle()
        
        // This gives us an animation while switching between presentation modes.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    private func showNewFolderVC() {
        let vc = AddEditBookmarkTableViewController(mode: .addFolder(title: Strings.newFolderDefaultName))
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch presentationMode {
        case .currentSelection:
            switch saveLocation {
            case .rootLevel: return rootLevelFolderCell
            case .favorites: return favoritesCell
            case .folder(let folder):
                let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_folder"))
                cell.folderName.text = folder.displayTitle
                cell.tag = folderCellTag
                return cell
            }
        case .folderHierarchy:
            let row = indexPath.row
            
            if let specialCell = specialCell(forRow: row) {
                return specialCell
            }
            
            // Custom folder cells
            
            let cell = IndentedImageTableViewCell()
            cell.tag = folderCellTag
            
            let indentedFolder = sortedFolders[row - specialButtonsCount]
            
            cell.folderName.text = indentedFolder.folder.displayTitle
            cell.indentationLevel = indentedFolder.indentationLevel
            
            // Folders with children folders have a different icon
            let hasChildrenFolders = indentedFolder.folder.children?.contains(where: { $0.isFolder })
            cell.customImage.image = hasChildrenFolders == true ? #imageLiteral(resourceName: "menu_folder_open") : #imageLiteral(resourceName: "menu_folder")
            
            if let folder = saveLocation.getFolder, folder.objectID == indentedFolder.folder.objectID {
                cell.accessoryType = .checkmark
            }
            
            return cell
        }
    }
    
    private func specialCell(forRow row: Int) -> UITableViewCell? {
        let cells = mode.specialCells
        if row > cells.count - 1 { return nil }
        
        let cell = cells[row]
        
        switch cell {
        case .addFolder: return addNewFolderCell
        case .favorites: return favoritesCell
        case .rootLevel: return rootLevelFolderCell
        }
    }
}

// MARK: - BookmarkDetailsViewDelegate

extension AddEditBookmarkTableViewController: BookmarkDetailsViewDelegate {
    func correctValues(validationPassed: Bool) {
        // Don't allow user to save until title and/or url is correct
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = validationPassed
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension AddEditBookmarkTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        // Possible performance bottleneck.
        // There is not easy way to get folder sorted by their parent/children hierarchy
        // and folders can be updated while user is in edit mode(via Sync)
        // We have to listen for database changes and reload data afterwards.
        // Unfortunately due to `syncOrder` implementation, a lot of folder updates may come in
        // For example, moving a folder may result in having to update all other folders on a given
        // level with updated `newSyncOrder`, which means a lot of calls to `reloadData`.
        //
        // Watching for CoreData save notification could be an alternative to using a frc delegate.
        reloadData()
    }
}
