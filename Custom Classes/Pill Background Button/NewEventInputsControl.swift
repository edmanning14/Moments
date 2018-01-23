//
//  NewEventInputsControl.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import QuartzCore
import CoreGraphics
import os.log

@IBDesignable class NewEventInputsControl: UIControl {
    
    //
    // MARK: - Parameters
    //
    
    //
    // Public Data Model
    
    var glyphSizeInPts = CGSize(width: 40.0, height: 40.0) {
        didSet {
            resizeImage()
            recalcOptimalLabelBackgroundSize()
        }
    }
    var buttonTitle = "Title" {
        didSet {
            buttonTitleLabel.text = buttonTitle
            recalcOptimalLabelBackgroundSize()
        }
    }
    var buttonTitleFont: UIFont? {
        didSet {
            if buttonTitleFont != nil {buttonTitleLabel.font = buttonTitleFont!}
            recalcOptimalLabelBackgroundSize()
        }
    }
    var buttonImageTitle: String? {
        didSet {
            initializeImage()
        }
    }
    var dataAcquired = false {
        didSet{
            if buttonImageView.image != nil {
                tintImage()
            }
        }
    }
    var buttonRepresentsRequiredData = false
    
    //
    // Private Data Model
    
    fileprivate var optimalLabelBackgroundSize = CGSize()
    fileprivate let deviceColorSpace = CGColorSpaceCreateDeviceRGB()
    fileprivate var buttonImage: UIImage? {didSet {buttonImageView.image = buttonImage}}
    
    //
    // References and UI Elements
    
    fileprivate let buttonImageView = UIImageView()
    fileprivate let labelBackgroundView = LabelBackgroundView()
    fileprivate let buttonTitleLabel = UILabel()
    
    //
    // Flags
    
    //
    // Other
    
    fileprivate let defaultFont = UIFont(name: "FiraSans-Light", size: 14.0)
    fileprivate let myErrorLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Drawing Errors")
    
    //
    // MARK: - Control Lifecycle
    //
    
    //
    // Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // WARNING: If implementing in storyboard, complete this implementation.
        fatalError("Incomplete init implementation!")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        initializeViews()
    }
    
    convenience init(frame: CGRect, buttonTitle title: String, font: UIFont?, buttonImageTitled imageTitle: String?, isDataRequired: Bool?, sizeOfGlyph: CGSize?) {
        self.init(frame: frame)
        if isDataRequired != nil {buttonRepresentsRequiredData = isDataRequired!}
        buttonTitle = title
        buttonTitleFont = font
        if buttonTitleFont != nil {buttonTitleLabel.font = buttonTitleFont!}
        buttonTitleLabel.text = buttonTitle
        if sizeOfGlyph != nil {glyphSizeInPts = sizeOfGlyph!}
        if imageTitle != nil {
            buttonImageTitle = imageTitle
            initializeImage()
        }
        recalcOptimalLabelBackgroundSize()
    }
    
    //
    // Methods
    
    override func draw(_ rect: CGRect) {
        
        //print("Passed Rect: \(rect)")
        //print("Button Bounds: \(bounds)")
        //print("Label Background View Frame: \(labelBackgroundView.frame)")
        
        switch self.state {
        case .selected: drawSelectedState(withRect: rect)
        case .normal: drawNormalState(withRect: rect)
        default: break
        }
    }
    
    override func sizeToFit() {
        buttonTitleLabel.sizeToFit()
        buttonImageView.frame.size = glyphSizeInPts
        
        recalcOptimalLabelBackgroundSize()
        labelBackgroundView.frame.size = optimalLabelBackgroundSize
        
        var newWidth: CGFloat = 0.0
        var newHeight: CGFloat = 0.0
        if glyphSizeInPts.height > optimalLabelBackgroundSize.height {newHeight = glyphSizeInPts.height}
        else {newHeight = optimalLabelBackgroundSize.height}
        if glyphSizeInPts.width > optimalLabelBackgroundSize.width {newWidth = glyphSizeInPts.width}
        else {newWidth = optimalLabelBackgroundSize.width}
        frame.size = CGSize(width: newWidth, height: newHeight)
       
        buttonImageView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        labelBackgroundView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        buttonTitleLabel.center = CGPoint(x: labelBackgroundView.bounds.width / 2, y: labelBackgroundView.bounds.height / 2)
    }
    
    
    //
    // MARK: - Delegate Methods
    //
    
    
    //
    // MARK: - Public Methods
    //
    
    
    
    //
    // MARK: - Helper Methods
    //
    
    fileprivate func initializeViews() {
        buttonImageView.backgroundColor = UIColor.clear
        buttonImageView.contentMode = .scaleAspectFit
        self.addSubview(buttonImageView)
        
        labelBackgroundView.backgroundColor = UIColor.clear
        
        labelBackgroundView.addSubview(buttonTitleLabel)
        buttonTitleLabel.text = buttonTitle
        buttonTitleLabel.textColor = UIColor.green
        buttonTitleLabel.textAlignment = .center
        buttonTitleLabel.backgroundColor = UIColor.clear
        buttonTitleLabel.sizeToFit()
        if buttonTitleFont != nil {buttonTitleLabel.font = buttonTitleFont!}
        else {
            if defaultFont != nil {buttonTitleLabel.font = defaultFont}
            else {
                os_log("firaSans Font did not initialize properly during NewEventsInputControl initialization.", log: myErrorLog, type: .error)
            }
        }
    }
    
    fileprivate func initializeImage() {
        if buttonImageTitle != nil {
            if let image = UIImage(named: buttonImageTitle!)?.withRenderingMode(.alwaysTemplate) {
                buttonImage = image
                resizeImage()
                tintImage()
            }
            else {
                // TODO: Fail this gracefully.
                fatalError("There was an error creating the \(buttonImageTitle!) image!")
            }
        }
    }
    
    fileprivate func resizeImage() {
        buttonImageView.frame.size = glyphSizeInPts
        buttonImageView.center = CGPoint(x: bounds.width / 2, y: bounds.width / 2)
    }
    
    fileprivate func tintImage() -> Void {
        if buttonImageView.image != nil {
            if dataAcquired {buttonImageView.tintColor = UIColor.green}
            else {
                let dataRequiredColor = UIColor(displayP3Red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
                if buttonRepresentsRequiredData {buttonImageView.tintColor = dataRequiredColor}
                else {buttonImageView.tintColor = UIColor.lightGray}
            }
        }
    }
    
    fileprivate func recalcOptimalLabelBackgroundSize() {
        let optimalLabelBackgroundHeight = buttonTitleLabel.bounds.height * 1.75
        let optimalOuterRadius = optimalLabelBackgroundHeight / 2
        let backgroundWidth = buttonTitleLabel.frame.width + (2 * optimalOuterRadius)
        
        optimalLabelBackgroundSize = CGSize(width: backgroundWidth, height: optimalLabelBackgroundHeight)
    }
    
    fileprivate func drawNormalState(withRect rect: CGRect) -> Void {
        for subview in subviews {if subview is LabelBackgroundView {subview.removeFromSuperview()}}
    }
    
    fileprivate func drawSelectedState(withRect rect: CGRect) -> Void {
        labelBackgroundView.frame.size = optimalLabelBackgroundSize
        labelBackgroundView.center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        addSubview(labelBackgroundView)
    }
}
