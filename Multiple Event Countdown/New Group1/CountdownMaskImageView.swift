//
//  CountdownMaskImageView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class CountdownMaskImageView: UIView {

    var image: CGImage! {didSet{setNeedsDisplay()}}
    var locationForCellView: CGFloat!
    var percentMaskCoverage: CGFloat = 1.0
    fileprivate let sizeOfGradientArea: CGFloat = 0.15
    
    convenience init(frame: CGRect, image: CGImage, locationForCellView: CGFloat) {
        self.init(frame: frame)
        self.image = image
        self.locationForCellView = locationForCellView
    }
    
    override func draw(_ rect: CGRect) {
        UIGraphicsBeginImageContext(rect.size)
        let imageCTX = UIGraphicsGetCurrentContext()!
        
        let contextAR = rect.size.aspectRatio
        let croppingRectHeight = Int(CGFloat(image.width) / contextAR)
        let croppingRectSize = CGSize(width: image.width, height: croppingRectHeight)
        
        let croppingRectY = (CGFloat(image.height) * locationForCellView) - (croppingRectSize.height / 2)
        let croppingRectOrigin = CGPoint(x: 0.0, y: croppingRectY)
        
        let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
        let croppedImage = image.cropping(to: croppingRect)!
        
        imageCTX.draw(croppedImage, in: rect)
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        UIGraphicsEndImageContext()
        
        // Gradient
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let grayscaleCGContext = CGContext(data: nil,
            width: maskImage.width,
            height: maskImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue
        )!
        let gradientColors: [CGColor] = [
            UIColor.black.cgColor,
            UIColor.white.cgColor
        ]
        let location2: CGFloat = 1.0 - percentMaskCoverage
        var location1: CGFloat {
            let location = location2 - sizeOfGradientArea
            if location < 0.0 {return 0.0} else {return location}
        }
        let locations = [location1, location2]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations)!
        grayscaleCGContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: maskImage.height / 2), end: CGPoint(x: maskImage.width, y: maskImage.height / 2), options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])
        let gradientImage = grayscaleCGContext.makeImage()!
        
        let tempImage = maskImage.masking(gradientImage)!
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.draw(tempImage, in: rect)
    }
}
