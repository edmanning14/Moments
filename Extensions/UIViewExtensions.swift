//
//  UIViewExtensions.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/21/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func asJPEGImage() -> Data {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.jpegData(withCompressionQuality: 1.0) { (rendererContext) in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func asPNGImage() -> Data {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.pngData { (rendererContext) in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
