// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import LinkPresentation
import BraveShared
import BraveUI
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
    
    func setupGlobalShieldsActivityController(theme: Theme) -> UIActivityViewController {
        let backgroundImage = #imageLiteral(resourceName: "share-activity-background")
        
        let statsView = UIView(frame: CGRect(size: backgroundImage.size)).then {
            let backgroundImageView = UIImageView(image: backgroundImage)
            let statsInfoView = BraveShieldStatsView().then {
                $0.applyTheme(theme)
            }
            
            $0.addSubview(backgroundImageView)
            $0.addSubview(statsInfoView)
            
            backgroundImageView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            statsInfoView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.centerY.equalToSuperview()
                $0.height.equalToSuperview().multipliedBy(0.3)
                $0.width.equalToSuperview().multipliedBy(0.65)
            }
        }
    
        let contentView = UIView(frame: CGRect(width: statsView.frame.width, height: statsView.frame.height + 85)).then {
            $0.backgroundColor = UIColor(rgb: 0xBE5269)
            $0.layer.borderWidth = 1
        }
        
        contentView.addSubview(statsView)
        statsView.frame = CGRect(origin: .zero,
                                 size: CGSize(width: statsView.frame.width, height: statsView.frame.height))
        
        let snapshotImage = statsView.snapshot
        let snapshotImageWithText = contentView.snapshot.textToImage(drawText: Strings.ShieldEducation.shareDescriptionTitle,
                                                                     atPoint: CGPoint(x: 0, y: statsView.frame.height + 20)) ?? snapshotImage

        let activityViewController = UIActivityViewController(activityItems: [ImageActivityItemSource(image: snapshotImage,
                                                                                                      imageWithText: snapshotImageWithText),
                                                                              OptionalTextActivityItemSource(text: Strings.ShieldEducation.shareDescriptionTitle)],
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
        
        return activityValueType == nil ? text : nil
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
        
        return activityValueType == nil ? image : imageWithText
    }
    
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let imageProvider = NSItemProvider(object: image)
        
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = Strings.ShieldEducation.shareDescriptionTitle
        return metadata
    }
}
