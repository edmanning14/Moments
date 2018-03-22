//
//  CountdownImageView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/2/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CoreGraphics

class CountdownMainImageView: UIView {

    var image: CGImage! {didSet{setNeedsDisplay()}}
    enum DisplayModes {case cell, detail}
    var displayMode = DisplayModes.cell
    
    convenience init(frame: CGRect, image: CGImage, displayMode: DisplayModes) {
        self.init(frame: frame)
        self.image = image
        self.displayMode = displayMode
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let contextAR = rect.width / rect.height
        
        ctx.translateBy(x: rect.width, y: 0.0)
        ctx.scaleBy(x: -1.0, y: 1.0)
        ctx.translateBy(x: rect.width, y: 0.0)
        ctx.rotate(by: CGFloat.pi / 2)
        
        // Origin: ULO, positive x down, positive y right
        
        let imageHeight = image.width
        let imageWidth = image.height
        
        switch displayMode {
        case .cell:
            let croppingRectWidth = Int(CGFloat(imageHeight) / contextAR)
            let croppingRectSize = CGSize(width: croppingRectWidth, height: imageHeight)
            
            let croppingRectX = CGFloat(imageWidth / 2) - (croppingRectSize.width / 2)
            let croppingRectOrigin = CGPoint(x: croppingRectX, y: 0.0)
            
            let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
            let croppedImage = image.cropping(to: croppingRect)!
            
            ctx.draw(croppedImage, in: CGRect(x: 0.0, y: 0.0, width: rect.height, height: rect.width))
        case .detail:
            let imageAR = CGFloat(image.width) / CGFloat(image.height)
            
            var drawToRectOrigin = CGPoint.zero
            var drawToRectSize = CGSize(width: rect.width, height: rect.height)
            if contextAR >= imageAR { // rect height set
                drawToRectSize.width = rect.height * imageAR
                drawToRectOrigin.y = (rect.width / 2) - (drawToRectSize.width / 2)
            }
            else { // rect width set
                drawToRectSize.height = rect.width / imageAR
                drawToRectOrigin.x =  (rect.height / 2) - (drawToRectSize.height / 2)
            }
            
            let drawToRect = CGRect(origin: drawToRectOrigin, size: drawToRectSize)
            ctx.draw(image, in: drawToRect)
        }
    }
}
