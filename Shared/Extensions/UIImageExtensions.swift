/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SDWebImage

private let imageLock = NSLock()

extension CGRect {
    public init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    public init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }
}

extension Data {
    public var isGIF: Bool {
        return [0x47, 0x49, 0x46].elementsEqual(prefix(3))
    }
}

extension UIImage {
    /// Despite docs that say otherwise, UIImage(data: NSData) isn't thread-safe (see bug 1223132).
    /// As a workaround, synchronize access to this initializer.
    /// This fix requires that you *always* use this over UIImage(data: NSData)!
    public static func imageFromDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage(data: data)
        imageLock.unlock()
        return image
    }

    /// Generates a UIImage from GIF data by calling out to SDWebImage. The latter in turn uses UIImage(data: NSData)
    /// in certain cases so we have to synchronize calls (see bug 1223132).
    public static func imageFromGIFDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage.sd_image(withGIFData: data)
        imageLock.unlock()
        return image
    }

    public static func createWithColor(_ size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(size: size)
        color.setFill()
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    public func createScaled(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    /// Return a UIImage which will always render as a template
    public var template: UIImage {
        return withRenderingMode(.alwaysTemplate)
    }
    
    public func scale(toSize size: CGSize) -> UIImage {
        if self.size == size {
            return self
        }
        
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.opaque = false
        rendererFormat.scale = 1.0
        
        let scaledImageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        let scaledImage = renderer.image { context in
            self.draw(in: scaledImageRect)
        }
        
        return scaledImage
    }
    
    public func withAlpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    public func textToImage(drawText text: String, textFont: UIFont? = nil, textColor: UIColor? = nil, atPoint point: CGPoint) -> UIImage? {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let font = textFont ?? UIFont.systemFont(ofSize: 20, weight: .medium)

        let fontAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: textColor ?? UIColor.white
        ]
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let rect = CGRect(origin: point, size: size)
        text.draw(in: rect.insetBy(dx: 15, dy: 0), withAttributes: fontAttributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // TESTING ONLY: not for use in release/production code.
    // PNG comparison can return false negatives, be very careful using for non-equal comparison.
    // PNG comparison requires UIImages to be constructed the same way in order for the metadata block to match,
    // this function ensures that.
    //
    // This can be verified with this code:
    //    let image = #imageLiteral(resourceName: "fxLogo")
    //    let data = UIImagePNGRepresentation(image)!
    //    assert(data != UIImagePNGRepresentation(UIImage(data: data)!))
    @available(*, deprecated, message: "use only in testing code")
    public func isStrictlyEqual(to other: UIImage) -> Bool {
        // Must use same constructor for PNG metadata block to be the same.
        let imageA = UIImage(data: self.pngData()!)!
        let imageB = UIImage(data: other.pngData()!)!
        let dataA = imageA.pngData()!
        let dataB = imageB.pngData()!
        return dataA == dataB
    }
}
