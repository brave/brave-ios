// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

extension UILabel {
    @objc dynamic var appearanceTextColor: UIColor! {
        get { return self.textColor }
        set {  self.textColor = newValue }
    }
}

extension UITableView {
    @objc dynamic var appearanceBackgroundColor: UIColor? {
        get { return self.backgroundColor }
        set {  self.backgroundColor = newValue }
    }
    
    @objc dynamic var appearanceSeparatorColor: UIColor? {
        get { return self.separatorColor }
        set {  self.separatorColor = newValue }
    }
}

