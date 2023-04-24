// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import BraveUI
import Lottie
import NetworkExtension
import GuardianConnect

class BraveVPNProtocolPickerViewController: BraveVPNPickerViewController {
  
  private let regionList: [GRDRegion]

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
    title = "Transport Protocol"

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

extension BraveVPNProtocolPickerViewController: UITableViewDelegate, UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    regionList.count
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return "Please select your preferred transport protocol. Once switched your existing VPN credentials will be cleared and you will be reconnected if a VPN connection is currently established"
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(for: indexPath) as VPNRegionCell
    cell.accessoryType = .none

    guard let server = regionList[safe: indexPath.row] else { return cell }
    cell.textLabel?.text = server.displayName

    if server.displayName == BraveVPN.selectedRegion?.displayName {
      cell.accessoryType = .checkmark
    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

  }
}
