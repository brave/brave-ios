// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveUI
import BraveCore

private let browserLogger = Log.main

fileprivate class LogLineCell: UITableViewCell, TableViewReusable {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    textLabel?.font = .systemFont(ofSize: 12, weight: .regular)
    textLabel?.numberOfLines = 0
    detailTextLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    detailTextLabel?.numberOfLines = 0
    selectionStyle = .none
  }
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
}

/// A file generator that copies all Rewards related log files into the sharable directory
struct RewardsInternalsLogsGenerator: RewardsInternalsFileGenerator {
  func generateFiles(at path: String, using builder: RewardsInternalsSharableBuilder, completion: @escaping (Error?) -> Void) {
    do {
        // FIXME: This does nothing now. Retrieve OSLogs once iOS 15 is minimum supported version
        
//      let fileURLs = try braveCoreLogger.logFilenamesAndURLs().map { URL(fileURLWithPath: $0.1.path) }
//      for url in fileURLs {
//        let logPath = URL(fileURLWithPath: path).appendingPathComponent(url.lastPathComponent)
//        try FileManager.default.copyItem(atPath: url.path, toPath: logPath.path)
//      }
      completion(nil)
    } catch {
      completion(error)
    }
  }
}
