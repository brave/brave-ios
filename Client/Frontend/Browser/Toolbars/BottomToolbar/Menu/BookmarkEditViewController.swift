// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Eureka
import Data
import Shared

class BookmarkEditViewController: FormViewController {
    var completionBlock: ((_ controller: BookmarkEditViewController) -> Void)?
    
    var folders: [Bookmark] = []
    
    var bookmarksPanel: BookmarksViewController!
    var bookmark: Bookmark!
    var bookmarkIndexPath: IndexPath!
    
    let BOOKMARK_TITLE_ROW_TAG: String = "BOOKMARK_TITLE_ROW_TAG"
    let BOOKMARK_URL_ROW_TAG: String = "BOOKMARK_URL_ROW_TAG"
    let BOOKMARK_FOLDER_ROW_TAG: String = "BOOKMARK_FOLDER_ROW_TAG"
    
    var titleRow: TextRow?
    var urlRow: URLRow?
    
    init(bookmarksPanel: BookmarksViewController, indexPath: IndexPath, bookmark: Bookmark) {
        super.init(nibName: nil, bundle: nil)
        
        self.bookmark = bookmark
        self.bookmarksPanel = bookmarksPanel
        self.bookmarkIndexPath = indexPath
        
        folders = Bookmark.getTopLevelFolders()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //called when we're about to be popped, so use this for callback
        if let block = self.completionBlock {
            block(self)
        }
        
        self.bookmark.update(customTitle: self.titleRow?.value, url: self.urlRow?.value?.absoluteString)
    }
    
    var isEditingFolder: Bool {
        return bookmark.isFolder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstSectionName = !isEditingFolder ?  Strings.Bookmark_Info : Strings.Bookmark_Folder
        
        let nameSection = Section(firstSectionName)
        
        nameSection <<< TextRow() { row in
            row.tag = BOOKMARK_TITLE_ROW_TAG
            row.title = Strings.Name
            row.value = bookmark.displayTitle
            self.titleRow = row
        }
        
        form +++ nameSection
        
        // Only show URL option for bookmarks, not folders
        if !isEditingFolder {
            nameSection <<< URLRow() { row in
                row.tag = BOOKMARK_URL_ROW_TAG
                row.title = Strings.URL
                row.value = URL(string: bookmark.url ?? "")
                self.urlRow = row
            }
        }
        
        // Currently no way to edit bookmark/folder locations
        // See de9e1cc for removal of this logic
    }
}
