// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveCore
import BraveShared
import Shared
import pop

public enum BraveNotificationAction {
  public enum Rewards {
    /// The user opened the ad by either clicking on it directly or by swiping and clicking the "view" button
    case opened
    /// The user swiped the ad away
    case dismissed
    /// The user ignored the ad for a given amount of time for it to automatically dismiss
    case timedOut
    /// The user clicked the thumbs down button by swiping on the ad
    case disliked
  }
  public enum Wallet {
    /// The user clicked the wallet connection notification
    case connectWallet
    /// The user swiped the notification away
    case dismissed
    /// The user ignored the wallet connection notification for a given amount of time for it to automatically dismiss
    case timedOut
  }
  
  case rewards(Rewards)
  case wallet(Wallet)
}

public enum BraveNotificationPriority: Int, Comparable {
  case high = 1
  case low = 0
  
  public static func < (lhs: BraveNotificationPriority, rhs: BraveNotificationPriority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

public enum DismissPolicy {
  case automatic(after: TimeInterval = 5)
  case explicit
}

public protocol BraveNotification: AnyObject {
  var priority: BraveNotificationPriority { get }
  var view: UIView { get }
  var dismissAction: (() -> Void)? { get set }
  var dismissPolicy: DismissPolicy { get }
  var id: String { get }
  
  func willDismiss(timedout: Bool)
}

extension BraveNotification {
  public var dismissPolicy: DismissPolicy { .automatic() }
  public var priority: BraveNotificationPriority { .high }
}

public class RewardsNotification: NSObject, BraveNotification {
  public var view: UIView
  public var dismissAction: (() -> Void)?
  public var id: String
  public let ad: AdNotification
  
  private let rewardsHandler: (BraveNotificationAction.Rewards) -> Void

  public func willDismiss(timedout: Bool) {
    guard let adView = view as? AdView else { return }
    adView.setSwipeTranslation(0, animated: true)
    rewardsHandler(timedout ? .timedOut : .dismissed)
  }
  
  init(
    ad: AdNotification,
    rewardsHandler: @escaping (BraveNotificationAction.Rewards) -> Void
  ) {
    self.ad = ad
    self.view = AdView()
    self.rewardsHandler = rewardsHandler
    self.id = ad.uuid
    super.init()
    self.setup()
  }
  
  private func setup() {
    guard let adView = view as? AdView else { return }
    
    adView.adContentButton.titleLabel.text = ad.title
    adView.adContentButton.bodyLabel.text = ad.body

    adView.adContentButton.addTarget(self, action: #selector(tappedAdView(_:)), for: .touchUpInside)
    adView.openSwipeButton.addTarget(self, action: #selector(tappedOpen(_:)), for: .touchUpInside)
    adView.dislikeSwipeButton.addTarget(self, action: #selector(tappedDisliked(_:)), for: .touchUpInside)
    
    let swipePanGesture = UIPanGestureRecognizer(target: self, action: #selector(swipePannedAdView(_:)))
    swipePanGesture.delegate = self
    adView.addGestureRecognizer(swipePanGesture)
  }
  
  @objc private func tappedAdView(_ sender: AdContentButton) {
    guard let adView = sender.superview as? AdView else { return }
    if sender.transform.tx != 0 {
      adView.setSwipeTranslation(0)
      return
    }
    dismissAction?()
    rewardsHandler(.opened)
  }
  
  @objc private func tappedOpen(_ sender: AdSwipeButton) {
    dismissAction?()
    rewardsHandler(.opened)
  }
  
  @objc private func tappedDisliked(_ sender: AdSwipeButton) {
    dismissAction?()
    rewardsHandler(.disliked)
  }
  
  // Distance travelled after decelerating to zero velocity at a constant rate
  private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
    return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
  }
  
  private let actionTriggerThreshold: CGFloat = 180.0
  private let actionRestThreshold: CGFloat = 90.0
  
  private var swipeState: CGFloat = 0
  @objc private func swipePannedAdView(_ pan: UIPanGestureRecognizer) {
    guard let adView = pan.view as? AdView else { return }
    switch pan.state {
    case .began:
      swipeState = adView.adContentButton.transform.tx
    case .changed:
      let tx = swipeState + pan.translation(in: adView).x
      if tx < -actionTriggerThreshold && !adView.dislikeSwipeButton.isHighlighted {
        UIImpactFeedbackGenerator(style: .medium).bzzt()
      }
      adView.dislikeSwipeButton.isHighlighted = tx < -actionTriggerThreshold
      adView.adContentButton.transform.tx = min(0, tx)
      adView.setNeedsLayout()
    case .ended:
      let velocity = pan.velocity(in: adView).x
      let tx = swipeState + pan.translation(in: adView).x
      let projected = project(initialVelocity: velocity, decelerationRate: UIScrollView.DecelerationRate.normal.rawValue)
      if /*tx > actionTriggerThreshold ||*/ tx < -actionTriggerThreshold {
        adView.setSwipeTranslation(0, animated: true, panVelocity: velocity)
        dismissAction?()
        rewardsHandler(tx > 0 ? .opened : .disliked)
        break
      } else if /*tx + projected > actionRestThreshold ||*/ tx + projected < -actionRestThreshold {
        adView.setSwipeTranslation((tx + projected) > 0 ? actionRestThreshold : -actionRestThreshold, animated: true, panVelocity: velocity)
        break
      }
      fallthrough
    case .cancelled:
      adView.setSwipeTranslation(0, animated: true)
    default:
      break
    }
  }
}

extension RewardsNotification: UIGestureRecognizerDelegate {
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: pan.view)
      // Horizontal only
      return abs(velocity.x) > abs(velocity.y)
    }
    return false
  }
}

public class WalletNotification: NSObject, BraveNotification {
  struct Constant {
    static let id = "wallet-notification"
  }
  
  public var priority: BraveNotificationPriority
  public var view: UIView
  public var id: String { WalletNotification.Constant.id }
  public var dismissAction: (() -> Void)?
  
  private let walletHandler: (BraveNotificationAction.Wallet) -> Void
  
  public func willDismiss(timedout: Bool) {
    walletHandler(timedout ? .timedOut : .dismissed)
  }
  
  init(
    priority: BraveNotificationPriority,
    walletHandler: @escaping (BraveNotificationAction.Wallet) -> Void
  ) {
    self.priority = priority
    self.view = WalletConnectionView()
    self.walletHandler = walletHandler
    super.init()
    self.setup()
  }
  
  private func setup() {
    guard let walletPanel = view as? WalletConnectionView else { return }
    walletPanel.addTarget(self, action: #selector(tappedWalletConnectionView(_:)), for: .touchUpInside)
  }
  
  @objc private func tappedWalletConnectionView(_ sender: WalletConnectionView) {
    dismissAction?()
    walletHandler(.connectWallet)
  }
}

public class BraveNotificationsPresenter: UIViewController {
  private var notificationsQueue: [BraveNotification] = []
  private var widthAnchor: NSLayoutConstraint?
  private var displayedNotifications: [BraveNotification] = []
  private var visibleNotification: BraveNotification?
  
  public override func loadView() {
    view = View(frame: UIScreen.main.bounds)
  }
  
  public func display(notification: BraveNotification, presentingController: UIViewController) {
    // check the priority of the notification
    if let visibleNotification = visibleNotification {
      if notification.priority <= visibleNotification.priority {
        // won't display if the incoming notification has the same or lower priority
        // put it in queue
        safeInsert(notification: notification)
        return
      } else {
        // will hide the current visible notification and display the incoming notification
        // if the notification has higher priority
        self.hide(visibleNotification)
      }
    }
    
    if parent == nil {
      presentingController.addChild(self)
      presentingController.view.addSubview(view)
      didMove(toParent: presentingController)
    }
    
    view.snp.makeConstraints {
      $0.edges.equalTo(presentingController.view.safeAreaLayoutGuide.snp.edges)
    }
    
    let notificationView = notification.view
    view.addSubview(notificationView)
    notificationView.snp.makeConstraints {
      $0.leading.greaterThanOrEqualTo(view).inset(8)
      $0.trailing.lessThanOrEqualTo(view).inset(8)
      $0.centerX.equalTo(view)
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.top.greaterThanOrEqualTo(view).offset(4) // Makes sure in landscape its at least 4px from the top
      
      if UIDevice.current.userInterfaceIdiom != .pad {
        $0.width.equalTo(view).priority(.high)
      }
    }
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      widthAnchor = notificationView.widthAnchor.constraint(equalToConstant: 0.0)
      widthAnchor?.priority = .defaultHigh
      widthAnchor?.isActive = true
    }
    
    view.layoutIfNeeded()
    
    notification.dismissAction = { [weak self] in
      guard let self = self else { return }
      self.hide(notification)
    }
    animateIn(adView: notificationView)
    if case .automatic(let interval) = notification.dismissPolicy {
      setupTimeoutTimer(for: notification, interval: interval)
    }
    visibleNotification = notification
    displayedNotifications.append(notification)
    
    // Add common swip gesture (swip-up to dismiss)
    let dismissPanGesture = UIPanGestureRecognizer(target: self, action: #selector(dismissPannedAdView(_:)))
    dismissPanGesture.delegate = self
    notificationView.addGestureRecognizer(dismissPanGesture)
  }
  
  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      let constant = max(view.bounds.width, view.bounds.height) * 0.40
      widthAnchor?.constant = ceil(constant * UIScreen.main.scale) / UIScreen.main.scale
    }
  }
  
  public func removeRewardsNotification(with id: String) {
    if let index = notificationsQueue.firstIndex(where: { $0.id == id }) {
      notificationsQueue.remove(at: index)
    }
  }
  
  public func hide(_ notification: BraveNotification) {
    hide(notificationView: notification.view, velocity: nil)
  }
  
  private func hide(notificationView: UIView, velocity: CGFloat?) {
    visibleNotification = nil
    animateOut(adView: notificationView, velocity: velocity) { [weak self] in
      guard let self = self else { return }
      notificationView.removeFromSuperview()
      if self.visibleNotification == nil {
        if self.notificationsQueue.isEmpty {
          self.willMove(toParent: nil)
          self.view.removeFromSuperview()
          self.removeFromParent()
        } else {
          guard let presentingController = self.parent else { return }
          self.display(notification: self.notificationsQueue.popLast()!, presentingController: presentingController)
        }
      }
    }
  }
  
  private func safeInsert(notification: BraveNotification) {
    // We will skip duplication checking for notifications that have empty id. These notifications are usually custom ads
    if !notification.id.isEmpty,
       notificationsQueue.contains(where: { $0.id == notification.id }) {
      return
    }
    // Kepp wallet notification alway the last to display
    let index: Int = notificationsQueue.first?.id == WalletNotification.Constant.id ? 1 : 0
    notificationsQueue.insert(notification, at: index)
  }
  
  deinit {
    dismissTimers.forEach({ $0.value.invalidate() })
  }
  
  // MARK: - Actions
  
  private var dismissTimers: [UIView: Timer] = [:]
  
  private func setupTimeoutTimer(for notification: BraveNotification, interval: TimeInterval) {
    if let timer = dismissTimers[notification.view] {
      // Invalidate and reschedule
      timer.invalidate()
    }
    var dismissInterval = interval
    if !AppConstants.buildChannel.isPublic, let override = Preferences.Rewards.adsDurationOverride.value, override > 0 {
      dismissInterval = TimeInterval(override)
    }
    dismissTimers[notification.view] = Timer.scheduledTimer(withTimeInterval: dismissInterval, repeats: false, block: { [weak self] _ in
      guard let self = self else { return }
      self.hide(notification)
      notification.willDismiss(timedout: true)
    })
  }
  
  // Distance travelled after decelerating to zero velocity at a constant rate
  func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
    return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
  }
  
  private var panState: CGPoint = .zero
  @objc private func dismissPannedAdView(_ pan: UIPanGestureRecognizer) {
    guard let notificationView = pan.view else { return }
    
    switch pan.state {
    case .began:
      panState = notificationView.center
      // Make sure to stop the dismiss timer
      dismissTimers[notificationView]?.invalidate()
    case .changed:
      notificationView.transform.ty = min(0, pan.translation(in: notificationView).y)
    case .ended:
      let velocity = pan.velocity(in: notificationView).y
      let y = min(panState.y, panState.y + pan.translation(in: notificationView).y)
      let projected = project(initialVelocity: velocity, decelerationRate: UIScrollView.DecelerationRate.normal.rawValue)
      if y + projected < 0 {
        guard let notification = self.displayedNotifications.first(where: { $0.view == notificationView }) else { return }
        hide(notificationView: notificationView, velocity: velocity)
        notification.willDismiss(timedout: false)
        break
      }
      fallthrough
    case .cancelled:
      // Re-setup timeout timer
      guard let notification = self.displayedNotifications.first(where: { $0.view == notificationView }) else { return }
      if case .automatic(let interval) = notification.dismissPolicy {
        setupTimeoutTimer(for: notification, interval: interval)
      }
      notificationView.layer.springAnimate(property: kPOPLayerTranslationY, key: "translation.y") { animation, _ in
        animation.toValue = 0
      }
    default:
      break
    }
  }
  
  // MARK: - Animations
  
  private func animateIn(adView: UIView) {
    adView.layoutIfNeeded()
    adView.layer.transform = CATransform3DMakeTranslation(0, -adView.bounds.size.height, 0)
    
    adView.layer.springAnimate(property: kPOPLayerTranslationY, key: "translation.y") { animation, _ in
      animation.toValue = 0
    }
  }
  
  private func animateOut(adView: UIView, velocity: CGFloat? = nil, completion: @escaping () -> Void) {
    adView.layoutIfNeeded()
    let y = adView.frame.minY - view.safeAreaInsets.top - adView.transform.ty
    
    adView.layer.springAnimate(property: kPOPLayerTranslationY, key: "translation.y") { animation, _ in
      animation.toValue = -(view.safeAreaInsets.top + y + adView.bounds.size.height)
      if let velocity = velocity {
        animation.velocity = velocity
      }
      animation.completionBlock = { _, _ in
        completion()
      }
    }
  }
}

extension BraveNotificationsPresenter {
  class View: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      // Only allow tapping the ad part of this VC
      if let view = super.hitTest(point, with: event), view.superview is AdView {
        return view
      } else if let view = super.hitTest(point, with: event), view is WalletConnectionView {
        return view
      }
      return nil
    }
  }
}

extension BraveNotificationsPresenter: UIGestureRecognizerDelegate {
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: pan.view)
      if let adView = pan.view as? AdView, adView.swipeTranslation != 0 {
        // dislike mode but swip vertically
        if let notification = displayedNotifications.first(where: { $0.view == adView }) {
          if case .automatic(let interval) = notification.dismissPolicy {
            setupTimeoutTimer(for: notification, interval: interval)
          }
        }
        // Vertical only and only if the user isn't in a swipe transform for a Rewards notification
        return false
      }
      return abs(velocity.y) > abs(velocity.x)
    }
    return false
  }
}

extension BraveNotificationsPresenter {
  
  /// Display a "My First Ad" on a presenting controller and be notified if they tap it
  public static func displayFirstAd(on presentingController: UIViewController, completion: @escaping (BraveNotificationAction.Rewards, URL) -> Void) {
    let notificationPresenter = BraveNotificationsPresenter()
    let notification = AdNotification.customAd(
        title: Strings.Ads.myFirstAdTitle,
        body: Strings.Ads.myFirstAdBody,
      url: "https://brave.com/my-first-ad"
    )
    
    guard let targetURL = URL(string: notification.targetURL) else {
      assertionFailure("My First Ad URL is not valid: \(notification.targetURL)")
      return
    }
    
    let rewardsNotification = RewardsNotification(ad: notification) { action in
      completion(action, targetURL)
    }
    notificationPresenter.display(notification: rewardsNotification, presentingController: presentingController)
  }
}
