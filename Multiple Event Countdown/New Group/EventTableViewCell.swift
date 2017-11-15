//
//  EventTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/23/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    //
    // MARK: - Variables and Constants
    //
    
    // Data Model
    var eventTitle: String? {didSet {testLabel.text = eventTitle ?? "New Event"}}
    
    var eventDate: Date? {
        didSet {
            convertPhotos()
        }
    }
    
    var images = EventImageSet() {didSet {initializePhotosAndMask()}}
    
    var imageMask: CAGradientLayer?
    
    // References and Outlets
    @IBOutlet weak var testLabel: UILabel!
    
    // Boolean Test Values
    var maskInitialized = false
    
    
    
    //
    // MARK: - Cell Lifecylce
    //
    
    override func awakeFromNib() {super.awakeFromNib()}
    override func setSelected(_ selected: Bool, animated: Bool) {super.setSelected(selected, animated: animated)}
    
    
    //
    // MARK: - Instance Methods
    //
    
    // Function to update the displayed event times.
    internal func Update() {
        let currentDate = Date()
        if let timeInterval = eventDate?.timeIntervalSince(currentDate){
            if timeInterval > 0.0 {
                //let formattedTimeInterval = FormatInterval(interval: timeInterval)
                updateMask()
            }
        }
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    // Function to initialize photo backgrouds.
    fileprivate func convertPhotos() -> Void {
        
        // function clips image to specified bounds. Returns nil if image clip failed.
        func clipImage(image: CGImage) -> CGImage? {
            let imageWidth = CGFloat(integerLiteral: image.width)
            
            let frameY = CGFloat(integerLiteral: image.height) / 2
            
            let cellAR = contentView.frame.width / contentView.frame.height
            let clippingHeight = imageWidth / cellAR
            
            let clippingFrame = CGRect(x: 0.0, y: frameY, width: imageWidth, height: clippingHeight)
            
            if let clippedImage = image.cropping(to: clippingFrame) {return clippedImage}
            else {return nil}
        }
        
        if let cgDesertDunesOriginal = UIImage(named: "Desert Dunes Original")?.cgImage {
            images.originalImage = clipImage(image: cgDesertDunesOriginal)
        }
        if let cgDesertDunesTrace = UIImage(named: "Desert Dunes Trace")?.cgImage {
            images.traceImage = clipImage(image: cgDesertDunesTrace)
        }
    }
    
    // Function to initialize the mask whith photo data.
    fileprivate func initializePhotosAndMask() -> Void {
        
        func initialzeMask() -> Void {
            let imageMask = CAGradientLayer()
            imageMask.frame = contentView.frame
            imageMask.startPoint = CGPoint(x: 0.0, y: 0.5)
            imageMask.endPoint = CGPoint(x: 1.0, y: 0.5)
            imageMask.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
            imageMask.locations = [NSNumber(value: 0.0),NSNumber(value: 1.0)]
            imageMask.contents = images.originalImage
            maskInitialized = true
        }
        
        switch images.containedImages {
        case .none:
            if contentView.layer.sublayers != nil {contentView.layer.sublayers!.removeAll()}
            contentView.layer.backgroundColor = UIColor.black.cgColor
        case .originalOnly:
            if !maskInitialized {initialzeMask()}
        case .traceOnly:
            contentView.layer.backgroundColor = UIColor.black.cgColor
            contentView.layer.contents = images.traceImage
        case .originalAndTrace:
            contentView.layer.backgroundColor = UIColor.black.cgColor
            contentView.layer.contents = images.traceImage
            if !maskInitialized {initialzeMask()}
        }
    }
    
    // Function to update mask alongside event timers.
    fileprivate func updateMask() -> Void {
        guard maskInitialized else {return} // Guard against mask not being initialized.
    }
}
