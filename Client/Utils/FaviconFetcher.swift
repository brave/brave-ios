/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import BraveShared
import XCGLogger
import Deferred
import SDWebImage
import Fuzi
import SwiftyJSON
import class Data.FaviconMO 

private let log = Logger.browserLogger
private let queue = DispatchQueue(label: "FaviconFetcher", attributes: DispatchQueue.Attributes.concurrent)

class FaviconFetcherErrorType: MaybeErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/* A helper class to find the favicon associated with a URL.
 * This will load the page and parse any icons it finds out of it.
 * If that fails, it will attempt to find a favicon.ico in the root host domain.
 */
open class FaviconFetcher: NSObject, XMLParserDelegate {
    public static var userAgent: String = ""
    static let expirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    fileprivate static var characterToFaviconCache = [String: UIImage]()
    static var defaultFavicon: UIImage = {
        return #imageLiteral(resourceName: "defaultFavicon")
    }()

    // An in-Memory data store that stores background colors domains. Stored using url.baseDomain.
    static var colors: [String: UIColor] = ["brave.com": UIColor.Photon.white100]

    // Sites can be accessed via their baseDomain.
    static var defaultIcons: [String: (color: UIColor, url: String)] = {
        return FaviconFetcher.getDefaultIcons()
    }()

    static let multiRegionDomains = ["craigslist", "google", "amazon"]

    class func getDefaultIconForURL(url: URL) -> (color: UIColor, url: String)? {
        // Problem: Sites like amazon exist with .ca/.de and many other tlds.
        // Solution: They are stored in the default icons list as "amazon" instead of "amazon.com" this allows us to have favicons for every tld."
        // Here, If the site is in the multiRegionDomain array look it up via its second level domain (amazon) instead of its baseDomain (amazon.com)
        let hostName = url.hostSLD
        if multiRegionDomains.contains(hostName), let icon = defaultIcons[hostName] {
            return icon
        }
        if let name = url.baseDomain, let icon = defaultIcons[name] {
            return icon
        }
        return nil
    }
    
    class func getCustomIcon(for url: URL) -> (url: URL, color: UIColor)? {
        let dirName = NTPDownloader.faviconOverridesDirectory
        
        guard let folder = FileManager.default.getOrCreateFolder(name: dirName),
            let baseDomain = url.baseDomain else { return nil }
        
        let backgroundFileName = baseDomain + NTPDownloader.faviconOverridesBackgroundSuffix
        let backgroundFilePath = folder.appendingPathComponent(backgroundFileName)
        
        do {
            let colorString = try String(contentsOf: backgroundFilePath)
            let colorFromHex = UIColor(colorString: colorString)
            
            if FileManager.default.fileExists(atPath: folder.appendingPathComponent(baseDomain).path) {
                return (folder.appendingPathComponent(baseDomain), colorFromHex)
            }
        } catch {
            return nil
        }
        
        return nil
    }

    class func getForURL(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url)
    }

    fileprivate func loadFavicons(_ url: URL, oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()

        var oldIcons: [Favicon] = oldIcons

        queue.async {
            self.parseHTMLForFavicons(url).bind({ (result: Maybe<[Favicon]>) -> Deferred<[Maybe<Favicon>]> in
                var deferreds = [Deferred<Maybe<Favicon>>]()
                if let icons = result.successValue {
                    deferreds = icons.map { self.getFavicon(url, icon: $0) }
                }
                return all(deferreds)
            }).bind({ (results: [Maybe<Favicon>]) -> Deferred<Maybe<[Favicon]>> in
                for result in results {
                    if let icon = result.successValue {
                        oldIcons.append(icon)
                    }
                }

                oldIcons = oldIcons.sorted {
                    return $0.width! > $1.width!
                }

                return deferMaybe(oldIcons)
            }).upon({ (result: Maybe<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }

        return deferred
    }

    lazy fileprivate var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": FaviconFetcher.userAgent]
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
    }()

    fileprivate func fetchDataForURL(_ url: URL) -> Deferred<Maybe<Data>> {
        let deferred = Deferred<Maybe<Data>>()
        session.dataTask(with: url) { data, response, error in
            // Don't cancel requests just because our Manager is deallocated.
            withExtendedLifetime(self.session) {
                if error == nil {
                    if let data = data {
                        deferred.fill(Maybe(success: data))
                        return
                    }
                }
                
                let errorDescription = (error as NSError?)?.description ?? "No content."
                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
            }
        }.resume()
        return deferred
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    fileprivate func parseHTMLForFavicons(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue, result.isSuccess,
                let root = try? HTMLDocument(data: data as Data) else {
                    return deferMaybe([])
            }
            var reloadUrl: URL?
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let url = NSURL(string: String(content.suffix(from: index.upperBound))) {
                    reloadUrl = url as URL
                }
            }

            if let url = reloadUrl {
                return self.parseHTMLForFavicons(url)
            }

            for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
                guard let href = link["href"] else {
                    continue //Skip the rest of the loop. But don't stop the loop
                }

                if let iconUrl = NSURL(string: href, relativeTo: url as URL), let absoluteString = iconUrl.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeTo: url as URL), icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

            }
            return deferMaybe(icons)
        })
    }

    private func getFavicon(_ siteUrl: URL, icon: Favicon) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url

        var favicon = Favicon(url: url)
        if let url = url.asURL {
            var imageOperation: SDWebImageOperation?

            let onProgress: ImageCacheProgress = { receivedSize, expectedSize, _ in
                if receivedSize > FaviconHandler.maximumFaviconSize || expectedSize > FaviconHandler.maximumFaviconSize {
                    imageOperation?.cancel()
                }
            }
            
            let onCompletion: ImageCacheCompletion = { image, _, _, _, url in
                favicon = Favicon(url: url.absoluteString)

                if let image = image {
                    favicon.width = Int(image.size.width)
                    favicon.height = Int(image.size.height)
                    FaviconMO.add(favicon, forSiteUrl: siteUrl)
                } else {
                    favicon.width = 0
                    favicon.height = 0
                }

                deferred.fill(Maybe(success: favicon))
            }

            imageOperation = WebImageCacheWithNoPrivacyProtectionManager.shared.load(from: url, options: [.lowPriority], progress: onProgress, completion: onCompletion)
        } else {
            return deferMaybe(FaviconFetcherErrorType(description: "Invalid URL \(url)"))
        }

        return deferred
    }

    // Returns a single Favicon UIImage for a given URL
    class func fetchFavImageForURL(forURL url: URL, profile: Profile) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()
        FaviconFetcher.getForURL(url.domainURL).uponQueue(.main) { result in
            guard let favicons = result.successValue, let favicon = favicons.first, let faviconURL = favicon.url.asURL else {
                return deferred.fill(Maybe(failure: FaviconError()))
            }

            WebImageCacheWithNoPrivacyProtectionManager.shared.load(from: faviconURL) { image, _, _, _, _ in
                guard let image = image else {
                    deferred.fill(Maybe(failure: FaviconError()))
                    return
                }
                
                deferred.fill(Maybe(success: image))
            }
        }
        return deferred
    }

    // Returns the default favicon for a site based on the first letter of the site's domain
    class func getDefaultFavicon(_ url: URL) -> UIImage {
        guard let character = url.baseDomain?.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = characterToFaviconCache[faviconLetter] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        faviconLabel.textColor = UIColor.Photon.white100
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        characterToFaviconCache[faviconLetter] = faviconImage
        return faviconImage
    }

    // Returns a color based on the url's hash
    class func getDefaultColor(_ url: URL) -> UIColor {
        guard let hash = url.baseDomain?.hashValue else {
            return UIColor.Photon.grey50
        }
        let index = abs(hash) % (UIConstants.defaultColorStrings.count - 1)
        let colorHex = UIConstants.defaultColorStrings[index]
        return UIColor(colorString: colorHex)
    }

    // Default favicons and background colors provided via mozilla/tippy-top-sites
    class func getDefaultIcons() -> [String: (color: UIColor, url: String)] {
        guard let filePath = Bundle.main.path(forResource: "top_sites", ofType: "json") else {
            log.error("Failed to get bundle path for \"top_sites.json\"")
            return [:]
        }
        do {
            let file = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let json = JSON(file)
            var icons: [String: (color: UIColor, url: String)] = [:]
            json.forEach({
                guard let url = $0.1["domain"].string, let color = $0.1["background_color"].string?.lowercased(),
                    var path = $0.1["image_url"].string else {
                    return
                }
                path = path.replacingOccurrences(of: ".png", with: "")
                let filePath = Bundle.main.path(forResource: "TopSites/" + path, ofType: "png")
                if let filePath = filePath {
                    if color == "#fff" {
                        icons[url] = (UIColor.white, filePath)
                    } else {
                        icons[url] = (UIColor(colorString: color.replacingOccurrences(of: "#", with: "")), filePath)
                    }
                }
            })
            return icons
        } catch {
            log.error("Failed to get default icons at \(filePath): \(error.localizedDescription)")
            return [:]
        }
    }
}
