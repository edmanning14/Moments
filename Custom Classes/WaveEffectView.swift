//
//  WaveEffectView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/29/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CoreGraphics

class WaveEffectView: UIView, CAAnimationDelegate {

    fileprivate let gradientLayer = CAGradientLayer()
    fileprivate var colorSets = [[CGColor]]()
    fileprivate var currentColorSet = 0
    
    required init?(coder aDecoder: NSCoder) {super.init(coder: aDecoder); initSteps()}
    override init(frame: CGRect) {super.init(frame: frame); initSteps()}
    
    fileprivate func initSteps() {
        let colorSet1 = [UIColor.darkGray.cgColor, UIColor.darkGray.cgColor]
        let colorSet2 = [UIColor.lightGray.cgColor, UIColor.darkGray.cgColor]
        let colorSet3 = [UIColor.darkGray.cgColor, UIColor.lightGray.cgColor]
        colorSets.append(contentsOf: [colorSet1, colorSet2, colorSet3])
        
        gradientLayer.colors = colorSet1
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.layer.addSublayer(gradientLayer)
    }
    
    override func draw(_ rect: CGRect) {gradientLayer.frame = rect}
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            if currentColorSet != 0 {animate()}
        }
    }
    
    func animate() {
        let animation = CABasicAnimation(keyPath: "colors")
        animation.delegate = self
        animation.duration = 0.3
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        animation.fromValue = colorSets[currentColorSet]
        if currentColorSet < (colorSets.count - 1) {currentColorSet += 1} else {currentColorSet = 0}
        animation.toValue = colorSets[currentColorSet]
        
        gradientLayer.add(animation, forKey: "colorChange")
    }
}
