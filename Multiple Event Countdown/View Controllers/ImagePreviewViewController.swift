//
//  ImagePreviewViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/1/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CloudKit

class ImagePreviewViewController: UIViewController, CountdownImageDelegate {
    
    //
    // MARK: - Paramters
    //
    
    //
    // MARK: Data Model
    
    var image: EventImage! {
        didSet {
            image.delegate = self
        }
    }
    
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: Types
    
    enum LoadStatuses {
        case locating, fetching, creating, done
        
        var message: String {
            switch self {
            case .locating: return "Locating Image"
            case .fetching: return "Fetching Image"
            case .creating: return "Creating Image"
            case .done: return "Done!"
            }
        }
    }
    
    //
    // MARK: Flags
    
    fileprivate var loadStatus: LoadStatuses = .locating {
        didSet {
            loadingStatusLabel?.text = loadStatus.message
            if loadStatus == .done && oldValue != .done {previewTypeButtonsStackView.isHidden = false}
            else if loadStatus != .done && oldValue == .done {previewTypeButtonsStackView.isHidden = true}
        }
    }
    fileprivate var hasMask: Bool?
    
    //
    // MARK: UI Content
    
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var loadingStatusLabel: UILabel?
    @IBOutlet weak var previewTypeButtonsStackView: UIStackView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var fullSizeButton: UIButton!
    @IBOutlet weak var homePreviewView: UIView!
    @IBOutlet weak var fullSizePreviewView: UIView!
    var homePreviewCell: EventTableViewCell!
    var fullSizePreviewCell: EventTableViewCell!
    
    lazy var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleNavButtonClick(_:)))
    
    //
    // MARK: Constants
    
    fileprivate struct PreviewTypeButtonTitles {
        static let homePreview = "Home Image"
        static let fullScreenPreview = "Original Image"
    }
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = doneButton
        homeButton.addTarget(self, action: #selector(handlePreviewTypeButtonClick(_:)), for: .touchUpInside)
        fullSizeButton.addTarget(self, action: #selector(handlePreviewTypeButtonClick(_:)), for: .touchUpInside)
        
        homeButton.setTitle(PreviewTypeButtonTitles.homePreview, for: .normal)
        homeButton.setTitle(PreviewTypeButtonTitles.homePreview, for: .selected)
        fullSizeButton.setTitle(PreviewTypeButtonTitles.fullScreenPreview, for: .normal)
        fullSizeButton.setTitle(PreviewTypeButtonTitles.fullScreenPreview, for: .selected)
        
        if let specialEventNib = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let view = specialEventNib[0] as? EventTableViewCell {
                homePreviewCell = view
                homePreviewCell!.translatesAutoresizingMaskIntoConstraints = false
                homePreviewView.addSubview(homePreviewCell!)
                homePreviewView.topAnchor.constraint(equalTo: homePreviewCell!.topAnchor).isActive = true
                homePreviewView.rightAnchor.constraint(equalTo: homePreviewCell!.rightAnchor).isActive = true
                homePreviewView.bottomAnchor.constraint(equalTo: homePreviewCell!.bottomAnchor).isActive = true
                homePreviewView.leftAnchor.constraint(equalTo: homePreviewCell!.leftAnchor).isActive = true
                homePreviewCell!.configuration = .imagePreviewControllerCell
            }
        }
        if let specialEventNib2 = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let view2 = specialEventNib2[0] as? EventTableViewCell {
                fullSizePreviewCell = view2
                fullSizePreviewCell!.translatesAutoresizingMaskIntoConstraints = false
                fullSizePreviewView.addSubview(fullSizePreviewCell!)
                fullSizePreviewView.topAnchor.constraint(equalTo: fullSizePreviewCell!.topAnchor).isActive = true
                fullSizePreviewView.rightAnchor.constraint(equalTo: fullSizePreviewCell!.rightAnchor).isActive = true
                fullSizePreviewView.bottomAnchor.constraint(equalTo: fullSizePreviewCell!.bottomAnchor).isActive = true
                fullSizePreviewView.leftAnchor.constraint(equalTo: fullSizePreviewCell!.leftAnchor).isActive = true
                fullSizePreviewCell!.configuration = .imagePreviewControllerDetail
                fullSizePreviewCell!.useGradient = false
            }
        }
        
        getImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .lightContent}
    override func viewWillDisappear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .default}

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    //
    // MARK: - Delegate Methods
    //
    
    func fetchComplete(forImageTypes types: [CountdownImage.ImageType], success: [Bool]) {
        if let i = types.index(where: {$0 == CountdownImage.ImageType.mask}) {
            if success[i] {hasMask = true}
            else {hasMask = false}
            if image.mainImage?.cgImage != nil {performImageSetup()}
        }
        else if let i = types.index(where: {$0 == CountdownImage.ImageType.main}) {
            if success[i] {
                if let _hasMask = hasMask {
                    if _hasMask {if image.maskImage?.cgImage != nil {performImageSetup()}}
                    else {performImageSetup()}
                }
            }
            else {
                // TODO: Error handling
                fatalError("There was an error fetching the main image from the cloud!")
            }
        }
    }
    
    
    //
    // MARK: - Target-Action and Objc Targeted Methods
    //
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        if let button = sender as? UIBarButtonItem {
            if button == doneButton {
                if let navController = self.presentingViewController as? UINavigationController {
                    let selectImageController = navController.viewControllers[0] as! SelectImageViewController
                    selectImageController.selectedImage = image
                    selectImageController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc fileprivate func handlePreviewTypeButtonClick(_ sender: UIButton?) {
        if let button = sender, let buttonTitle = button.titleLabel?.text {
            switch buttonTitle {
            case PreviewTypeButtonTitles.homePreview:
                homeButton.isSelected = true
                fullSizeButton.isSelected = false
                homePreviewView.isHidden = false
                fullSizePreviewView.isHidden = true
            case PreviewTypeButtonTitles.fullScreenPreview:
                fullSizeButton.isSelected = true
                homeButton.isSelected = false
                homePreviewView.isHidden = true
                fullSizePreviewView.isHidden = false
            default:
                // TODO: Error Handling
                fatalError("Unrecognized State: encountered an unknown button title in the ImagePreviewController!")
            }
        }
    }
    
    
    //
    // MARK: - Private Methods
    //

    fileprivate func getImage() {
        if image.mainImage?.cgImage == nil {loadStatus = .fetching}
        if image.maskImage?.cgImage == nil {loadStatus = .fetching}
        else {performImageSetup()}
    }
    
    fileprivate func performImageSetup() {
        loadStatus = .creating
        homePreviewCell.eventImage = image
        fullSizePreviewCell.eventImage = image
        loadStatus = .done
        loadingStackView.isHidden = true
        homeButton.sendActions(for: .touchUpInside)
    }
}
