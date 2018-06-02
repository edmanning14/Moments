//
//  CircularDisplayView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 5/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class CircularDisplayView: UIView {
    
    enum RadiusCenterLocations {case middle, top, bottom, right, left}
    var radiusCenterLocation = RadiusCenterLocations.middle
    var unitDistanceFromBoundsEdge: CGFloat = 0.25 {didSet {self.setNeedsDisplay()}}
    
    fileprivate var managedViews = [UIView]() {didSet {self.setNeedsDisplay()}}
    fileprivate var atMaxDistanceFromBoundsEdge = false
    
    convenience init(unitDistanceFromScreenEdge: CGFloat = 0.25, radiusCenterLocation: RadiusCenterLocations = .middle) {
        self.init()
        self.unitDistanceFromBoundsEdge = unitDistanceFromScreenEdge
        self.radiusCenterLocation = radiusCenterLocation
    }

    override func draw(_ rect: CGRect) {
        
        func findDistance(between point1: CGPoint, and point2: CGPoint) -> CGFloat {
            let diffXs = Double(point2.x - point1.x)
            let diffYs = Double(point2.y - point1.y)
            let diffXsSquared = pow(diffXs, 2)
            let diffYsSquared = pow(diffYs, 2)
            let c = sqrt(diffXsSquared + diffYsSquared)
            return CGFloat(c)
        }
        
        let numViews = managedViews.count
        guard numViews > 0 else {return}
        if unitDistanceFromBoundsEdge < 0.1 {
            unitDistanceFromBoundsEdge = 0.1
            print("WARNING: unitDistanceFromScreenEdge is too small and was reset to 0.1. Please use values larger than 0.1 and less than half the distance between arc end points (the radius)")
        }
        
        var arcPoints = [CGPoint]()
        var arcCenter = CGPoint()
        var useEndPointsOnArc = false
        
        //
        // IMPORTANT NOTE: When adding new cases, make sure that all point following the first point follow in order in a clockwise direction
        //
        switch radiusCenterLocation {
        case .middle:
            if self.bounds.width < self.bounds.height {
                let point1 = CGPoint(x: unitDistanceFromBoundsEdge * self.bounds.width, y: self.bounds.height / 2)
                let point2 = CGPoint(x: self.bounds.width - (unitDistanceFromBoundsEdge * self.bounds.width), y: self.bounds.height / 2)
                let radius = point2.x - point1.x / 2
                let point3 = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2 - radius)
                arcPoints.append(contentsOf: [point1, point3, point2])
            }
            else {
                let point1 = CGPoint(x: self.bounds.width / 2, y: unitDistanceFromBoundsEdge * self.bounds.height)
                let radius = (self.bounds.height / 2) - point1.y
                let point2 = CGPoint(x: self.bounds.width - radius, y: self.bounds.height / 2)
                let point3 = CGPoint(x: self.bounds.width + radius, y: self.bounds.height / 2)
                arcPoints.append(contentsOf: [point2, point1, point3])
            }
            arcCenter.x = self.bounds.width / 2
            arcCenter.y = self.bounds.height / 2
            useEndPointsOnArc = true
            atMaxDistanceFromBoundsEdge = true
        case .top:
            if unitDistanceFromBoundsEdge * self.bounds.height > self.bounds.width / 2 {
                unitDistanceFromBoundsEdge = (self.bounds.width / 2) / self.bounds.height
                atMaxDistanceFromBoundsEdge = true
                print("NOTE: unitDistanceFromScreenEdge was larger than the circle radius and was reset to \(unitDistanceFromBoundsEdge).")
            }
            let point1 = CGPoint(x: 0.0, y: 0.0)
            let point2 = CGPoint(x: self.bounds.width / 2, y: unitDistanceFromBoundsEdge * self.bounds.height)
            let point3 = CGPoint(x: self.bounds.width, y: 0.0)
            arcPoints.append(contentsOf: [point3, point2, point1])
            arcCenter.x = self.bounds.width / 2
            arcCenter.y = -1.0
        case .bottom:
            if unitDistanceFromBoundsEdge * self.bounds.height > self.bounds.width / 2 {
                unitDistanceFromBoundsEdge = (self.bounds.width / 2) / self.bounds.height
                atMaxDistanceFromBoundsEdge = true
                print("NOTE: unitDistanceFromScreenEdge was larger than the circle radius and was reset to \(unitDistanceFromBoundsEdge).")
            }
            let point1 = CGPoint(x: 0.0, y: self.bounds.height)
            let point2 = CGPoint(x: self.bounds.width / 2, y: self.bounds.height - (unitDistanceFromBoundsEdge * self.bounds.height))
            let point3 = CGPoint(x: self.bounds.width, y: self.bounds.height)
            arcPoints.append(contentsOf: [point1, point2, point3])
            arcCenter.x = self.bounds.width / 2
            arcCenter.y = 1.0
        case .right:
            if unitDistanceFromBoundsEdge * self.bounds.width > self.bounds.height / 2 {
                unitDistanceFromBoundsEdge = (self.bounds.height / 2) / self.bounds.width
                atMaxDistanceFromBoundsEdge = true
                print("NOTE: unitDistanceFromScreenEdge was larger than the circle radius and was reset to \(unitDistanceFromBoundsEdge).")
            }
            let point1 = CGPoint(x: self.bounds.width, y: 0.0)
            let point2 = CGPoint(x: self.bounds.width - (self.bounds.width * unitDistanceFromBoundsEdge), y: self.bounds.height / 2)
            let point3 = CGPoint(x: self.bounds.width, y: self.bounds.height)
            arcPoints.append(contentsOf: [point3, point2, point1])
            arcCenter.x = 1.0
            arcCenter.y = self.bounds.height / 2
        case .left:
            if unitDistanceFromBoundsEdge * self.bounds.width > self.bounds.height / 2 {
                unitDistanceFromBoundsEdge = (self.bounds.height / 2) / self.bounds.width
                atMaxDistanceFromBoundsEdge = true
                print("NOTE: unitDistanceFromScreenEdge was larger than the circle radius and was reset to \(unitDistanceFromBoundsEdge).")
            }
            let point1 = CGPoint(x: 0.0, y: 0.0)
            let point2 = CGPoint(x: self.bounds.width * unitDistanceFromBoundsEdge, y: self.bounds.height / 2)
            let point3 = CGPoint(x: 0.0, y: self.bounds.height)
            arcPoints.append(contentsOf: [point1, point2, point3])
            arcCenter.x = -1.0
            arcCenter.y = self.bounds.height / 2
        }
        
        let distance12 = findDistance(between: arcPoints[0], and: arcPoints[1])
        let distance13 = findDistance(between: arcPoints[0], and: arcPoints[2])
        let distance23 = findDistance(between: arcPoints[1], and: arcPoints[2])
        let operand1 = distance12 + distance13 + distance23
        let operand2 = distance12 - distance13 + distance23
        let operand3 = distance12 + distance13 - distance23
        let operand4 = distance13 + distance23 - distance12
        let operand5 = CGFloat(sqrt(Double(operand1 * operand2 * operand3 * operand4)))
        
        let radius = (distance12 * distance13 * distance23) / operand5
        
        
        if arcCenter.x == 1.0 || arcCenter.x == -1.0 {
            arcCenter.x = arcPoints[1].x + (arcCenter.x * radius)
        }
        else if arcCenter.y == 1.0 || arcCenter.y == -1.0 {
            arcCenter.y = arcPoints[1].y + (arcCenter.y * radius)
        }
        
        var arcAngle: CGFloat = 0.0
        if atMaxDistanceFromBoundsEdge {arcAngle = CGFloat.pi}
        else {
            let radiusSquared = pow(radius, 2)
            let doubleRadiusSquared = 2 * radiusSquared
            let distance13Squared = pow(distance13, 2)
            let operand6 = distance13Squared / doubleRadiusSquared
            let operand7 = 1 - operand6
            arcAngle = abs(acos(operand7))
        }
        
        func transformPoint(_ point: CGPoint, byAngle alpha: CGFloat) -> CGPoint {
            let sinAlpha = sin(alpha)
            let cosAlpha = cos(alpha)
            let newX = (point.x - arcCenter.x) * cosAlpha + (arcCenter.y - point.y) * sinAlpha + arcCenter.x
            let newY = (point.x - arcCenter.x) * sinAlpha - (arcCenter.y - point.y) * cosAlpha + arcCenter.y
            return CGPoint(x: newX, y: newY)
        }
        
        var unorderedCenters = [CGPoint]()
        if useEndPointsOnArc {
            let arcIncrement = arcAngle / CGFloat(numViews - 1)
            unorderedCenters.append(arcPoints[0])
            var alpha = arcIncrement
            for _ in 1...numViews - 2 {
                unorderedCenters.append(transformPoint(arcPoints[0], byAngle: alpha))
                alpha += arcIncrement
            }
            unorderedCenters.append(arcPoints[2])
        }
        else {
            let segmentCount = numViews + 1
            let arcIncrement = arcAngle / CGFloat(segmentCount)
            var alpha = arcIncrement
            for _ in 1...numViews {
                unorderedCenters.append(transformPoint(arcPoints[0], byAngle: alpha))
                alpha += arcIncrement
            }
        }
        
        var centers = [CGPoint]()
        var sameMaxYs = [CGPoint]()
        while !unorderedCenters.isEmpty {
            
            sameMaxYs.removeAll()
            
            let maxY = unorderedCenters.max(by: {$0.y > $1.y})!.y
            var index = unorderedCenters.index(where: {$0.y < maxY + 0.1 && $0.y > maxY - 0.1})
            while index != nil {
                sameMaxYs.append(unorderedCenters[index!])
                unorderedCenters.remove(at: index!)
                index = unorderedCenters.index(where: {$0.y == maxY})
            }
            sameMaxYs.sort(by: {$0.x < $1.x})
            
            centers.append(contentsOf: sameMaxYs)
        }
        
        for (center, view) in managedViews.enumerated() {view.center = centers[center]}
    }
    
    func addManagedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        managedViews.append(view)
        self.addSubview(view)
    }
    
    func addManagedSubviews(_ views: [UIView]) {
        for view in views {addManagedSubview(view)}
    }

}
