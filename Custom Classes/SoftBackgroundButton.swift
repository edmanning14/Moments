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
    fileprivate let rectGrowthAmount: CGFloat = 20.0

    override var isSelected: Bool {
        didSet {
            if !layerInitialized {initializeLayer()}
            if isSelected && !oldValue {layer.shadowOpacity = 0.25}
            else if !isSelected && oldValue {layer.shadowOpacity = 0.0}
        }
    }
    
    override func draw(_ rect: CGRect) {
        let shadowRect = CGRect(
            x: titleLabel!.frame.origin.x - rectGrowthAmount,
            y: titleLabel!.frame.origin.y - rectGrowthAmount,
            width: titleLabel!.frame.size.width + (2 * rectGrowthAmount),
            height: titleLabel!.frame.size.height + (2 * rectGrowthAmount)
        )
        layer.shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: shadowRect.size.height / 2).cgPath
    }
    
    fileprivate func initializeLayer() {
        backgroundColor = .clear
        layer.shadowColor = softEffectColor.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        layer.shadowRadius = 10.0
        layerInitialized = true
    }

}
