//
//  Extensions.swift
//  Example
//
//  Created by leven on 2023/1/30.
//

import Foundation
import Toast_Swift
import UIKit
import JKCategories
import BigInt
extension UIView {
    @discardableResult
    func addTap(_ callback: @escaping () -> Void) -> UITapGestureRecognizer? {
        self.isUserInteractionEnabled = true
        self.jk_addTapAction { _ in
            callback()
        }
        if let tap = self.gestureRecognizers?.first(where: { g in
            return g is UITapGestureRecognizer
        }) as? UITapGestureRecognizer {
            return tap
        }
        return nil
    }
}
extension UInt64 {
    var toEth: Double {
        let ethValue = Double(self) / pow(Double(10), Double(18))

        return ethValue
    }
}
extension Double {
    var str_6f : String {
        return String(format: "%.6f", self)
    }
    var toWei: BigUInt? {
        let weiValue: UInt64 = UInt64(self * pow(Double(10), Double(18)))
        return BigUInt("\(weiValue)")
    }
}
extension UIWindow {
    static var key: UIWindow? {
        return UIApplication.shared.keyWindow
    }
    
    static func toast(msg: String, maxLength: Int = 200, placeholder: String? = "", duration: Double? = 3, centerY: CGFloat = UIScreen.main.bounds.size.height * 0.5) {
        
        var text: String = msg.count > maxLength ? "\(msg.prefix(maxLength))" : msg
        
        if let aPlaceholder = placeholder, !aPlaceholder.isEmpty, text.isEmpty {
            text = aPlaceholder
        }
        
        var showDuration: TimeInterval
        if let aDuration = duration {
            showDuration = TimeInterval(aDuration)
        } else {
            let purposeTime: Double = Double(text.count) * 0.15
            showDuration = max(0.8, purposeTime)
        }
        
        let postion = CGPoint(x: UIScreen.main.bounds.size.width * 0.5, y: centerY)
        
        guard text.count > 0 else { return }
        UIWindow.key?.makeToast(text + "  ",
                                duration: showDuration,
                                point: postion,
                                title: nil,
                                image: nil,
                                style: toastStyle,
                                completion: nil)
    }
    static var toastStyle: ToastStyle {
        var style = ToastManager.shared.style
        style.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        style.titleColor = UIColor.white
        return style
    }
}
extension String {
    /// Converts String to Int
    public func toInt() -> Int? {
        if let num = NumberFormatter().number(from: self) {
            return num.intValue
        } else {
            return nil
        }
    }
    
    /// Converts String to Double
    public func toDouble() -> Double? {
        if let num = NumberFormatter().number(from: self) {
            return num.doubleValue
        } else {
            return nil
        }
    }
    
    /// Converts String to Float
    public func toFloat() -> Float? {
        if let num = NumberFormatter().number(from: self) {
            return num.floatValue
        } else {
            return nil
        }
    }
    
}
extension UIImage {
    class func createQRCode(size: CGFloat, dataStr: String) -> UIImage? {
        let filter = CIFilter(name:"CIQRCodeGenerator")
        filter?.setDefaults()
        let data = dataStr.data(using: .utf8)
        filter?.setValue(data, forKey:"inputMessage")
        guard let cIImage = filter?.outputImage else {
            return nil
        }
        return self.createNonInterpolatedUIImage(image: cIImage, size: size)
    }
    
    private class func createNonInterpolatedUIImage(image:CIImage,size:CGFloat) -> UIImage? {
        let extent = image.extent.integral
        let scale = min(size/extent.width, size/extent.height)
        let width = extent.width * scale
        let height = extent.height * scale
        let cs = CGColorSpaceCreateDeviceGray()
        let context = CIContext(options: nil)
        let bitmapImage = context.createCGImage(image, from: extent)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        guard let bitmapRef = CGContext(data: nil,
                                        width: Int(width),
                                        height: Int(height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: 0,
                                        space: cs,
                                        bitmapInfo: bitmapInfo.rawValue)else {
                                            return nil
        }
        bitmapRef.interpolationQuality = CGInterpolationQuality.none
        bitmapRef.scaleBy(x: scale,y: scale)
        bitmapRef.draw(bitmapImage!, in: extent)
        guard let scaledImage = bitmapRef.makeImage() else {
            return nil
        }
        return UIImage(cgImage:scaledImage)
    }
}
