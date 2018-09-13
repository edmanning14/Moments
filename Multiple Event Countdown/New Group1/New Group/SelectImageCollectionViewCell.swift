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
    /*var imageIsAvailable = false {
        didSet {
            glyphImageView.tintColor = UIColor.lightGray
            cellLabel.textColor = primaryTextRegularColor
            cellLabel.font = UIFont(name: contentSecondaryFontName, size: 12.0)
            if imageIsAvailable {
                glyphImageView.isHidden = true
                cellLabel.isHidden = false
            }
            else {
                if !isSelected {
                    glyphImageView.isHidden = false
                    cellLabel.isHidden = true
                }
                else {
                    glyphImageView.isHidden = true
                    cellLabel.isHidden = false
                }
            }
        }
    }*/

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    
    /*override var isSelected: Bool {
        didSet {
            if isSelected != oldValue && !imageIsAvailable {
                if isSelected {glyphImageView.isHidden = true; cellLabel.isHidden = false}
                else {glyphImageView.isHidden = false; cellLabel.isHidden = true}
            }
        }
    }*/
    
    //fileprivate func labelSelected() {cellLabel.textColor = UIColor.white}
    //fileprivate func labelNotSelected() {cellLabel.textColor = primaryTextRegularColor}
}
