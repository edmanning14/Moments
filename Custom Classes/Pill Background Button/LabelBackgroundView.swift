//
//  LabelBackgroundView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/23/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class LabelBackgroundView: UIView {
    
    let deviceColorSpace = CGColorSpaceCreateDeviceRGB()

    override func draw(_ rect: CGRect) {
        if let currentCTX = UIGraphicsGetCurrentContext() {
            
            let outerRadius = rect.height / 2
            let clearPathCenter = outerRadius * 0.75
            let clearPathStroke: CGFloat = 2.0
            let path2Radius = clearPathCenter + (clearPathStroke / 2)
            let path3Radius = clearPathCenter - (clearPathStroke / 2)
            
            let leftArcCenter = CGPoint(x: outerRadius, y: rect.height / 2)
            let rightArcCenter = CGPoint(x: rect.width - outerRadius, y: rect.height / 2)
            
            let path1StartPoint = CGPoint(x: leftArcCenter.x, y: leftArcCenter.y - outerRadius)
            let path2StartPoint = CGPoint(x: leftArcCenter.x, y: leftArcCenter.y - path2Radius)
            let path3StartPoint = CGPoint(x: leftArcCenter.x, y: leftArcCenter.y - path3Radius)
            
            currentCTX.move(to: path1StartPoint)
            currentCTX.addArc(center: rightArcCenter, radius: outerRadius, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: false)
            currentCTX.addArc(center: leftArcCenter, radius: outerRadius, startAngle: CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: false)
            
            currentCTX.move(to: path2StartPoint)
            currentCTX.addArc(center: rightArcCenter, radius: path2Radius, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: false)
            currentCTX.addArc(center: leftArcCenter, radius: path2Radius, startAngle: CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: false)
            
            currentCTX.move(to: path3StartPoint)
            currentCTX.addArc(center: rightArcCenter, radius: path3Radius, startAngle: 3 * CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: false)
            currentCTX.addArc(center: leftArcCenter, radius: path3Radius, startAngle: CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: false)
            
            let fillColor: [CGFloat] = [0.0, 0.3, 0.0, 0.75]
            currentCTX.setFillColorSpace(deviceColorSpace)
            currentCTX.setFillColor(fillColor)
            currentCTX.fillPath(using: .evenOdd)
        }
        else {
            // TODO: Add a an alert pop-up that gracefully fails the app.
            fatalError("Unable to get the current graphics context when creating NewEventInputsControl")
        }
    }
}
