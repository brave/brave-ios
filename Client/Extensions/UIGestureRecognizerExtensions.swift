//
//  UIGestureRecognizerExtensions.swift
//  Client
//
//  Created by Kyle Hickinson on 2018-05-31.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import UIKit

extension UIGestureRecognizer {
    
    /// Cancels the gesture recognizer by toggling `isEnabled`.
    func cancel() {
        // Setting `isEnabled` to false immediately fails a gesture... Casually waiting on Swift 4.2 for Bool.toggle()
        isEnabled = false
        isEnabled = true
    }
}
