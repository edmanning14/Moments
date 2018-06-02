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

class SelectImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITabBarDelegate, CountdownImageDelegate {
    
    //
    // \
    //
    
    //
    // Public data model
    
    var selectedImage: UserEventImage? {
        didSet {
            if isViewLoaded {
                if selectedImage != nil {
                    if let appImage = selectedImage as? AppEventImage {
                        if !catalogImages.contains(where: {$0.title == appImage.title}) {
                            catalogImages.append(appImage)
                        }
                        selectedImageIndexPath = IndexPath(row: catalogImages.count - 1, section: 0)
                    }
                }
                else {selectedImageIndexPath = nil}
            }
        }
    }
    
    var catalogImages = [AppEventImage]() {
        willSet {
            for image in newValue {
                guard image.thumbnail?.uiImage != nil else {
                    fatalError("An image in catalogImages did not contain a thumbnail!")
                }
            }
        }
        didSet {
            if isViewLoaded {
                catalogImagesCollectionView.reloadData()
                catalogImagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)
            }
        }
    }
    
    //
    // Private data model
    
    fileprivate var selectedImageIndexPath: IndexPath?
    fileprivate let userPhotosCellSpacing: CGFloat = 1.0
    fileprivate let numberOfUserPhotoCellsPerColumn: CGFloat = 4.0
    fileprivate var userPhotoCellSize = CGSize()
    fileprivate var productIDs = Set<Product>()
    
    fileprivate var loadedUserMoments: PHFetchResult<PHAssetCollection>?
    
    fileprivate var userPhotoAssets = [PHFetchResult<PHAsset>]() {
        didSet {
            //let dimension = userPhotosCollectionView.bounds.width / numberOfUserPhotoCellsPerColumn
            let dimension = (userPhotosCollectionView.bounds.width - ((numberOfUserPhotoCellsPerColumn - 1) * userPhotosCellSpacing)) / numberOfUserPhotoCellsPerColumn
            userPhotoCellSize = CGSize(width: dimension, height: dimension)
            userPhotosCollectionView.reloadData()
        }
    }
    
    fileprivate var userPhotosImageManager: PHCachingImageManager?
    
    //
    // Types
    
    fileprivate class CollectionViewBackground: UIView {
        
        struct Messages {
            static let selectSource = "Select an image source below to view Images!"
            static let noImages = "Nothing to see here..."
            static let loading = "Fetching Images"
            static let loadImagesError = "Sorry! There was an error loading the images. Please try again later."
            static let restrictedAccess = "Need a message here..." // TODO: Add a message here.
            static let deniedAccess = "Your moments are inaccessable! If you would like to allow access, please navigate to Settings -> Photos to allow access."
        }
        
        var message = Messages.noImages {didSet{messageLabel.text = message}}
        
        private let messageLabel = UILabel()
        private var didSetConstraints = false
        
        private let contentSecondaryFontName = "Raleway-Regular"
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            commonInit()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }
        
        func commonInit() {
            
            self.translatesAutoresizingMaskIntoConstraints = false
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            
            messageLabel.font = UIFont(name: contentSecondaryFontName, size: 14.0)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            
            addSubview(messageLabel)
            centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor).isActive = true
            leftAnchor.constraint(equalTo: messageLabel.leftAnchor, constant: 8.0).isActive = true
            rightAnchor.constraint(equalTo: messageLabel.rightAnchor, constant: 8.0).isActive = true
            
            self.setNeedsLayout()
        }
        
        override func layoutSubviews() {
            if !didSetConstraints {
                messageLabel.centerYAnchor.constraint(equalTo: superview!.centerYAnchor).isActive = true
                messageLabel.leftAnchor.constraint(equalTo: superview!.layoutMarginsGuide.leftAnchor).isActive = true
                messageLabel.rightAnchor.constraint(equalTo: superview!.layoutMarginsGuide.rightAnchor).isActive = true
                messageLabel.text = message
                didSetConstraints = true
            }
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
    
    fileprivate enum TabBarSelections: Int {case catalog = 0, personalPhotos, none}
    
    //
    // States
    
    fileprivate var tabBarSelectionTitle: String? {
        didSet {
            switch tabBarSelectionTitle {
            case TabBarTitles.catalog?: tabBarSelection = .catalog
            case TabBarTitles.personalPhotos?: tabBarSelection = .personalPhotos
            case nil: tabBarSelection = .none
            default: fatalError("Unexpected State: Recieved an unrecognized TabBar Title")
            }
        }
    }
    fileprivate var tabBarSelection = TabBarSelections.none {
        didSet {
            switch tabBarSelection {
            case .catalog:
                catalogImagesCollectionView.isHidden = false; catalogImagesCollectionView.isUserInteractionEnabled = true
                userPhotosCollectionView.isHidden = true; userPhotosCollectionView.isUserInteractionEnabled = false
            case .personalPhotos:
                catalogImagesCollectionView.isHidden = true; catalogImagesCollectionView.isUserInteractionEnabled = false
                userPhotosCollectionView.isHidden = false; userPhotosCollectionView.isUserInteractionEnabled = true
            case .none:
                catalogImagesCollectionView.isHidden = true; catalogImagesCollectionView.isUserInteractionEnabled = false
                userPhotosCollectionView.isHidden = true; userPhotosCollectionView.isUserInteractionEnabled = false
            }
        }
    }
    
    //
    // MARK: States
    
    var networkState = NewEventViewController.NetworkStates.loading {
        didSet {
            if isViewLoaded {
                if networkState == .complete {
                    catalogImagesCollectionView.reloadData()
                    catalogImagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)
                    return
                }
                let ip = IndexPath(row: catalogImages.count, section: 0)
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
    
    //
    // MARK: Flags
    fileprivate var needToDismissSelf = false
    fileprivate var userPhotoFetchComplete = false
    
    //
    // MARK: Constants
    let defaultNetworkErrorMessage = "Network error! Tap to retry."
    
    //
    // MARK: Persistence
    
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    fileprivate var localPersistentStore: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    
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
        static let personalPhotos = "Personal Photos"
    }
    
    fileprivate let marginForCellImage: CGFloat = 10.0
    fileprivate let collectionViewMargin: CGFloat = 20.0
    fileprivate let cellGlyphHeight: CGFloat = 20.0
    fileprivate let cellImageToGlyphSpacing: CGFloat = 10.0
    fileprivate let catalogPhotosCellSpacing: CGFloat = 10.0
    
    //
    // MARK: UIElements
    
    var navItemTitleLabel: UILabel!
    var cancelButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem!
    fileprivate var collectionViewBackgroundView: CollectionViewBackground?
    
    fileprivate class UserPhotosCollectionViewSectionHeader: UICollectionReusableView {
        let titleLabel = UILabel()
        let subTitleLabel = UILabel()
        
        fileprivate let headingsFontName = "Comfortaa-Regular"
        fileprivate let contentSecondaryFontName = "Raleway-Regular"
        
        fileprivate func commonInit() {
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont(name: headingsFontName, size: 18.0)
            
            subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            subTitleLabel.font = UIFont(name: contentSecondaryFontName, size: 14.0)
            subTitleLabel.numberOfLines = 0
            subTitleLabel.lineBreakMode = .byWordWrapping
            
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
   
    @IBOutlet weak var catalogImagesCollectionView: UICollectionView!
    @IBOutlet weak var userPhotosCollectionView: UICollectionView!
    @IBOutlet weak var imagesTabBar: UITabBar!
    
    //
    // MARK: Design
    // MARK: Colors
    let primaryTextRegularColor = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
    let primaryTextDarkColor = UIColor(red: 230/255, green: 81/255, blue: 0.0, alpha: 1.0)
    
    // MARK: Fonts
    let headingsFontName = "Comfortaa-Light"
    let contentSecondaryFontName = "Raleway-Regular"
    
    //
    // Other

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
        
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont(name: headingsFontName, size: 30.0) as Any,
            .foregroundColor: primaryTextRegularColor
        ]
        
        let doneButton = UIBarButtonItem()
        doneButton.target = self
        doneButton.action = #selector(handleNavButtonClick(_:))
        doneButton.tintColor = primaryTextDarkColor
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: contentSecondaryFontName, size: 16.0)! as Any]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.title = "USE IMAGE"
        navigationItem.rightBarButtonItem = doneButton
        if let image = selectedImage {if image.locationForCellView == nil {doneButton.isEnabled = false}}
        else {doneButton.isEnabled = false}
        
        /*cancelButton = UIBarButtonItem()
        cancelButton.target = self
        cancelButton.action = #selector(handleNavButtonClick(_:))
        cancelButton.tintColor = primaryTextDarkColor
        cancelButton.setTitleTextAttributes(attributes, for: .normal)
        cancelButton.title = "CANCEL"
        navigationItem.leftBarButtonItem = cancelButton*/
        
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        userPhotosCollectionView.register(UserPhotosCollectionViewSectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "userPhotosHeader")
        
        fetchUserPhotos()
        
        if let tabBarItems = imagesTabBar.items {
            if let i = tabBarItems.index(where: {$0.title! == TabBarTitles.catalog}) {
                imagesTabBar.selectedItem = tabBarItems[i]
                tabBarSelectionTitle = TabBarTitles.catalog
            }
        }
        
        if selectedImage != nil {
            if let image = selectedImage as? AppEventImage {
                let i = catalogImages.index(where: {$0.title == image.title})!
                selectedImageIndexPath = IndexPath(row: i, section: 0)
                catalogImagesCollectionView.selectItem(at: selectedImageIndexPath, animated: true, scrollPosition: .top)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .default}
    
    /*override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if selectedImageIndexPath != nil {
            imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: true, scrollPosition: .top)
        }
    }*/
    
    override func viewWillDisappear(_ animated: Bool) {UIApplication.shared.statusBarStyle = .lightContent}

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    

    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let ident = segue.identifier {
            switch ident {
            case SegueIdentifiers.imagePreview:
                let navController = segue.destination as! UINavigationController
                let destination = navController.viewControllers[0] as! ImagePreviewViewController
                destination.selectedImage = selectedImage
                
                let cancelButton = UIBarButtonItem()
                cancelButton.tintColor = primaryTextDarkColor
                let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: contentSecondaryFontName, size: 16.0)! as Any]
                cancelButton.setTitleTextAttributes(attributes, for: .normal)
                cancelButton.title = "IMAGES"
                navController.navigationItem.backBarButtonItem = cancelButton
                
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
                if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                collectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                collectionView.backgroundView = collectionViewBackgroundView
                collectionView.backgroundView!.setNeedsLayout()
                return 0
            }
            else if catalogImages.isEmpty && networkState == .complete {
                if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                collectionViewBackgroundView!.message = CollectionViewBackground.Messages.loadImagesError
                collectionView.backgroundView = collectionViewBackgroundView
                collectionView.backgroundView!.setNeedsLayout()
                return 0
            }
            else {
                collectionView.backgroundView = nil
                return 1
            }
        }
        else {
            if userPhotoAssets.isEmpty && !userPhotoFetchComplete {
                if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                collectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                collectionView.backgroundView = collectionViewBackgroundView
                collectionView.backgroundView!.setNeedsLayout()
                return 0
            }
            else if userPhotoAssets.isEmpty && userPhotoFetchComplete {
                if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                collectionViewBackgroundView!.message = CollectionViewBackground.Messages.noImages
                collectionView.backgroundView = collectionViewBackgroundView
                collectionView.backgroundView!.setNeedsLayout()
                return 0
            }
            else {
                collectionView.backgroundView = nil
                return userPhotoAssets.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == catalogImagesCollectionView {
            if networkState == .complete {return catalogImages.count}
            else {return catalogImages.count + 1}
        }
        else {return userPhotoAssets[section].count}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView == userPhotosCollectionView {
            let width = collectionView.bounds.width
            let height: CGFloat = 70.0
            return CGSize(width: width, height: height)
        }
        else {return CGSize()}
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == userPhotosCollectionView {
            if kind == UICollectionElementKindSectionHeader {
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
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == catalogImagesCollectionView {
            if indexPath.row >= catalogImages.count {
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
                cell.image = catalogImages[indexPath.row].thumbnail?.uiImage
                cell.imageTitle = catalogImages[indexPath.row].title
                cell.imageIsAvailable = true
                if cell.gestureRecognizers?.count == 0 || cell.gestureRecognizers == nil {
                    let cellDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCellDoubleTap(_:)))
                    cellDoubleTapGestureRecognizer.numberOfTapsRequired = 2
                    cell.addGestureRecognizer(cellDoubleTapGestureRecognizer)
                }
                configure(cell: cell)
                return cell
            }
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.userPhotoCell, for: indexPath)
            let imageView = cell.contentView.subviews[0] as! UIImageView
            if cell.tag != 0 {userPhotosImageManager?.cancelImageRequest(PHImageRequestID(cell.tag))}
        
            let id = userPhotosImageManager?.requestImage(for: userPhotoAssets[indexPath.section][indexPath.row], targetSize: userPhotoCellSize, contentMode: .aspectFill, options: nil) { (image, _info) in
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
            
            if cell.gestureRecognizers?.count == 0 || cell.gestureRecognizers == nil {
                let cellDoubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCellDoubleTap(_:)))
                cellDoubleTapGestureRecognizer.numberOfTapsRequired = 2
                cell.addGestureRecognizer(cellDoubleTapGestureRecognizer)
            }
            
            return cell
        }
    }
    
    //
    // UICollectionViewDelegate

    // Determining if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath) {
            if cell.reuseIdentifier == ReuseIdentifiers.loading {return false}
        }
        
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            for ip in selectedCells {
                collectionView.deselectItem(at: ip, animated: true)
                if let cell = collectionView.cellForItem(at: ip) as? SelectImageCollectionViewCell {
                    cell.layer.shadowColor = UIColor.gray.cgColor
                }
            }
        }
        return true
    }
    
    // Did Select Cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == catalogImagesCollectionView {
            selectedImage = catalogImages[indexPath.row]
        }
        else {
            let userImage = userPhotoAssets[indexPath.section][indexPath.row]
            selectedImage = UserEventImage(fromPhotosAsset: userImage)
        }
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.layer.shadowColor = UIColor.black.cgColor
        }
    }
    
    //
    // UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == catalogImagesCollectionView {
            if indexPath.row < catalogImages.count {
                let width = catalogImages[indexPath.row].thumbnail!.uiImage!.size.width + (2 * marginForCellImage)
                let height = catalogImages[indexPath.row].thumbnail!.uiImage!.size.height + (2 * marginForCellImage) + cellGlyphHeight + cellImageToGlyphSpacing
                return CGSize(width: width, height: height)
            }
            else {return CGSize(width: 100.0, height: 100.0)}
        }
        else {return userPhotoCellSize}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == catalogImagesCollectionView {
            return UIEdgeInsets(top: collectionViewMargin, left: collectionViewMargin, bottom: collectionViewMargin, right: collectionViewMargin)
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
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {tabBarSelectionTitle = tabBar.selectedItem?.title}
    
    //
    // CountdownImageDelagate
    func fetchComplete(forImageTypes: [CountdownImage.ImageType], success: [Bool]) {
        if !success.contains(where: {$0 == false}) && needToDismissSelf {
            let appImage = selectedImage as! AppEventImage
            guard appImage.mainImage != nil && appImage.maskImage != nil else {return}
            let splitViewController = self.presentingViewController as! UISplitViewController
            let navController = splitViewController.viewControllers[0] as! UINavigationController
            let navController2 = navController.viewControllers[1] as! UINavigationController
            let newEventController = navController2.viewControllers[0] as! NewEventViewController
            newEventController.selectedImage = selectedImage
            self.dismiss(animated: true, completion: nil)
            newEventController.dismiss(animated: true, completion: nil)
            needToDismissSelf = false
        }
    }
    
    
    //
    // MARK: - Target-Action and Objc Targeted Methods
    //
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        if let button = sender as? UIBarButtonItem {
            let splitViewController = self.presentingViewController as! UISplitViewController
            let navController = splitViewController.viewControllers[0] as! UINavigationController
            let navController2 = navController.viewControllers[1] as! UINavigationController
            let newEventController = navController2.viewControllers[0] as! NewEventViewController
            if button == cancelButton {newEventController.dismiss(animated: true, completion: nil)}
            if button == doneButton {
                guard selectedImage != nil else {
                    fatalError("Unexpected State: Done button was activated even though an image wasn't selected!")
                }
                var imagesToFetch = [CountdownImage.ImageType]()
                if selectedImage?.mainImage?.cgImage == nil {imagesToFetch.append(.main)}
                if let appImage = selectedImage as? AppEventImage {
                    if appImage.maskImage?.cgImage == nil {imagesToFetch.append(.mask)}
                }
                if imagesToFetch.isEmpty {
                    newEventController.selectedImage = selectedImage
                    newEventController.dismiss(animated: true, completion: nil)
                }
                else {
                    let popup = UIAlertController(title: "Fetching Image", message: "This may take a moment.", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel) { (action) in
                        if action.title == "CANCEL" {
                            self.selectedImage?.cancelAllFetches()
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
        }
    }
    
    @objc fileprivate func handleCellDoubleTap(_ sender: Any?) {
        if let recognizer = sender as? UITapGestureRecognizer {
            if let cell = recognizer.view as? SelectImageCollectionViewCell, let ipForCell = catalogImagesCollectionView.indexPath(for: cell) {
                selectedImage = catalogImages[ipForCell.row]
            }
            else if let cell = recognizer.view as? UICollectionViewCell, let ipForCell = catalogImagesCollectionView.indexPath(for: cell) {
                let userImage = userPhotoAssets[ipForCell.section][ipForCell.row]
                selectedImage = UserEventImage(fromPhotosAsset: userImage)
            }
            performSegue(withIdentifier: SegueIdentifiers.imagePreview, sender: self)
        }
    }
    
    
    //
    // MARK: - Private helper methods
    //
    
    //
    // MARK: init helpers
    fileprivate func fetchUserPhotos() {
        let localPhotosFetchQueue = DispatchQueue(label: "localPhotosFetchQueue", qos: .utility, target: nil)
        userPhotosImageManager = PHCachingImageManager()
        
        func getPhotos() {
            userPhotoFetchComplete = false
            let localPhotosFetchWorkItem = DispatchWorkItem { [weak self] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
                self?.loadedUserMoments = PHAssetCollection.fetchMoments(with: fetchOptions)
                var assets = [PHFetchResult<PHAsset>]()
                self?.loadedUserMoments?.enumerateObjects { [weak self] (collection, _, _) in
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", argumentArray: [PHAssetMediaType.image.rawValue])
                    fetchOptions.includeAllBurstAssets = false
                    let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    assets.append(result)
                    var imagesToCache = [PHAsset]()
                    result.enumerateObjects { (asset, _, _) in imagesToCache.append(asset)}
                    self?.userPhotosImageManager?.startCachingImages(for: imagesToCache, targetSize: self!.userPhotoCellSize, contentMode: .aspectFit, options: nil)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.userPhotoFetchComplete = true
                    self?.userPhotoAssets = assets
                }
            }
            localPhotosFetchQueue.async(execute: localPhotosFetchWorkItem)
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in if status == .authorized {getPhotos()}}
        case .restricted:
            if let background = userPhotosCollectionView.backgroundView as? CollectionViewBackground {
                background.message = CollectionViewBackground.Messages.restrictedAccess
            }
        case .denied:
            if let background = userPhotosCollectionView.backgroundView as? CollectionViewBackground {
                background.message = CollectionViewBackground.Messages.deniedAccess
            }
        case .authorized: getPhotos()
        }
    }
    
    //
    // MARK: Utility helpers
    fileprivate func configure(cell: SelectImageCollectionViewCell) {
        let cellBackgroundView = UIView()
        let cellSelectedBackgroundView = UIView()
        let cornerRadius: CGFloat = 5.0
        
        cellBackgroundView.layer.backgroundColor = UIColor.darkGray.cgColor
        cellBackgroundView.layer.cornerRadius = cornerRadius
        cellBackgroundView.layer.masksToBounds = true
        cellBackgroundView.layer.isOpaque = true
        
        cellSelectedBackgroundView.layer.backgroundColor = UIColor.black.cgColor
        cellSelectedBackgroundView.layer.cornerRadius = cornerRadius
        cellSelectedBackgroundView.layer.masksToBounds = true
        cellSelectedBackgroundView.layer.isOpaque = true
        
        cell.backgroundView = cellBackgroundView
        cell.selectedBackgroundView = cellSelectedBackgroundView
        cell.layoutMargins = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
        cell.clipsToBounds = false
        
        cell.layer.cornerRadius = cornerRadius
        cell.layer.masksToBounds = false
        cell.layer.isOpaque = true
        
        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
        cell.layer.shadowOpacity = 1.0
        cell.layer.shadowRadius = 10.0
        
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cornerRadius).cgPath
    }
    
    fileprivate func initializeCollectionViewBackground() {
        collectionViewBackgroundView = CollectionViewBackground()
    }
}
