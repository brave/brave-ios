/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftyJSON
import SwiftKeychainWrapper

enum BinanceWidgetState {
    case loading
    case disconnected
    case connected
    case invalid
}

protocol BinanceWidgetServiceDelegate {
    func didChangeState(widget: BinanceWidgetServiceManager, state: BinanceWidgetState)
}

class BinanceWidgetServiceManager: NSObject {
    var delegate: BinanceWidgetServiceDelegate?
    var state: BinanceWidgetState = .disconnected {
        didSet {
            delegate?.didChangeState(widget: self, state: state)
        }
    }
    
    override init() {
        super.init()
    }
    
    func start() {
        state = .disconnected
    }
}

