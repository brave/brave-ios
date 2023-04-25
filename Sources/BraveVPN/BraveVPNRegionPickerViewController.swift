// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveUI
import Lottie
import NetworkExtension
import GuardianConnect

class BraveVPNRegionPickerViewController: BraveVPNPickerViewController {
  private let regionList: [GRDRegion]

  private enum Section: Int, CaseIterable {
    case automatic = 0
    case regionList
  }

  /// This group monitors vpn connection status.
  private var dispatchGroup: DispatchGroup?
  private var vpnRegionChangeSuccess = false

  override init() {
    self.regionList = BraveVPN.regions
      .sorted { $0.displayName < $1.displayName }

    super.init()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    title = Strings.VPN.regionPickerTitle

    tableView.delegate = self
    tableView.dataSource = self
    
    super.viewDidLoad()
  }

  override func vpnConfigChanged(notification: NSNotification) {
    guard let connection = notification.object as? NEVPNConnection else { return }

    if connection.status == .connected {
      dispatchGroup?.leave()
      self.vpnRegionChangeSuccess = true
      dispatchGroup = nil
    }
  }
}

// MARK: - UITableView Data Source & Delegate

extension BraveVPNRegionPickerViewController: UITableViewDelegate, UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    Section.allCases.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    section == Section.automatic.rawValue ? 1 : regionList.count
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if section == Section.automatic.rawValue {
      return Strings.VPN.regionPickerAutomaticDescription
    }

    return nil
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath) as VPNRegionCell
    cell.accessoryType = .none

    switch indexPath.section {
    case Section.automatic.rawValue:
      cell.textLabel?.text = Strings.VPN.regionPickerAutomaticModeCellText
      if BraveVPN.isAutomaticRegion {
        cell.accessoryType = .checkmark
      }
    case Section.regionList.rawValue:
      guard let server = regionList[safe: indexPath.row] else { return cell }
      cell.textLabel?.text = server.displayName

      if server.displayName == BraveVPN.selectedRegion?.displayName {
        cell.accessoryType = .checkmark
      }
    default:
      assertionFailure("Section count out of bounds")
    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let region = regionList[safe: indexPath.row] else { return }

    // Tapped on the same cell, do nothing
    let sameRegionSelected = region.displayName == BraveVPN.selectedRegion?.displayName
    let sameAutomaticRegionSelected = indexPath.section == Section.automatic.rawValue && BraveVPN.isAutomaticRegion
    
    if sameRegionSelected || sameAutomaticRegionSelected {
      return
    }

    tableView.reloadData()

    isLoading = true

    // Implementation detail: nil region means we use an automatic way to connect to the host.
    let newRegion = indexPath.section == Section.automatic.rawValue ? nil : region

    self.dispatchGroup = DispatchGroup()

    BraveVPN.changeVPNRegion(to: newRegion) { [weak self] success in
      guard let self = self else { return }

      if !success {
        self.showErrorAlert(title: Strings.VPN.regionPickerErrorTitle,
                            message: Strings.VPN.regionPickerErrorMessage)
      }

      // Changing vpn server settings takes lot of time,
      // and nothing we can do about it as it relies on Apple apis.
      // Here we observe vpn status and we show success alert if it connected,
      // otherwise an error alert is show if it did not manage to connect in 60 seconds.
      self.dispatchGroup?.enter()

      DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
        self.vpnRegionChangeSuccess = false
        self.dispatchGroup?.leave()
        self.dispatchGroup = nil
      }

      self.dispatchGroup?.notify(queue: .main) { [weak self] in
        guard let self = self else { return }
        if self.vpnRegionChangeSuccess {

          self.dismiss(animated: true) {
            self.showSuccessAlert()
          }
        } else {
          self.showErrorAlert(title: Strings.VPN.regionPickerErrorTitle,
                              message: Strings.VPN.regionPickerErrorMessage)
        }
      }
    }
  }
}
