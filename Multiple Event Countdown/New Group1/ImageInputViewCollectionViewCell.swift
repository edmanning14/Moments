//
//  ImageInputViewCollectionViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/24/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class ImageInputViewCollectionViewCell: UICollectionViewCell {
    
    //
    // MARK: - Parameters
    //
    
    // UI Elements
    //
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var imageViewBackgroundView: UIView!
    
    
    //
    // MARK: - Helper Methods
    //
    
    func select() -> Void {
        layer.backgroundColor = UIColor.black.cgColor
        cellLabel.textColor = UIColor.white
    }
    
    func deselect() -> Void {
        layer.backgroundColor = UIColor.groupTableViewBackground.cgColor
        cellLabel.textColor = UIColor.black
    }
    
    func configure() -> Void {
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        layer.isOpaque = true
        
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 2.0
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
    }
}
