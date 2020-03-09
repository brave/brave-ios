// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import ImageIO
//import libwebp

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// Gif

extension UIImage {
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithURL(_ gifUrl: String) -> UIImage? {
        guard let bundleURL: URL = URL(string: gifUrl)
            else {
                print("image named \"\(gifUrl)\" doesn't exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("image named \"\(gifUrl)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        if let dDelay = delayObject as? Double {
            delay = dDelay
        }
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)
        
        return animation
    }
}

//// WebP
//
////Let's free some memory
//private func freeWebPData(info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) {
//    free(UnsafeMutableRawPointer(mutating: data))
//}
//
//extension UIImage {
//
//    //MARK: Inits
//    convenience init(webpWithPath path: String) {
//        let data = NSData(contentsOfFile: path)!
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data))
//    }
//
//    convenience init(webpWithPath path: String, andOptions options: [String: Int32]) {
//        let data = NSData(contentsOfFile: path)!
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data, withOptions: options))
//    }
//
//    convenience init(webpWithURL url: URL) {
//        let data = NSData(contentsOf: url)!
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data))
//    }
//
//    convenience init(webpWithURL url: URL, andOptions options: [String: Int32]) {
//        let data = NSData(contentsOf: url)!
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data, withOptions: options))
//    }
//
//    convenience init(webpWithData data: NSData) {
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data))
//    }
//
//    convenience init(webpWithData data: NSData, andOptions options: [String: Int32]) {
//        self.init(cgImage: UIImage.webPDataToCGImage(data: data, withOptions: options))
//    }
//
//    //MARK: WebP Decoder
//    //Let's the magic begin
//    class private func webPDataToCGImage(data: NSData) -> CGImage {
//
//        var w: CInt = 0
//        var h: CInt = 0
//
//        //Get image dimensions
//        if !UIImage.webPInfo(data: data, width: &w, height: &h) {
//            print("ERROR", w, h)
//            return UIImage.empty
//        }
//
//        //Data Provider
//        var provider: CGDataProvider
//
//        //RGBA by default
//        let rawData = WebPDecodeRGBA(data.bytes.assumingMemoryBound(to: UInt8.self), data.length, &w, &h)
//
//        provider = CGDataProvider(dataInfo: nil, data: rawData!, size: (Int(w)*Int(h)*4), releaseData: freeWebPData)!
//
//        return UIImage.webPProviderToCGImage(provider: provider, width: w, height: h)
//    }
//
//    class private func webPDataToCGImage(data: NSData, withOptions options: [String: Int32]) -> CGImage {
//
//        var w: CInt = 0
//        var h: CInt = 0
//
//        //Get image dimensions
//        if !UIImage.webPInfo(data: data, width: &w, height: &h) {
//            return UIImage.empty
//        }
//
//        //Data Provider
//        var provider: CGDataProvider
//
//        //Get configs
//        var config = UIImage.webPConfig(options: options)
//
//        //RGBA by default
//        WebPDecode(data.bytes.assumingMemoryBound(to: UInt8.self), data.length, &config)
//
//        provider = CGDataProvider(dataInfo: &config, data: config.output.u.RGBA.rgba, size: (Int(w)*Int(h)*4), releaseData: freeWebPData)!
//
//        return UIImage.webPProviderToCGImage(provider: provider, width: w, height: h)
//    }
//
//    //Generate CGImage from decoded data
//    class private func webPProviderToCGImage(provider: CGDataProvider, width w: CInt, height h: CInt) -> CGImage {
//
//        let bitmapWithAlpha = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
//
//        if let image = CGImage(
//            width: Int(w),
//            height: Int(h),
//            bitsPerComponent: 8,
//            bitsPerPixel: 32,
//            bytesPerRow: Int(w)*4,
//            space: CGColorSpaceCreateDeviceRGB(),
//            bitmapInfo: bitmapWithAlpha,
//            provider: provider,
//            decode: nil,
//            shouldInterpolate: false,
//            intent: CGColorRenderingIntent.defaultIntent
//            ) {
//            return image
//        } else {
//            return UIImage.empty
//        }
//
//    }
//
//    //MARK: UTILS
//    //Get WebP image info (width and height)
//    static private func webPInfo(data: NSData, width: inout CInt, height: inout CInt) -> Bool {
//        let statusOk = Int32(1)
//        if WebPGetInfo(data.bytes.assumingMemoryBound(to: UInt8.self), data.length, &width, &height) == statusOk {
//            return true
//        }
//        return false
//    }
//
//    //Transform swift array into WebPDecoderConfig
//    static private func webPConfig(options: [String: Int32]) -> WebPDecoderConfig {
//        var config = WebPDecoderConfig()
//
//        if let noFancyUpsampling = options["no_fancy_upsampling"] {
//            config.options.no_fancy_upsampling = noFancyUpsampling
//        } else {
//            config.options.no_fancy_upsampling = 1
//        }
//
//        if let bypassFiltering = options["bypass_filtering"] {
//            config.options.bypass_filtering = bypassFiltering
//        } else {
//            config.options.bypass_filtering = 1
//        }
//
//        if let useThreads = options["use_threads"] {
//            config.options.use_threads = useThreads
//        } else {
//            config.options.use_threads = 1
//        }
//
//        if let colorSpace = options["color_space"] {
//            config.output.colorspace = WEBP_CSP_MODE(rawValue: UInt32(colorSpace))
//        } else {
//            config.output.colorspace = MODE_RGBA
//        }
//
//        return config
//    }
//
//    //Get empty 1x1 image as fallback
//    static var empty: CGImage {
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0.0)
//        let blank = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return blank.cgImage!
//    }
//
//}
