// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import os.log
import OSLog
import SnapKit

public class BraveTalkLogsViewController: UIViewController {
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    let logsTextView = UITextView()
    logsTextView.isEditable = false
    
    view.addSubview(logsTextView)
    logsTextView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .long
    
    logsTextView.text = getLogs()
  }
  
  private func getLogs() -> String {
    do {
      let store = try OSLogStore(scope: .currentProcessIdentifier)
      
      return try store
        .getEntries()
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.category == "BraveTalk" && $0.subsystem == Bundle.main.bundleIdentifier }
        .map { "[\($0.date.formatted())] \($0.composedMessage)" }
        .joined()
    } catch {
      Logger.module.error("\(error.localizedDescription, privacy: .public)")
    }
    
    return ""
  }
}
