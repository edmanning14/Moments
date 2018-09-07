//
//  SelectImageViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/1/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import CloudKit
import os.log
import StoreKit
import RealmSwift
import Photos

class SelectImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITabBarDelegate, CountdownImageDelegate, ManagedCatalogImagesDelegate, UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    //
    // MARK: Parameters
    //
    
    //
    // Public data model
    
    var selectedImage: UserEventImage? {
        didSet {
            if isViewLoaded {
                if selectedImage != nil {
                    if let appImage = selectedImage as? AppEventImage {
                        catalogImages.addImage(appImage)
                        //selectedUserPhotoIndexPath = catalogImages.indexPathFor(appImage)
                    }
                    /*doneButton.isEnabled = true
                    if locationForCellView == nil {
                        if doneButton.title != "CREATE IMAGE" {
                            navigationItem.setRightBarButton(nil, animated: true)
                            doneButton.title = "CREATE IMAGE"
                            navigationItem.setRightBarButton(doneButton, animated: true)
                        }
                    }
                    else {
                        if doneButton.title != "USE IMAGE" {
                            navigationItem.setRightBarButton(nil, animated: true)
                            doneButton.title = "USE IMAGE"
                            navigationItem.setRightBarButton(doneButton, animated: true)
                        }
                    }*/
                }
                else {
                    //selectedCatalogImageIndexPath = nil
                    //selectedUserPhotoIndexPath = nil
//                    doneButton.isEnabled = false
//                    doneButton.title = "SELECT IMAGE"
                }
            }
        }
    }
    
    var locationForCellView: CGFloat?
    
    class ManagedCatalogImages: Collection {
        var startIndex = 0
        var endIndex: Int {return orderedCategories.count}
        
        private var orderedCategories = [String]()
        private var orderedImages = [[AppEventImage]]()
        
        var delegate: ManagedCatalogImagesDelegate?
        var count: Int {return orderedImages.count}
        var isEmpty: Bool {return count == 0}
        
        subscript(section: Int) -> [AppEventImage] {get {return orderedImages[section]}}
        
        fileprivate func add(_ image: AppEventImage) -> Bool {
            guard image.thumbnail?.uiImage != nil else {
                fatalError("An image in catalogImages did not contain a thumbnail!")
            }
            
            if contains(image) {return false}
            
            let category = image.category
            if !orderedCategories.contains(category) {
                orderedCategories.append(category)
                orderedImages.append([image])
            }
            else {
                let i = orderedCategories.index(of: category)!
                orderedImages[i].append(image)
            }
            return true
        }
        
        func index(after i: Int) -> Int {return i + 1}
        
        func addImage(_ image: AppEventImage) {if add(image) {delegate?.dataUpdated()}}
        
        func addImages(_ images: [AppEventImage]) {
            var success = [Bool]()
            for image in images {success.append(add(image))}
            if success.contains(true) {delegate?.dataUpdated()}
        }
        
        func titleForSection(_ section: Int) -> String {return orderedCategories[section]}
        
        func contains(_ image: AppEventImage) -> Bool {
            if let section = orderedCategories.index(of: image.category) {
                if orderedImages[section].contains(where: {$0.title == image.title}) {return true}
            }
            return false
        }
        
        func indexPathFor(_ appImage: AppEventImage) -> IndexPath? {
            for (section, images) in orderedImages.enumerated() {
                if let row = images.index(where: {$0.title == appImage.title}) {
                    return IndexPath(row: row, section: section)
                }
            }
            return nil
        }
    }
    
    var catalogImages = ManagedCatalogImages()
    
    //
    // Private data model
    
    //fileprivate var selectedCatalogImageIndexPath: IndexPath?
    //fileprivate var selectedUserPhotoIndexPath: IndexPath?
    fileprivate var userPhotoCellSize = CGSize()
    fileprivate var productIDs = Set<Product>()
    
    var loadedUserMoments: PHFetchResult<PHAssetCollection>?
    var loadedUserAlbums: PHFetchResult<PHAssetCollection>?
    
    var momentsPhotoAssets = [PHFetchResult<PHAsset>]() {
        didSet {if isViewLoaded {userPhotosCollectionView.reloadData()}}
    }
    
    var albumsPhotoAssets = [PHFetchResult<PHAsset>]() {
        didSet {if isViewLoaded {userPhotosCollectionView.reloadData()}}
    }
    
    var userPhotosImageManager: PHCachingImageManager?
    
    //
    // MARK: Types
    
    fileprivate class CollectionViewBackground: UIView {
        
        struct Messages {
            static let selectSource = "Select an image source below to view Images!"
            static let noImages = "Couldn't find any images!"
            static let loading = "Fetching Images"
            static let loadImagesError = "Sorry! There was an error loading the images. Please try again later."
            static let restrictedAccess = "Need a message here..." // TODO: Add a message here.
            static let deniedAccess = "Your moments are inaccessable! If you would like to allow access, please navigate to Settings -> Photos to allow access."
        }
        
        var message = Messages.loading {didSet{messageLabel.text = message}}
        
        private let messageLabel = UILabel()
        private var initialized = false
        
        private let contentSecondaryFontName = "Raleway-Regular"
        private let primaryTextRegularColor = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
        
        override class var requiresConstraintBasedLayout: Bool {return true}
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            commonInit()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        private func commonInit() {
            self.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            messageLabel.font = UIFont(name: contentSecondaryFontName, size: 16.0)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            messageLabel.textColor = primaryTextRegularColor
            
            self.setNeedsLayout()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            if !initialized {
                addSubview(messageLabel)
                messageLabel.text = message
                initialized = true
            }
            
            let margin: CGFloat = 8.0
            
            messageLabel.sizeToFit()
            
            messageLabel.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
            let origin = CGPoint(x: margin, y: messageLabel.frame.origin.y)
            let size = CGSize(width: self.bounds.width - (2 * margin), height: messageLabel.frame.height)
            messageLabel.frame = CGRect(origin: origin, size: size)
        }
    }
    
    fileprivate struct Product: Hashable {
        var hashValue: Int
        let id: String
        let includedRecords: [CKRecordID]
        
        init(id: String, includedRecords records: [CKRecordID]) {self.id = id; self.includedRecords = records; hashValue = id.hashValue}
        
        static func ==(lhs: SelectImageViewController.Product, rhs: SelectImageViewController.Product) -> Bool {
            if lhs.id == rhs.id {return true} else {return false}
        }
    }
    
    fileprivate enum CloudErrors: Error {
        case imageCreationFailure, assetCreationFailure, noRecords
    }
    
    fileprivate enum TabBarSelections: Int {case catalog = 0, userMoments, userAlbums, none}
    
    //
    // MARK: States
    
    fileprivate var tabBarSelectionTitle: String? {
        didSet {
            if tabBarSelectionTitle != oldValue {
                switch tabBarSelectionTitle {
                case TabBarTitles.catalog: tabBarSelection = .catalog
                case TabBarTitles.userMoments: tabBarSelection = .userMoments
                case TabBarTitles.userAlbums: tabBarSelection = .userAlbums
                case nil: tabBarSelection = .none
                default:
                    // TODO: Remove
                    fatalError("Unexpected State: Recieved an unrecognized TabBar Title")
                }
                
                let transition = CATransition()
                transition.duration = 0.2
                transition.type = kCATransitionFade
                navigationController?.navigationBar.layer.add(transition, forKey: "fadeText")
                navigationItem.title = tabBarSelectionTitle ?? "Select A Moment"
            }
        }
    }
    
    fileprivate var tabBarSelection = TabBarSelections.none {
        didSet {
            if tabBarSelection != oldValue {
                
                func swapToCatalog() {
                    let fadeOutAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.userPhotosCollectionView.layer.opacity = 0.0}
                    let fadeInAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.catalogImagesCollectionView.layer.opacity = 1.0}
                    
                    fadeOutAnim.addCompletion { (position) in
                        self.catalogImagesCollectionView.layer.opacity = 0.0
                        self.catalogImagesCollectionView.isHidden = false; self.catalogImagesCollectionView.isUserInteractionEnabled = true
                        self.userPhotosCollectionView.isHidden = true; self.userPhotosCollectionView.isUserInteractionEnabled = false
                        fadeInAnim.startAnimation()
                    }
                    
                    fadeOutAnim.startAnimation()
                }
                
                func swapToUserPhotos() {
                    userPhotosCollectionView.reloadData()
                    let fadeOutAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.catalogImagesCollectionView.layer.opacity = 0.0}
                    let fadeInAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.userPhotosCollectionView.layer.opacity = 1.0}
                    
                    fadeOutAnim.addCompletion { (position) in
                        self.userPhotosCollectionView.layer.opacity = 0.0
                        self.catalogImagesCollectionView.isHidden = true; self.catalogImagesCollectionView.isUserInteractionEnabled = false
                        self.userPhotosCollectionView.isHidden = false; self.userPhotosCollectionView.isUserInteractionEnabled = true
                        fadeInAnim.startAnimation()
                    }
                    
                    fadeOutAnim.startAnimation()
                }
                
                func swapBetweenUserPhotos() {
                    let fadeOutAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.userPhotosCollectionView.layer.opacity = 0.0}
                    let fadeInAnim = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {self.userPhotosCollectionView.layer.opacity = 1.0}
                    
                    fadeOutAnim.addCompletion { (position) in
                        self.userPhotosCollectionView.reloadData()
                        fadeInAnim.startAnimation()
                    }
                    
                    fadeOutAnim.startAnimation()
                }
                
                func closeAll() {
                    catalogImagesCollectionView.isHidden = true; catalogImagesCollectionView.isUserInteractionEnabled = false
                    userPhotosCollectionView.isHidden = true; userPhotosCollectionView.isUserInteractionEnabled = false
                }
                
                switch oldValue {
                case .catalog:
                    switch tabBarSelection {
                    case .catalog: break
                    case .userAlbums, .userMoments: swapToUserPhotos()
                    case .none: closeAll()
                    }
                case .userAlbums, .userMoments:
                    switch tabBarSelection {
                    case .catalog: swapToCatalog()
                    case .userAlbums, .userMoments: swapBetweenUserPhotos()
                    case .none: closeAll()
                    }
                case .none:
                    switch tabBarSelection {
                    case .catalog:
                        catalogImagesCollectionView.isHidden = false; catalogImagesCollectionView.isUserInteractionEnabled = true
                        userPhotosCollectionView.isHidden = true; userPhotosCollectionView.isUserInteractionEnabled = false
                    case .userAlbums, .userMoments:
                        catalogImagesCollectionView.isHidden = true; catalogImagesCollectionView.isUserInteractionEnabled = false
                        userPhotosCollectionView.isHidden = false; userPhotosCollectionView.isUserInteractionEnabled = true
                    case .none: break
                    }
                }
            }
        }
    }
    
//    fileprivate var userPhotosDataState = UserPhotosDataStates.moments {
//        didSet {
//            if userPhotosDataState != oldValue {
//                let transition = CATransition()
//                transition.duration = 0.1
//                transition.type = kCATransitionFade
//
//                userPhotosCollectionView.layer.add(transition, forKey: "transition")
//                userPhotosCollectionView.layer.opacity = 0.0
//                userPhotosCollectionView.reloadData()
//                userPhotosCollectionView.layer.add(transition, forKey: "transition")
//                userPhotosCollectionView.layer.opacity = 1.0
//            }
//        }
//    }
    
    var networkState = NewEventViewController.NetworkStates.loading {
        didSet {
            if isViewLoaded {
                if networkState == .complete {
                    catalogImagesCollectionView.reloadData()
                    //catalogImagesCollectionView.selectItem(at: selectedCatalogImageIndexPath, animated: true, scrollPosition: .top)
                    return
                }
                for (section, images) in catalogImages.enumerated() {
                    let ip = IndexPath(row: images.count - 1, section: section)
                    if let cell = catalogImagesCollectionView.cellForItem(at: ip) as? LoadingCollectionViewCell {
                        switch networkState {
                        case .failed(let message):
                            cell.networkActivityIndicator.stopAnimating()
                            cell.networkActivityIndicator.isHidden = true
                            cell.textLabel.isHidden = false
                            cell.textLabel.text = message ?? defaultNetworkErrorMessage
                        case .loading:
                            cell.networkActivityIndicator.startAnimating()
                            cell.networkActivityIndicator.isHidden = false
                            cell.textLabel.isHidden = true
                        case .complete: fatalError("This should have never happened...")
                        }
                    }
                }
            }
        }
    }
    
    //
    // MARK: Flags
    fileprivate var needToDismissSelf = false
    var momentsAssetFetchComplete = false
    var albumsAssetFetchComplete = false
    
    //
    // MARK: Constants
    let defaultNetworkErrorMessage = "Network error! Tap to retry."
    
    //
    // MARK: Persistence
    
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: Date stuff
    fileprivate let dateFormatter = DateFormatter()
    
    //
    // MARK: Constants
    
    fileprivate struct SegueIdentifiers {
        static let imagePreview = "Image Preview"
    }
    
    fileprivate struct ReuseIdentifiers {
        static let image = "Image"
        static let loading = "Loading"
        static let userPhotoCell = "User Photo Cell"
    }
    
    fileprivate struct TabBarTitles {
        static let catalog = "Catalog"
        static let userMoments = "Your Moments"
        static let userAlbums = "Your Albums"
    }
    
    fileprivate let marginForCellImage: CGFloat = 10.0
    fileprivate let collectionViewMargin: CGFloat = 15.0
    fileprivate let cellGlyphHeight: CGFloat = 20.0
    fileprivate let cellImageToGlyphSpacing: CGFloat = 10.0
    fileprivate let catalogPhotosCellSpacing: CGFloat = 10.0
    
    //
    // MARK: GUI
    
    fileprivate var catalogCollectionViewBackgroundView: CollectionViewBackground?
    fileprivate var userPhotosCollectionViewBackgroundView: CollectionViewBackground?
    
    fileprivate class CatalogCollectionViewSectionHeader: UICollectionReusableView {
        let titleLabel = UILabel()
        
        fileprivate let headingsFontName = "Comfortaa-Regular"
        fileprivate let secondaryTextRegularColor = UIColor(red: 100/255, green: 1.0, blue: 218/255, alpha: 1.0)
        
        fileprivate func commonInit() {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.backgroundColor = UIColor.clear
            titleLabel.textColor = secondaryTextRegularColor
            titleLabel.font = UIFont(name: headingsFontName, size: 30.0)
            titleLabel.textAlignment = .left
            
            self.addSubview(titleLabel)
            self.leftAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -20.0).isActive = true
            self.rightAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 8.0).isActive = true
            self.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -8.0).isActive = true
            self.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0).isActive = true
            //self.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        }
        
        override init(frame: CGRect) {super.init(frame: frame); commonInit()}
        required init?(coder aDecoder: NSCoder) {super.init(coder: aDecoder); commonInit()}
    }
    
    fileprivate class UserPhotosCollectionViewSectionHeader: UICollectionReusableView {
        let titleLabel = UILabel()
        let subTitleLabel = UILabel()
        
        fileprivate let headingsFontName = "Comfortaa-Regular"
        fileprivate let contentSecondaryFontName = "Raleway-Regular"
        fileprivate let secondaryTextRegularColor = UIColor(red: 100/255, green: 1.0, blue: 218/255, alpha: 1.0)
        
        fileprivate func commonInit() {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont(name: headingsFontName, size: 18.0)
            titleLabel.textColor = secondaryTextRegularColor
            
            subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subTitleLabel.font = UIFont(name: contentSecondaryFontName, size: 14.0)
            subTitleLabel.numberOfLines = 0
            subTitleLabel.lineBreakMode = .byWordWrapping
            subTitleLabel.textColor = secondaryTextRegularColor
            
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(titleLabel); containerView.addSubview(subTitleLabel)
            containerView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor).isActive = true
            containerView.leftAnchor.constraint(equalTo: subTitleLabel.leftAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: titleLabel.rightAnchor).isActive = true
            containerView.rightAnchor.constraint(equalTo: subTitleLabel.rightAnchor).isActive = true
            containerView.topAnchor.constraint(equalTo: titleLabel.topAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: subTitleLabel.topAnchor, constant: -2.0).isActive = true
            containerView.bottomAnchor.constraint(equalTo: subTitleLabel.bottomAnchor).isActive = true
            
            self.addSubview(containerView)
            self.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
            self.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: -8.0).isActive = true
            self.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 8.0).isActive = true
        }
        
        override init(frame: CGRect) {super.init(frame: frame); commonInit()}
        required init?(coder aDecoder: NSCoder) {super.init(coder: aDecoder); commonInit()}
    }
   
    @IBOutlet weak var loadingStackView: UIStackView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var catalogImagesCollectionView: UICollectionView!
    @IBOutlet weak var userPhotosCollectionView: UICollectionView!
    @IBOutlet weak var imagesTabBar: UITabBar!
    @IBOutlet weak var findTabBar: UITabBar!
    @IBOutlet weak var catalogTabBarItem: UITabBarItem!
    @IBOutlet weak var userMomentsTabBarItem: UITabBarItem!
    @IBOutlet weak var userAlbumsTabBarItem: UITabBarItem!
    @IBOutlet weak var findTabBarItem: UITabBarItem!
    
    //
    // MARK: Other

    fileprivate var productRequest: SKProductsRequest?
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        catalogImagesCollectionView.delegate = self
        catalogImagesCollectionView.dataSource = self
        userPhotosCollectionView.delegate = self
        userPhotosCollectionView.dataSource = self
        imagesTabBar.delegate = self
        findTabBar.delegate = self
        catalogImages.delegate = self
        
        _ = addBackButton(action: #selector(defaultPop), title: "CANCEL", target: self)
        //doneButton = addBarButtonItem(side: .right, action: #selector(handleNavButtonClick(_:)), target: self, title: "USE IMAGE", image: nil)
        
        /*if locationForCellView == nil {doneButton.isEnabled = false}
        else {doneButton.isEnabled = false}*/
        
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        userPhotosCollectionView.register(UserPhotosCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "userPhotosHeader")
        userPhotosCollectionView.register(CatalogCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "catalogPhotosHeader")
        catalogImagesCollectionView.register(CatalogCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "catalogPhotosHeader")
        
        let dimension = (userPhotosCollectionView.bounds.width - ((numberOfUserPhotoCellsPerColumn - 1) * userPhotosCellSpacing)) / numberOfUserPhotoCellsPerColumn
        userPhotoCellSize = CGSize(width: dimension, height: dimension)
        
        imagesTabBar.unselectedItemTintColor = GlobalColors.unselectedButtonColor
        imagesTabBar.tintColor = GlobalColors.cyanRegular
        
        findTabBar.unselectedItemTintColor = GlobalColors.orangeDark
        findTabBar.tintColor = GlobalColors.orangeDark
        
        if let tabBarItems = imagesTabBar.items {
            if let i = tabBarItems.index(where: {$0.title! == TabBarTitles.catalog}) {
                imagesTabBar.selectedItem = tabBarItems[i]
                tabBarSelectionTitle = TabBarTitles.catalog
            }
        }
        
        /*if selectedImage != nil, let appImage = selectedImage as? AppEventImage {
            selectedCatalogImageIndexPath = catalogImages.indexPathFor(appImage)
            catalogImagesCollectionView.selectItem(at: selectedCatalogImageIndexPath, animated: true, scrollPosition: .top)
        }*/
        
        if !momentsAssetFetchComplete || !albumsAssetFetchComplete {
            switch PHPhotoLibrary.authorizationStatus() {
            case .notDetermined: break
            case .restricted:
                if let background = userPhotosCollectionView.backgroundView as? CollectionViewBackground {
                    background.message = CollectionViewBackground.Messages.restrictedAccess
                }
            case .denied:
                if let background = userPhotosCollectionView.backgroundView as? CollectionViewBackground {
                    background.message = CollectionViewBackground.Messages.deniedAccess
                }
            case .authorized:
                if let background = userPhotosCollectionView.backgroundView as? CollectionViewBackground {
                    background.message = CollectionViewBackground.Messages.loading
                }
            }
        }
    }
    
    /*override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if selectedImageIndexPath != nil {
            imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: true, scrollPosition: .top)
        }
    }*/

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    

    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let ident = segue.identifier {
            switch ident {
            case SegueIdentifiers.imagePreview:
                
                let destination = segue.destination as! ImagePreviewViewController
                destination.selectedImage = selectedImage
                destination.locationForCellView = locationForCellView
                destination.selectImageViewController = self
                
                /*if let button = sender as? UIBarButtonItem, button == doneButton, button.title == "CREATE IMAGE" {
                    destination.createImage = true
                }*/
                
            default: break
            }
        }
    }

    
    //
    // MARK: Data Source Methods
    //
    
    //
    // UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView == catalogImagesCollectionView {
            if catalogImages.isEmpty && networkState != .complete {
                if catalogCollectionViewBackgroundView == nil {
                    catalogCollectionViewBackgroundView = CollectionViewBackground()
                }
                switch networkState {
                case .complete:
                    catalogCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.noImages
                case .failed(let message):
                    catalogCollectionViewBackgroundView!.message = message ?? CollectionViewBackground.Messages.loadImagesError
                case .loading:
                    catalogCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                }
                collectionView.backgroundView = catalogCollectionViewBackgroundView!
                return 0
            }
            else {
                collectionView.backgroundView = nil
                return catalogImages.count
            }
        }
            
        else if collectionView == userPhotosCollectionView {
            
            func numSectionsForMoments() -> Int {
                if momentsPhotoAssets.isEmpty {
                    if userPhotosCollectionViewBackgroundView == nil {
                        userPhotosCollectionViewBackgroundView = CollectionViewBackground()
                    }
                    if !momentsAssetFetchComplete {
                        userPhotosCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                    }
                    else {
                        userPhotosCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.noImages
                    }
                    collectionView.backgroundView = userPhotosCollectionViewBackgroundView!
                    return 0
                }
                else {
                    collectionView.backgroundView = nil
                    return momentsPhotoAssets.count
                }
            }
            
            let dimension = (userPhotosCollectionView.bounds.width - ((numberOfUserPhotoCellsPerColumn - 1) * userPhotosCellSpacing)) / numberOfUserPhotoCellsPerColumn
            userPhotoCellSize = CGSize(width: dimension, height: dimension)
            
            switch tabBarSelection {
            case .userMoments: return numSectionsForMoments()
            case .userAlbums:
                if albumsPhotoAssets.isEmpty {
                    if userPhotosCollectionViewBackgroundView == nil {
                        userPhotosCollectionViewBackgroundView = CollectionViewBackground()
                    }
                    if !albumsAssetFetchComplete {
                        userPhotosCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                    }
                    else {
                        userPhotosCollectionViewBackgroundView!.message = CollectionViewBackground.Messages.noImages
                    }
                    collectionView.backgroundView = userPhotosCollectionViewBackgroundView!
                    return 0
                }
                else {
                    collectionView.backgroundView = nil
                    return albumsPhotoAssets.count
                }
            default: return numSectionsForMoments()
            }
            
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == catalogImagesCollectionView {
            if networkState == .complete {return catalogImages[section].count}
            else {return catalogImages[section].count + 1}
        }
        else if collectionView == userPhotosCollectionView {
            switch tabBarSelection {
            case .userMoments: return momentsPhotoAssets[section].count
            case .userAlbums: return albumsPhotoAssets[section].count
            default: return momentsPhotoAssets[section].count
            }
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let width = collectionView.bounds.width
        if collectionView == userPhotosCollectionView {
            let height: CGFloat = 90.0
            return CGSize(width: width, height: height)
        }
        else if collectionView == catalogImagesCollectionView {
            let height: CGFloat = 70.0
            return CGSize(width: width, height: height)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        func userMomentsHeaderView() -> UICollectionReusableView {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "userPhotosHeader", for: indexPath)
            let userPhotosHeaderView = headerView as! UserPhotosCollectionViewSectionHeader
            
            if let title = loadedUserMoments?[indexPath.section].localizedTitle {
                userPhotosHeaderView.titleLabel.text = title
            }
            if let endDate = loadedUserMoments?[indexPath.section].endDate {
                userPhotosHeaderView.subTitleLabel.text = dateFormatter.string(from: endDate)
            }
            if let locations = loadedUserMoments?[indexPath.section].localizedLocationNames {
                if locations.count > 0 {
                    userPhotosHeaderView.subTitleLabel.text = userPhotosHeaderView.subTitleLabel.text! + "  \u{F1C}  " + locations[0]
                    if locations.count == 2 {
                        userPhotosHeaderView.subTitleLabel.text = userPhotosHeaderView.subTitleLabel.text! + " & 1 more place"
                    }
                    else if locations.count > 2 {
                        userPhotosHeaderView.subTitleLabel.text = userPhotosHeaderView.subTitleLabel.text! + ", & \(locations.count - 1) more places"
                    }
                }
            }
            return headerView
        }
        
        if collectionView == userPhotosCollectionView {
            if kind == UICollectionElementKindSectionHeader {
                switch tabBarSelection {
                case .userMoments: return userMomentsHeaderView()
                case .userAlbums:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "catalogPhotosHeader", for: indexPath)
                    let userPhotosHeaderView = headerView as! CatalogCollectionViewSectionHeader
                    
                    if let title = loadedUserAlbums?[indexPath.section].localizedTitle {
                        userPhotosHeaderView.titleLabel.numberOfLines = 0
                        userPhotosHeaderView.titleLabel.adjustsFontSizeToFitWidth = true
                        userPhotosHeaderView.titleLabel.minimumScaleFactor = 0.4
                        userPhotosHeaderView.titleLabel.text = title
                    }
                    return headerView
                default: return userMomentsHeaderView()
                }
            }
        }
        else if collectionView == catalogImagesCollectionView {
            if kind == UICollectionElementKindSectionHeader {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "catalogPhotosHeader", for: indexPath)
                let catalogPhotosHeaderView = headerView as! CatalogCollectionViewSectionHeader
                catalogPhotosHeaderView.titleLabel.text = catalogImages.titleForSection(indexPath.section)
                return catalogPhotosHeaderView
            }
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        func configure(_ cell: UICollectionViewCell) {
            
            var cornerRadius: CGFloat!
            if cell.reuseIdentifier == ReuseIdentifiers.image {
                cornerRadius = 5.0
                cell.layoutMargins = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
            }
            else if cell.reuseIdentifier == ReuseIdentifiers.userPhotoCell {
                cornerRadius = 3.0
            }
            
            let cellBackgroundView = UIView()
            let cellSelectedBackgroundView = UIView()
            
            cellBackgroundView.layer.backgroundColor = UIColor.black.cgColor
            
            cellSelectedBackgroundView.layer.backgroundColor = GlobalColors.darkPurpleForFills.cgColor
            cellSelectedBackgroundView.layer.cornerRadius = cornerRadius
            cellSelectedBackgroundView.layer.masksToBounds = true
            cellSelectedBackgroundView.layer.isOpaque = true
            
            cell.backgroundView = cellBackgroundView
            cell.selectedBackgroundView = cellSelectedBackgroundView
        }
        
        if collectionView == catalogImagesCollectionView {
            if indexPath.row >= catalogImages[indexPath.section].count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.loading, for: indexPath) as! LoadingCollectionViewCell
                switch networkState {
                case .loading:
                    cell.networkActivityIndicator.startAnimating()
                    cell.networkActivityIndicator.isHidden = false
                    cell.textLabel.isHidden = true
                case .failed:
                    cell.networkActivityIndicator.stopAnimating()
                    cell.networkActivityIndicator.isHidden = true
                    cell.textLabel.isHidden = false
                    
                case .complete: fatalError("This should have never happend...")
                }
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.image, for: indexPath) as! SelectImageCollectionViewCell
                cell.image = catalogImages[indexPath.section][indexPath.row].thumbnail?.uiImage
                cell.imageTitle = catalogImages[indexPath.section][indexPath.row].title
                cell.imageIsAvailable = true
                /*if cell.gestureRecognizers?.count == 0 || cell.gestureRecognizers == nil {
                    let cellDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCellDoubleTap(_:)))
                    cellDoubleTapGestureRecognizer.numberOfTapsRequired = 2
                    cell.addGestureRecognizer(cellDoubleTapGestureRecognizer)
                }*/
                configure(cell)
                return cell
            }
        }
        else if collectionView == userPhotosCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.userPhotoCell, for: indexPath)
            let imageView = cell.contentView.subviews[0] as! UIImageView
            if cell.tag != 0 {userPhotosImageManager?.cancelImageRequest(PHImageRequestID(cell.tag))}
            
            func momentsPhotoAssetsRequest() {
                let id = userPhotosImageManager?.requestImage(for: momentsPhotoAssets[indexPath.section][indexPath.row], targetSize: userPhotoCellSize, contentMode: .aspectFill, options: nil) { (image, _info) in
                    if let info = _info {
                        if let error = info[PHImageErrorKey] as? NSError {
                            // TODO: Handle errors gracefully
                            print(error.debugDescription)
                            fatalError()
                        }
                    }
                    imageView.image = image
                }
                if id != nil {cell.tag = Int(id!)}
                else {
                    // TODO: Error handling
                    fatalError("Error requesting the image... userPhotosManager is nil maybe?")
                }
            }
            
            switch tabBarSelection {
            case .userMoments: momentsPhotoAssetsRequest()
            case .userAlbums:
                let id = userPhotosImageManager?.requestImage(for: albumsPhotoAssets[indexPath.section][indexPath.row], targetSize: userPhotoCellSize, contentMode: .aspectFill, options: nil) { (image, _info) in
                    if let info = _info {
                        if let error = info[PHImageErrorKey] as? NSError {
                            // TODO: Handle errors gracefully
                            print(error.debugDescription)
                            fatalError()
                        }
                    }
                    imageView.image = image
                }
                if id != nil {cell.tag = Int(id!)}
                else {
                    // TODO: Error handling
                    fatalError("Error requesting the image... userPhotosManager is nil maybe?")
                }
            default: momentsPhotoAssetsRequest()
            }
            
            /*if cell.gestureRecognizers?.count == 0 || cell.gestureRecognizers == nil {
                let cellDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCellDoubleTap(_:)))
                cellDoubleTapGestureRecognizer.numberOfTapsRequired = 2
                cell.addGestureRecognizer(cellDoubleTapGestureRecognizer)
            }*/
            
            configure(cell)
            return cell
        }
        return UICollectionViewCell()
    }
    
    //
    // MARK: Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {return 1} // Filter table views
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tabBarSelectionTitle {
        case TabBarTitles.catalog: return catalogImages.count
        case TabBarTitles.userMoments: return loadedUserMoments?.count ?? 0
        case TabBarTitles.userAlbums: return loadedUserAlbums?.count ?? 0
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "FilterEntry")
        
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        
        cell.textLabel?.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 14.0)
        cell.textLabel?.textColor = GlobalColors.orangeRegular
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.numberOfLines = 0
        
        cell.detailTextLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 12.0)
        cell.detailTextLabel?.textColor = GlobalColors.orangeRegular
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        
        switch tabBarSelectionTitle {
        case TabBarTitles.catalog:
            cell.textLabel?.text = catalogImages.titleForSection(indexPath.row)
        case TabBarTitles.userMoments:
            if let title = loadedUserMoments?[indexPath.row].localizedTitle {cell.textLabel?.text = title}
            else {cell.textLabel?.text = "Moment"}
            
            if let endDate = loadedUserMoments?[indexPath.row].endDate {
                var stringToDisplay = dateFormatter.string(from: endDate)
                if let locations = loadedUserMoments?[indexPath.row].localizedLocationNames {
                    if locations.count > 0 {
                        stringToDisplay += "  \u{F1C}  \(locations[0])"
                        if locations.count == 2 {stringToDisplay += " & 1 more place"}
                        else if locations.count > 2 {stringToDisplay += ", & \(locations.count - 1) more places"}
                    }
                }
                cell.detailTextLabel?.text = stringToDisplay
            }
        case TabBarTitles.userAlbums:
            cell.textLabel?.text = loadedUserAlbums?[indexPath.row].localizedTitle
        default: break
        }
       
        return cell
    }
    
    
    //
    // MARK: Delegate Methods
    //
    
    //
    // UICollectionViewDelegate

    // Determining if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            if cell.reuseIdentifier == ReuseIdentifiers.loading {
                switch networkState {
                case .failed(_):
                    if let newEventViewController = navigationController?.viewControllers[1] as? NewEventViewController {
                        newEventViewController.reFetchCloudImages()
                    }
                default: break
                }
                return false
            }
        }
        
//        let transition = CATransition()
//        transition.duration = 0.2
//        transition.type = kCATransitionFade
//
//        if let selectedCells = catalogImagesCollectionView.indexPathsForSelectedItems {
//            for ip in selectedCells {
//                catalogImagesCollectionView.cellForItem(at: ip)?.backgroundView?.layer.add(transition, forKey: "transition")
//                catalogImagesCollectionView.deselectItem(at: ip, animated: true)
//            }
//        }
//        if let selectedCells = userPhotosCollectionView.indexPathsForSelectedItems {
//            for ip in selectedCells {
//                userPhotosCollectionView.cellForItem(at: ip)?.backgroundView?.layer.add(transition, forKey: "transition")
//                userPhotosCollectionView.deselectItem(at: ip, animated: true)
//            }
//        }
//
//        return true
        
        switch tabBarSelection {
        case .catalog:
            selectedImage = catalogImages[indexPath.section][indexPath.row]
            locationForCellView = catalogImages[indexPath.section][indexPath.row].recommendedLocationForCellView
            //selectedCatalogImageIndexPath = indexPath
        case .userMoments:
            locationForCellView = nil
            let userImage = momentsPhotoAssets[indexPath.section][indexPath.row]
            selectedImage = UserEventImage(fromPhotosAsset: userImage)
           //selectedUserPhotoIndexPath = indexPath
        case .userAlbums:
            locationForCellView = nil
            let userImage = albumsPhotoAssets[indexPath.section][indexPath.row]
            selectedImage = UserEventImage(fromPhotosAsset: userImage)
            //selectedUserPhotoIndexPath = indexPath
        case .none: break
        }
        performSegue(withIdentifier: SegueIdentifiers.imagePreview, sender: self)
        
        return false
    }
    
    // Did Select Cell
    /*func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = kCATransitionFade
        collectionView.cellForItem(at: indexPath)!.backgroundView?.layer.add(transition, forKey: "transition")
        
        if collectionView == catalogImagesCollectionView {
            let _selectedImage = catalogImages[indexPath.section][indexPath.row]
            locationForCellView = _selectedImage.recommendedLocationForCellView
            selectedImage = _selectedImage
            selectedCatalogImageIndexPath = indexPath
        }
        else if collectionView == userPhotosCollectionView {
            locationForCellView = nil
            switch tabBarSelection {
            case .userMoments:
                let userImage = momentsPhotoAssets[indexPath.section][indexPath.row]
                selectedImage = UserEventImage(fromPhotosAsset: userImage)
                selectedUserPhotoIndexPath = indexPath
            case .userAlbums:
                let userImage = albumsPhotoAssets[indexPath.section][indexPath.row]
                selectedImage = UserEventImage(fromPhotosAsset: userImage)
                selectedUserPhotoIndexPath = indexPath
            default: break
            }
        }
    }*/
        
    //
    // UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == catalogImagesCollectionView {
            if indexPath.row < catalogImages[indexPath.section].count {
                let width = catalogImages[indexPath.section][indexPath.row].thumbnail!.uiImage!.size.width + (2 * marginForCellImage)
                let height = catalogImages[indexPath.section][indexPath.row].thumbnail!.uiImage!.size.height + (2 * marginForCellImage) + cellGlyphHeight + cellImageToGlyphSpacing
                return CGSize(width: width, height: height)
            }
            else {return CGSize(width: 100.0, height: 100.0)}
        }
        else {return userPhotoCellSize}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == catalogImagesCollectionView {
            return UIEdgeInsets(top: 0.0, left: collectionViewMargin, bottom: 0.0, right: collectionViewMargin)
        }
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == catalogImagesCollectionView {return catalogPhotosCellSpacing}
        return userPhotosCellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == catalogImagesCollectionView {return catalogPhotosCellSpacing}
        return userPhotosCellSpacing
    }
    
    //
    // UITabBarDelegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if tabBar == imagesTabBar {tabBarSelectionTitle = item.title}
        else if tabBar == findTabBar && item == findTabBarItem {
            if presentedViewController == nil {presentFilterPopover()}
            else {dismiss(animated: true, completion: nil)}
        }
//        if item.title == tabBarSelectionTitle {
//
//            let optionsViewController = UIViewController()
//            optionsViewController.modalPresentationStyle = .popover
//
//            let popController = optionsViewController.popoverPresentationController!
//            popController.backgroundColor = GlobalColors.darkPurpleForFills
//            popController.delegate = self
//            popController.sourceView = tabBar
//
//            let edgeInsets: CGFloat = 12.0
//            let spacing: CGFloat = 6.0
//
//            let containerStackView = UIStackView()
//            containerStackView.translatesAutoresizingMaskIntoConstraints = false
//            containerStackView.backgroundColor = UIColor.clear
//            containerStackView.axis = .vertical
//            containerStackView.distribution = .fillEqually
//            containerStackView.spacing = 4.0
//
//            let filterButton = UIButton()
//            filterButton.translatesAutoresizingMaskIntoConstraints = false
//            filterButton.tag = 1
//            filterButton.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//            filterButton.tintColor = GlobalColors.orangeDark
//            filterButton.setTitle("Find", for: .normal)
//            filterButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
//            filterButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
//            filterButton.contentEdgeInsets = UIEdgeInsets(top: spacing / 2, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
//
//            let filterButtonImage = UIButton()
//            filterButtonImage.translatesAutoresizingMaskIntoConstraints = false
//            filterButtonImage.tag = 2
//            filterButtonImage.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//            filterButtonImage.setImage(#imageLiteral(resourceName: "FilterButtonImage"), for: .normal)
//            filterButtonImage.tintColor = GlobalColors.orangeDark
//            filterButtonImage.contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: spacing / 2, right: edgeInsets)
//
//            let filterStackView = UIStackView()
//            filterStackView.translatesAutoresizingMaskIntoConstraints = false
//            filterStackView.axis = .vertical
//            filterStackView.alignment = .center
//
//            filterStackView.addArrangedSubview(filterButtonImage)
//            filterStackView.addArrangedSubview(filterButton)
//
//            containerStackView.addArrangedSubview(filterStackView)
//
//            if tabBarSelection == .userPhotos {
//                let momentsButton = UIButton()
//                momentsButton.translatesAutoresizingMaskIntoConstraints = false
//                momentsButton.tag = 3
//                momentsButton.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//                if userPhotosDataState == .moments {momentsButton.setTitleColor(GlobalColors.cyanRegular, for: .normal)}
//                else {momentsButton.setTitleColor(GlobalColors.unselectedButtonColor, for: .normal)}
//                momentsButton.setTitle("Moments", for: .normal)
//                momentsButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
//                momentsButton.contentEdgeInsets = UIEdgeInsets(top: spacing / 2, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
//
//                let momentsImageButton = UIButton()
//                momentsImageButton.translatesAutoresizingMaskIntoConstraints = false
//                momentsImageButton.tag = 4
//                momentsImageButton.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//                momentsImageButton.setImage(#imageLiteral(resourceName: "UserMomentsButtonImage"), for: .normal)
//                if userPhotosDataState == .moments {momentsImageButton.tintColor = GlobalColors.cyanRegular}
//                else {momentsImageButton.tintColor = GlobalColors.unselectedButtonColor}
//                momentsImageButton.contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: spacing / 2, right: edgeInsets)
//
//                let albumsButton = UIButton()
//                albumsButton.translatesAutoresizingMaskIntoConstraints = false
//                albumsButton.tag = 5
//                albumsButton.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//                if userPhotosDataState == .albums {albumsButton.setTitleColor(GlobalColors.cyanRegular, for: .normal)}
//                else {albumsButton.setTitleColor(GlobalColors.unselectedButtonColor, for: .normal)}
//                albumsButton.setTitle("Albums", for: .normal)
//
//                albumsButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
//                albumsButton.contentEdgeInsets = UIEdgeInsets(top: spacing / 2, left: edgeInsets, bottom: edgeInsets, right: edgeInsets)
//
//                let albumsButtonImage = UIButton()
//                albumsButtonImage.translatesAutoresizingMaskIntoConstraints = false
//                albumsButtonImage.tag = 6
//                albumsButtonImage.addTarget(self, action: #selector(handleUserPhotosOptionsButtonClick(_:)), for: .touchUpInside)
//                albumsButtonImage.setImage(#imageLiteral(resourceName: "UserAlbumsButtonImage"), for: .normal)
//                if userPhotosDataState == .albums {albumsButtonImage.tintColor = GlobalColors.cyanRegular}
//                else {albumsButtonImage.tintColor = GlobalColors.unselectedButtonColor}
//                albumsButtonImage.contentEdgeInsets = UIEdgeInsets(top: edgeInsets, left: edgeInsets, bottom: spacing / 2, right: edgeInsets)
//
//                optionsViewController.view = {
//                    let rootView = UIView()
//                    rootView.backgroundColor = UIColor.clear
//                    rootView.translatesAutoresizingMaskIntoConstraints = false
//
//                    let buttonsStackView = UIStackView()
//                    buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
//                    buttonsStackView.axis = UILayoutConstraintAxis.horizontal
//                    buttonsStackView.alignment = .center
//                    buttonsStackView.distribution = UIStackViewDistribution.fillEqually
//                    buttonsStackView.spacing = 4.0
//
//                    let momentsStackView = UIStackView()
//                    momentsStackView.translatesAutoresizingMaskIntoConstraints = false
//                    momentsStackView.axis = .vertical
//                    momentsStackView.alignment = .center
//
//                    momentsStackView.addArrangedSubview(momentsImageButton)
//                    momentsStackView.addArrangedSubview(momentsButton)
//
//                    let albumsStackView = UIStackView()
//                    albumsStackView.translatesAutoresizingMaskIntoConstraints = false
//                    albumsStackView.axis = .vertical
//                    albumsStackView.alignment = .center
//
//                    albumsStackView.addArrangedSubview(albumsButtonImage)
//                    albumsStackView.addArrangedSubview(albumsButton)
//
//                    buttonsStackView.addArrangedSubview(momentsStackView)
//                    buttonsStackView.addArrangedSubview(albumsStackView)
//
//                    containerStackView.addArrangedSubview(buttonsStackView)
//
//                    rootView.addSubview(containerStackView)
//
//                    rootView.topAnchor.constraint(equalTo: containerStackView.topAnchor).isActive = true
//                    rootView.leftAnchor.constraint(equalTo: containerStackView.leftAnchor).isActive = true
//                    rootView.rightAnchor.constraint(equalTo: containerStackView.rightAnchor).isActive = true
//                    rootView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor).isActive = true
//
//                    return rootView
//                }()
//
//                optionsViewController.preferredContentSize = optionsViewController.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
//                popController.sourceRect = CGRect(x: tabBar.bounds.width / 2, y: 0.0, width: tabBar.bounds.width / 2, height: tabBar.bounds.height)
//
//                present(optionsViewController, animated: true, completion: nil)
//            }
//            else if tabBarSelection == .catalog {
//
//            }
//        }
    }
    
    //
    // MARK: Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tabBarSelection {
        case .catalog:
            if let attributes = catalogImagesCollectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.row)) {
                dismiss(animated: true, completion: nil)
                catalogImagesCollectionView.setContentOffset(attributes.frame.origin, animated: true)
            }
        case .userMoments, .userAlbums:
            if let attributes = userPhotosCollectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.row)) {
                self.userPhotosCollectionView.setContentOffset(attributes.frame.origin, animated: true)
            }
        case .none: break
        }
        dismiss(animated: true, completion: nil)
    }
    
    //
    // CountdownImageDelagate
    func fetchComplete(forImageTypes: [CountdownImage.ImageType], success: [Bool]) {
        if !success.contains(where: {$0 == false}) && needToDismissSelf {
            let appImage = selectedImage as! AppEventImage
            guard appImage.mainImage != nil && appImage.maskImage != nil else {return}
            let newEventController = navigationController!.viewControllers[1] as! NewEventViewController
            newEventController.selectedImage = selectedImage
            self.dismiss(animated: true, completion: nil)
            navigationController!.viewControllers[0].dismiss(animated: true, completion: nil)
            needToDismissSelf = false
        }
    }
    
    //
    // MARK: ManagedCatalogImageDelegate
    func dataUpdated() {
        catalogImagesCollectionView.reloadData()
        //catalogImagesCollectionView.selectItem(at: selectedCatalogImageIndexPath, animated: true, scrollPosition: .top)
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
            let newEventController = navigationController!.viewControllers[1] as! NewEventViewController
            if button == doneButton {
                if doneButton.title == "USE IMAGE" {
                    guard locationForCellView != nil else {
                        fatalError("Unexpected State: Done button was activated even though the image had no locationForCell View!")
                    }
                    var imagesToFetch = [CountdownImage.ImageType]()
                    if selectedImage?.mainImage?.cgImage == nil {imagesToFetch.append(.main)}
                    if let appImage = selectedImage as? AppEventImage {
                        if appImage.maskImage?.cgImage == nil {imagesToFetch.append(.mask)}
                    }
                    if imagesToFetch.isEmpty {
                        newEventController.selectedImage = selectedImage
                        newEventController.locationForCellView = locationForCellView
                        navigationController?.popViewController(animated: true)
                    }
                    else {
                        let popup = UIAlertController(title: "Fetching Image", message: "This may take a moment.", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel) { (action) in
                            if action.title == "CANCEL" {
                                self.selectedImage?.cancelNetworkFetches()
                                self.needToDismissSelf = false
                            }
                        }
                        popup.addAction(cancelAction)
                        self.present(popup, animated: true, completion: nil)
                        selectedImage?.delegate = self
                        needToDismissSelf = true
                        selectedImage?.fetch(imageTypes: imagesToFetch, alertDelegate: true)
                        
                        Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] (timer) in
                            if let _ = self {
                                popup.message = "Still fetching, the network is a bit slow."
                            }
                        }
                    }
                }
                else if doneButton.title == "CREATE IMAGE" {
                    performSegue(withIdentifier: SegueIdentifiers.imagePreview, sender: doneButton)
                }
                else {fatalError("Fatal Error: Unhandled done button title!")}
            }
        }
    }*/
    
    /*@objc fileprivate func handleUserPhotosOptionsButtonClick(_ sender: UIButton) {
        
        switch sender.tag {
        case 1, 2: dismiss(animated: false, completion: nil); presentFilterPopover()
        case 3, 4: dismiss(animated: true, completion: nil); tabBarSelectionTitle = TabBarTitles.userMoments
        case 5, 6: dismiss(animated: true, completion: nil); tabBarSelectionTitle = TabBarTitles.userAlbums
        default:
            // TODO: Remove for production.
            fatalError("Fatal Error: Unrecognized options button title handled.")
        }
    }*/
    
    /*@objc fileprivate func handleCellDoubleTap(_ sender: Any?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if let cell = recognizer.view as? SelectImageCollectionViewCell, let ipForCell = catalogImagesCollectionView.indexPath(for: cell) {
                selectedImage = catalogImages[ipForCell.section][ipForCell.row]
                locationForCellView = catalogImages[ipForCell.section][ipForCell.row].recommendedLocationForCellView
                selectedCatalogImageIndexPath = ipForCell
            }
            else if let cell = recognizer.view as? UICollectionViewCell, let ipForCell = userPhotosCollectionView.indexPath(for: cell) {
                locationForCellView = nil
                switch tabBarSelection {
                case .userMoments:
                    let userImage = momentsPhotoAssets[ipForCell.section][ipForCell.row]
                    selectedImage = UserEventImage(fromPhotosAsset: userImage)
                    selectedUserPhotoIndexPath = ipForCell
                case .userAlbums:
                    let userImage = albumsPhotoAssets[ipForCell.section][ipForCell.row]
                    selectedImage = UserEventImage(fromPhotosAsset: userImage)
                    selectedUserPhotoIndexPath = ipForCell
                default: break
                }
            }
            performSegue(withIdentifier: SegueIdentifiers.imagePreview, sender: self)
        }
    }*/
    
    
    //
    // MARK: - Private helper methods
    //
    
    //
    // MARK: init helpers
    
    fileprivate func presentFilterPopover() {
        let filterViewController = UITableViewController()
        filterViewController.view.backgroundColor = UIColor.clear
        filterViewController.tableView.backgroundColor = UIColor.clear
        
        filterViewController.tableView.dataSource = self
        filterViewController.tableView.delegate = self
        
        filterViewController.tableView.tableFooterView = UIView()
        
        filterViewController.modalPresentationStyle = .popover
        filterViewController.preferredContentSize = CGSize(width: view.bounds.width * 0.75, height: view.bounds.height * 0.50)
        
        let popController = filterViewController.popoverPresentationController!
        popController.backgroundColor = GlobalColors.lightGrayForFills
        popController.delegate = self
        popController.sourceView = findTabBar
        popController.sourceRect = findTabBar.bounds
        
        self.present(filterViewController, animated: true, completion: nil)
    }
}
