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
    var percentMaskCoverage: CGFloat = 1.0 {didSet {setNeedsDisplay()}}
    fileprivate let sizeOfGradientArea: CGFloat = 0.15
    fileprivate let gradientColors: [CGColor] = [
        UIColor.black.cgColor,
        UIColor.white.cgColor
    ]
    
    convenience init(frame: CGRect, image: CGImage) {
        self.init(frame: frame)
        self.image = image
    }
    
    override func draw(_ rect: CGRect) {
        guard percentMaskCoverage > 0.0 else {return}
        
        // Gradient
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let grayscaleCGContext = CGContext(data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).rawValue
        )!
        
        let location2: CGFloat = 1.0 - percentMaskCoverage
        var location1: CGFloat {
            let location = location2 - sizeOfGradientArea
            if location < 0.0 {return 0.0} else {return location}
        }
        let locations = [location1, location2]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations)!
        grayscaleCGContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: image.height / 2), end: CGPoint(x: image.width, y: image.height / 2), options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])
        let gradientImage = grayscaleCGContext.makeImage()!
        
        let tempImage = image.masking(gradientImage)!
        
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.draw(tempImage, in: rect)
    }
}
