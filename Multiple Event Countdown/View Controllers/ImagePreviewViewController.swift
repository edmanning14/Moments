//
//  ImagePreviewViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/1/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CloudKit
import Photos

class ImagePreviewViewController: UIViewController, CountdownImageDelegate {
    
    //
    // MARK: - Paramters
    //
    
    //
    // MARK: Data Model
    
    var selectedImage: UserEventImage?
    fileprivate var cropRectStartEditOrigin: CGPoint?
    fileprivate var cropRectStartPanOrigin: CGPoint?
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
            if loadStatus == .done && oldValue != .done {
                if selectedImage?.locationForCellView == nil {createHomeImageButton.isHidden =  false}
                else {previewTypeButtonsStackView.isHidden = false}
            }
            else if loadStatus != .done && oldValue == .done {
                previewTypeButtonsStackView.isHidden = true
                createHomeImageButton.isHidden = true
            }
        }
    }
    fileprivate var hasMask: Bool?
    
    //
    // MARK: UI Content
    
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var loadingStatusLabel: UILabel?
    @IBOutlet weak var editingButtonsStackView: UIStackView!
    @IBOutlet weak var previewTypeButtonsStackView: UIStackView!
    @IBOutlet weak var homeButton: SoftBackgroundButton!
    @IBOutlet weak var fullSizeButton: SoftBackgroundButton!
    @IBOutlet weak var createHomeImageButton: UIButton!
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var homePreviewView: UIView!
    @IBOutlet weak var fullSizePreviewView: UIView!
    var homePreviewCell: EventTableViewCell!
    var fullSizePreviewCell: EventTableViewCell!
    var cropAreaView: UIView?
    var blurView1: UIVisualEffectView?
    var blurView2: UIVisualEffectView?
    var sideBlurView1: UIVisualEffectView?
    var sideBlurView2: UIVisualEffectView?
    
    //
    // MARK: Constants
    
    fileprivate struct PreviewTypeButtonTitles {
        static let homePreview = "HOME"
        static let fullScreenPreview = "DETAIL"
    }
    
    fileprivate let animationDuration: TimeInterval = 0.2
    
    //
    // MARK: Fonts
    let headingsFontName = "Comfortaa-Light"
    let contentSecondaryFontName = "Raleway-Regular"
    
    //
    // MARK: Colors
    let primaryTextRegularColor = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
    let primaryTextDarkColor = UIColor(red: 230/255, green: 81/255, blue: 0.0, alpha: 1.0)
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem()
        doneButton.target = self
        doneButton.action = #selector(handleNavButtonClick(_:))
        doneButton.tintColor = primaryTextDarkColor
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: contentSecondaryFontName, size: 16.0)! as Any]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.title = "USE IMAGE"
        navigationItem.rightBarButtonItem = doneButton
        if selectedImage?.locationForCellView == nil {doneButton.isEnabled = false}
        
        let navItemTitleLabel = UILabel()
        navItemTitleLabel.text = "Image Preview"
        navItemTitleLabel.backgroundColor = UIColor.clear
        navItemTitleLabel.textColor = primaryTextRegularColor
        navItemTitleLabel.font = UIFont(name: headingsFontName, size: 20.0)
        navigationItem.titleView = navItemTitleLabel
        
        homeButton.addTarget(self, action: #selector(handlePreviewTypeButtonClick(_:)), for: .touchUpInside)
        fullSizeButton.addTarget(self, action: #selector(handlePreviewTypeButtonClick(_:)), for: .touchUpInside)
        
        homeButton.setTitle(PreviewTypeButtonTitles.homePreview, for: .normal)
        homeButton.setTitle(PreviewTypeButtonTitles.homePreview, for: .selected)
        homeButton.softEffectColor = primaryTextRegularColor
        fullSizeButton.setTitle(PreviewTypeButtonTitles.fullScreenPreview, for: .normal)
        fullSizeButton.setTitle(PreviewTypeButtonTitles.fullScreenPreview, for: .selected)
        fullSizeButton.softEffectColor = primaryTextRegularColor
        
        createHomeImageButton.addTarget(self, action: #selector(handleEditButtonClick(_:)), for: .touchUpInside)
        cancelEditButton.addTarget(self, action: #selector(handleEditButtonClick(_:)), for: .touchUpInside)
        
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
                
                let bottomAnchorConstraint = homePreviewCell!.constraints.first {$0.secondAnchor == homePreviewCell!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                homePreviewCell!.bottomAnchor.constraint(equalTo: homePreviewCell!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
                
                homePreviewCell!.viewWithMargins.layer.cornerRadius = 3.0
                homePreviewCell!.viewWithMargins.layer.masksToBounds = true
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
                fullSizePreviewCell!.useMask = false
            }
        }
        
        setImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .lightContent}
    override func viewWillDisappear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .default}

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    
    //
    // MARK: - Delegate Methods
    //
    
    //
    // MARK: CountdownImageDelegate
    func fetchComplete(forImageTypes types: [CountdownImage.ImageType], success: [Bool]) {
        if let appImage = selectedImage as? AppEventImage {
            if let i = types.index(where: {$0 == CountdownImage.ImageType.mask}) {
                if success[i] {hasMask = true}
                else {hasMask = false}
                if appImage.mainImage?.cgImage != nil {performAppImageSetup()}
            }
            else if let i = types.index(where: {$0 == CountdownImage.ImageType.main}) {
                if success[i] {
                    if let _hasMask = hasMask {
                        if _hasMask {if appImage.maskImage?.cgImage != nil {performAppImageSetup()}}
                        else {performAppImageSetup()}
                    }
                }
                else {
                    // TODO: Error handling
                    fatalError("There was an error fetching the main image from the cloud!")
                }
            }
        }
        else {performUserImageSetup()}
    }
    
    
    //
    // MARK: - Target-Action and Objc Targeted Methods
    //
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        if let button = sender as? UIBarButtonItem {
            if button.title == "USE IMAGE" {
                performSegue(withIdentifier: "UnwindToNewEventController", sender: self)
            }
        }
    }
    
    @objc fileprivate func handlePreviewTypeButtonClick(_ sender: UIButton?) {
        if let button = sender, let buttonTitle = button.titleLabel?.text {
            let transition = CATransition()
            transition.type = kCATransitionPush
            transition.duration = animationDuration
            
            switch buttonTitle {
            case PreviewTypeButtonTitles.homePreview:
                transition.subtype = kCATransitionFromLeft
                homePreviewView.layer.add(transition, forKey: "transition")
                fullSizePreviewView.layer.add(transition, forKey: "transition")
                homeButton.isSelected = true
                fullSizeButton.isSelected = false
                homePreviewView.isHidden = false
                fullSizePreviewView.isHidden = true
            case PreviewTypeButtonTitles.fullScreenPreview:
                transition.subtype = kCATransitionFromRight
                homePreviewView.layer.add(transition, forKey: "transition")
                fullSizePreviewView.layer.add(transition, forKey: "transition")
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
    
    @objc fileprivate func handleEditButtonClick(_ sender: UIButton) {
        
        func removeCropRect() {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: animationDuration,
                delay: 0.0,
                options: .curveEaseIn,
                animations: {
                    self.blurView1!.layer.opacity = 0.0
                    self.blurView2!.layer.opacity = 0.0
                    self.sideBlurView1?.layer.opacity = 0.0
                    self.sideBlurView2?.layer.opacity = 0.0
                },
                completion: { [weak self] (_) in
                    self?.cropAreaView?.removeFromSuperview()
                    self?.cropAreaView = nil
                    self?.blurView1?.removeFromSuperview()
                    self?.blurView1 = nil
                    self?.blurView2?.removeFromSuperview()
                    self?.blurView2 = nil
                    self?.sideBlurView1?.removeFromSuperview()
                    self?.sideBlurView1 = nil
                    self?.sideBlurView2?.removeFromSuperview()
                    self?.sideBlurView2 = nil
                }
            )
        }
        
        if sender.title(for: .normal) == "CANCEL" {
            removeCropRect()
            cancelEditButton.isHidden = true
            createHomeImageButton.isSelected = false
            previewTypeButtonsStackView.isHidden = false
        }
        else {
            if !sender.isSelected {
                previewTypeButtonsStackView.isHidden = true
                cancelEditButton.isHidden = false
                if let imageFrame = fullSizePreviewCell.mainImageView?.imageFrame {
                    
                    func createSideBlurs() {
                        let blurEffect = UIBlurEffect(style: .dark)
                        sideBlurView1 = UIVisualEffectView(effect: blurEffect)
                        sideBlurView1!.layer.opacity = 0.0
                        sideBlurView1!.translatesAutoresizingMaskIntoConstraints = false
                        sideBlurView2 = UIVisualEffectView(effect: blurEffect)
                        sideBlurView2!.layer.opacity = 0.0
                        sideBlurView2!.translatesAutoresizingMaskIntoConstraints = false
                        
                        fullSizePreviewView.addSubview(sideBlurView1!)
                        fullSizePreviewView.addSubview(sideBlurView2!)
                        
                        let sideBlur1Width = fullSizePreviewCell.mainImageView!.imageFrame!.origin.x
                        let sideBlur2Width = fullSizePreviewView.frame.width - (fullSizePreviewCell.mainImageView!.imageFrame!.origin.x + fullSizePreviewCell.mainImageView!.imageFrame!.width)
                        let sideBlurHeight = fullSizePreviewView.frame.height
                        let sideBlur2x = fullSizePreviewCell.mainImageView!.imageFrame!.origin.x + fullSizePreviewCell.mainImageView!.imageFrame!.width
                        
                        sideBlurView1!.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sideBlur1Width, height: sideBlurHeight))
                        sideBlurView2!.frame = CGRect(x: sideBlur2x, y: 0.0, width: sideBlur2Width, height: sideBlurHeight)
                    }
                    
                    if fullSizePreviewView.isHidden {fullSizeButton.sendActions(for: .touchUpInside)}
                    
                    let blurEffect = UIBlurEffect(style: .dark)
                    blurView1 = UIVisualEffectView(effect: blurEffect)
                    blurView1!.layer.opacity = 0.0
                    blurView1!.translatesAutoresizingMaskIntoConstraints = false
                    blurView2 = UIVisualEffectView(effect: blurEffect)
                    blurView2!.layer.opacity = 0.0
                    blurView2!.translatesAutoresizingMaskIntoConstraints = false
                    
                    cropAreaView = UIView()
                    cropAreaView!.translatesAutoresizingMaskIntoConstraints = false
                    cropAreaView!.backgroundColor = UIColor.clear
                    
                    fullSizePreviewView.addSubview(blurView1!)
                    fullSizePreviewView.addSubview(blurView2!)
                    fullSizePreviewView.addSubview(cropAreaView!)
                    
                    let height: CGFloat = 160.0
                    let width = imageFrame.width
                    if width < fullSizePreviewView.frame.width {createSideBlurs()}
                    if cropRectStartEditOrigin == nil {
                        if selectedImage!.locationForCellView != nil {
                            let y = (fullSizePreviewCell.mainImageView!.imageFrame!.origin.y + (fullSizePreviewCell.mainImageView!.imageFrame!.height * selectedImage!.locationForCellView!)) - (height / 2)
                            cropRectStartEditOrigin = CGPoint(x: 0.0, y: y)
                            cropAreaView!.frame = CGRect(origin: cropRectStartEditOrigin!, size: CGSize(width: width, height: height))
                        }
                        else {
                            let x = imageFrame.origin.x
                            print(fullSizePreviewView.frame)
                            let y = (fullSizePreviewView.frame.height / 2) - (height / 2)
                            cropAreaView!.frame = CGRect(x: x, y: y, width: width, height: height)
                        }
                    }
                    else {
                        cropAreaView!.frame = CGRect(origin: cropRectStartEditOrigin!, size: CGSize(width: width, height: height))
                    }
                    
                    let blur1Height = cropAreaView!.frame.origin.y
                    let blur1x = imageFrame.origin.x
                    let blur1y: CGFloat = 0.0
                    blurView1!.frame = CGRect(x: blur1x, y: blur1y, width: width, height: blur1Height)
                    
                    let blur2Height = fullSizePreviewView.frame.height - height - blur1Height
                    let blur2x = imageFrame.origin.x
                    let blur2y = blur1Height + height
                    blurView2!.frame = CGRect(x: blur2x, y: blur2y, width: width, height: blur2Height)
                    
                    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropRectPan(_:)))
                    cropAreaView!.addGestureRecognizer(panGesture)
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: animationDuration, delay: 0.0, options: .curveEaseIn, animations: {
                            self.blurView1!.layer.opacity = 1.0
                            self.blurView2!.layer.opacity = 1.0
                            self.sideBlurView1?.layer.opacity = 1.0
                            self.sideBlurView2?.layer.opacity = 1.0
                    }, completion: nil)
                }
                sender.isSelected = true
            }
            else {
                let locationForCellView = ((cropAreaView!.frame.origin.y - fullSizePreviewCell.mainImageView!.imageFrame!.origin.y) + (cropAreaView!.frame.height / 2)) / fullSizePreviewCell.mainImageView!.imageFrame!.height
                selectedImage!.locationForCellView = locationForCellView
                cropRectStartEditOrigin = cropAreaView!.frame.origin
                
                removeCropRect()
                
                homePreviewCell.eventImage = selectedImage
                homeButton.isEnabled = true
                homeButton.layer.opacity = 1.0
                homeButton.sendActions(for: .touchUpInside)
                
                previewTypeButtonsStackView.isHidden = false
                cancelEditButton.isHidden = true
                sender.isSelected = false
                sender.setTitle("EDIT HOME IMAGE", for: .normal)
                navigationItem.rightBarButtonItem!.isEnabled = true
            }
        }
    }
    
    @objc fileprivate func handleCropRectPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed, .ended:
            if sender.state == .began {cropRectStartPanOrigin = cropAreaView!.frame.origin}
            let translation = sender.translation(in: homePreviewView)
            let newCropRect = CGRect(x: cropAreaView!.frame.origin.x, y: cropRectStartPanOrigin!.y + translation.y, width: cropAreaView!.frame.width, height: cropAreaView!.frame.height)
            guard fullSizePreviewCell.mainImageView!.imageFrame!.contains(newCropRect) else {return}
            cropAreaView!.frame = newCropRect
            blurView1!.frame.size.height = cropRectStartPanOrigin!.y + translation.y
            blurView2!.frame.origin.y = cropRectStartPanOrigin!.y + translation.y + cropAreaView!.frame.height
            blurView2!.frame.size.height = fullSizePreviewView.frame.height - (cropRectStartPanOrigin!.y + translation.y + cropAreaView!.frame.height)
        default: break
        }
    }
    
    
    //
    // MARK: - Private Methods
    //
    
    fileprivate func setImage() {
        if selectedImage != nil {
            selectedImage!.delegate = self
            if let appImage = selectedImage as? AppEventImage {
                if appImage.mainImage?.cgImage == nil {loadStatus = .fetching}
                if appImage.maskImage?.cgImage == nil {loadStatus = .fetching}
                else {performAppImageSetup()}
            }
            else {
                if selectedImage!.mainImage?.cgImage == nil {loadStatus = .fetching}
                else {performUserImageSetup()}
            }
        }
    }
    
    fileprivate func performAppImageSetup() {
        let appImage = selectedImage as! AppEventImage
        loadStatus = .creating
        homePreviewCell.eventImage = appImage
        fullSizePreviewCell.eventImage = appImage
        loadStatus = .done
        homeButton.sendActions(for: .touchUpInside)
        loadingStackView.isHidden = true
        previewTypeButtonsStackView.isHidden = false
    }
    
    fileprivate func performUserImageSetup() {
        fullSizePreviewCell.eventImage = selectedImage!
        if selectedImage!.locationForCellView != nil {createHomeImageButton.setTitle("EDIT HOME IMAGE", for: .normal)}
        loadStatus = .done
        loadingStackView.isHidden = true
        editingButtonsStackView.isHidden = false
        previewTypeButtonsStackView.isHidden = false
        if selectedImage!.locationForCellView != nil {
            homePreviewCell.eventImage = self.selectedImage!
            homeButton.isEnabled = true
            homeButton.layer.opacity = 1.0
            homeButton.sendActions(for: .touchUpInside)
        }
        else {
            homeButton.isEnabled = false
            homeButton.layer.opacity = 0.5
            fullSizeButton.sendActions(for: .touchUpInside)
        }
    }
}
