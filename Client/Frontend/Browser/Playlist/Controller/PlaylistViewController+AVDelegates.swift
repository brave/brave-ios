// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVKit
import AVFoundation
import Shared

// MARK: - AVPictureInPictureControllerDelegate

extension PlaylistViewController: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController = splitViewController?.parent
        
        if UIDevice.isIpad {
            splitViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if UIDevice.isPhone {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            if UIDevice.isIpad {
                attachPlayerView()
            }
            delegate.playlistRestorationController = nil
        }
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        
        let alert = UIAlertController(title: Strings.PlayList.sorryAlertTitle,
                                      message: Strings.PlayList.pictureInPictureErrorTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.PlayList.okayButtonTitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
           let restorationController = delegate.playlistRestorationController {
            restorationController.modalPresentationStyle = .fullScreen
            if view.window == nil {
                delegate.browserViewController.present(restorationController, animated: true) {
                    delegate.playlistRestorationController = nil
                }
            } else {
                delegate.playlistRestorationController = nil
            }
        }
        
        completionHandler(true)
    }
}
