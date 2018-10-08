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
import os

class ImagePreviewViewController: UIViewController, CountdownImageDelegate, UITabBarDelegate, UIPopoverPresentationControllerDelegate {
    
    //
    // MARK: - Paramters
    //
    
    //
    // MARK: Data Model
    
    var selectedImage: UserEventImage?
    var locationForCellView: CGFloat? {
        didSet {
            if isViewLoaded {
                if locationForCellView != nil {
                    homeTabBarItem.title = TabBarTitles.home
                    useImageButton.isHidden = false
                }
                else {
                    homeTabBarItem.title = TabBarTitles.setImage
                    useImageButton.isHidden = true
                }
            }
        }
    }
    var selectImageViewController: SelectImageViewController?
    
    fileprivate var cropRect: CGRect?
    fileprivate var cropRectStartPanOrigin: CGPoint?
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: Types
    
    enum LoadStatuses {
        case fetching, done, failedImageFetch, failedMainHomeCreate
        
        var statusLabelMessage: String {
            switch self {
            case .fetching: return "Fetching Image"
            case .done: return "Done!"
            case .failedImageFetch: return "Oops"
            case .failedMainHomeCreate: return "Oops"
            }
        }
        
        var detailMessage: String {
            switch self {
            case .fetching: return "This may take a moment."
            case .done: return ""
            case .failedImageFetch: return "There was an error fetching the image from iCloud, please try again. If problem persists, it would be greatly appreciated if you submitted a bug report by navigating to the 'Settings' page."
            case .failedMainHomeCreate: return "There was an error creating the cropped image, please try again. If problem persists, it would be greatly appreciated if you submitted a bug report by navigating to the 'Settings' page."
            }
        }
    }
    
    enum TabBarStates {case home, original}
    
    struct TabBarTitles {
        static let home = "Home"
        static let original = "Original"
        static let setImage = "Crop Image"
    }
    
    //
    // MARK: Flags
    
    var createImage = false
    
    fileprivate var isInMaskPreviewMode = false {
        didSet {
            if isInMaskPreviewMode {homePreviewCell.percentMaskCoverage = 0.75; homePreviewCell.useMask = true}
            else {homePreviewCell.useMask = false}
        }
    }
    
    fileprivate var loadStatus: LoadStatuses = .fetching {
        didSet {
            loadingStatusLabel.text = loadStatus.statusLabelMessage
            loadingDetailLabel.text = loadStatus.detailMessage
            switch loadStatus {
            case .fetching:
                loadingActivityIndicator.startAnimating()
                loadingActivityIndicator.isHidden = false
                loadingStackView.isHidden = false
                homeTabBarItem.isEnabled = false
                originalTabBarItem.isEnabled = false
            case .failedImageFetch, .failedMainHomeCreate:
                loadingActivityIndicator.stopAnimating()
                loadingActivityIndicator.isHidden = true
                if loadStatus == .failedImageFetch && tabBarState == .original {loadingStackView.isHidden = false}
                else if loadStatus == .failedMainHomeCreate && tabBarState == .home {loadingStackView.isHidden = false}
                homeTabBarItem.isEnabled = false
                originalTabBarItem.isEnabled = false
                
                if !homePreviewOptionsButtonsStackView.isHidden {
                    let animOut = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
                        self.homePreviewOptionsButtonsStackView.layer.opacity = 0.0
                    }
                    animOut.addCompletion { (position) in self.homePreviewOptionsButtonsStackView.isHidden = true}
                    animOut.startAnimation()
                }
            case .done:
                loadingStackView.isHidden = true
                homeTabBarItem.isEnabled = true
                originalTabBarItem.isEnabled = true
                if homePreviewOptionsButtonsStackView.isHidden {
                    homePreviewOptionsButtonsStackView.layer.opacity = 0.0
                    homePreviewOptionsButtonsStackView.isHidden = false
                    
                    let animIn = UIViewPropertyAnimator(duration: 0.5, curve: .linear) {
                        self.homePreviewOptionsButtonsStackView.layer.opacity = 1.0
                    }
                    animIn.startAnimation()
                }
            }
            /*if loadStatus == .done && oldValue != .done {
                if locationForCellView == nil {createHomeImageButton.isHidden =  false}
            }
            else if loadStatus != .done && oldValue == .done {
                homeTabBarItem.isEnabled = false
                originalTabBarItem.isEnabled = false
                createHomeImageButton.isHidden = true
            }*/
        }
    }
    
    fileprivate var tabBarState: TabBarStates = .original {
        didSet {
            
            let standardDuration = 0.2
            let cascadeDelayTime = 0.1
            
            switch tabBarState {
            case .home:
                if let image = selectedImage {
                    previewTypeTabBar.selectedItem = homeTabBarItem
                    let cropRect = getCropRect()
                    let desiredOriginY = cropRect.origin.y - ((homePreviewView.bounds.height - cropRect.size.height) / 2)
                    homePreviewView.frame.origin = CGPoint(x: 0.0, y: desiredOriginY)
                    let centeredOrigin = CGPoint(x: 0.0, y: (fullSizePreviewView.bounds.height / 2) - (homePreviewView.bounds.height / 2))
                    homePreviewView.isHidden = false
                    
                    if let appImage = image as? AppEventImage, appImage.maskImage != nil {toggleMaskButton.isHidden = false}
                    else {toggleMaskButton.isHidden = true}
                    
                    let standardDuration = 0.2
                    let cascadeDelayTime = 0.1
                    
                    let originalFadeOutAnim = UIViewPropertyAnimator(duration: standardDuration, curve: .linear) {
                        self.fullSizePreviewView.layer.opacity = 0.0
                    }
                    let cellMoveAnim = UIViewPropertyAnimator(duration: standardDuration, curve: .easeInOut) {
                        self.homePreviewView.frame.origin = centeredOrigin
                    }
                    
                    originalFadeOutAnim.addCompletion { (position) in self.fullSizePreviewView.isHidden = true}
                    
                    originalFadeOutAnim.startAnimation()
                    cellMoveAnim.startAnimation(afterDelay: cascadeDelayTime)
                }
                else {loadingStackView.isHidden = false}
            case .original:
                if selectedImage != nil {
                    previewTypeTabBar.selectedItem = originalTabBarItem
                    
                    if !homePreviewView.isHidden {
                        
                        // Preconfigure
                        fullSizePreviewView.layer.opacity = 0.0
                        fullSizePreviewView.isHidden = false
                        let cropRect = getCropRect()
                        let desiredOriginY = cropRect.origin.y - ((homePreviewView.bounds.height - cropRect.size.height) / 2)
                        let destOrigin = CGPoint(x: 0.0, y: desiredOriginY)
                        
                        // Anims
                        let cellMoveAnim = UIViewPropertyAnimator(duration: standardDuration, curve: .easeInOut) {
                            self.homePreviewView.frame.origin = destOrigin
                        }
                        let fullSizePreviewFadeIn = UIViewPropertyAnimator(duration: standardDuration, curve: .linear) {
                            self.fullSizePreviewView.layer.opacity = 1.0
                        }
                        
                        // Completions
                        fullSizePreviewFadeIn.addCompletion { (position) in self.homePreviewView.isHidden = true}
                        
                        // Starts
                        cellMoveAnim.startAnimation()
                        fullSizePreviewFadeIn.startAnimation(afterDelay: cascadeDelayTime)
                    }
                    else {
                        fullSizePreviewView.layer.opacity = 0.0
                        fullSizePreviewView.isHidden = false
                        let fullSizePreviewFadeIn = UIViewPropertyAnimator(duration: standardDuration, curve: .linear) {
                            self.fullSizePreviewView.layer.opacity = 1.0
                        }
                        fullSizePreviewFadeIn.startAnimation()
                    }
                }
                else {loadingStackView.isHidden = false}
            }
        }
    }
    
    fileprivate var hasMask: Bool?
    fileprivate var initialLoad = true
    
    //
    // MARK: GUI
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingStatusLabel: UILabel!
    @IBOutlet weak var loadingDetailLabel: UILabel!
    @IBOutlet weak var editingButtonsStackView: UIStackView!
    @IBOutlet weak var homePreviewOptionsButtonsStackView: UIStackView!
    @IBOutlet weak var previewTypeTabBar: UITabBar!
    @IBOutlet weak var homeTabBarItem: UITabBarItem!
    @IBOutlet weak var originalTabBarItem: UITabBarItem!
    @IBOutlet weak var createHomeImageButton: UIButton!
    @IBOutlet weak var cancelEditButton: UIButton!
    @IBOutlet weak var toggleMaskButton: UIButton!
    @IBOutlet weak var cropImageButton: UIButton!
    @IBOutlet weak var useImageButton: UIButton!
    @IBOutlet weak var homePreviewView: UIView!
    @IBOutlet weak var fullSizePreviewView: UIView!
    @IBOutlet weak var homePreviewViewCenterYConstraint: NSLayoutConstraint!
    var homePreviewCell: EventTableViewCell!
    var fullSizePreviewCell: EventTableViewCell!
    var cropAreaView: UIView?
    var blurView1: UIVisualEffectView?
    var blurView2: UIVisualEffectView?
    var sideBlurView1: UIVisualEffectView?
    var sideBlurView2: UIVisualEffectView?
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = addBackButton(action: #selector(defaultPop), title: "BACK", target: self)
        
        if locationForCellView != nil {
            useImageButton.isHidden = false
            homeTabBarItem.title = TabBarTitles.home
        }
        else {
            useImageButton.isHidden = true
            homeTabBarItem.title = TabBarTitles.setImage
        }
        
        previewTypeTabBar.delegate = self
        previewTypeTabBar.barTintColor = UIColor.clear
        previewTypeTabBar.backgroundImage = UIImage()
        previewTypeTabBar.unselectedItemTintColor = GlobalColors.unselectedButtonColor
        previewTypeTabBar.tintColor = GlobalColors.cyanRegular
        
        cropImageButton.regularFormat()
        toggleMaskButton.regularFormat()
        useImageButton.emphasisedFormat()
        cropImageButton.addTarget(self, action: #selector(handleHomeOptionsButtonClick(_:)), for: .touchUpInside)
        toggleMaskButton.addTarget(self, action: #selector(handleHomeOptionsButtonClick(_:)), for: .touchUpInside)
        useImageButton.addTarget(self, action: #selector(handleHomeOptionsButtonClick(_:)), for: .touchUpInside)

        createHomeImageButton.emphasisedFormat()
        cancelEditButton.regularFormat()
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
                homePreviewCell!.configuration = .cell
                
                homePreviewCell!.titleLabel.removeFromSuperview()
                homePreviewCell!.taglineLabel.removeFromSuperview()
                homePreviewCell!.timerContainerView.removeFromSuperview()
                homePreviewCell!.abridgedTimerContainerView.removeFromSuperview()
                
                let bottomAnchorConstraint = homePreviewCell!.constraints.first {$0.secondAnchor == homePreviewCell!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                homePreviewCell!.bottomAnchor.constraint(equalTo: homePreviewCell!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
                
                homePreviewCell!.viewWithMargins.layer.cornerRadius = 3.0
                homePreviewCell!.viewWithMargins.layer.masksToBounds = true
                
                if let _ = selectedImage as? AppEventImage {}
                else {
                    let doubleTabGesture = UITapGestureRecognizer(target: self, action: #selector(handleHomePreviewDoubleTap(_:)))
                    doubleTabGesture.numberOfTapsRequired = 2
                    homePreviewView.isUserInteractionEnabled = true
                    homePreviewView.addGestureRecognizer(doubleTabGesture)
                }
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
                fullSizePreviewCell!.configuration = .detail
                fullSizePreviewCell!.useMask = false
                
                fullSizePreviewCell!.titleLabel.removeFromSuperview()
                fullSizePreviewCell!.taglineLabel.removeFromSuperview()
                fullSizePreviewCell!.timerContainerView.removeFromSuperview()
                fullSizePreviewCell!.abridgedTimerContainerView.removeFromSuperview()
                
                let bottomAnchorConstraint = fullSizePreviewCell!.constraints.first {$0.secondAnchor == fullSizePreviewCell!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                fullSizePreviewCell!.bottomAnchor.constraint(equalTo: fullSizePreviewCell!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
            }
        }
        
        setImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initialLoad = false
        if createImage {enterCropMode(animated: true)}
    }

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
                    os_log("There was an error fetching the main image for %@ from the cloud!", log: .default, type: .error, appImage.title)
                    loadStatus = .failedImageFetch
                }
            }
        }
        else {performUserImageSetup()}
    }
    
    //
    // MARK: TabBar Delegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == homeTabBarItem && tabBarState != .home {
            if locationForCellView == nil {enterCropMode(animated: true)}
            else {tabBarState = .home}
        }
        else if item == originalTabBarItem && tabBarState != .original {tabBarState = .original}
    }
    
    //
    // MARK: UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
    //
    // MARK: - Target-Action and Objc Targeted Methods
    //
    
    /*@objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        if let button = sender as? UIBarButtonItem {
            if button.title == "USE IMAGE" {
                performSegue(withIdentifier: "UnwindToNewEventController", sender: self)
            }
            else if button.title == "CROP IMAGE" {enterCropMode()}
        }
    }*/
    
    @objc fileprivate func handleEditButtonClick(_ sender: UIButton) {
        
        func removeCropRect() {
            let fadeOutAnim = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
                self.cropAreaView?.layer.opacity = 0.0
                self.blurView1?.layer.opacity = 0.0
                self.blurView2?.layer.opacity = 0.0
                self.sideBlurView1?.layer.opacity = 0.0
                self.sideBlurView2?.layer.opacity = 0.0
            }
            
            fadeOutAnim.addCompletion { (position) in
                self.cropAreaView?.removeFromSuperview()
                self.cropAreaView = nil
                self.blurView1?.removeFromSuperview()
                self.blurView1 = nil
                self.blurView2?.removeFromSuperview()
                self.blurView2 = nil
                self.sideBlurView1?.removeFromSuperview()
                self.sideBlurView1 = nil
                self.sideBlurView2?.removeFromSuperview()
                self.sideBlurView2 = nil
            }
            
            fadeOutAnim.startAnimation()
        }
        
        if sender.title(for: .normal) == "Cancel" {
            removeCropRect()
            viewTransitionOutOfCropMode()
            if locationForCellView != nil {tabBarState = .home}
            else {tabBarState = .original}
        }
        else if sender.title(for: .normal) == "CROP" {
            
            func setHomePreview() {
                selectImageViewController?.selectedImage = selectedImage
                selectImageViewController?.locationForCellView = locationForCellView
                tabBarState = .home
            }
            
            let _locationForCellView = ((cropAreaView!.frame.origin.y - fullSizePreviewCell.mainImageView.imageRect!.origin.y) + (cropAreaView!.frame.height / 2)) / fullSizePreviewCell.mainImageView.imageRect!.height
            locationForCellView = _locationForCellView
            cropRect = cropAreaView!.frame
            
            guard let mainImage = selectedImage?.generateMainHomeImage(size: cropRect!.size, locationForCellView: _locationForCellView) else {
                os_log("There was an error creating the main home image for %@.", log: .default, type: .error, selectedImage!.title)
                loadStatus = .failedMainHomeCreate
                viewTransitionOutOfCropMode()
                removeCropRect()
                setHomePreview()
                return
            }
            var maskImage: UIImage?
            if let appImage = selectedImage as? AppEventImage {
                maskImage = appImage.generateMaskHomeImage(size: cropRect!.size, locationForCellView: _locationForCellView)
            }
            
            homePreviewCell.setHomeImages(mainHomeImage: mainImage, maskHomeImage: maskImage)
            
            viewTransitionOutOfCropMode()
            
            removeCropRect()
            setHomePreview()
        }
        else {os_log("Unrecognized edit button title!", log: .default, type: .error)}
    }
    
    @objc fileprivate func handleHomeOptionsButtonClick(_ sender: UIButton) {
        if sender == cropImageButton {enterCropMode(animated: true)}
        else if sender == toggleMaskButton {isInMaskPreviewMode = !isInMaskPreviewMode}
        else if sender == useImageButton {performSegue(withIdentifier: "UnwindToNewEventController", sender: self)}
        else {os_log("Unrecognized options button title!", log: .default, type: .error)}
    }
    
    @objc fileprivate func handleCropRectPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed, .ended:
            if sender.state == .began {cropRectStartPanOrigin = cropAreaView!.frame.origin}
            let translation = sender.translation(in: homePreviewView)
            let newCropRect = CGRect(x: cropAreaView!.frame.origin.x, y: cropRectStartPanOrigin!.y + translation.y, width: cropAreaView!.frame.width, height: cropAreaView!.frame.height)
            guard fullSizePreviewCell.mainImageView.imageRect!.contains(newCropRect) else {return}
            cropAreaView!.frame = newCropRect
            blurView1!.frame.size.height = cropRectStartPanOrigin!.y + translation.y
            blurView2!.frame.origin.y = cropRectStartPanOrigin!.y + translation.y + cropAreaView!.frame.height
            blurView2!.frame.size.height = view.frame.height - (cropRectStartPanOrigin!.y + translation.y + cropAreaView!.frame.height)
        default: break
        }
    }
    
    @objc fileprivate func handleHomePreviewDoubleTap(_ sender: UITapGestureRecognizer) {enterCropMode(animated: false)}
    
    
    //
    // MARK: - Private Methods
    //
    
    fileprivate func setImage() {
        if selectedImage != nil {
            selectedImage!.delegate = self
            if let appImage = selectedImage as? AppEventImage {
                if appImage.mainImage?.uiImage == nil {loadStatus = .fetching}
                else {performAppImageSetup()}
                appImage.fetch(imageTypes: [.mask], alertDelegate: true)
            }
            else {
                if selectedImage!.mainImage?.uiImage == nil {loadStatus = .fetching}
                else {performUserImageSetup()}
            }
        }
    }
    
    fileprivate var isAppImageSetup = false
    
    fileprivate func performAppImageSetup() {
        if !isAppImageSetup {
            let appImage = selectedImage as! AppEventImage
            homePreviewCell.setSelectedImage(image: appImage, locationForCellView: locationForCellView)
            fullSizePreviewCell.setSelectedImage(image: appImage, locationForCellView: nil)
            loadStatus = .done
            tabBarState = .original
            homeTabBarItem.title = TabBarTitles.home
            isAppImageSetup = true
        }
    }
    
    fileprivate func performUserImageSetup() {
        fullSizePreviewCell.setSelectedImage(image: selectedImage!, locationForCellView: nil)
        loadStatus = .done
        if let _locationForCellView = locationForCellView {
            homePreviewCell.setSelectedImage(image: self.selectedImage!, locationForCellView: _locationForCellView)
            selectImageViewController?.selectedImage = self.selectedImage!
            selectImageViewController?.locationForCellView = _locationForCellView
            homeTabBarItem.title = TabBarTitles.home
        }
        else {homeTabBarItem.title = TabBarTitles.setImage}
        tabBarState = .original
    }
    
    fileprivate func enterCropMode(animated: Bool = true) {
        if let imageFrame = fullSizePreviewCell.mainImageView.imageRect {
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
                
                let sideBlur1Width = imageFrame.origin.x
                let sideBlur2Width = fullSizePreviewView.frame.width - (imageFrame.origin.x + imageFrame.width)
                let sideBlurHeight = fullSizePreviewView.frame.height
                let sideBlur2x = imageFrame.origin.x + imageFrame.width
                
                sideBlurView1!.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sideBlur1Width, height: sideBlurHeight))
                sideBlurView2!.frame = CGRect(x: sideBlur2x, y: 0.0, width: sideBlur2Width, height: sideBlurHeight)
            }
            
            if fullSizePreviewView.isHidden {tabBarState = .original}
            
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
            
            let cropRect = getCropRect()
            cropAreaView!.frame = cropRect
            if cropRect.width < fullSizePreviewView.frame.width {createSideBlurs()}
            
            let blur1Height = cropAreaView!.frame.origin.y
            let blur1x = imageFrame.origin.x
            let blur1y: CGFloat = 0.0
            blurView1!.frame = CGRect(x: blur1x, y: blur1y, width: cropRect.width, height: blur1Height)
            
            let blur2Height = view.frame.height - cropRect.height - blur1Height
            let blur2x = imageFrame.origin.x
            let blur2y = blur1Height + cropRect.height
            blurView2!.frame = CGRect(x: blur2x, y: blur2y, width: cropRect.width, height: blur2Height)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropRectPan(_:)))
            cropAreaView!.addGestureRecognizer(panGesture)
            
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                        self.blurView1!.layer.opacity = 1.0
                        self.blurView2!.layer.opacity = 1.0
                        self.sideBlurView1?.layer.opacity = 1.0
                        self.sideBlurView2?.layer.opacity = 1.0
                }, completion: nil)
            }
            else {
                self.blurView1!.layer.opacity = 1.0
                self.blurView2!.layer.opacity = 1.0
                self.sideBlurView1?.layer.opacity = 1.0
                self.sideBlurView2?.layer.opacity = 1.0
            }
            
            let transition = CATransition()
            transition.type = kCATransitionFade
            transition.duration = 0.5
            
            previewTypeTabBar.layer.add(transition, forKey: "transition")
            homePreviewOptionsButtonsStackView.layer.add(transition, forKey: "transition")
            editingButtonsStackView.layer.add(transition, forKey: "transition")
            
            previewTypeTabBar.isHidden = true
            homePreviewOptionsButtonsStackView.isHidden = true
            editingButtonsStackView.isHidden = false
        }
    }
    
    fileprivate func getCropRect() -> CGRect {
        if let rect = cropRect {return rect}
        else if let imageFrame = fullSizePreviewCell.mainImageView.imageRect {
            let height: CGFloat = {return (160.0 / fullSizePreviewView.bounds.width) * imageFrame.width}()
            let width = imageFrame.width
            let x = imageFrame.origin.x
            let y: CGFloat = {
                if let _locationForCellView = locationForCellView {
                     return (imageFrame.origin.y + (imageFrame.height * _locationForCellView)) - (height / 2)
                }
                else {return (fullSizePreviewView.frame.height / 2) - (height / 2)}
            }()
            return CGRect(x: x, y: y, width: width, height: height)
        }
        return CGRect(x: 0.0, y: (view.bounds.height / 2) - (160.0 / 2), width: view.bounds.width, height: 160.0)
    }
    
    //@objc fileprivate func enterEditMode() {dismiss(animated: true, completion: nil); enterCropMode(animated: true)}
    //@objc fileprivate func togglePreviewMode() {isInMaskPreviewMode = !isInMaskPreviewMode}
    
    fileprivate func viewTransitionOutOfCropMode() {
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.5
        
        editingButtonsStackView.layer.add(transition, forKey: "transition")
        homePreviewOptionsButtonsStackView.layer.add(transition, forKey: "transition")
        previewTypeTabBar.layer.add(transition, forKey: "transition")
        
        editingButtonsStackView.isHidden = true
        homePreviewOptionsButtonsStackView.isHidden = false
        previewTypeTabBar.isHidden = false
    }
}
