/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Note that this file is imported into SyncTests, too.

import Foundation
import Shared
@testable import Storage
import XCTest

extension BrowserDB {
  func assertQueryReturns(_ query: String, int: Int) async throws {
    let value = try await self.runQuery(query, args: nil, factory: intFactory)[0]
    XCTAssertEqual(int, value)
  }
}

extension BrowserDB {
  func moveLocalToMirrorForTesting() async throws {
    // This is a risky process -- it's not the same logic that the real synchronizer uses
    // (because I haven't written it yet), so it might end up lying. We do what we can.
    let valueSQL = """
      INSERT OR IGNORE INTO bookmarksMirror
          (guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
          description, tags, keyword, folderName, queryId,
          is_overridden, server_modified, faviconID)
      SELECT
          guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
          description, tags, keyword, folderName, queryId,
          0 AS is_overridden, \(Date.now()) AS server_modified, faviconID
      FROM bookmarksLocal
      """

    // Copy its mirror structure.
    let structureSQL = "INSERT INTO bookmarksMirrorStructure SELECT * FROM bookmarksLocalStructure"

    // Throw away the old.
    let deleteLocalStructureSQL = "DELETE FROM bookmarksLocalStructure"
    let deleteLocalSQL = "DELETE FROM bookmarksLocal"

    try await self.run([
      valueSQL,
      structureSQL,
      deleteLocalStructureSQL,
      deleteLocalSQL,
    ])
  }

  func moveBufferToMirrorForTesting() async throws {
    let valueSQL = """
      INSERT OR IGNORE INTO bookmarksMirror
          (guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
          description, tags, keyword, folderName, queryId, server_modified)
      SELECT
          guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos,
          description, tags, keyword, folderName, queryId, server_modified
      FROM bookmarksBuffer
      """

    let structureSQL = "INSERT INTO bookmarksMirrorStructure SELECT * FROM bookmarksBufferStructure"
    let deleteBufferStructureSQL = "DELETE FROM bookmarksBufferStructure"
    let deleteBufferSQL = "DELETE FROM bookmarksBuffer"

    try await self.run([
      valueSQL,
      structureSQL,
      deleteBufferStructureSQL,
      deleteBufferSQL,
    ])
  }
}

extension BrowserDB {
  func getGUIDs(_ sql: String) async throws -> [GUID] {
    func guidFactory(_ row: SDRow) -> GUID {
      return row[0] as! GUID
    }

    return try await self.runQuery(sql, args: nil, factory: guidFactory).asArray()
  }

  func getPositionsForChildrenOfParent(_ parent: GUID, fromTable table: String) async throws -> [GUID: Int] {
    let args: Args = [parent]
    let factory: (SDRow) -> (GUID, Int) = {
      return ($0["child"] as! GUID, $0["idx"] as! Int)
    }
    let cursor = try await self.runQuery("SELECT child, idx FROM \(table) WHERE parent = ?", args: args, factory: factory)
    return cursor.reduce(
      [:],
      { (dict, pair) in
        var dict = dict
        if let (k, v) = pair {
          dict[k] = v
        }
        return dict
      })
  }

  func isLocallyDeleted(_ guid: GUID) async throws -> Bool? {
    let args: Args = [guid]
    let cursor = try await self.runQuery("SELECT is_deleted FROM bookmarksLocal WHERE guid = ?", args: args, factory: { $0.getBoolean("is_deleted") })
    return cursor[0]
  }

  func isOverridden(_ guid: GUID) async throws -> Bool? {
    let args: Args = [guid]
    let cursor = try await self.runQuery("SELECT is_overridden FROM bookmarksMirror WHERE guid = ?", args: args, factory: { $0.getBoolean("is_overridden") })
    return cursor[0]
  }

  func getChildrenOfFolder(_ folder: GUID) async throws -> [GUID] {
    let args: Args = [folder]
    let sql = """
      SELECT child
      FROM view_bookmarksLocalStructure_on_mirror
      WHERE parent = ?
      ORDER BY idx ASC
      """

    return try await self.runQuery(sql, args: args, factory: { $0[0] as! GUID }).asArray()
  }
}
