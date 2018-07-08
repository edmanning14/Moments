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

class ImagePreviewViewController: UIViewController, CountdownImageDelegate, UITabBarDelegate, UIPopoverPresentationControllerDelegate {
    
    //
    // MARK: - Paramters
    //
    
    //
    // MARK: Data Model
    
    var selectedImage: UserEventImage?
    var locationForCellView: CGFloat?
    var selectImageViewController: SelectImageViewController?
    
    fileprivate var cropRect: CGRect?
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
    
    enum TabBarStates {case home, original}
    
    struct TabBarTitles {
        static let home = "Home"
        static let original = "Original"
        static let setImage = "Set Home Image"
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
    
    fileprivate var loadStatus: LoadStatuses = .locating {
        didSet {
            loadingStatusLabel?.text = loadStatus.message
            if loadStatus == .done && oldValue != .done {
                if locationForCellView == nil {createHomeImageButton.isHidden =  false}
            }
            else if loadStatus != .done && oldValue == .done {
                homeTabBarItem.isEnabled = false
                originalTabBarItem.isEnabled = false
                createHomeImageButton.isHidden = true
            }
        }
    }
    
    fileprivate var tabBarState: TabBarStates = .original {
        didSet {
            switch tabBarState {
            case .home:
                previewTypeTabBar.selectedItem = homeTabBarItem
                homeTabBarItem.title = TabBarTitles.home
                homePreviewView.frame.origin = getCropRect().origin
                let centeredOrigin = CGPoint(x: 0.0, y: (view.bounds.height / 2) - (homePreviewView.bounds.height / 2))
                
                homePreviewView.isHidden = false
                
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: animationDuration,
                    delay: animationDuration,
                    options: .curveEaseInOut,
                    animations: {self.fullSizePreviewView.layer.opacity = 0.0},
                    completion: { [weak self] (_) in
                        if let livingSelf = self {
                            livingSelf.fullSizePreviewView.isHidden = true
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: livingSelf.animationDuration,
                                delay: 0.0,
                                options: .curveEaseInOut,
                                animations: {livingSelf.homePreviewView.frame.origin = centeredOrigin},
                                completion: nil
                            )
                        }
                    }
                )
            case .original:
                previewTypeTabBar.selectedItem = originalTabBarItem
                if locationForCellView == nil {homeTabBarItem.title = TabBarTitles.setImage}
                else {homeTabBarItem.title = TabBarTitles.home}
                
                if !homePreviewView.isHidden {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: animationDuration,
                        delay: 0.0,
                        options: .curveEaseInOut,
                        animations: {self.homePreviewView.frame.origin = self.getCropRect().origin},
                        completion: { [weak self] (_) in
                            if let livingSelf = self {
                                livingSelf.fullSizePreviewView.layer.opacity = 0.0
                                livingSelf.fullSizePreviewView.isHidden = false
                                UIViewPropertyAnimator.runningPropertyAnimator(
                                    withDuration: livingSelf.animationDuration,
                                    delay: 0.0,
                                    options: .curveEaseInOut,
                                    animations: {
                                        livingSelf.fullSizePreviewView.layer.opacity = 1.0
                                    },
                                    completion: { (_) in livingSelf.homePreviewView.isHidden = true}
                                )
                            }
                        }
                    )
                }
                else {fullSizePreviewView.isHidden = false}
            }
        }
    }
    
    fileprivate var hasMask: Bool?
    fileprivate var initialLoad = true
    
    //
    // MARK: UI Content
    
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var loadingStatusLabel: UILabel?
    @IBOutlet weak var editingButtonsStackView: UIStackView!
    @IBOutlet weak var previewTypeTabBar: UITabBar!
    @IBOutlet weak var homeTabBarItem: UITabBarItem!
    @IBOutlet weak var originalTabBarItem: UITabBarItem!
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
    fileprivate let animationDuration: TimeInterval = 0.2
    
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem()
        doneButton.target = self
        doneButton.action = #selector(handleNavButtonClick(_:))
        doneButton.tintColor = GlobalColors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.setTitleTextAttributes(attributes, for: .disabled)
        doneButton.title = "USE IMAGE"
        navigationItem.rightBarButtonItem = doneButton
        if locationForCellView == nil {doneButton.isEnabled = false}
        
        previewTypeTabBar.delegate = self
        previewTypeTabBar.barTintColor = UIColor.clear
        previewTypeTabBar.backgroundImage = UIImage()
        previewTypeTabBar.unselectedItemTintColor = GlobalColors.unselectedButtonColor
        previewTypeTabBar.tintColor = GlobalColors.cyanRegular
        
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
                    // TODO: Error handling
                    fatalError("There was an error fetching the main image from the cloud!")
                }
            }
        }
        else {performUserImageSetup()}
    }
    
    //
    // MARK: TabBar Delegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == homeTabBarItem && tabBarState == .home {
            
            let optionsViewController = UIViewController()
            optionsViewController.modalPresentationStyle = .popover
            
            let popController = optionsViewController.popoverPresentationController!
            popController.backgroundColor = GlobalColors.darkPurpleForFills
            popController.delegate = self
            popController.sourceView = tabBar
            
            let edgeInsets: CGFloat = 12.0
            let spacing: CGFloat = 6.0
            
            let setHomeImageButton = UIButton()
            setHomeImageButton.translatesAutoresizingMaskIntoConstraints = false
            setHomeImageButton.tag = 1
            setHomeImageButton.addTarget(self, action: #selector(enterEditMode), for: .touchUpInside)
            setHomeImageButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
            setHomeImageButton.setTitle("Set Home Image", for: .normal)
            setHomeImageButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
            setHomeImageButton.contentEdgeInsets = UIEdgeInsets(top: spacing / 2, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
            
            let setHomeImageImageButton = UIButton()
            setHomeImageImageButton.translatesAutoresizingMaskIntoConstraints = false
            setHomeImageImageButton.tag = 2
            setHomeImageImageButton.addTarget(self, action: #selector(enterEditMode), for: .touchUpInside)
            setHomeImageImageButton.setImage(#imageLiteral(resourceName: "HomeButtonImage"), for: .normal)
            setHomeImageImageButton.tintColor = GlobalColors.orangeDark
            setHomeImageImageButton.contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: spacing / 2, right: edgeInsets)
            
            let maskPreviewButton = UIButton()
            maskPreviewButton.translatesAutoresizingMaskIntoConstraints = false
            maskPreviewButton.tag = 3
            maskPreviewButton.addTarget(self, action: #selector(togglePreviewMode), for: .touchUpInside)
            maskPreviewButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
            maskPreviewButton.setTitle("Toggle Mask Preview", for: .normal)
            maskPreviewButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
            maskPreviewButton.contentEdgeInsets = UIEdgeInsets(top: spacing / 2, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
            
            let maskPreviewImageButton = UIButton()
            maskPreviewImageButton.translatesAutoresizingMaskIntoConstraints = false
            maskPreviewImageButton.tag = 4
            maskPreviewImageButton.addTarget(self, action: #selector(togglePreviewMode), for: .touchUpInside)
            maskPreviewImageButton.setImage(#imageLiteral(resourceName: "ImageButtonImage"), for: .normal)
            maskPreviewImageButton.tintColor = GlobalColors.orangeDark
            maskPreviewImageButton.contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: spacing / 2, right: edgeInsets)
            
            optionsViewController.view = {
                let rootView = UIView()
                rootView.backgroundColor = UIColor.clear
                rootView.translatesAutoresizingMaskIntoConstraints = false
                
                let buttonsStackView = UIStackView()
                buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
                buttonsStackView.axis = UILayoutConstraintAxis.horizontal
                buttonsStackView.alignment = .center
                buttonsStackView.distribution = UIStackViewDistribution.fillEqually
                buttonsStackView.spacing = 4.0
                
                let setHomeImageStackView = UIStackView()
                setHomeImageStackView.translatesAutoresizingMaskIntoConstraints = false
                setHomeImageStackView.axis = .vertical
                setHomeImageStackView.alignment = .center
                
                setHomeImageStackView.addArrangedSubview(setHomeImageImageButton)
                setHomeImageStackView.addArrangedSubview(setHomeImageButton)
                
                let maskPreviewStackView = UIStackView()
                maskPreviewStackView.translatesAutoresizingMaskIntoConstraints = false
                maskPreviewStackView.axis = .vertical
                maskPreviewStackView.alignment = .center
                
                maskPreviewStackView.addArrangedSubview(maskPreviewImageButton)
                maskPreviewStackView.addArrangedSubview(maskPreviewButton)
                
                buttonsStackView.addArrangedSubview(setHomeImageStackView)
                buttonsStackView.addArrangedSubview(maskPreviewStackView)
                
                rootView.addSubview(buttonsStackView)
                
                rootView.topAnchor.constraint(equalTo: buttonsStackView.topAnchor).isActive = true
                rootView.leftAnchor.constraint(equalTo: buttonsStackView.leftAnchor).isActive = true
                rootView.rightAnchor.constraint(equalTo: buttonsStackView.rightAnchor).isActive = true
                rootView.bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor).isActive = true
                
                return rootView
            }()
            
            optionsViewController.preferredContentSize = optionsViewController.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
            popController.sourceRect = CGRect(x: 0.0, y: 0.0, width: tabBar.bounds.width / 2, height: tabBar.bounds.height)
            
            present(optionsViewController, animated: true, completion: nil)
        }
        else if item == homeTabBarItem && tabBarState != .home {
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
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        if let button = sender as? UIBarButtonItem {
            if button.title == "USE IMAGE" {
                performSegue(withIdentifier: "UnwindToNewEventController", sender: self)
            }
        }
    }
    
    @objc fileprivate func handleEditButtonClick(_ sender: UIButton) {
        
        func removeCropRect() {
            cropAreaView?.removeFromSuperview()
            cropAreaView = nil
            blurView1?.removeFromSuperview()
            blurView1 = nil
            blurView2?.removeFromSuperview()
            blurView2 = nil
            sideBlurView1?.removeFromSuperview()
            sideBlurView1 = nil
            sideBlurView2?.removeFromSuperview()
            sideBlurView2 = nil
            /*UIViewPropertyAnimator.runningPropertyAnimator(
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
            )*/
        }
        
        if sender.title(for: .normal) == "CANCEL" {
            removeCropRect()
            viewTransition(from: editingButtonsStackView, to: previewTypeTabBar)
            if locationForCellView != nil {
                navigationItem.rightBarButtonItem!.isEnabled = true
                tabBarState = .home
            }
            else {
                navigationItem.rightBarButtonItem!.isEnabled = false
                tabBarState = .original
            }
        }
        else if sender.title(for: .normal) == "SET" {
            
            func setHomePreview() {
                selectImageViewController?.selectedImage = selectedImage
                selectImageViewController?.locationForCellView = locationForCellView
                tabBarState = .home
                navigationItem.rightBarButtonItem!.isEnabled = true
            }
            
            let _locationForCellView = ((cropAreaView!.frame.origin.y - fullSizePreviewCell.mainImageView.imageRect!.origin.y) + (cropAreaView!.frame.height / 2)) / fullSizePreviewCell.mainImageView.imageRect!.height
            locationForCellView = _locationForCellView
            cropRect = cropAreaView!.frame
            
            viewTransition(from: editingButtonsStackView, to: previewTypeTabBar)
            removeCropRect()
            
            if let appImage = selectedImage as? AppEventImage {
                appImage.generateMainHomeImage(size: cropRect!.size, locationForCellView: _locationForCellView, userInitiated: true) { (mainHomeImage) in
                    if let main = mainHomeImage {
                        DispatchQueue.main.async { [weak self] in
                            self?.homePreviewCell.setHomeImages(mainHomeImage: main, maskHomeImage: nil)
                            setHomePreview()
                        }
                    }
                    else {
                        // TODO: Error handling. Show an error to the user and ask for a bug report.
                        fatalError("Fatal error: Failed to create main home image!")
                    }
                }
                appImage.generateMaskHomeImage(size: cropRect!.size, locationForCellView: _locationForCellView, userInitiated: true) { [weak self] (maskHomeImage) in
                    if let mask = maskHomeImage {
                        DispatchQueue.main.async { [weak self] in
                            self?.homePreviewCell.setHomeImages(mainHomeImage: nil, maskHomeImage: mask)
                        }
                    }
                    else {
                        // TODO: Error handling. Show an error to the user and ask for a bug report.
                        fatalError("Fatal error: Failed to create mask home image!")
                    }
                }
            }
            else {
                selectedImage!.generateMainHomeImage(size: cropRect!.size, locationForCellView: _locationForCellView, userInitiated: true) { (mainHomeImage) in
                    if let main = mainHomeImage {
                        DispatchQueue.main.async { [weak self] in
                            self?.homePreviewCell.setHomeImages(mainHomeImage: main, maskHomeImage: nil)
                            setHomePreview()
                        }
                    }
                    else {
                        // TODO: Error handling. Show an error to the user and ask for a bug report.
                        fatalError("Fatal error: Failed to create main home image!")
                    }
                }
            }
        }
        else {
            // TODO: Remove for prodcution.
            fatalError("Fatal Error: Unrecognized editButton title.")
        }
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
            blurView2!.frame.size.height = fullSizePreviewView.frame.height - (cropRectStartPanOrigin!.y + translation.y + cropAreaView!.frame.height)
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
        homePreviewCell.setSelectedImage(image: appImage, locationForCellView: locationForCellView)
        fullSizePreviewCell.setSelectedImage(image: appImage, locationForCellView: nil)
        loadStatus = .done
        loadingStackView.isHidden = true
        homeTabBarItem.isEnabled = true
        originalTabBarItem.isEnabled = true
        tabBarState = .original
        homeTabBarItem.title = TabBarTitles.home
    }
    
    fileprivate func performUserImageSetup() {
        fullSizePreviewCell.setSelectedImage(image: selectedImage!, locationForCellView: nil)
        loadStatus = .done
        loadingStackView.isHidden = true
        originalTabBarItem.isEnabled = true
        homeTabBarItem.isEnabled = true
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
            navigationItem.rightBarButtonItem!.isEnabled = false
            
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
            cropAreaView!.frame = getCropRect()
            
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
            
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: animationDuration, delay: 0.0, options: .curveEaseIn, animations: {
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
            editingButtonsStackView.layer.add(transition, forKey: "transition")
            
            previewTypeTabBar.isHidden = true
            editingButtonsStackView.isHidden = false
        }
    }
    
    fileprivate func getCropRect() -> CGRect {
        let height: CGFloat = 160.0
        if let rect = cropRect {return rect}
        else if let imageFrame = fullSizePreviewCell.mainImageView.imageRect {
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
        return CGRect(x: 0.0, y: (view.bounds.height / 2) - (height / 2), width: view.bounds.width, height: height)
    }
    
    @objc fileprivate func enterEditMode() {dismiss(animated: true, completion: nil); enterCropMode(animated: true)}
    @objc fileprivate func togglePreviewMode() {isInMaskPreviewMode = !isInMaskPreviewMode}
    
    fileprivate func viewTransition(from view1: UIView, to view2: UIView) {
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.5
        
        view1.layer.add(transition, forKey: "transition")
        view2.layer.add(transition, forKey: "transition")
        
        view1.isHidden = true
        view2.isHidden = false
    }
}
