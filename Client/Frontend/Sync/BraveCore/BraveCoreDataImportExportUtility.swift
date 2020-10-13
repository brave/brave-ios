// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import Shared
import BraveShared
import Data
import CoreData

private let log = Logger.browserLogger

class BraveCoreDataImportExportUtility {
    
    // Import an array of bookmarks into CoreData
    func importBookmarks(from array: [BraveImportedBookmark], _ completion: @escaping (_ success: Bool) -> Void) {
        precondition(state == .none, "Bookmarks Import - Error Importing while an Import/Export operation is in progress")
        
        state = .importing
        self.queue.async {
            DataController.perform { context in
                self.readBookmarks(from: array, context: context)
                
                self.state = .none
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
    
    // Import bookmarks from a file into CoreData
    func importBookmarks(from path: URL, _ completion: @escaping (_ success: Bool) -> Void) {
        precondition(state == .none, "Bookmarks Import - Error Importing while an Import/Export operation is in progress")
        
        state = .importing
        self.queue.async {
            self.braveCoreImporterExporter.importBookmarks(from: path) { [weak self] success, bookmarks in
                guard let self = self else { return }
                
                if success {
                    DataController.perform { context in
                        self.readBookmarks(from: bookmarks, context: context)
                        
                        self.state = .none
                        log.info("Bookmarks Import - Completed Import Into CoreData Successfully")
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                } else {
                    self.state = .none
                    log.error(ParsingError.errorUnknown)
                    
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    // Export bookmarks from CoreData to a file
    func exportBookmarks(to path: URL, _ completion: @escaping (_ success: Bool) -> Void) {
        precondition(state == .none, "Bookmarks Import - Error Exporting while an Import/Export operation is in progress")
        
        self.state = .exporting
        self.queue.async {
            DataController.perform { context in
                do {
                    try self.writeBookmarks(to: path, context: context)
                    self.state = .none
                    log.info("Bookmarks Export - Completed Export Successfully")
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } catch {
                    self.state = .none
                    log.error(error)
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    // MARK: - Private
    private var state: State = .none
    private var currentIndentation = ""
    private let braveCoreImporterExporter = BraveCoreImportExportUtility()
    
    //Serial queue because we don't want someone accidentally importing and exporting at the same time..
    private let queue = DispatchQueue(label: "brave.coredata.import.export.utility", qos: .userInitiated)
    
    private enum State {
        case importing
        case exporting
        case none
    }
}

// MARK: - Parsing

struct CoreDataBookmark: Hashable {
    let isFolder: Bool
    let title: String?
    let customTitle: String?
    let url: String?
    let created: Date?
    let lastVisited: Date?
    let favIconUrl: String?
    let children: Set<CoreDataBookmark>?
    
    private init(from bookmark: Bookmark) {
        self.isFolder = bookmark.isFolder
        self.title = bookmark.title
        self.customTitle = bookmark.customTitle
        self.url = bookmark.url
        self.created = bookmark.created
        self.lastVisited = bookmark.lastVisited
        self.favIconUrl = bookmark.domain?.favicon?.url
        if let children = bookmark.children?.map({ CoreDataBookmark(from: $0) }) {
            self.children = Set(children)
        } else {
            self.children = nil
        }
    }
    
    static func getTopLevelBookmarks() -> [CoreDataBookmark] {
        //Can't invoke `Bookmark`.allTopLevelBookmarks on different threads.
        //Therefore, force invoke it on main, and map it to a struct that can be passed to any thread.
        if Thread.current.isMainThread {
            let bookmarks = Bookmark.getAllTopLevelBookmarks()
            return bookmarks.map({ CoreDataBookmark(from: $0) })
        }
        
        return DispatchQueue.main.sync {
            let bookmarks = Bookmark.getAllTopLevelBookmarks()
            return bookmarks.map({ CoreDataBookmark(from: $0) })
        }
    }
    
    static func getTopLevelBookmarks(context: NSManagedObjectContext) -> [CoreDataBookmark] {
        let bookmarks = Bookmark.getAllTopLevelBookmarks(context)
        return bookmarks.map({ CoreDataBookmark(from: $0) })
    }
}

extension BraveCoreDataImportExportUtility {
    private func readBookmarks(from array: [BraveImportedBookmark], context: NSManagedObjectContext) {
        let topLevelBookmarks = Bookmark.getAllTopLevelBookmarks(context)
        let importToTopLevel = topLevelBookmarks.isEmpty
        var topLevelEntries = [BraveImportedBookmark]()
        var reorderedEntries = [BraveImportedBookmark]()
        
        for bookmark in array {
            if bookmark.inToolbar {
                topLevelEntries.append(bookmark)
            } else {
                reorderedEntries.append(bookmark)
            }
        }
        
        reorderedEntries = topLevelEntries + reorderedEntries
        let addAllToTopLevel = importToTopLevel && topLevelEntries.isEmpty
        
        var foldersAddedTo = Set<Bookmark?>()
        var topLevelFolder: Bookmark?
        
        for bookmark in reorderedEntries {
            //Disregard any bookmarks with invalid urls.
            if !bookmark.isFolder && bookmark.url == nil {
                continue
            }
            
            var parent: Bookmark?
            if importToTopLevel && (addAllToTopLevel || bookmark.inToolbar) {
                //Add directly to the bookmarks bar.
                parent = nil
            } else {
                //Add to a folder that will contain all the imported bookmarks not added
                //to the bar. The first time we do so, create the folder.
                if topLevelFolder == nil {
                    //Generate a unique folder name
                    let topLevelFolderName = "Imported Bookmarks"
                    var chosenFolder = topLevelFolderName
                    var counter = 1
                    while true {
                        if topLevelBookmarks.firstIndex(where: {
                            $0.customTitle == chosenFolder
                        }) != nil {
                            chosenFolder = topLevelFolderName + " (\(counter))"
                            counter += 1
                            continue
                        }
                        break
                    }
                    
                    Bookmark.addFolder(title: chosenFolder, context: .existing(context))
                    //try context.save()
                    topLevelFolder = Bookmark.getTopLevelFolders(context).first(where: { $0.isFolder && $0.customTitle == chosenFolder })
                }
                
                parent = topLevelFolder
            }
            
            // Ensure any enclosing folders are present in the model. The bookmark's
            // enclosing folder structure should be
            //    path[0] -> path[1] -> ... -> path[path.count - 1]
            for folderName in bookmark.path ?? [] {
                if bookmark.inToolbar && parent == nil && folderName == bookmark.path?.first {
                    //If we're importing directly to the bookmarks bar, skip over the
                    // folder named "Bookmarks Toolbar" (or any non-Firefox equivalent).
                    continue
                }
                
                let index = parent?.children?.first(where: { $0.isFolder && $0.customTitle == folderName })
                if index == nil {
                    Bookmark.addFolder(title: folderName, parentFolder: parent, context: .existing(context))
                    //try context.save()
                    
                    parent = parent?.children?.filter({ $0.isFolder && $0.customTitle == folderName }).first
                } else {
                    parent = index
                }
            }
            
            foldersAddedTo.insert(parent)
            if bookmark.isFolder {
                Bookmark.addFolder(title: bookmark.title, parentFolder: parent, context: .existing(context))
                //try context.save()
            } else if let url = bookmark.url {
                Bookmark.add(url: url, title: bookmark.title, parentFolder: parent, context: .existing(context))
                //try context.save()
                
                let child = parent?.children?.first(where: { !$0.isFolder && $0.url == url.absoluteString && $0.title == bookmark.title })
                child?.created = bookmark.creationTime
                child?.lastVisited = nil
                //try context.save()
            }
        }
    }
}

extension BraveCoreDataImportExportUtility {
    private func convertToChromiumFormat(_ bookmark: Bookmark) -> BraveExportedBookmark {
        // Tail recursion to map children..
        return BraveExportedBookmark(title: bookmark.isFolder ? bookmark.customTitle ?? "(No Title)" : bookmark.title ?? "(No Title)", id: Int64(bookmark.order), guid: UUID().uuidString.lowercased(), url: URL(string: bookmark.url ?? ""), dateAdded: bookmark.created ?? Date(), dateModified: bookmark.lastVisited ?? Date(), children: bookmark.children?.map({ convertToChromiumFormat($0) }))
    }
    
    
    private func writeBookmarks(to path: URL, context: NSManagedObjectContext) throws {
        //Create Output File
        if FileManager.default.fileExists(atPath: path.absoluteString) {
            do {
                try FileManager.default.removeItem(atPath: path.absoluteString)
            } catch {
                log.error(error)
                throw ParsingError.errorCreatingFile
            }
        }
        
        if !FileManager.default.createFile(atPath: path.absoluteString, contents: nil, attributes: nil) {
            throw ParsingError.errorCreatingFile
        }
        
        guard let fileHandle = FileHandle(forWritingAtPath: path.absoluteString) else {
            throw ParsingError.errorCreatingFile
        }
        
        //Guarantee Exception Safe Close
        defer { fileHandle.closeFile() }
        
        //Start Header
        try rethrow(fileHandle.write(BraveCoreDataImportExportUtility.kHeader), error: .errorWritingHeader)

        //Write Nodes
        incrementIndent()
        try rethrow(self.writeNodes(Bookmark.getAllTopLevelBookmarks(context), to: fileHandle), error: .errorWritingNode)
        decrementIndent()
        
        //End Header
        try rethrow(fileHandle.write(FolderWriter.kFolderChildrenEnd), error: .errorWritingNode)
        
        //Flush To Disk
        fileHandle.synchronizeFile()
    }
    
    private func writeNodes(_ bookmarks: [Bookmark], to file: FileHandle) throws {
        for bookmark in bookmarks.sorted(by: { $0.isFolder && !$1.isFolder }) {
            if bookmark.isFolder {
                try file.write(currentIndentation)
                
                //Start Folder
                try file.write(FolderWriter.kFolderStart)
                
                //Created Date
                try file.write("\(Int(bookmark.created?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))")
                
                //Last Modified Date
                try file.write(FolderWriter.kLastModified)
                try file.write("\(Int(bookmark.lastVisited?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))")
                
                //End Attributes
                try file.write(FolderWriter.kFolderAttributeEnd)
                
                //Title
                try file.write((bookmark.customTitle ?? "(No Title)").escapeForHTML())
                
                //End Folder
                try file.write(FolderWriter.kFolderEnd)
                try file.write(BraveCoreDataImportExportUtility.kNewline)
                
                //Children
                if let children = bookmark.children, !children.isEmpty {
                    try file.write(currentIndentation)
                    try file.write(FolderWriter.kFolderChildren)
                    try file.write(BraveCoreDataImportExportUtility.kNewline)
                    incrementIndent()
                    
                    //Recursive Children
                    try self.writeNodes(Array(children), to: file)
                    
                    decrementIndent()
                    try file.write(currentIndentation)
                    try file.write(FolderWriter.kFolderChildrenEnd)
                    try file.write(BraveCoreDataImportExportUtility.kNewline)
                }
            } else {
                try file.write(currentIndentation)
                
                //Start Bookmark
                try file.write(BookmarkWriter.kBookmarkStart)
                
                //URL
                try file.write(bookmark.url?.escapeAsHTMLQuotes() ?? "")
                
                //Created Date
                try file.write("\(Int(bookmark.created?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))")
                
                //ICON (OPTIONAL) - 16x16 PNG
                if let iconUrl = bookmark.domain?.favicon?.url,
                   let url = URL(string: iconUrl),
                   let iconData = try? Data(contentsOf: url),
                   let image = UIImage(data: iconData, scale: UIScreen.main.scale)?.scale(toSize: CGSize(width: 16.0, height: 16.0)),
                   let pngData = image.pngData() {
                    try file.write(BookmarkWriter.kIcon)
                    try file.write("data:image/png;base64,\(pngData.base64EncodedString)".escapeAsHTMLQuotes())
                }
                
                //End Attributes
                try file.write(BookmarkWriter.kBookmarkAttributeEnd)
                
                //Title
                try file.write((bookmark.title ?? "(No Title)").escapeForHTML())
                
                //End Bookmark
                try file.write(BookmarkWriter.kBookmarkEnd)
                try file.write(BraveCoreDataImportExportUtility.kNewline)
            }
        }
    }
    
    private func incrementIndent() {
        currentIndentation += String(repeating: " ", count: BraveCoreDataImportExportUtility.kIndentSize)
    }
    
    private func decrementIndent() {
        if currentIndentation.count >= BraveCoreDataImportExportUtility.kIndentSize {
            currentIndentation.removeLast(BraveCoreDataImportExportUtility.kIndentSize)
        }
    }
    
    private func rethrow(_ closure: @autoclosure () throws -> Void, error: ParsingError) rethrows {
        do {
            try closure()
        } catch {
            throw error
        }
    }
    
    // File header.
    private static let kHeader =
        "<!DOCTYPE NETSCAPE-Bookmark-file-1>\r\n" +
        "<!-- This is an automatically generated file.\r\n" +
        "     It will be read and overwritten.\r\n" +
        "     DO NOT EDIT! -->\r\n" +
        "<META HTTP-EQUIV=\"Content-Type\"" +
        " CONTENT=\"text/html; charset=UTF-8\">\r\n" +
        "<TITLE>Bookmarks</TITLE>\r\n" +
        "<H1>Bookmarks</H1>\r\n" +
        "<DL><p>\r\n"

    // Newline separator.
    private static let kNewline = "\r\n"

    private struct BookmarkWriter {
        // Start of a bookmark.
        static let kBookmarkStart = "<DT><A HREF=\""
        // After kBookmarkStart.
        static let kAddDate = "\" ADD_DATE=\""
        // After kAddDate.
        static let kIcon = "\" ICON=\""
        // After kIcon.
        static let kBookmarkAttributeEnd = "\">"
        // End of a bookmark.
        static let kBookmarkEnd = "</A>"
    }
    
    private struct FolderWriter {
        // Start of a folder.
        static let kFolderStart = "<DT><H3 ADD_DATE=\""
        // After kFolderStart.
        static let kLastModified = "\" LAST_MODIFIED=\""
        // After kLastModified when writing the bookmark bar.
        static let kBookmarkBar = "\" PERSONAL_TOOLBAR_FOLDER=\"true\">"
        // After kLastModified when writing a user created folder.
        static let kFolderAttributeEnd = "\">"
        // End of the folder.
        static let kFolderEnd = "</H3>"
        // Start of the children of a folder.
        static let kFolderChildren = "<DL><p>"
        // End of the children for a folder.
        static let kFolderChildrenEnd = "</DL><p>"
    }

    // Number of characters to indent by.
    private static let kIndentSize = 4
}

// MARK: - Errors

private enum ParsingError: String, Error {
    case errorCreatingFile = "Error Creating File"
    case errorWritingHeader = "Error Writing Header"
    case errorWritingNode = "Error Writing Node"
    case errorUnknown = "Unknown Error"
}

// MARK: - Helpers

private extension FileHandle {
    func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.errorUnknown
        }
        
        self.write(data)
    }
}

private extension String {
    func escapeAsHTMLQuotes() -> String {
        return self.replacingOccurrences(of: "\"", with: "&quot;")
    }
    
    func escapeForHTML() -> String {
        let characters = [
            "<": "&lt;",
            ">": "&gt;",
            "&": "&amp;",
            "\"": "&quot;",
            "'": "&#39;"
        ]
        
        var str = self
        for character in characters {
            str = str.replacingOccurrences(of: character.key, with: character.value)
        }
        return str
    }
}
