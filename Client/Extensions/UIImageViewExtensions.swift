/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import Data

public extension UIImageView {

    public func setIcon(_ icon: Favicon?, forURL url: URL?, completed completionBlock: ((UIColor, URL?) -> Void)? = nil ) {
        if let url = url, let defaultIcon = FaviconFetcher.getDefaultIconForURL(url: url) {
            self.image = UIImage(contentsOfFile: defaultIcon.url)
            self.backgroundColor = defaultIcon.color
            completionBlock?(defaultIcon.color, url)
        } else {
            let imageURL = URL(string: icon?.url ?? "")
            let defaults = defaultFavicon(url)
            self.sd_setImage(with: imageURL, placeholderImage: defaults.image, options: []) {(img, err, _, _) in
                guard let image = img, let dUrl = url, err == nil else {
                    self.backgroundColor = defaults.color
                    completionBlock?(defaults.color, url)
                    return
                }
                self.color(forImage: image, andURL: dUrl, completed: completionBlock)
            }
        }
    }
    
    public func setIcon(_ icon: FaviconMO?, forURL url: URL?, completed completionBlock: ((UIColor, URL?) -> Void)? = nil ) {
        if let url = url, let defaultIcon = FaviconFetcher.getDefaultIconForURL(url: url), icon == nil {
            self.image = UIImage(contentsOfFile: defaultIcon.url)?.createScaled(CGSize(width: 40, height: 40))
            self.contentMode = .center
            self.backgroundColor = defaultIcon.color
            completionBlock?(defaultIcon.color, url)
        } else {
            let defaults = defaultFavicon(url)
            if let url = url, icon == nil {
                FaviconFetcher.getForURL(url).uponQueue(.main) { result in
                    guard let favicons = result.successValue, favicons.count > 0, let foundIconUrl = favicons.first?.url.asURL else {
                        return
                    }
                    self.sd_setImage(with: foundIconUrl, placeholderImage: defaults.image, options: []) {(img, err, _, _) in
                        guard let image = img, err == nil else {
                            self.backgroundColor = defaults.color
                            completionBlock?(defaults.color, url)
                            return
                        }
                        self.color(forImage: image, andURL: url, completed: completionBlock)
                    }
                }
                return
            }
            let imageURL = URL(string: icon?.url ?? "")
            self.sd_setImage(with: imageURL, placeholderImage: defaults.image, options: []) {(img, err, _, _) in
                guard let image = img, let dUrl = url, err == nil else {
                    self.backgroundColor = defaults.color
                    completionBlock?(defaults.color, url)
                    return
                }
                self.color(forImage: image, andURL: dUrl, completed: completionBlock)
            }
        }
    }

   /*
    * Fetch a background color for a specfic favicon UIImage. It uses the URL to store the UIColor in memory for subsequent requests.
    */
    private func color(forImage image: UIImage, andURL url: URL, completed completionBlock: ((UIColor, URL?) -> Void)? = nil) {
        guard let domain = url.baseDomain else {
            self.backgroundColor = .gray
            completionBlock?(UIColor.Photon.Grey50, url)
            return
        }

        if let color = FaviconFetcher.colors[domain] {
            self.backgroundColor = color
            completionBlock?(color, url)
        } else {
            image.getColors(scaleDownSize: CGSize(width: 25, height: 25)) {colors in
                let isSame = [colors.primary, colors.secondary, colors.detail].every { $0 == colors.primary }
                if isSame {
                    completionBlock?(UIColor.Photon.White100, url)
                    FaviconFetcher.colors[domain] = UIColor.Photon.White100
                } else {
                    completionBlock?(colors.background, url)
                    FaviconFetcher.colors[domain] = colors.background
                }
            }
        }
    }

    public func setFavicon(forSite site: Site, onCompletion completionBlock: ((UIColor, URL?) -> Void)? = nil ) {
        self.setIcon(site.icon, forURL: site.tileURL, completed: completionBlock)
    }

    private func defaultFavicon(_ url: URL?) -> (image: UIImage, color: UIColor) {
        if let url = url {
            return (FaviconFetcher.getDefaultFavicon(url), FaviconFetcher.getDefaultColor(url))
        } else {
            return (FaviconFetcher.defaultFavicon, .white)
        }
    }
}
