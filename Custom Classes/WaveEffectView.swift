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
    fileprivate var completionBlock: () -> Void = {}
    
    required init?(coder aDecoder: NSCoder) {super.init(coder: aDecoder); initSteps()}
    override init(frame: CGRect) {super.init(frame: frame); initSteps()}
    
    fileprivate func initSteps() {
        
        backgroundColor = UIColor.clear
        layer.backgroundColor = UIColor.darkGray.cgColor
        layer.opacity = 0.5
        
        let colorSet1 = [UIColor.darkGray.cgColor, UIColor.darkGray.cgColor]
        let colorSet2 = [UIColor.lightGray.cgColor, UIColor.darkGray.cgColor]
        let colorSet3 = [UIColor.darkGray.cgColor, UIColor.lightGray.cgColor]
        colorSets.append(contentsOf: [colorSet1, colorSet2, colorSet3])
        
        gradientLayer.colors = colorSet1
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
    }
    
    override func draw(_ rect: CGRect) {gradientLayer.frame = rect}
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            let basicAnim = anim as! CABasicAnimation
            if basicAnim.keyPath == "opacity" && basicAnim.fromValue as! Double == 0.5 {animateGradient()}
            else if basicAnim.keyPath == "colors" {
                if currentColorSet != 0 {animateGradient()}
                else {
                    gradientLayer.removeFromSuperlayer()
                    animateFadeOut()
                }
            }
            else if basicAnim.keyPath == "opacity" && basicAnim.fromValue as! Double == 1.0 {completionBlock()}
        }
    }
    
    func animate(completionBlock: @escaping () -> Void) {
        self.completionBlock = completionBlock
        let fadeInAnim = CABasicAnimation(keyPath: "opacity")
        fadeInAnim.fromValue = 0.5
        fadeInAnim.toValue = 1.0
        fadeInAnim.duration = 0.05
        fadeInAnim.isRemovedOnCompletion = false
        fadeInAnim.delegate = self
        
        layer.add(fadeInAnim, forKey: "opacity")
        layer.opacity = 1.0
    }
    
    fileprivate func animateGradient() {
        if currentColorSet == 0 {self.layer.addSublayer(gradientLayer)}
        let gradientAnim = CABasicAnimation(keyPath: "colors")
        gradientAnim.delegate = self
        gradientAnim.duration = 0.1
        gradientAnim.fillMode = kCAFillModeForwards
        gradientAnim.isRemovedOnCompletion = false
        
        gradientAnim.fromValue = colorSets[currentColorSet]
        if currentColorSet < (colorSets.count - 1) {currentColorSet += 1} else {currentColorSet = 0}
        gradientAnim.toValue = colorSets[currentColorSet]
        
        gradientLayer.add(gradientAnim, forKey: "colorChange")
    }
    
    fileprivate func animateFadeOut() {
        let fadeOutAnim = CABasicAnimation(keyPath: "opacity")
        fadeOutAnim.fromValue = 1.0
        fadeOutAnim.toValue = 0.5
        fadeOutAnim.duration = 0.05
        fadeOutAnim.isRemovedOnCompletion = false
        fadeOutAnim.delegate = self
        
        layer.add(fadeOutAnim, forKey: "opacity")
        layer.opacity = 0.5
    }
}
