//
//  ButtonsView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/16/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import os.log

class ButtonsView: UIView {
    
    //
    // Paramters
    //
    
    //
    // Private data model
    
    fileprivate var requiredDataButtons: [NewEventInputsControl] = []
    fileprivate var otherButtons: [NewEventInputsControl] = []
    
    fileprivate let requiredLabel = UILabel()
    fileprivate let optionalLabel = UILabel()
    fileprivate var requiredLabelInitialized = false
    fileprivate var optionalLabelInitialized = false
    
    fileprivate let firaSansFont = UIFont(name: "FiraSans-Light", size: 12.0)
    fileprivate let myErrorLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Drawing Errors")

    override func didAddSubview(_ subview: UIView) {
        if let button = subview as? NewEventInputsControl {
            if button.buttonRepresentsRequiredData {
                requiredDataButtons.append(button)
                if !requiredLabelInitialized {
                    addSubview(requiredLabel)
                    requiredLabel.text = "Required"
                    configure(label: requiredLabel)
                    requiredLabel.textColor = UIColor(displayP3Red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
                    requiredLabelInitialized = true
                }
            }
            else {
                otherButtons.append(button)
                if !optionalLabelInitialized {
                    addSubview(optionalLabel)
                    optionalLabel.text = "Optional"
                    configure(label: optionalLabel)
                    optionalLabel.textColor = UIColor.lightGray
                    optionalLabelInitialized = true
                }
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        if !requiredDataButtons.isEmpty || !otherButtons.isEmpty {
            
            // Layout guides
            let upperRowCenterGuide: CGFloat = bounds.height * 0.25
            let centerGuide: CGFloat = bounds.height / 2
            let lowerRowCenterGuide: CGFloat = bounds.height * 0.75
            
            // Resize buttons
            for button in requiredDataButtons {button.sizeToFit()}
            for button in otherButtons {button.sizeToFit()}
            
            // Locate buttons
            let requiredButtonCount = CGFloat(requiredDataButtons.count)
            for (index, button) in requiredDataButtons.enumerated() {
                let point = CGPoint(x: (bounds.width / (requiredButtonCount + 1)) * CGFloat(index + 1), y: upperRowCenterGuide)
                button.center = point
            }
            
            let otherButtonCount = CGFloat(otherButtons.count)
            for (index, button) in otherButtons.enumerated() {
                button.center = CGPoint(x: (bounds.width / (otherButtonCount + 1)) * CGFloat(index + 1), y: lowerRowCenterGuide)
            }
            
            // Draw separator.
            let separatorStartPoint = CGPoint(x: bounds.width * 0.1, y: centerGuide)
            let separatorEndPoint = CGPoint(x: bounds.width * 0.9, y: centerGuide)
            
            let path = UIBezierPath()
            path.move(to: separatorStartPoint)
            path.addLine(to: separatorEndPoint)
            path.lineWidth = 1.0
            UIColor(displayP3Red: 255.0, green: 255.0, blue: 255.0, alpha: 100.0).setStroke()
            path.stroke()
            
            // Locate labels
            if requiredLabelInitialized {
                let labelCenter = CGPoint(x: bounds.width / 2, y: centerGuide - (requiredLabel.bounds.height * 0.75))
                requiredLabel.center = labelCenter
            }
            if optionalLabelInitialized {
                let labelCenter = CGPoint(x: bounds.width / 2, y: centerGuide + (optionalLabel.bounds.height * 0.75))
                optionalLabel.center = labelCenter
            }
        }
    }
    
    //
    // MARK: Helper Functions
    //
    
    fileprivate func configure(label: UILabel) {
        label.frame = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        if firaSansFont != nil {label.font = firaSansFont}
        else {
            os_log("firaSans Font did not initialize properly during NewEventsInputControl initialization.", log: myErrorLog, type: .error)
        }
        label.sizeToFit()
    }
}
