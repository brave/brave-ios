// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import CoreData
import Data

class AddEditBookmarkTableViewController: UITableViewController {
    
    enum Mode {
        case addBookmark(title: String, url: URL)
        case addFolder(title: String)
        case editBookmark(bookmark: Bookmark)
        case editFolder(folder: Bookmark)
    }
    
    enum Action { case add, edit }
    
    enum BookmarkType {
        case bookmark(title: String, url: URL)
        case folder(title: String)
    }
    
    enum Location {
        case favorites
        case rootLevel
        case folder(folder: Bookmark)
        
        static let favoritesTag = 10
        static let rootLevelTag = 11
        static let folderTag = 12
        
        var getFolder: Bookmark? {
            switch self {
            case .folder(let folder): return folder
            default: return nil
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
    
    let action: AddEditBookmarkTableViewController.Action
    let type: AddEditBookmarkTableViewController.BookmarkType
    
    lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem()
        button.target = self
        button.action = #selector(save)
        button.title = "Save"
        
        return button
    }()
    
    var location: Location
    
    lazy var bookmarkDetailsView: BookmarkDetailsView = {
        let view = BookmarkDetailsView(type: type)
        return view
    }()
    
    private var presentationMode: DataSourcePresentationMode
    
    init(action: AddEditBookmarkTableViewController.Action,
         type: AddEditBookmarkTableViewController.BookmarkType) {
        self.action = action
        self.type = type
        
        frc = Bookmark.foldersFrc()
        location = .rootLevel
        presentationMode = .currentSelection
        
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var sortedFolders = [IndentedFolder]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = saveButton

        tableView.rowHeight = 44
        tableView.contentInset = UIEdgeInsets(top: 36, left: 0, bottom: 0, right: 0)
        
        frc.delegate = self
        try? frc.performFetch()
        sortedFolders = sortFolders()
        
        tableView.reloadData()
    }
    
    typealias IndentedFolder = (Bookmark, indentationLevel: Int)
    
    /// Indentation level starts with 0, but this level is designed for arbitrary folders
    /// (root level bookamrks, favorites)
    func sortFolders(parentID: NSManagedObjectID? = nil, indentationLevel: Int = 1) -> [IndentedFolder] {
        guard let objects = frc.fetchedObjects else { return [] }
        
        var result = [IndentedFolder]()
        
        objects.filter { $0.parentFolder?.objectID == parentID }.forEach {
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
        header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        var newFrame = header.frame
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let newSize = header.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        newFrame.size.height = newSize.height
        header.frame = newFrame
        tableView.tableHeaderView = header
    }
    
    @objc func save() {
        guard let title = bookmarkDetailsView.titleTextField.text, let urlString = bookmarkDetailsView.urlTextField.text, let url = URL(string: urlString) else {
            assertionFailure()
            dismiss(animated: true)
            return
        }
        
        switch location {
        case .rootLevel:
            Bookmark.add(url: url, title: title)
        case .favorites:
            Bookmark.addFavorite(url: url, title: title)
        case .folder(let folder):
            Bookmark.add(url: url, title: title, parentFolder: folder)
        }
        
        dismiss(animated: true)
    }
    
    var totalCount: Int { return sortedFolders.count + 3 }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch presentationMode {
        case .currentSelection: return 1
        case .folderHierarchy: return sortedFolders.count + 3
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Location"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if presentationMode == .folderHierarchy {
            guard let tag = tableView.cellForRow(at: indexPath)?.tag else { return }
            
            switch tag {
            case Location.favoritesTag: location = .favorites
            case Location.rootLevelTag: location = .rootLevel
            case Location.folderTag:
                let folder = sortedFolders[indexPath.row - 3].0
                location = .folder(folder: folder)
            default: assertionFailure("not supported tag was selected: \(tag)")
                
            }
        }
        
        presentationMode.toggle()
        
        // This gives us an animation while switching between presentation modes.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    var rootLevelFolderCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell().then {
            $0.folderName.text = "Bookmarks"
            $0.tag = Location.rootLevelTag
            if case .rootLevel = location, presentationMode == .folderHierarchy {
                $0.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    var favoritesCell: IndentedImageTableViewCell {
        let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "bookmark"))
        cell.folderName.text = "Favorites"
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
                let cell = IndentedImageTableViewCell()
                cell.folderName.text = folder.displayTitle
                cell.tag = Location.folderTag
                return cell
            }
        case .folderHierarchy:
            let row = indexPath.row
            
            if row == 0 {
                let cell = IndentedImageTableViewCell(image: #imageLiteral(resourceName: "add_tab"))
                cell.folderName.text = "New Folder"
                cell.accessoryType = .disclosureIndicator
                
                return cell
            }
            
            if row == 1 {
                return favoritesCell
            }
            
            if row == 2 {
                return rootLevelFolderCell
            }
            
            let cell = IndentedImageTableViewCell()
            
            let indentedFolder = sortedFolders[row - 3]
            
            cell.folderName.text = indentedFolder.0.displayTitle
            cell.indentationLevel = indentedFolder.indentationLevel
            cell.tag = Location.folderTag
            
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

// TODO: add frc to see when folders from sync come, do a manual reconfiguration
extension AddEditBookmarkTableViewController: NSFetchedResultsControllerDelegate {
}
