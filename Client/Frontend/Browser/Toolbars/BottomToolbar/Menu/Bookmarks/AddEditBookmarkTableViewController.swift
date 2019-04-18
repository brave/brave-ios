// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import CoreData
import Data
import Shared

protocol AddEditBookmarkDelegate: class {
    func didSelectFolder(/*_ folder: Bookmark*/)
}

class AddEditBookmarkTableViewController: UITableViewController {
    
    struct UX {
        static let cellHeight: CGFloat = 44
    }
    
    enum Mode {
        case newBookmark(title: String, url: String)
        case newFolder(title: String)
        case editBookmark(_ bookmark: Bookmark)
        case editFolder(_ folder: Bookmark)
        
        var initialLocation: Location {
            switch self {
            case .newBookmark(_, _), .newFolder(_):
                return .rootLevel
            case .editBookmark(let bookmark):
                return folderOrRoot(bookmarkOrFolder: bookmark)
            case .editFolder(let folder):
                return folderOrRoot(bookmarkOrFolder: folder)
            }
        }
        
        var folder: Bookmark? {
            switch self {
            case .editFolder(let folder): return folder
            default: return nil
            }
        }
        
        private func folderOrRoot(bookmarkOrFolder: Bookmark) -> Location {
            guard let parent = bookmarkOrFolder.parentFolder else { return .rootLevel }
            return .folder(folder: parent)
        }
    }
    
    enum Location {
        case favorites
        case rootLevel
        case folder(folder: Bookmark)
        
        static let favoritesTag = 10
        static let rootLevelTag = 11
        static let folderTag = 12
        static let newFolderTag = 13
        
        var getFolder: Bookmark? {
            switch self {
            case .folder(let folder): return folder
            default: return nil
            }
        }
        
        /// Making sure the folder we are saving to still exists.
        /// This could happen if the folder got deleted by another device in sync chain.
        var exists: Bool {
            // Root level and favorites locations are permanent, only custom folder needs to be checked.
            switch self {
            case .folder(let folder):
                return folder.existsInPersistentStore()
            default:
                return false
            }
        }
    }
    
    private enum DataSourcePresentationMode {
        /// Showing currently selected save location.
        case currentSelection
        /// Showing a list of folders of which user can save the Bookmark to.
        case folderHierarchy
        
        mutating func toggle() {
            switch self {
            case .currentSelection: self = .folderHierarchy
            case .folderHierarchy: self = .currentSelection
            }
        }
    }
    
    let frc: NSFetchedResultsController<Bookmark>
    let mode: AddEditBookmarkTableViewController.Mode
    
    lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.action = #selector(save)
        button.title = Strings.SaveButtonTitle
        
        return button
    }()
    
    var location: Location
    
    lazy var bookmarkDetailsView: BookmarkFormFieldsProtocol = {
        switch mode {
        case .newBookmark(let title, let url):
            return BookmarkDetailsView(title: title, url: url)
        case .newFolder(let title):
            return FolderDetailsViewTableViewCell(title: title, viewHeight: UX.cellHeight)
        case .editBookmark(let bookmark):
            return BookmarkDetailsView(title: bookmark.displayTitle, url: bookmark.url)
        case .editFolder(let folder):
            return FolderDetailsViewTableViewCell(title: folder.displayTitle, viewHeight: UX.cellHeight)
        }
    }()
    
    private var presentationMode: DataSourcePresentationMode
    
    weak var delegate: AddEditBookmarkDelegate?
    
    init(mode: AddEditBookmarkTableViewController.Mode) {
        self.mode = mode
        
        location = mode.initialLocation
        presentationMode = .currentSelection
        frc = Bookmark.foldersFrc(excludedFolder: mode.folder)
        
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var sortedFolders = [IndentedFolder]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = saveButton

        tableView.rowHeight = UX.cellHeight
        tableView.contentInset = UIEdgeInsets(top: 36, left: 0, bottom: 0, right: 0)
        
        frc.delegate = self
        
        switch mode {
        case .newBookmark(_, _): title = Strings.NewBookmarkTitle
        case .newFolder(_): title = Strings.NewFolderTitle
        case .editBookmark(_): title = Strings.EditBookmarkTitle
        case .editFolder(_): title = Strings.EditFolderTitle
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        try? frc.performFetch()
        sortedFolders = sortFolders()
        
        // If the bookmark we save to was deleted, UI needs an update
        // and a fallback location.
        if !location.exists {
            location = .rootLevel
        }
        
        tableView.reloadData()
    }
    
    typealias IndentedFolder = (Bookmark, indentationLevel: Int)
    
    /// Indentation level starts with 0, but this level is designed for arbitrary folders
    /// (root level bookamrks, favorites)
    func sortFolders(parentID: NSManagedObjectID? = nil, indentationLevel: Int = 1) -> [IndentedFolder] {
        guard let objects = frc.fetchedObjects else { return [] }
        
        let sortedObjects = objects.sorted(by: { $0.order < $1.order })
        
        var result = [IndentedFolder]()
        
        sortedObjects.filter { $0.parentFolder?.objectID == parentID }.forEach {
            result.append(($0, indentationLevel: indentationLevel))
            result.append(contentsOf: sortFolders(parentID: $0.objectID,
                                                  indentationLevel: indentationLevel + 1))
        }
     
        return result
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView.tableHeaderView != nil { return }
        let header = bookmarkDetailsView
        header.delegate = self
        
        header.setNeedsUpdateConstraints()
        header.updateConstraintsIfNeeded()
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height)
        var newFrame = header.frame
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let newSize = header.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        newFrame.size.height = newSize.height
        header.frame = newFrame
        tableView.tableHeaderView = header
    }
    
    @objc func save() {
        func earlyReturn() {
            assertionFailure()
            dismiss(animated: true)
        }
        
        guard let title = bookmarkDetailsView.titleTextField.text else { return earlyReturn() }
        
        if !location.exists {
            location = .rootLevel
        }
        
        switch mode {
        case .newBookmark(_, _):
            guard let urlString = bookmarkDetailsView.urlTextField?.text,
                let url = URL(string: urlString) else {
                    return earlyReturn()
            }
            
            switch location {
            case .rootLevel:
                Bookmark.add(url: url, title: title)
            case .favorites:
                Bookmark.addFavorite(url: url, title: title)
            case .folder(let folder):
                Bookmark.add(url: url, title: title, parentFolder: folder)
            }
        case .newFolder(_):
            switch location {
            case .rootLevel:
                Bookmark.addFolder(title: title)
            case .favorites:
                fatalError("Folders can't be saved to favorites")
            case .folder(let folder):
                Bookmark.addFolder(title: title, parentFolder: folder)
            }
            
            delegate?.didSelectFolder()
        case .editBookmark(let bookmark):
            guard let urlString = bookmarkDetailsView.urlTextField?.text,
                let url = URL(string: urlString) else {
                    return earlyReturn()
            }
            
            if !bookmark.existsInPersistentStore() { break }
            
            switch location {
            case .rootLevel:
                bookmark.updateWithNewLocation(customTitle: title, url: urlString, location: nil)
            case .favorites:
                bookmark.delete()
                Bookmark.addFavorite(url: url, title: title)
            case .folder(let folder):
                bookmark.updateWithNewLocation(customTitle: title, url: urlString, location: folder)
            }
            
        case .editFolder(let folder):
            if !folder.existsInPersistentStore() { break }
            
            switch location {
            case .rootLevel:
                folder.updateWithNewLocation(customTitle: title, url: nil, location: nil)
            case .favorites:
                fatalError("Folders can't be saved to favorites")
            case .folder(let folderSaveLocation):
                folder.updateWithNewLocation(customTitle: title, url: nil, location: folderSaveLocation)
            }
        }
        
        if let nc = navigationController, nc.childViewControllers.count > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    var totalCount: Int { return sortedFolders.count + 3 }
    
    var specialButtonsCount: Int {
        switch mode {
        case .newFolder(_), .editFolder(_): return 1
        case .newBookmark(_, _), .editBookmark(_): return 3
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch presentationMode {
        case .currentSelection: return 1
        case .folderHierarchy: return sortedFolders.count + specialButtonsCount
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch location {
        case .favorites: return Strings.FavoritesLocationFooterText
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Strings.EditBookmarkTableLocationHeader
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if presentationMode == .folderHierarchy {
            guard let tag = tableView.cellForRow(at: indexPath)?.tag else { return }
            
            switch tag {
            case Location.favoritesTag: location = .favorites
            case Location.rootLevelTag: location = .rootLevel
            case Location.newFolderTag: showNewFolderVC()
            case Location.folderTag:
                let folder = sortedFolders[indexPath.row - specialButtonsCount].0
                location = .folder(folder: folder)
            default: assertionFailure("not supported tag was selected: \(tag)")
                
            }
        }
        
        presentationMode.toggle()
        
        // This gives us an animation while switching between presentation modes.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func showNewFolderVC() {
        let vc = AddEditBookmarkTableViewController(mode: .newFolder(title: Strings.NewFolderDefaultName))
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    var rootLevelFolderCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_bookmarks")).then {
            $0.folderName.text = Strings.BookmarkRootLevelCellTitle
            $0.tag = Location.rootLevelTag
            if case .rootLevel = location, presentationMode == .folderHierarchy {
                $0.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    var favoritesCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_favorites"))
        cell.folderName.text = Strings.FavoritesRootLevelCellTitle
        cell.tag = Location.favoritesTag
        if case .favorites = location, presentationMode == .folderHierarchy {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch presentationMode {
        case .currentSelection:
            switch location {
            case .rootLevel: return rootLevelFolderCell
            case .favorites: return favoritesCell
            case .folder(let folder):
                let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_folder"))
                cell.folderName.text = folder.displayTitle
                cell.tag = Location.folderTag
                return cell
            }
        case .folderHierarchy:
            let row = indexPath.row
            
            switch mode {
            case .newFolder(_), .editFolder(_):
                if row == 0 {
                    return rootLevelFolderCell
                }
            case .newBookmark(_), .editBookmark(_):
                if row == 0 {
                    let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "menu_new_folder"))
                    cell.folderName.text = Strings.AddFolderActionCellTitle
                    cell.accessoryType = .disclosureIndicator
                    cell.tag = Location.newFolderTag
                    
                    return cell
                }
                
                if row == 1 {
                    return favoritesCell
                }
                
                if row == 2 {
                    return rootLevelFolderCell
                }
            }
            
            let cell = IndentedImageTableViewCell()
            
            let indentedFolder = sortedFolders[row - specialButtonsCount]
            
            cell.folderName.text = indentedFolder.0.displayTitle
            cell.indentationLevel = indentedFolder.indentationLevel
            cell.tag = Location.folderTag
            
            let hasChildrenFolders = indentedFolder.0.children?.contains(where: { $0.isFolder })
            cell.customImage.image = hasChildrenFolders == true ? #imageLiteral(resourceName: "menu_folder_open") : #imageLiteral(resourceName: "menu_folder")
            
            if let folder = location.getFolder, folder.objectID == indentedFolder.0.objectID {
                cell.accessoryType = .checkmark
            }
            
            return cell
        }
    }
}

extension AddEditBookmarkTableViewController: BookmarkDetailsViewDelegate {
    func correctValues(validationPassed: Bool) {
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = validationPassed
    }
}

extension AddEditBookmarkTableViewController: AddEditBookmarkDelegate {
    func didSelectFolder(/*_ folder: Bookmark*/) {
        // FIXME: Does not work, saving folder is async
        //try? frc.performFetch()
        //sortedFolders = sortFolders()
        
        //tableView.reloadData()
    }
}

// TODO: add frc to see when folders from sync come, do a manual reconfiguration
extension AddEditBookmarkTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        // Possible performance bottleneck
        reloadData()
    }
}
