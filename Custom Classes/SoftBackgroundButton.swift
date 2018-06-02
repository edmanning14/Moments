//
//  SoftBackgroundButton.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/8/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class SoftBackgroundButton: UIButton {
    
    var softEffectColor: UIColor = UIColor(red: 0.0, green: 180/255, blue: 1.0, alpha: 1.0) {
        didSet {layer.shadowColor = softEffectColor.cgColor}
    }
    
    fileprivate var layerInitialized = false
    fileprivate let rectXGrowthAmount: CGFloat = 15.0
    fileprivate let rectYGrowthAmount: CGFloat = 10.0

    override var isSelected: Bool {
        didSet {
            if !layerInitialized {initializeLayer()}
            if isSelected && !oldValue {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.2,
                    delay: 0.0,
                    options: .curveLinear,
                    animations: {self.layer.shadowOpacity = 0.5},
                    completion: nil
                )
            }
            else if !isSelected && oldValue {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.2,
                    delay: 0.0,
                    options: .curveLinear,
                    animations: {self.layer.shadowOpacity = 0.0},
                    completion: nil
                )
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        let shadowRect = CGRect(
            x: titleLabel!.frame.origin.x - rectXGrowthAmount,
            y: titleLabel!.frame.origin.y - rectYGrowthAmount,
            width: titleLabel!.frame.size.width + (2 * rectXGrowthAmount),
            height: titleLabel!.frame.size.height + (2 * rectYGrowthAmount)
        )
        layer.shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: shadowRect.size.height / 2).cgPath
    }
    
    fileprivate func initializeLayer() {
        backgroundColor = .clear
        layer.shadowColor = softEffectColor.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 15.0
        layerInitialized = true
    }

}
