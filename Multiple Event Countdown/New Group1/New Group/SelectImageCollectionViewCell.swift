//
//  SelectImageCollectionViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/1/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class SelectImageCollectionViewCell: UICollectionViewCell {
    
    var image: UIImage? {didSet {cellImageView.image = image}}
    var imageTitle: String? {didSet {cellLabel.text = imageTitle}}
    var imageIsAvailable = false {
        didSet {
            glyphImageView.tintColor = UIColor.lightGray
            if imageIsAvailable {
                glyphImageView.isHidden = true
                if isSelected {labelSelected()} else {labelNotSelected()}
            }
        }
    }

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var glyphImageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            if isSelected != oldValue {
                if isSelected {glyphImageView.isHidden = true; cellLabel.isHidden = false; labelSelected()}
                else {
                    if imageIsAvailable {labelNotSelected()}
                    else {glyphImageView.isHidden = false; cellLabel.isHidden = true}
                }
            }
        }
    }
    
    fileprivate func labelSelected() {cellLabel.textColor = UIColor.white}
    fileprivate func labelNotSelected() {cellLabel.textColor = UIColor.black}
}
