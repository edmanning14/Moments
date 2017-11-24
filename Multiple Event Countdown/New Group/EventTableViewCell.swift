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
    
    var eventDate: Date? {didSet {initializePhotosAndMask()}}
    
    var mainImage: UIImage? {
        didSet {
            if clippedMainImage == nil  && mainImage != nil {
                clippedMainImage = formatImage(mainImage!)
            }
        }
    }
    var overlayImage: UIImage? {
        didSet {
            if clippedOverlayImage == nil && overlayImage != nil {
                clippedOverlayImage = formatImage(overlayImage!)
            }
        }
    }
    var clippedMainImage: UIImage? {didSet {initializePhotosAndMask()}}
    var clippedOverlayImage: UIImage? {didSet {initializePhotosAndMask()}}
    
    var containedImages: packageContents {
        if mainImage == nil && overlayImage == nil {return .none}
        else if mainImage != nil && overlayImage == nil {return .mainOnly}
        else if mainImage == nil && overlayImage != nil {return .overlayOnly}
        else {return .mainAndOverlay}
    }
    
    enum packageContents {case none, mainOnly, overlayOnly, mainAndOverlay}
    
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
    fileprivate func formatImage(_ image: UIImage) -> UIImage? {
        
        if let cgImage = image.cgImage {
            let imageWidth = CGFloat(integerLiteral: cgImage.width)
            
            let frameY = CGFloat(integerLiteral: cgImage.height) / 2
            
            let cellAR = contentView.frame.width / contentView.frame.height
            let clippingHeight = imageWidth / cellAR
            
            let clippingFrame = CGRect(x: 0.0, y: frameY, width: imageWidth, height: clippingHeight)
            
            if let clippedImage = cgImage.cropping(to: clippingFrame) {return UIImage(cgImage: clippedImage)}
        }
        return nil
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
            imageMask.contents = clippedMainImage!
            maskInitialized = true
        }
        
        switch containedImages {
        case .none:
            if contentView.layer.sublayers != nil {contentView.layer.sublayers!.removeAll()}
            contentView.layer.backgroundColor = UIColor.black.cgColor
        case .mainOnly:
            if !maskInitialized {initialzeMask()}
        case .overlayOnly:
            contentView.layer.backgroundColor = UIColor.black.cgColor
            contentView.layer.contents = clippedOverlayImage!
        case .mainAndOverlay:
            contentView.layer.backgroundColor = UIColor.black.cgColor
            contentView.layer.contents = clippedOverlayImage!
            if !maskInitialized {initialzeMask()}
        }
    }
    
    // Function to update mask alongside event timers.
    fileprivate func updateMask() -> Void {
        guard maskInitialized else {return} // Guard against mask not being initialized.
    }
}
