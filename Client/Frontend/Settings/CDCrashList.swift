/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import BraveShared

public class CDCrashList: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let logsTextView = UITextView()
        logsTextView.isEditable = false

        view.addSubview(logsTextView)
        logsTextView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        
        var logs = ""
        
        Preferences.cdError.value.forEach {
            logs.append("\($0)\n\n")
        }

        logsTextView.text = logs
    }
}
