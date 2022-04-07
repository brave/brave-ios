// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import Data

private let log = Logger.browserLogger

struct PrivacyReportsManager {

  // MARK: - Notifications

  static var pendingBlockedRequests: [(host: String, domain: URL, date: Date)] = []

  static func processBlockedRequests() {
    if !Preferences.PrivacyHub.captureShieldsData.value { return }
    
    let itemsToSave = pendingBlockedRequests
    pendingBlockedRequests.removeAll()

    BlockedResource.batchInsert(items: itemsToSave)
  }

  private static var saveBlockedResourcesTimer: Timer?
  private static var vpnAlertsTimer: Timer?

  static func scheduleProcessingBlockedRequests() {
    saveBlockedResourcesTimer?.invalidate()

    saveBlockedResourcesTimer = Timer.scheduledTimer(withTimeInterval: 1.minutes, repeats: true) { _ in
      processBlockedRequests()
    }
  }

  static func scheduleVPNAlertsTask() {
    vpnAlertsTimer?.invalidate()

    // Because fetching VPN alerts involves making a url request,
    // the time interval to fetch them is longer than the local on-device blocked requests
    let timeInterval = AppConstants.buildChannel.isPublic ? 5.minutes : 1.minutes
    vpnAlertsTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
      BraveVPN.processVPNAlerts()
    }
  }

  // MARK: - View
  static func prepareView() -> PrivacyReportsView {
    let lastWeekMostFrequentTracker = BlockedResource.mostBlockedTracker(inLastDays: 7)
    let allTimeMostFrequentTracker = BlockedResource.mostBlockedTracker(inLastDays: nil)

    let lastWeekRiskiestWebsite = BlockedResource.riskiestWebsite(inLastDays: 7)
    let allTimeRiskiestWebsite = BlockedResource.riskiestWebsite(inLastDays: nil)

    let allTimeListTracker = BlockedResource.allTimeMostFrequentTrackers()

    // FIXME: VPNAlerts flag
    let allTimeVPN = BraveVPNAlert.allByHostCount

    let allTimeListWebsites = BlockedResource.allTimeMostRiskyWebsites().map {
      PrivacyReportsItem(domainOrTracker: $0.domain, faviconUrl: $0.faviconUrl, count: $0.count)
    }

    let allAlerts: [PrivacyReportsItem] =
      PrivacyReportsItem.merge(shieldItems: allTimeListTracker, vpnItems: allTimeVPN)

    let last = BraveVPNAlert.last(3)

    let view = PrivacyReportsView(
      lastWeekMostFrequentTracker: lastWeekMostFrequentTracker,
      lastWeekRiskiestWebsite: lastWeekRiskiestWebsite,
      allTimeMostFrequentTracker: allTimeMostFrequentTracker,
      allTimeRiskiestWebsite: allTimeRiskiestWebsite,
      allTimeListTrackers: allAlerts,
      allTimeListWebsites: allTimeListWebsites,
      lastVPNAlerts: last)

    return view
  }

  // MARK: - Notifications

  static let notificationID = "privacy-report-weekly-notification"

  static func scheduleNotification(debugMode: Bool = false) {
    let notificationCenter = UNUserNotificationCenter.current()

    if debugMode {
      cancelNotification()
    }

    notificationCenter.getPendingNotificationRequests { requests in
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
        // Every Sunday at 11 AM
        dateComponents.weekday = 1
        dateComponents.hour = 11
      }

      // Create the trigger as a repeating event.
      let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents, repeats: true)

      // Create the request
      let request = UNNotificationRequest(
        identifier: notificationID,
        content: content, trigger: trigger)

      // Schedule the request with the system.

      notificationCenter.add(request) { error in
        if let error = error {
          log.error("Scheduling privacy reports notification error: \(error)")
        }
      }
    }
  }

  static func cancelNotification() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
  }
}
