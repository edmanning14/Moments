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
    //fileprivate var imageCGLayer: CGLayer?
    fileprivate var homeImage: CGImage?
    fileprivate var drawToRect: CGRect?
    var imageFrame: CGRect?
    var isAppImage: Bool!
    var locationForCellView: CGFloat?
    enum DisplayModes {case cell, detail}
    var displayMode = DisplayModes.detail
    
    fileprivate let drawQueue = DispatchQueue(label: "drawQueue", qos: .userInitiated)
    fileprivate var runningWorkItem: DispatchWorkItem?
    fileprivate var queuedWorkItem: DispatchWorkItem?
    
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
        
        let ctx = UIGraphicsGetCurrentContext()!
        
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
            if let _image = homeImage {ctx.draw(_image, in: rect)}
            else {drawImageAsync(inContext: ctx, rect: rect)}
        case .detail:
            if let drawRect = drawToRect {ctx.draw(image, in: drawRect)}
            else {drawImageAsync(inContext: ctx, rect: rect)}
        }
    }
    
    fileprivate func drawImageAsync(inContext ctx: CGContext, rect: CGRect) {
        
        let workItem = DispatchWorkItem { [weak self] in
            
            let contextAR = rect.width / rect.height
            
            if let livingSelf = self {
                if livingSelf.isAppImage { // Origin: ULO, positive x down, positive y right
                    ctx.translateBy(x: rect.width, y: 0.0)
                    ctx.scaleBy(x: -1.0, y: 1.0)
                    ctx.translateBy(x: rect.width, y: 0.0)
                    ctx.rotate(by: CGFloat.pi / 2)
                }
                else { // Origin: LLO, positive x right, positive y up
                    ctx.translateBy(x: 0.0, y: rect.height)
                    ctx.scaleBy(x: 1.0, y: -1.0)
                }
                
                switch livingSelf.displayMode {
                case .cell:
                    if livingSelf.isAppImage {
                        let imageHeight = livingSelf.image.width
                        let imageWidth = livingSelf.image.height
                        
                        let croppingRectWidth = Int(CGFloat(imageHeight) / contextAR)
                        let croppingRectSize = CGSize(width: croppingRectWidth, height: imageHeight)
                        
                        let croppingRectX = (CGFloat(imageWidth) * livingSelf.locationForCellView!) - (croppingRectSize.width / 2)
                        let croppingRectOrigin = CGPoint(x: croppingRectX, y: 0.0)
                        
                        let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                        livingSelf.homeImage = livingSelf.image.cropping(to: croppingRect)!
                    }
                    else {
                        let imageHeight = livingSelf.image.height
                        let imageWidth = livingSelf.image.width
                        
                        let croppingRectHeight = Int(CGFloat(imageWidth) / contextAR)
                        let croppingRectSize = CGSize(width: imageWidth, height: croppingRectHeight)
                        
                        //let croppingRectY: CGFloat = 0.0
                        var croppingRectY = (CGFloat(imageHeight) * livingSelf.locationForCellView!) - (croppingRectSize.height / 2)
                        if croppingRectY < 0.0 {croppingRectY = 0.0}
                        else if croppingRectY + CGFloat(croppingRectHeight) > CGFloat(imageHeight) {croppingRectY = CGFloat(imageHeight)}
                        let croppingRectOrigin = CGPoint(x: 0.0, y: croppingRectY)
                        
                        let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                        livingSelf.homeImage = livingSelf.image.cropping(to: croppingRect)!
                    }
                case .detail:
                    let imageAR = CGFloat(livingSelf.image.width) / CGFloat(livingSelf.image.height)
                    
                    var drawToRectOrigin = CGPoint.zero
                    var drawToRectSize = CGSize(width: rect.width, height: rect.height)
                    if livingSelf.isAppImage {
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
                    
                    livingSelf.drawToRect = CGRect(origin: drawToRectOrigin, size: drawToRectSize)
                    if livingSelf.isAppImage {
                        livingSelf.imageFrame = CGRect(x: livingSelf.drawToRect!.origin.y, y: livingSelf.drawToRect!.origin.x, width: livingSelf.drawToRect!.height, height: livingSelf.drawToRect!.width)
                    }
                    else {livingSelf.imageFrame = livingSelf.drawToRect}
                }
                
                if livingSelf.queuedWorkItem == nil {
                    DispatchQueue.main.async {[weak self] in self?.setNeedsDisplay()}
                    livingSelf.runningWorkItem = nil
                }
                else {
                    livingSelf.runningWorkItem = livingSelf.queuedWorkItem
                    livingSelf.queuedWorkItem = nil
                }
            }
        }
        
        if runningWorkItem == nil {runningWorkItem = workItem}
        else {
            if let queuedWork = queuedWorkItem {queuedWork.cancel()}
            queuedWorkItem = workItem
        }
        drawQueue.async(execute: workItem)
    }
}
