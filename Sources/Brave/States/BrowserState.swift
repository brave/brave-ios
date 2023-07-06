//
//  BrowserState.swift
//  
//
//  Created by Brandon T on 2023-05-15.
//

import Foundation
import UIKit

public class BrowserState {
  public static let sceneId = "com.brave.ios.browser-scene"
  
  let window: UIWindow
  let profile: Profile
  //let browser: BrowserViewController
  
  init(window: UIWindow, profile: Profile) {
    self.window = window
    self.profile = profile
  }
  
  public static func userActivity(for windowId: UUID, isPrivate: Bool) -> NSUserActivity {
    return NSUserActivity(activityType: sceneId).then {
      $0.targetContentIdentifier = windowId.uuidString
      $0.addUserInfoEntries(from: [
        "WindowID": windowId.uuidString,
        "isPrivate": isPrivate
      ])
    }
  }
}
