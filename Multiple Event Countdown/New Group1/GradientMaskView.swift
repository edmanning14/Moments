//
//  GradientMaskView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/2/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CoreGraphics

class GradientMaskView: UIView {

    var percentMaskCoverage: CGFloat = 1.0
    fileprivate let sizeOfGradientArea: CGFloat = 0.15
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradientColors: [CGFloat] = [
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        ]
        let location2: CGFloat = 1.0 - percentMaskCoverage
        var location1: CGFloat {
            let location = location2 - sizeOfGradientArea
            if location < 0.0 {return 0.0} else {return location}
        }
        
        let locations = [location1, location2]
        
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColors, locations: locations, count: locations.count)!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: rect.height / 2), end: CGPoint(x: rect.width, y: rect.height / 2), options: [.drawsAfterEndLocation, .drawsBeforeStartLocation])
    }

}
