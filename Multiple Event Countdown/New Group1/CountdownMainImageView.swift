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
    fileprivate var imageCGLayer: CGLayer?
    var imageFrame: CGRect?
    var isAppImage: Bool!
    var locationForCellView: CGFloat?
    enum DisplayModes {case cell, detail}
    var displayMode = DisplayModes.detail
    
    convenience init?(frame: CGRect, image: CGImage, isAppImage: Bool, locationForCellView: CGFloat?, displayMode: DisplayModes = .detail) {
        if displayMode == .cell && locationForCellView == nil {return nil}
        self.init(frame: frame)
        self.image = image
        self.isAppImage = isAppImage
        self.locationForCellView = locationForCellView
        self.displayMode = displayMode
        
    }
    
    override func draw(_ rect: CGRect) {
        if displayMode == .cell && locationForCellView == nil {return}
        
        if let cgLayer = imageCGLayer {
            
        }
        else {
            
        }
        
        let ctx = UIGraphicsGetCurrentContext()!
        let contextAR = rect.width / rect.height
        
        if isAppImage { // Origin: ULO, positive x down, positive y right
            ctx.translateBy(x: rect.width, y: 0.0)
            ctx.scaleBy(x: -1.0, y: 1.0)
            ctx.translateBy(x: rect.width, y: 0.0)
            ctx.rotate(by: CGFloat.pi / 2)
        }
        else { // Origin: LLO, positive x right, positive y up
            ctx.translateBy(x: 0.0, y: rect.height)
            ctx.scaleBy(x: 1.0, y: -1.0)
        }
        
        switch displayMode {
        case .cell:
            if isAppImage {
                let imageHeight = image.width
                let imageWidth = image.height
                
                let croppingRectWidth = Int(CGFloat(imageHeight) / contextAR)
                let croppingRectSize = CGSize(width: croppingRectWidth, height: imageHeight)
                
                let croppingRectX = (CGFloat(imageWidth) * locationForCellView!) - (croppingRectSize.width / 2)
                let croppingRectOrigin = CGPoint(x: croppingRectX, y: 0.0)
                
                let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                let croppedImage = image.cropping(to: croppingRect)!
                ctx.draw(croppedImage, in: CGRect(x: 0.0, y: 0.0, width: rect.height, height: rect.width))
            }
            else {
                let imageHeight = image.height
                let imageWidth = image.width
                
                let croppingRectHeight = Int(CGFloat(imageWidth) / contextAR)
                let croppingRectSize = CGSize(width: imageWidth, height: croppingRectHeight)
                
                //let croppingRectY: CGFloat = 0.0
                var croppingRectY = (CGFloat(imageHeight) * locationForCellView!) - (croppingRectSize.height / 2)
                if croppingRectY < 0.0 {croppingRectY = 0.0}
                else if croppingRectY + CGFloat(croppingRectHeight) > CGFloat(imageHeight) {croppingRectY = CGFloat(imageHeight)}
                let croppingRectOrigin = CGPoint(x: 0.0, y: croppingRectY)
                
                let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                let croppedImage = image.cropping(to: croppingRect)!
                ctx.draw(croppedImage, in: rect)
            }
        case .detail:
            let imageAR = CGFloat(image.width) / CGFloat(image.height)
            
            var drawToRectOrigin = CGPoint.zero
            var drawToRectSize = CGSize(width: rect.width, height: rect.height)
            if isAppImage {
                if contextAR >= imageAR { // rect height set
                    drawToRectSize.width = rect.height * imageAR
                    drawToRectOrigin.y = (rect.width / 2) - (drawToRectSize.width / 2)
                }
                else { // rect width set
                    drawToRectSize.height = rect.width / imageAR
                    drawToRectOrigin.x =  (rect.height / 2) - (drawToRectSize.height / 2)
                }
            }
            else {
                if contextAR >= imageAR { // rect width set
                    drawToRectSize.width = drawToRectSize.height * imageAR
                    drawToRectOrigin.x = (rect.width / 2) - (drawToRectSize.width / 2)
                }
                else { // rect height set
                    drawToRectSize.height = drawToRectSize.width / imageAR
                    drawToRectOrigin.y =  (rect.height / 2) - (drawToRectSize.height / 2)
                }
            }
            
            let drawToRect = CGRect(origin: drawToRectOrigin, size: drawToRectSize)
            if isAppImage {
                imageFrame = CGRect(x: drawToRect.origin.y, y: drawToRect.origin.x, width: drawToRect.height, height: drawToRect.width)
            }
            else {imageFrame = drawToRect}
            ctx.draw(image, in: drawToRect)
        }
    }
}
