// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveShared
import NetworkExtension
import Data
import GuardianConnect

private let log = Logger.browserLogger

/// A static class to handle all things related to the Brave VPN service.
class BraveVPN {

  private static let housekeepingApi = GRDHousekeepingAPI()
  private static let helper = GRDVPNHelper.sharedInstance()
  private static let serverManager = GRDServerManager()

  /// List of regions the VPN can connect to.
  /// This list is not static and should be refetched every now and then.
  static var regions: [GRDRegion] = []
  
  private static let connectionName = "Brave Firewall + VPN"

  // MARK: - Initialization

  /// This class is supposed to act as a namespace, disabling possibility of creating an instance of it.
  @available(*, unavailable)
  init() {}

  /// Initialize the vpn service. It should be called even if the user hasn't bought the vpn yet.
  /// This function can have side effects if the receipt has expired(removes the vpn connection then).
  static func initialize() {
    // The vpn can live outside of the app.
    // When the app loads we should load it from preferences to track its state.
    NEVPNManager.shared().loadFromPreferences { error in
      if let error = error {
        logAndStoreError("Failed to load vpn conection: \(error)")
      }
      
      helper.verifyMainCredentials { _, _ in }
      GRDSubscriptionManager.setIsPayingUser(true)
      
      helper.dummyDataForDebugging = !AppConstants.buildChannel.isPublic
      helper.tunnelLocalizedDescription = connectionName
      
      if case .notPurchased = vpnState {
        // Unlikely if user has never bought the vpn, we clear vpn config here for safety.
        BraveVPN.clearConfiguration()
        return
      }

      // We validate the current receipt at the start to know if the subscription has expirerd.
      BraveVPN.validateReceipt() { expired in
        if expired == true {
          BraveVPN.clearConfiguration()
          logAndStoreError("Receipt expired")
          return
        }

        populateRegionDataIfNecessary()
      }
    }
  }

  // MARK: - STATE

  /// Lock to prevent user from spamming connect/disconnect button.
  static var reconnectPending = false

  enum VPNPurchaseError {
    /// Returned when the receipt sent to the server is expired. This happens for sandbox users only.
    case receiptExpired
    /// Purchase failed on Apple's side or canceled by user.
    case purchaseFailed
  }

  /// A state in which the vpn can be.
  enum State {
    case notPurchased
    /// Purchased but not installed
    case purchased
    /// Purchased and installed
    case installed(enabled: Bool)

    case expired(enabled: Bool)

    /// What view controller to show once user taps on `Enable VPN` button at one of places in the app.
    var enableVPNDestinationVC: UIViewController? {
      switch self {
      case .notPurchased, .expired: return BuyVPNViewController()
      case .purchased: return InstallVPNViewController()
      // Show nothing, the `Enable` button will now be used to connect and disconnect the vpn.
      case .installed: return nil
      }
    }
  }

  /// Current state ot the VPN service.
  static var vpnState: State {
    // User hasn't bought or restored the vpn yet.
    // If vpn plan expired, this preference is not set to nil but the date is set to year 1970
    // to force the UI to show expired state.
    if Preferences.VPN.expirationDate.value == nil { return .notPurchased }
    
    if hasExpired == true {
      return .expired(enabled: NEVPNManager.shared().isEnabled)
    }
    
    // The app has not expired yet and nothing is in keychain.
    // This means user has reinstalled the app while their vpn plan is still active.
    if helper.mainCredential?.mainCredential != true {
      return .notPurchased
    }
    
    // No VPN config set means the user could buy the vpn but hasn't gone through the second screen
    // to install the vpn and connect to a server.
    if NEVPNManager.shared().connection.status == .invalid { return .purchased }

    return .installed(enabled: isConnected)
  }

  /// Returns true if the user is connected to Brave's vpn at the moment.
  /// This will return true if the user is connected to other VPN.
  static var isConnected: Bool {
    helper.isConnected()
  }

  /// Returns the last used hostname for the vpn configuration.
  /// Returns nil if the hostname string is empty(due to some error when configuring it for example).
  static var hostname: String? {
    helper.mainCredential?.hostname
  }

  /// Whether the vpn subscription has expired.
  /// Returns nil if there has been no subscription yet (user never bought the vpn).
  static var hasExpired: Bool? {
    guard let expirationDate = Preferences.VPN.expirationDate.value else { return nil }

    return expirationDate < Date()
  }

  /// Location of last used server for the vpn configuration.
  static var serverLocation: String? {
    helper.mainCredential?.hostnameDisplayValue
  }

  /// Name of the purchased vpn plan.
  static var subscriptionName: String {
    guard let credential = GRDSubscriberCredential.current() else {
      logAndStoreError("subscriptionName: failed to retrieve subscriber credentials")
      return ""
    }
    let productId = credential.subscriptionType
    
    switch productId {
    case VPNProductInfo.ProductIdentifiers.monthlySub:
      return Strings.VPN.vpnSettingsMonthlySubName
    case VPNProductInfo.ProductIdentifiers.yearlySub:
      return Strings.VPN.vpnSettingsYearlySubName
    default:
      assertionFailure("Can't get product id")
      return ""
    }
  }
  
  // MARK: - Actions

  /// Reconnects to the vpn. Checks for server health first, if it's bad it tries to connect to another host.
  /// The vpn must be configured prior to that otherwise it does nothing.
  static func reconnect() {
    if reconnectPending {
      logAndStoreError("Can't reconnect the vpn while another reconnect is pending.")
      return
    }

    reconnectPending = true

    connectToVPN()
  }

  /// Disconnects the vpn.
  /// The vpn must be configured prior to that otherwise it does nothing.
  static func disconnect() {
    if reconnectPending {
      logAndStoreError("Can't disconnect the vpn while reconnect is still pending.")
      return
    }

    helper.disconnectVPN()
  }

  /// Connects to Guardian's server to validate locally stored receipt.
  /// Returns true if the receipt expired, false if not or nil if expiration status can't be determined.
  static func validateReceipt(receiptHasExpired: ((Bool?) -> Void)? = nil) {
    guard let receiptUrl = Bundle.main.appStoreReceiptURL,
          let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString else {
      receiptHasExpired?(nil)
      return
    }

    housekeepingApi.verifyReceipt(receipt, bundleId: "com.brave.ios.browser") { validSubscriptions, success, error in
      if !success {
        // Api call for receipt verification failed,
        // we do not know if the receipt has expired or not.
        receiptHasExpired?(nil)
        logAndStoreError("Api call for receipt verification failed")
        return
      }

      guard let validSubscriptions = validSubscriptions,
            let newestReceipt = validSubscriptions.sorted(by: { $0.expiresDate > $1.expiresDate }).first else {
        // Setting super old date to force expiration logic in the UI.
        Preferences.VPN.expirationDate.value = Date(timeIntervalSince1970: 1)
        receiptHasExpired?(true)
        logAndStoreError("vpn expired", printToConsole: false)
        return
      }

      Preferences.VPN.expirationDate.value = newestReceipt.expiresDate
      Preferences.VPN.freeTrialUsed.value = !newestReceipt.isTrialPeriod

      receiptHasExpired?(false)
    }
  }

  static func connectToVPN(completion: ((Bool) -> Void)? = nil) {
    if isConnected {
      helper.disconnectVPN()
    }

    // do they have EAP creds
    if GRDVPNHelper.activeConnectionPossible() {
      // just configure & connect, no need for 'first user' setup
      helper.configureAndConnectVPN { error, status in
        reconnectPending = false
        if status == .success {
          populateRegionDataIfNecessary()
          completion?(true)
        } else {
          completion?(false)
        }
      }
      
    } else {
      helper.configureFirstTimeUserPostCredential(nil) { success, error in
        reconnectPending = false
        if !success {
          if let error = error {
            logAndStoreError("configureFirstTimeUserPostCredential \(error)")
          }
          completion?(false)
          return
        }
        
        log.debug("Creating credentials and vpn connection successful")
        populateRegionDataIfNecessary()
        completion?(true)
      }
    }
  }
  
  /// Attempts to reconfigure the vpn by migrating to a new server.
  /// The new hostname is chosen randomly.
  /// Depending on user preference this will connect to either manually selected server region or a region closest to the user.
  /// This method disconnects from the vpn before reconfiguration is happening
  /// and reconnects automatically after reconfiguration is done.
  static func reconfigureVPN(completion: ((Bool) -> Void)? = nil) {
    helper.forceDisconnectVPNIfNecessary()
    GRDVPNHelper.clearVpnConfiguration()
    selectRegion(nil)

    connectToVPN() { status in
      completion?(status)
    }
  }

  /// Clears current vpn configuration and removes it from preferences.
  /// This method does not clear keychain items and jwt token.
  private static func clearConfiguration() {
    GRDVPNHelper.clearVpnConfiguration()

    NEVPNManager.shared().removeFromPreferences { error in
      if let error = error {
        logAndStoreError("Remove vpn error: \(error)")
      }
    }
  }

  static func clearCredentials() {
    GRDKeychain.removeGuardianKeychainItems()
    GRDKeychain.removeKeychanItem(forAccount: kKeychainStr_SubscriberCredential)
  }

  static func sendVPNWorksInBackgroundNotification() {

    switch vpnState {
    case .expired, .notPurchased, .purchased:
      break
    case .installed(let enabled):
      if !enabled || Preferences.VPN.vpnWorksInBackgroundNotificationShowed.value {
        break
      }

      let center = UNUserNotificationCenter.current()
      let notificationId = "vpnWorksInBackgroundNotification"

      center.requestAuthorization(options: [.provisional, .alert, .sound, .badge]) { granted, error in
        if let error = error {
          log.error("Failed to request notifications permissions: \(error)")
          return
        }

        if !granted {
          log.info("Not authorized to schedule a notification")
          return
        }

        center.getPendingNotificationRequests { requests in
          if requests.contains(where: { $0.identifier == notificationId }) {
            // Already has one scheduled no need to schedule again.
            // Should not happens since we push the notification right away.
            return
          }

          let content = UNMutableNotificationContent()
          content.title = Strings.VPN.vpnBackgroundNotificationTitle
          content.body = Strings.VPN.vpnBackgroundNotificationBody

          // Empty `UNNotificationTrigger` sends the notification right away.
          let request = UNNotificationRequest(identifier: notificationId, content: content,
                                              trigger: nil)

          center.add(request) { error in
            if let error = error {
              log.error("Failed to add notification: \(error)")
              return
            }

            Preferences.VPN.vpnWorksInBackgroundNotificationShowed.value = true
          }
        }
      }
    }
  }
  
  // MARK: - Region selection

  static func selectRegion(_ region: GRDRegion?) {
    helper.select(nil)
  }

  static var selectedRegion: GRDRegion? {
    helper.selectedRegion
  }
  
  static func useAutomaticRegion() {
    helper.select(nil)
  }
  
  static var isAutomaticRegion: Bool {
    helper.selectedRegion == nil
  }
  
  static func changeVPNRegion(_ region: GRDRegion?, completion: @escaping ((Bool) -> Void)) {
    helper.configureFirstTimeUser(with: region) { success, error in
      if success {
        log.debug("Changed VPN region to \(region?.regionName ?? "default selection")")
        completion(true)
      } else {
        log.debug("connection failed: \(String(describing: error))")
        completion(false)
      }
    }
  }
  
  static func populateRegionDataIfNecessary () {
    serverManager.getRegionsWithCompletion { regions in
      self.regions = regions
    }
  }
  
  // MARK: - VPN Alerts
  private static func shouldProcessVPNAlerts() -> Bool {
    if !Preferences.PrivacyReports.captureVPNAlerts.value {
      return false
    }
    
    switch vpnState {
    case .installed(let enabled):
      return enabled
    default:
      return false
    }
  }

  static func processVPNAlerts() {
    if !shouldProcessVPNAlerts() { return }
    
    Task {
      let (data, success, error) = await GRDGatewayAPI().events()
      if !success {
        log.error("VPN getEvents call failed")
        if let error = error {
          log.warning(error)
        }
        
        return
      }
      
      guard let alertsData = data["alerts"] else {
        log.error("Failed to unwrap json for vpn alerts")
        return
      }
      
      do {
        let dataAsJSON =
        try JSONSerialization.data(withJSONObject: alertsData, options: [.fragmentsAllowed])
        let decoded = try JSONDecoder().decode([BraveVPNAlertJSONModel].self, from: dataAsJSON)
        
        BraveVPNAlert.batchInsertIfNotExists(alerts: decoded)
      } catch {
        log.error("Failed parsing vpn alerts data")
      }
    }
  }
  
  // MARK: - Error Handling
  
  /// Stores a in-memory list of vpn errors encountered during current browsing session.
  private(set) static var errorLog = [(date: Date, message: String)]()
  private static let errorLogQueue = DispatchQueue(label: "com.brave.errorLogQueue")

  /// Prints out the error to the logger and stores it in a in memory array.
  /// This can be further used for a customer support form.
  private static func logAndStoreError(_ message: String, printToConsole: Bool = true) {
    if printToConsole {
      log.error(message)
    }

    // Extra safety here in case the log is spammed by many messages.
    // Early logs are more valuable for debugging, we do not rotate them with new entries.
    errorLogQueue.async {
      if errorLog.count < 1000 {
        errorLog.append((Date(), message))
      }
    }
  }
}
