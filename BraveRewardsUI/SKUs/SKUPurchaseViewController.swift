// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveRewards

public class SKUPurchaseViewController: UIViewController, UIViewControllerTransitioningDelegate {
  
  private let rewards: BraveRewards
  private let amount: Double
  private let ledgerObserver: LedgerObserver
  private var openBraveTermsOfSale: () -> Void
  
  public init(rewards: BraveRewards, amount: Double, openBraveTermsOfSale: @escaping () -> Void) {
    self.rewards = rewards
    self.amount = amount
    self.openBraveTermsOfSale = openBraveTermsOfSale
    self.ledgerObserver = LedgerObserver(ledger: rewards.ledger)
    
    super.init(nibName: nil, bundle: nil)
    
    modalPresentationStyle = .overCurrentContext
    if #available(iOS 13.0, *) {
      isModalInPresentation = true
    }
    transitioningDelegate = self
    
    self.rewards.ledger.add(self.ledgerObserver)
    setupLedgerObserver()
    
    rewards.ledger.fetchBalance(nil)
  }
  
  @available(*, unavailable)
  required init(coder: NSCoder) {
    fatalError()
  }
  
  private var purchaseView: SKUPurchaseView {
    return view as! SKUPurchaseView // swiftlint:disable:this force_cast
  }
  
  public override func loadView() {
    view = SKUPurchaseView()
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    title = Strings.SKUPurchaseTitle
    
    purchaseView.detailView.dismissButton.addTarget(self, action: #selector(tappedDismissButton), for: .touchUpInside)
    purchaseView.gesturalDismissExecuted = { [unowned self] in
      self.dismiss(animated: true)
    }
    purchaseView.buyButton.buyButton.addTarget(self, action: #selector(tappedBuyButton), for: .touchUpInside)
    purchaseView.buyButton.disclaimerLabel.onLinkedTapped = { [weak self] _ in
      self?.openBraveTermsOfSale()
    }
    
    updateInsufficentBalanceState()
  }
  
  func setupLedgerObserver() {
    ledgerObserver.fetchedBalance = { [weak self] in
      self?.updateInsufficentBalanceState()
    }
  }
  
  @objc private func tappedDismissButton() {
    dismiss(animated: true)
  }
  
  @objc private func tappedBuyButton() {
    // Start order transactions
    purchaseView.viewState = .processing
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.purchaseView.viewState = .complete
    }
  }
  
  private func updateInsufficentBalanceState() {
    guard isViewLoaded, let balance = rewards.ledger.balance else { return }
    let insufficientFunds = balance.total < amount
    purchaseView.isShowingInsufficientFundsView = insufficientFunds
  }
  
  // MARK: -
  
  override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if UIDevice.current.userInterfaceIdiom == .phone {
      return .portrait
    }
    return .all
  }
  
  // MARK: - UIViewControllerTransitioningDelegate
  
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: purchaseView, direction: .presenting)
  }
  
  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return BasicAnimationController(delegate: purchaseView, direction: .dismissing)
  }
}
