// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import Shared
import Preferences
import StoreKit
import os.log
import DesignSystem

class BuyVPNViewController: VPNSetupLoadingController {
    
  let iapObserver: IAPObserver
  
  var activeSubcriptionChoice: SubscriptionType = .yearly {
    didSet {
      buyVPNView.activeSubcriptionChoice = activeSubcriptionChoice
    }
  }
  
  init(iapObserver: IAPObserver) {
    self.iapObserver = iapObserver
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }
  
  private var buyVPNView = BuyVPNView(with: .yearly)
  
  override func viewDidLoad() {
    super.viewDidLoad()

    title = Strings.VPN.vpnName
    view.backgroundColor = BraveVPNCommonUI.UX.purpleBackgroundColor

    navigationItem.standardAppearance = BraveVPNCommonUI.navigationBarAppearance
    navigationItem.scrollEdgeAppearance = BraveVPNCommonUI.navigationBarAppearance

    navigationItem.rightBarButtonItem = .init(
      title: Strings.VPN.restorePurchases, style: .done,
      target: self, action: #selector(restorePurchasesAction))
    
    let tryButton = BraveGradientButton(gradient: .lightGradient01).then {
      $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
      $0.titleLabel?.textAlignment = .center
      $0.setTitle(Strings.VPN.freeTrialPeriodAction.uppercased(), for: .normal)
      
      $0.snp.makeConstraints {
        $0.height.equalTo(50)
      }
      
      $0.layer.do {
        $0.cornerRadius = 12
        $0.cornerCurve = .continuous
        $0.masksToBounds = true
      }
      
      $0.addTarget(self, action: #selector(startSubscriptionAction), for: .touchUpInside)
    }
  
    let seperator = UIView().then {
      $0.backgroundColor = UIColor.white.withAlphaComponent(0.1)
      $0.snp.makeConstraints { make in
        make.height.equalTo(1)
      }
    }
        
    view.addSubview(buyVPNView)
    view.addSubview(seperator)
    view.addSubview(tryButton)
    
    buyVPNView.snp.makeConstraints {
      $0.leading.trailing.top.equalToSuperview()
    }
    
    seperator.snp.makeConstraints() {
      $0.top.equalTo(buyVPNView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
    }
    
    tryButton.snp.makeConstraints() {
      $0.top.equalTo(seperator.snp.bottom).inset(-12)
      $0.leading.trailing.bottom.equalToSuperview().inset(24)
    }

    buyVPNView.monthlySubButton
      .addTarget(self, action: #selector(monthlySubscriptionAction), for: .touchUpInside)

    buyVPNView.yearlySubButton
      .addTarget(self, action: #selector(yearlySubscriptionAction), for: .touchUpInside)

    iapObserver.delegate = self

    Preferences.VPN.popupShowed.value = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // navigationItem.standardAppearance does not support tinting the back button for some
    // reason, so we still must apply a custom tint to the bar
    navigationController?.navigationBar.tintColor = .white
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Reset styling set above
    navigationController?.navigationBar.tintColor = UINavigationBar.appearance().tintColor
  }

  // MARK: - Button Actions
  
  @objc func yearlySubscriptionAction() {
    activeSubcriptionChoice = .yearly
  }
  
  @objc func monthlySubscriptionAction() {
    activeSubcriptionChoice = .monthly
  }

  @objc func closeView() {
    dismiss(animated: true)
  }

  @objc func restorePurchasesAction() {
    isLoading = true
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
  
  @objc func startSubscriptionAction() {
    addPaymentForSubcription(type: activeSubcriptionChoice)
  }
  
  private func addPaymentForSubcription(type: SubscriptionType) {
    var subscriptionProduct: SKProduct?
    
    switch type {
    case .yearly:
      subscriptionProduct = VPNProductInfo.yearlySubProduct
    case .monthly:
      subscriptionProduct = VPNProductInfo.monthlySubProduct
    }
    
    guard let subscriptionProduct = subscriptionProduct else {
      Logger.module.error("Failed to retrieve \(type.rawValue) subcription product")
      return
    }
    
    isLoading = true
    let payment = SKPayment(product: subscriptionProduct)
    SKPaymentQueue.default().add(payment)
  }
}

// MARK: - IAPObserverDelegate

extension BuyVPNViewController: IAPObserverDelegate {
  func purchasedOrRestoredProduct(validateReceipt: Bool) {
    DispatchQueue.main.async {
      self.isLoading = false
    }
    
    // Not using `push` since we don't want the user to go back.
    DispatchQueue.main.async {
      self.navigationController?.setViewControllers(
        [InstallVPNViewController()],
        animated: true)
    }
    
    if validateReceipt {
      BraveVPN.validateReceipt()
    }
  }

  func purchaseFailed(error: IAPObserver.PurchaseError) {
    DispatchQueue.main.async {
      self.isLoading = false

      // User intentionally tapped to cancel purchase , no need to show any alert on our side.
      if case .transactionError(let err) = error, err?.code == SKError.paymentCancelled {
        return
      }

      // For all other errors, we attach associated code for easier debugging.
      // See SKError.h for list of all codes.
      let message = Strings.VPN.vpnErrorPurchaseFailedBody

      let alert = UIAlertController(
        title: Strings.VPN.vpnErrorPurchaseFailedTitle,
        message: message,
        preferredStyle: .alert)
      let ok = UIAlertAction(title: Strings.OKString, style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true)
    }
  }
}

class VPNSetupLoadingController: UIViewController {
  
  private var overlayView: UIView?

  var isLoading: Bool = false {
    didSet {
      overlayView?.removeFromSuperview()

      // Disable Action bar button while loading
      navigationItem.rightBarButtonItem?.isEnabled = !isLoading

      // Prevent dismissing the modal by swipe
      navigationController?.isModalInPresentation = isLoading == true

      if !isLoading { return }

      let overlay = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let activityIndicator = UIActivityIndicatorView().then {
          $0.startAnimating()
          $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          $0.style = .large
          $0.color = .white
        }

        $0.addSubview(activityIndicator)
      }

      view.addSubview(overlay)
      overlay.snp.makeConstraints {
        $0.edges.equalToSuperview()
      }

      overlayView = overlay
    }
  }
}
