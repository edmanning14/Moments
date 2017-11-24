//
//  ImageInputView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class ImageInputView: UIView {

    //
    // MARK: - Parameters
    //
    
    // Data Model
    //
    
    let lastButtonSelected: Options = .app
    enum Options {case app, user, none}
    
    // UI Items
    //
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var appImagesButton: UIButton!
    @IBOutlet weak var userImageButton: UIButton!
    @IBOutlet weak var noImageButton: UIButton!
    
    @IBOutlet weak var collectionViewContainer: UIView!
    @IBOutlet weak var viewSeparator: UIView!
    
    
    //
    // MARK: - View Lifecycle
    //
    
    override func awakeFromNib() {
        self.sizeToFit()
        expandButton.addTarget(self, action: #selector(handleButtonClick(_:)), for: .touchUpInside)
        appImagesButton.addTarget(self, action: #selector(handleButtonClick(_:)), for: .touchUpInside)
        userImageButton.addTarget(self, action: #selector(handleButtonClick(_:)), for: .touchUpInside)
        noImageButton.addTarget(self, action: #selector(handleButtonClick(_:)), for: .touchUpInside)
        
        switch lastButtonSelected {
        case .app: select(button: appImagesButton)
        case .user: select(button: userImageButton)
        case .none: select(button: noImageButton)
        }
    }
    
    
    //
    // MARK: - Target-Action Methods
    //
    
    @objc fileprivate func handleButtonClick(_ button: UIButton) -> Void {
        switch button.titleLabel!.text! {
        case "Expand":
            break
        case "Catalog", "Personal Photo", "None":
            if !button.isSelected {select(button: button)}
        default:
            break
        }
    }
    
    
    //
    // MARK: - Class Methods
    //
    
    internal func select(button: UIButton) -> Void {
        
        // Select requested button, deselect others, change collectionView data as necessary.
        button.isSelected = true
        if button == appImagesButton {
            userImageButton.isSelected = false; noImageButton.isSelected = false
            showHideCollectionView()
            imageCollectionView.reloadData()
        }
        else if button == userImageButton {
            appImagesButton.isSelected = false; noImageButton.isSelected = false
            showHideCollectionView()
            imageCollectionView.reloadData()
        }
        else if button == noImageButton {
            userImageButton.isSelected = false; appImagesButton.isSelected = false
            showHideCollectionView()
        }
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func showHideCollectionView() -> Void {
        if imageCollectionView.isHidden {
            imageCollectionView.isHidden = false
            collectionViewContainer.backgroundColor = UIColor.white
        }
        else {
            imageCollectionView.isHidden = true
            collectionViewContainer.backgroundColor = UIColor.lightGray
        }
    }
}
