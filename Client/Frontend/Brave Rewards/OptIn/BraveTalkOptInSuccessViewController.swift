// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI

class BraveTalkOptInSuccessViewController: UIViewController, PopoverContentComponent {
    
    private var braveTalkView: View {
        view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
        preferredContentSize = .init(width: 350, height: 250)
    }
}
