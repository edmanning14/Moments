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

class SelectImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITabBarDelegate, CountdownImageDelegate {
    
    //
    // MARK: - Parameters
    //
    
    //
    // Public data model
    
    var selectedImage: EventImage? {
        didSet {
            if isViewLoaded {
                if selectedImage != nil {
                    if !catalogImages.contains(where: {$0.title == selectedImage!.title}) {
                        catalogImages.append(selectedImage!)
                    }
                    selectedImageIndexPath = IndexPath(row: catalogImages.count - 1, section: 0)
                }
                else {selectedImageIndexPath = nil}
            }
        }
    }
    
    var catalogImages = [EventImage]() {
        willSet {
            for image in newValue {
                guard image.thumbnail?.uiImage != nil else {
                    fatalError("An image in catalogImages did not contain a thumbnail!")
                }
            }
        }
        didSet {
            if isViewLoaded {
                imagesCollectionView.reloadData()
                imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)
            }
        }
    }
    
    //
    // Private data model
    
    fileprivate var selectedImageIndexPath: IndexPath?
    fileprivate var productIDs = Set<Product>()
    
    fileprivate var loadedUserImages = [UIImage]() {didSet {imagesCollectionView.reloadData(); imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)}}
    
    //
    // Types
    
    fileprivate class CollectionViewBackground: UIView {
        
        struct Messages {
            static let selectSource = "Select an image source below to view Images!"
            static let noImages = "Nothing to see here..."
            static let loading = "Loading"
            static let loadImagesError = "Sorry! There was an error loading the images. Please try again later."
        }
        
        var message = Messages.noImages {didSet{messageLabel.text = message}}
        
        private let messageLabel = UILabel()
        private var didSetConstraints = false
        
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
            addSubview(messageLabel)
            
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byTruncatingTail
            
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
    fileprivate var tabBarSelection = TabBarSelections.none {didSet{imagesCollectionView.reloadData(); imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)
        }}
    
    //
    // Flags
    
    var catalogLoadComplete = false {
        didSet {
            if isViewLoaded {
                imagesCollectionView.reloadData()
                imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)
            }
        }
    }
    fileprivate var userPhotLoadComplete = false {didSet{imagesCollectionView.reloadData(); imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: false, scrollPosition: .top)}}
    fileprivate var needToDismissSelf = false
    
    //
    // MARK: Persistence
    
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    fileprivate var localPersistentStore: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    
    //
    // MARK: Constants
    
    fileprivate struct SegueIdentifiers {
        static let imagePreview = "Image Preview"
    }
    
    fileprivate struct ReuseIdentifiers {
        static let image = "Image"
        static let loading = "Loading"
    }
    
    fileprivate struct TabBarTitles {
        static let catalog = "Catalog"
        static let personalPhotos = "Personal Photos"
    }
    
    fileprivate let marginForCellImage: CGFloat = 10.0
    fileprivate let collectionViewMargin: CGFloat = 20.0
    fileprivate let cellGlyphHeight: CGFloat = 20.0
    fileprivate let cellImageToGlyphSpacing: CGFloat = 10.0
    fileprivate let cellSpacing: CGFloat = 10.0
    
    //
    // UIElements
    
    lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleNavButtonClick(_:)))
    lazy var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleNavButtonClick(_:)))
    fileprivate var collectionViewBackgroundView: CollectionViewBackground?
   
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imagesTabBar: UITabBar!
    
    //
    // MARK: Gesture Recognizers
    
    //
    // Other

    fileprivate var productRequest: SKProductsRequest?
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        imagesTabBar.delegate = self
        
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = cancelButton
        
        if let tabBarItems = imagesTabBar.items {
            if let i = tabBarItems.index(where: {$0.title! == TabBarTitles.catalog}) {
                imagesTabBar.selectedItem = tabBarItems[i]
                tabBarSelectionTitle = TabBarTitles.catalog
            }
        }
        
        if selectedImage != nil {
            if !catalogImages.contains(where: {$0.title == selectedImage!.title}) {
                catalogImages.append(selectedImage!)
            }
            let i = catalogImages.index(where: {$0.title == selectedImage!.title})!
            selectedImageIndexPath = IndexPath(row: i, section: 0)
            imagesCollectionView.selectItem(at: selectedImageIndexPath, animated: true, scrollPosition: .top)
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
                destination.image = selectedImage
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
        if imagesTabBar.selectedItem == nil {
            if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
            collectionViewBackgroundView!.message = CollectionViewBackground.Messages.selectSource
            collectionView.backgroundView = collectionViewBackgroundView
            collectionView.backgroundView!.setNeedsLayout()
            return 0
        }
        else {
            switch imagesTabBar.selectedItem!.title! {
            case TabBarTitles.catalog:
                if catalogImages.isEmpty && !catalogLoadComplete {
                    if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                    collectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                    collectionView.backgroundView = collectionViewBackgroundView
                    collectionView.backgroundView!.setNeedsLayout()
                    return 0
                }
                else if catalogImages.isEmpty && catalogLoadComplete {
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
            case TabBarTitles.personalPhotos:
                if loadedUserImages.isEmpty && !catalogLoadComplete {
                    if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                    collectionViewBackgroundView!.message = CollectionViewBackground.Messages.loading
                    collectionView.backgroundView = collectionViewBackgroundView
                    collectionView.backgroundView!.setNeedsLayout()
                    return 0
                }
                else if loadedUserImages.isEmpty && catalogLoadComplete {
                    if collectionViewBackgroundView == nil {initializeCollectionViewBackground()}
                    collectionViewBackgroundView!.message = CollectionViewBackground.Messages.noImages
                    collectionView.backgroundView = collectionViewBackgroundView
                    collectionView.backgroundView!.setNeedsLayout()
                    return 0
                }
                else {
                    collectionView.backgroundView = nil
                    return 1
                }
            default: fatalError("Unexpected State: Recieved an unrecognized TabBar title")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch imagesTabBar.selectedItem!.title! {
        case TabBarTitles.catalog:
            if catalogLoadComplete {return catalogImages.count}
            else {return catalogImages.count + 1}
        case TabBarTitles.personalPhotos: return loadedUserImages.count
        default: fatalError("Unexpected State: Recieved an unrecognized TabBar Title")
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch imagesTabBar.selectedItem!.title! {
        case TabBarTitles.catalog:
            if indexPath.row >= catalogImages.count {
                return collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.loading, for: indexPath)
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
        case TabBarTitles.personalPhotos:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifiers.image, for: indexPath) as! SelectImageCollectionViewCell
            cell.image = loadedUserImages[indexPath.row]
            cell.imageIsAvailable = true
            configure(cell: cell)
            return cell
        default: fatalError("Unexpected State: Recieved an unrecognized TabBar Title")
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
        selectedImage = catalogImages[indexPath.row]
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.layer.shadowColor = UIColor.black.cgColor
        }
    }
    
    //
    // UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row < catalogImages.count {
            let width = catalogImages[indexPath.row].thumbnail!.uiImage!.size.width + (2 * marginForCellImage)
            let height = catalogImages[indexPath.row].thumbnail!.uiImage!.size.height + (2 * marginForCellImage) + cellGlyphHeight + cellImageToGlyphSpacing
            return CGSize(width: width, height: height)
        }
        else {return CGSize(width: 100.0, height: 100.0)}
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: collectionViewMargin, left: collectionViewMargin, bottom: collectionViewMargin, right: collectionViewMargin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellSpacing
    }
    
    //
    // UITabBarDelegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {tabBarSelectionTitle = tabBar.selectedItem?.title}
    
    //
    // CountdownImageDelagate
    func fetchComplete(forImageTypes: [CountdownImage.ImageType], success: [Bool]) {
        if !success.contains(where: {$0 == false}) && needToDismissSelf {
            guard selectedImage!.mainImage != nil && selectedImage!.maskImage != nil else {
                fatalError("Unexpectedly found nil for main image and mask image, check yo code foo.")
            }
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
                if selectedImage!.mainImage?.cgImage == nil {imagesToFetch.append(.main)}
                if selectedImage!.maskImage?.cgImage == nil {imagesToFetch.append(.mask)}
                if imagesToFetch.isEmpty {
                    newEventController.selectedImage = selectedImage
                    newEventController.dismiss(animated: true, completion: nil)
                }
                else {
                    let popup = UIAlertController(title: "Fetching Image...", message: "This may take a moment.", preferredStyle: .alert)
                    self.present(popup, animated: true, completion: nil)
                    selectedImage!.delegate = self
                    needToDismissSelf = true
                    selectedImage!.fetch(imageTypes: imagesToFetch, alertDelegate: true)
                }
            }
        }
    }
    
    @objc fileprivate func handleCellDoubleTap(_ sender: Any?) {
        if let recognizer = sender as? UITapGestureRecognizer, let cell = recognizer.view as? SelectImageCollectionViewCell, let ipForCell = imagesCollectionView.indexPath(for: cell) {
            selectedImage = catalogImages[ipForCell.row]
            performSegue(withIdentifier: SegueIdentifiers.imagePreview, sender: self)
        }
    }
    
    
    //
    // MARK: - Private helper methods
    //
    
    fileprivate func configure(cell: SelectImageCollectionViewCell) {
        let cellBackgroundView = UIView()
        let cellSelectedBackgroundView = UIView()
        let cornerRadius: CGFloat = 5.0
        
        cellBackgroundView.layer.backgroundColor = UIColor.groupTableViewBackground.cgColor
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
