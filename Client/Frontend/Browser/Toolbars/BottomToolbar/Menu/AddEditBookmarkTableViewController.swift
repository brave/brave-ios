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
    
    let frc: NSFetchedResultsController<Bookmark>
    
    let mode: Mode
    
    init(mode: AddEditBookmarkTableViewController.Mode) {
        frc = Bookmark.foldersFrc()
        self.mode = mode
        
        super.init(style: .grouped)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.rowHeight = 44
        tableView.cellLayoutMarginsFollowReadableWidth = false
        
        let bookmarkDetailsView = BookmarkDetailsView()
        bookmarkDetailsView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.tableHeaderView = bookmarkDetailsView
        
        bookmarkDetailsView.snp.makeConstraints {
            $0.width.equalTo(self.view)
            $0.top.equalTo(self.view)
            $0.centerX.equalTo(self.view)
        }
        
        tableView.contentInset = UIEdgeInsets(top: 36, left: 0, bottom: 0, right: 0)
        
        bookmarkDetailsView.layoutIfNeeded()
        
        //tableView.tableFooterView = UIView()
        
        frc.delegate = self
        
        try? frc.performFetch()
        sortedFolders = sortFolders()
        
        tableView.reloadData()
        
        
    }
    
    var allFolders = [Bookmark]()
    var sortedFolders = [IndentedFolder]()
    
    typealias IndentedFolder = (Bookmark, indentationLevel: Int)
    
    func sortFolders(parentID: NSManagedObjectID? = nil, indentationLevel: Int = 0) -> [IndentedFolder] {
        guard let objects = frc.fetchedObjects else { return [] }
        
        var s = [IndentedFolder]()
        
        objects.filter { $0.parentFolder?.objectID == parentID }.forEach {
            s.append(($0, indentationLevel: indentationLevel))
            s.append(contentsOf: sortFolders(parentID: $0.objectID, indentationLevel: indentationLevel + 1))
        }
     
        return s
    }
    
    var testToggle = false

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedFolders.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Location"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        testToggle = !testToggle
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = IndentedImageTableViewCell()
        
        let indentedFolder = sortedFolders[indexPath.row]
        
        cell.folderName.text = indentedFolder.0.displayTitle
        
        //cell.textLabel?.text = indentedFolder.0.displayTitle
        //cell.imageView?.image = #imageLiteral(resourceName: "bookmarks_folder_hollow")
        cell.indentationLevel = indentedFolder.indentationLevel
        
        

        return cell
    }
    
    
}

extension AddEditBookmarkTableViewController: NSFetchedResultsControllerDelegate {
}
