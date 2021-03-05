// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import LinkPresentation
import Shared

// MARK: - ActivityTypeValue

public enum ActivityTypeValue: String, CaseIterable {
    case whatsapp = "net.whatsapp.WhatsApp.ShareExtension"
    case slack = "com.tinyspeck.chatlyio.share"
    case gmail = "com.google.Gmail.ShareExtension"
    case instagram = "com.burbn.instagram.shareextension"
}

// MARK: - ShieldsActivityItemSourceProvider

final class ShieldsActivityItemSourceProvider {
    
    static let shared = ShieldsActivityItemSourceProvider()
    
    func setupGlobalShieldsActivityController(height: CGFloat, theme: Theme) -> UIActivityViewController {
        let statsView = BraveShieldStatsView(frame: CGRect(width: height, height: 110)).then {
            $0.applyTheme(theme)
            $0.backgroundColor = .darkGray
        }
        
        let contentView = UIView(frame: CGRect(width: statsView.frame.width, height: statsView.frame.height + 85)).then {
            $0.backgroundColor = .darkGray
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.black.cgColor
        }
        
        contentView.addSubview(statsView)
        statsView.frame = CGRect(origin: .zero,
                                 size: CGSize(width: statsView.frame.width, height: statsView.frame.height))
        
        let snapshotImage = statsView.snapshot
        let snapshotImageWithText = contentView.snapshot.textToImage(drawText: Strings.SocialSharing.shareDescriptionTitle,
                                                                     atPoint: CGPoint(x: 0, y: statsView.frame.height + 20)) ?? snapshotImage

        let activityViewController = UIActivityViewController(activityItems: [ImageActivityItemSource(image: snapshotImage,
                                                                                                      imageWithText: snapshotImageWithText),
                                                                              OptionalTextActivityItemSource(text: Strings.SocialSharing.shareDescriptionTitle)],
                                                              applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [.openInIBooks, .saveToCameraRoll, .assignToContact]
        
        return activityViewController
    }
    
}

// MARK: - OptionalTextActivityItemSource

class OptionalTextActivityItemSource: NSObject, UIActivityItemSource {
    
    let text: String
    
    weak var viewController: UIViewController?
    
    init(text: String) {
        self.text = text
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let activityValueType = ActivityTypeValue.allCases.first(where: { $0.rawValue == activityType?.rawValue })
        
        if activityValueType != nil {
            return nil
        } else {
            return text
        }
    }
}

// MARK: - ImageActivityItemSource

class ImageActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let imageWithText: UIImage
    
    init(image: UIImage, imageWithText: UIImage) {
        self.image = image
        self.imageWithText = imageWithText
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let activityValueType = ActivityTypeValue.allCases.first(where: { $0.rawValue == activityType?.rawValue })
        
        if activityValueType != nil {
            return imageWithText
        } else {
            return image
        }
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let imageProvider = NSItemProvider(object: image)
        
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = Strings.SocialSharing.shareDescriptionTitle
        return metadata
    }
}
