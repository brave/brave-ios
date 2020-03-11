/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import BraveShared
import Lottie

class BraveTodayOnboardingStep1View: UIView {
    fileprivate var dialogImage: UIView?
    fileprivate var titleLabel: UILabel!
    fileprivate var messageLabel: UILabel!
    
    fileprivate let kPadding: CGFloat = 20.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        autoresizingMask = [.flexibleWidth]
        
        let dialogImage = UIImageView(image: UIImage(named: "placeholder_graphic_brave_today"))
        addSubview(dialogImage)
        self.dialogImage = dialogImage
       
        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        titleLabel.text = "Brave Today"
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontSizeToFitWidth = false
        addSubview(titleLabel)

        messageLabel = UILabel(frame: CGRect.zero)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.text = "New content, tailored privately to your interests, updated every hour."
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontSizeToFitWidth = false
        addSubview(messageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let width: CGFloat = bounds.width
        
        var imageFrame: CGRect = dialogImage?.frame ?? CGRect.zero
        if let dialogImage = dialogImage {
            let dialogImageSize = dialogImage.frame.size
            imageFrame.size = CGSize(width: dialogImageSize.width, height: dialogImageSize.height)
            imageFrame.origin.x = (width - imageFrame.width) / 2.0
            imageFrame.origin.y = kPadding * 2.0
            dialogImage.frame = imageFrame
        }
        
        let titleLabelSize: CGSize = titleLabel.sizeThatFits(CGSize(width: width - kPadding * 3.0, height: CGFloat.greatestFiniteMagnitude))
        var titleLabelFrame: CGRect = titleLabel.frame
        titleLabelFrame.size = titleLabelSize
        titleLabelFrame.origin.x = rint((width - titleLabelSize.width) / 2.0)
        titleLabelFrame.origin.y = imageFrame.maxY + kPadding
        titleLabel.frame = titleLabelFrame
        
        let messageLabelSize: CGSize = messageLabel.sizeThatFits(CGSize(width: width - kPadding * 4.0, height: CGFloat.greatestFiniteMagnitude))
        var messageLabelFrame: CGRect = messageLabel.frame
        messageLabelFrame.size = messageLabelSize
        messageLabelFrame.origin.x = rint((width - messageLabelSize.width) / 2.0)
        messageLabelFrame.origin.y = rint(titleLabelFrame.maxY + kPadding * 1.5 / 2.0)
        messageLabel.frame = messageLabelFrame
        
        var viewFrame: CGRect = frame
        viewFrame.size.width = width
        viewFrame.size.height = rint(messageLabelFrame.maxY + kPadding * 1.5)
        frame = viewFrame
    }
}

class BraveTodayOnboardingPopupView: PopupView {
    
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
        } else {
            dialogView.effect = UIBlurEffect(style: .dark)
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
