//
//  UIBarButtonItemExtensions.swift
//  Client
//
//  Created by Kyle Hickinson on 2018-05-31.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation
import UIKit

extension UIBarButtonItem {
    
    /// Creates a fixed space `UIBarButtonItem` with a given width
    class func fixedSpace(_ width: CGFloat) -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil).then {
            $0.width = width
        }
    }
}
