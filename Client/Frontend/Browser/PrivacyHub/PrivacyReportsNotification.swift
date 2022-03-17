// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared

private let log = Logger.browserLogger

struct PrivacyReportsNotification {
  private static let notificationID = "privacy-report-weekly-notification"
  
  static func scheduleIfNeeded(debugMode: Bool = false) {
    let notificationCenter = UNUserNotificationCenter.current()
    
    notificationCenter.getPendingNotificationRequests {  requests in
        if !debugMode && requests.contains(where: { $0.identifier == notificationID }) {
            // Already has one scheduled no need to schedule again.
            return
        }
      
      let content = UNMutableNotificationContent()
      content.title = Strings.PrivacyHub.notificationTitle
      content.body = Strings.PrivacyHub.notificationMessage
      
      var dateComponents = DateComponents()
      let calendar = Calendar.current
      dateComponents.calendar = calendar

      // For testing purposes, notification launched from the debug menu will show up
      // in the next 5 minutes of the time it was requested.
      if debugMode {
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute + 5
      } else {
        // Every Sunday at 2 PM
        dateComponents.weekday = 1
        dateComponents.hour = 14
      }
      
      // Create the trigger as a repeating event.
      let trigger = UNCalendarNotificationTrigger(
               dateMatching: dateComponents, repeats: true)
      
      // Create the request
      let identifier = debugMode ? UUID().uuidString : notificationID
      let request = UNNotificationRequest(identifier: identifier,
                  content: content, trigger: trigger)

      // Schedule the request with the system.
      
      notificationCenter.add(request) { error in
        if let error = error {
          log.error("Scheduling privacy reports notification error: \(error)")
        }
      }
    }
  }
  
  static func cancel() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
  }
}
