//
//  PopoverContentComponent.swift
//  Brave
//
//  Created by Kyle Hickinson on 2018-05-22.
//  Copyright © 2018 Kyle Hickinson. All rights reserved.
//

import Foundation
import UIKit

/// Defines behavior of a component which will be used with a `PopoverController`
protocol PopoverContentComponent {
    /// Whether or not the pan to dismiss gesture is enabled. Optional, true by defualt
    var isPanToDismissEnabled: Bool { get }
    /// Allows the component to decide whether or not the popover should dismiss based on some gestural action (tapping
    /// the background around the popover or dismissing via pan). Optional, true by defualt
    func popoverShouldDismiss(_ popoverController: PopoverController) -> Bool
    /// Allows the component to know when the popover was dismissed by some gestural action. Optional
    func popoverDidDismiss(_ popoverController: PopoverController)
}

extension PopoverContentComponent {
    var isPanToDismissEnabled: Bool {
        return true
    }
    
    func popoverShouldDismiss(_ popoverController: PopoverController) -> Bool {
        return true
    }
    
    func popoverDidDismiss(_ popoverController: PopoverController) {
    }
}
