// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Kingfisher

class BraveTodaySourcesPopupView: PopupView {
    
    fileprivate var containerView: UIView!
    
    fileprivate var onboardingStep: OnboardingStep = .step1
    
    var completionHandler: ((Bool) -> Void)?
    
    var isShown = false
    
    enum OnboardingStep {
        case step1
        case step2
        case step3
    }
    
    fileprivate let kAlertPopupScreenFraction: CGFloat = 0.8
    fileprivate let kPadding: CGFloat = 20.0
    
    init(completed: ((Bool) -> Void)? = nil) {
        super.init(frame: CGRect.zero)
        
        if completed != nil {
            completionHandler = completed
        }
        
        overlayDismisses = false
        defaultShowType = .normal
        defaultDismissType = .noAnimation
        presentsOverWindow = true
        
        updateContentView(step: .step1)
        
        setStyle(popupStyle: .dialog)
        setDialogColor(color: UIColor.white.withAlphaComponent(0.2))
        setOverlayColor(color: UIColor.black.withAlphaComponent(0.15), animate: false)
        
        if #available(iOS 13.0, *) {
            dialogView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        }
        
        addButton(title: "Continue", type: .primary, fontSize: 16) { () -> PopupViewDismissType in
            self.completionHandler?(true)
            return .normal
        }
    }
    
    fileprivate func updateContentView(step: OnboardingStep) {
        switch step {
        case .step1:
            setPopupContentView(view: BraveTodayOnboardingStep1View())
        case .step2:
            setPopupContentView(view: BraveTodayOnboardingStep1View())
        case .step3:
            setPopupContentView(view: BraveTodayOnboardingStep1View())
        }
        
        onboardingStep = step
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func showWithType(showType: PopupViewShowType) {
        guard !isShown else { return }
        
        super.showWithType(showType: showType)
        
        isShown = true
    }
    
    override func dismissWithType(dismissType: PopupViewDismissType) {
        guard isShown else { return }
        
        super.dismissWithType(dismissType: dismissType)
        
        isShown = false
    }
}
