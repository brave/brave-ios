/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import BraveShared

class AlertPopupView: PopupView {
    
    fileprivate var dialogImage: UIImageView?
    fileprivate var titleLabel: UILabel!
    fileprivate var messageLabel: UILabel!
    fileprivate var containerView: UIView!
    
    fileprivate let kAlertPopupScreenFraction: CGFloat = 0.8
    fileprivate let kPadding: CGFloat = 20.0
    
    init(image: UIImage?, title: String, message: String) {
        super.init(frame: CGRect.zero)
        
        overlayDismisses = false
        defaultShowType = .normal
        defaultDismissType = .noAnimation
        presentsOverWindow = true
        
        containerView = UIView(frame: CGRect.zero)
        containerView.autoresizingMask = [.flexibleWidth]
        
        if let image = image {
            let di = UIImageView(image: image)
            containerView.addSubview(di)
            dialogImage = di
        }
        
        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.textColor = BraveUX.GreyJ
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.bold)
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        messageLabel = UILabel(frame: CGRect.zero)
        messageLabel.textColor = BraveUX.GreyH
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        updateSubviews()
        
        setPopupContentView(view: containerView)
        setStyle(popupStyle: .dialog)
        setDialogColor(color: BraveUX.PopupDialogColorLight)
    }
    
    func updateSubviews() {
        titleLabel.adjustsFontSizeToFitWidth = false
        messageLabel.adjustsFontSizeToFitWidth = false

        _updateSubviews()
        
        let paddingHeight: CGFloat = padding * 3.0
        let externalContentHeight: CGFloat = dialogButtons.count == 0 ? paddingHeight
            : kPopupDialogButtonHeight + paddingHeight
        
        if containerView.frame.height + externalContentHeight > UIScreen.main.bounds.height {
            let desiredHeight: CGFloat = UIScreen.main.bounds.height - externalContentHeight
            let resizePercentage = desiredHeight / containerView.frame.height
            titleLabel.adjustsFontSizeToFitWidth = true
            messageLabel.adjustsFontSizeToFitWidth = true
            _updateSubviews(resizePercentage)
        }
    }
    
    fileprivate func _updateSubviews(_ resizePercentage: CGFloat = 1.0) {
        let width: CGFloat = dialogWidth
        
        var imageFrame: CGRect = dialogImage?.frame ?? CGRect.zero
        if let dialogImage = dialogImage {
            imageFrame.size = CGSize(width: dialogImage.image!.size.width * resizePercentage, height: dialogImage.image!.size.height * resizePercentage)
            imageFrame.origin.x = (width - imageFrame.width) / 2.0
            imageFrame.origin.y = kPadding * 2.0 * resizePercentage
            dialogImage.frame = imageFrame
        }
        
        var titleLabelSize: CGSize = titleLabel.sizeThatFits(CGSize(width: width - kPadding * 3.0, height: CGFloat.greatestFiniteMagnitude))
        titleLabelSize.height = titleLabelSize.height * resizePercentage
        var titleLabelFrame: CGRect = titleLabel.frame
        titleLabelFrame.size = titleLabelSize
        titleLabelFrame.origin.x = rint((width - titleLabelSize.width) / 2.0)
        titleLabelFrame.origin.y = imageFrame.maxY + kPadding * resizePercentage
        titleLabel.frame = titleLabelFrame
        
        var messageLabelSize: CGSize = messageLabel.sizeThatFits(CGSize(width: width - kPadding * 4.0, height: CGFloat.greatestFiniteMagnitude))
        messageLabelSize.height = messageLabelSize.height * resizePercentage
        var messageLabelFrame: CGRect = messageLabel.frame
        messageLabelFrame.size = messageLabelSize
        messageLabelFrame.origin.x = rint((width - messageLabelSize.width) / 2.0)
        messageLabelFrame.origin.y = rint(titleLabelFrame.maxY + kPadding * 1.5 / 2.0 * resizePercentage)
        messageLabel.frame = messageLabelFrame
        
        var containerViewFrame: CGRect = containerView.frame
        containerViewFrame.size.width = width
        containerViewFrame.size.height = rint(messageLabelFrame.maxY + kPadding * 1.5 * resizePercentage)
        containerView.frame = containerViewFrame
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateSubviews()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
