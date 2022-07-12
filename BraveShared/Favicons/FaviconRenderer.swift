// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveCore

/// A class for rendering a FavIcon onto a `UIImage`
class FaviconRenderer {
  private var task: DispatchWorkItem?

  deinit {
    task?.cancel()
  }

  func loadIcon(for url: URL, persistent: Bool, completion: ((Favicon?) -> Void)?) {
    let taskCompletion = { [weak self] (image: Favicon?) in
      self?.task = nil
      
      DispatchQueue.main.async {
        completion?(image)
      }
    }
    
    task?.cancel()
    task = DispatchWorkItem { [weak self] in
      guard let self = self, !self.isCancelled else {
        taskCompletion(nil)
        return
      }

      // Load the Favicon from Brave-Core
      FaviconLoader.getForPrivateMode(persistent).favicon(forPageURL: url,
                                                          sizeInPoints: .desiredMedium,
                                                          minSizeInPoints: .init(rawValue: 0),
                                                          fallbackToGoogleServer: false) { [weak self] attributes in
        
        guard let self = self, !self.isCancelled else {
          taskCompletion(nil)
          return
        }
        
        if attributes.usesDefaultImage {
          return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
          guard let self = self, !self.isCancelled else {
            taskCompletion(nil)
            return
          }
          
          if let image = attributes.faviconImage {
            // Render the Favicon on a UIImage
            UIImage.renderImage(image, backgroundColor: attributes.backgroundColor) { [weak self] favicon in
              guard let self = self, !self.isCancelled else {
                taskCompletion(nil)
                return
              }
              
              taskCompletion(favicon)
            }
          } else {
            // Render the Monogram on a UIImage
            let textColor = !attributes.isDefaultBackgroundColor ? attributes.textColor : nil
            let backColor = !attributes.isDefaultBackgroundColor ? attributes.backgroundColor : nil
            
            UIImage.renderMonogram(url,
                                   textColor: textColor,
                                   backgroundColor: backColor,
                                   monogramString: attributes.monogramString) { [weak self] favicon in
              guard let self = self, !self.isCancelled else {
                taskCompletion(nil)
                return
              }
              
              taskCompletion(favicon)
            }
          }
        }
      }
    }

    if let task = task {
      DispatchQueue.main.async(execute: task)
    }
  }
  
  private var isCancelled: Bool {
    guard let cancellable = task else {
      return true
    }
    
    return cancellable.isCancelled
  }
}
