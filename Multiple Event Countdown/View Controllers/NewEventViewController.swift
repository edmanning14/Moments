//
//  NewEventViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/3/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import Foundation
import RealmSwift
import QuartzCore
import os.log
import CloudKit
import StoreKit

class NewEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, SKProductsRequestDelegate, CAAnimationDelegate {

    
    //
    // MARK: - Parameters
    //
    
    //
    // MARK: Data Model
    
    var specialEvent: SpecialEvent?
    
    var eventCategory: String? {
        didSet {
            if editingEvent && isUserChange {
                let master = navigationController!.viewControllers[0] as! MasterViewController
                master.categoryDidChange = true
            }
            if eventCategory != nil && eventCategory != "" {
                categoryLabel.layer.add(labelTransition, forKey: nil)
                categoryLabel.text = eventCategory
                categoryLabel.textColor = Colors.cyanRegular
                categoryProgressImageView?.tintColor = Colors.taskCompleteColor
                if !categoryWaveEffectView.isHidden {
                    viewTransition(from: categoryWaveEffectView, to: categoryLabel)
                }
            }
            else {
                categoryLabel.layer.add(labelTransition, forKey: nil)
                categoryLabel.text = "Category"
                categoryLabel.textColor = Colors.inactiveColor
                categoryProgressImageView?.tintColor = Colors.inactiveColor
            }
            
            checkFinishButtonEnable()
            isUserChange = false
        }
    }
    
    var eventTitle: String? {
        didSet {
            specialEventView?.eventTitle = eventTitle
            if eventTitle != oldValue && !initialLoad && specialEvent != nil {
                try! localPersistentStore.write {
                    localPersistentStore.delete(specialEvent!)
                    specialEvent = nil
                }
                needNewObject = true
            }
            if eventTitle != nil {
                titleProgressImageView?.tintColor = Colors.taskCompleteColor
            }
            else {titleProgressImageView?.tintColor = Colors.inactiveColor}
            checkFinishButtonEnable()
        }
    }
    var eventTagline: String? {
        didSet {
            specialEventView?.eventTagline = eventTagline
            checkFinishButtonEnable()
            if eventTagline != nil {
                taglineProgressImageView?.tintColor = Colors.taskCompleteColor
            }
            else {
                taglineProgressImageView?.tintColor = Colors.inactiveColor
                if editingEvent {specialEventView?.eventTagline = ""}
            }
        }
    }
    
    var eventDate: EventDate? {
        didSet {
            specialEventView?.eventDate = eventDate
            if editingEvent && isUserChange {
                let master = navigationController!.viewControllers[0] as! MasterViewController
                master.dateDidChange = true
            }
            if eventDate != nil {
                if eventDate!.dateOnly {longDateFormater.timeStyle = .none}
                else {longDateFormater.timeStyle = .short}
                dateLabel.text = longDateFormater.string(from: eventDate!.date)
                if !isUserChange {
                    eventDatePicker.datePickerMode = .date
                    eventDatePicker.date = eventDate!.date
                }
                dateProgressImageView?.tintColor = Colors.taskCompleteColor
            }
            else {isUserChange = false; dateProgressImageView?.tintColor = Colors.optionalTaskIncompleteColor}
            
            if eventDate != nil && oldValue == nil {
                eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                    DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
                }
            }
            else if eventDate == nil && oldValue != nil {
                eventTimer?.invalidate()
                eventTimer = nil
            }
            checkFinishButtonEnable()
            isUserChange = false
        }
    }
    
    var creationDate = Date() {didSet {specialEventView!.creationDate = creationDate}}
    
    var abridgedDisplayMode = false {didSet {specialEventView?.abridgedDisplayMode = abridgedDisplayMode}}
    
    var selectedImage: UserEventImage? {
        didSet {
            if let image = selectedImage {
                specialEventView?.setSelectedImage(image: image, locationForCellView: locationForCellView)
                imageTitleLabel.layer.add(labelTransition, forKey: nil)
                imageTitleLabel.textColor = Colors.orangeRegular
                imageProgressImageView?.tintColor = Colors.taskCompleteColor
                enableButton(editImageButton)
                enableButton(useImageButton)
                enableButton(useMaskButton)
                
                if let appImage = selectedImage as? AppEventImage {imageTitleLabel.text = "\"\(appImage.title)\""}
                else {imageTitleLabel.text = "Your moment!"}
                
                useImageButton.tintColor = UIColor.green
                if useMask {useMaskButton.tintColor = UIColor.green} else {useMaskButton.tintColor = Colors.inactiveColor}
                
                if !isUserChange {currentInputViewState = .none}
            }
            else {
                specialEventView?.clearEventImage()
                //if imagePlaceholderView == nil {addPlaceholderView()}
                imageTitleLabel.layer.add(labelTransition, forKey: nil)
                imageTitleLabel.text = noImageSelectedTextForTitle
                imageTitleLabel.textColor = Colors.inactiveColor
                imageProgressImageView?.tintColor = Colors.optionalTaskIncompleteColor
                disableButton(editImageButton)
                if previousSelectedImage == nil {disableButton(useImageButton)}
                disableButton(useMaskButton)
                useImageButton.tintColor = Colors.inactiveColor
                useMaskButton.tintColor = Colors.inactiveColor
            }
            isUserChange = false
            checkFinishButtonEnable()
        }
    }
    
    var locationForCellView: CGFloat?
    
    fileprivate var previousSelectedImage: UserEventImage?
    
    var useMask = true {
        didSet {
            specialEventView!.useMask = useMask
            if useMask {useMaskButton.tintColor = UIColor.green} else {useMaskButton.tintColor = Colors.inactiveColor}
        }
    }
    
    var cachedImages = [AppEventImage]() {
        didSet {selectImageController?.catalogImages.addImages(cachedImages)}
    }
    
    fileprivate let defaultImageTitle = "Desert Dunes"
    fileprivate let noImageSelectedTextForTitle = "Select an image"
    fileprivate var defaultEventDate: EventDate = {
        let eventDate = EventDate()
        
        let calendar = Calendar.current
        let today = Date()
        var dateComponents = DateComponents()
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 12
        dateComponents.day = calendar.component(.day, from: today) + 1
        dateComponents.month = calendar.component(.month, from: today)
        dateComponents.year = calendar.component(.year, from: today)
        let tomorrowAtNoon = calendar.date(from: dateComponents)!
        
        eventDate.date = tomorrowAtNoon
        eventDate.dateOnly = false
        return eventDate
    }()
    fileprivate var selectableCategories = [String]()
    fileprivate var productIDs = Set<Product>()
    fileprivate weak var selectImageController: SelectImageViewController?
    var editingEvent = false
    var isUserChange = false
    
    //
    // MARK: Calendar
    
    fileprivate let currentCalendar = Calendar.current
    fileprivate let calendarComponentsOfInterest: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    fileprivate let ymdCalendarComponents: Set<Calendar.Component> = [.year, .month, .day]
    fileprivate let hmsCalendarComponents: Set<Calendar.Component> = [.hour, .minute, .second]
    fileprivate let longDateFormater = DateFormatter()
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let timeFormatter = DateFormatter()
    fileprivate var eventTimer: Timer?
    
    //
    // MARK: Types
    
    fileprivate struct Product: Hashable {
        var hashValue: Int
        let id: String
        let includedRecords: [CKRecordID]
        
        init(id: String, includedRecords records: [CKRecordID]) {self.id = id; self.includedRecords = records; hashValue = id.hashValue}
        
        static func ==(lhs: NewEventViewController.Product, rhs: NewEventViewController.Product) -> Bool {
            if lhs.id == rhs.id {return true} else {return false}
        }
    }
    
    fileprivate enum CloudErrors: Error {
        case imageCreationFailure, assetCreationFailure, noRecords
    }
    enum NetworkStates: Equatable {
        static func ==(lhs: NetworkStates, rhs: NetworkStates) -> Bool {
            switch lhs {
            case .complete:
                switch rhs {
                case .complete: return true
                default: break
                }
            case .loading:
                switch rhs {
                case .loading: return true
                default: break
                }
            case .failed(_):
                switch rhs {
                case .failed(_): return true
                default: break
                }
            }
            return false
        }
        case loading, complete, failed(String?)
    }
    fileprivate var currentNetworkState = NetworkStates.loading {
        didSet{selectImageController?.networkState = currentNetworkState}
    }
    
    //
    // MARK: Persistence
    
    fileprivate var localPersistentStore: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    fileprivate let userDefaultsContainer = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: UI Elements
    fileprivate var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var specialEventViewContainer: UIView!
    fileprivate var specialEventView: EventTableViewCell?
    fileprivate var imagePlaceholderView: UIImageView?
    
    fileprivate var textInputAccessoryView: TextInputAccessoryView?
    
    @IBOutlet weak var categoryLabel: UILabel!
    let categoryWaveEffectView = WaveEffectView()
    @IBOutlet weak var imageTitleLabel: UILabel!
    
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var taglineButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    
    fileprivate var categoryProgressImageView: UIImageView?
    fileprivate var titleProgressImageView: UIImageView?
    fileprivate var dateProgressImageView: UIImageView?
    fileprivate var taglineProgressImageView: UIImageView?
    fileprivate var imageProgressImageView: UIImageView?
    fileprivate var finishProgressImageView: UIImageView?
    
    @IBOutlet weak var dataInputView: UIView!
    
    @IBOutlet weak var currentInputLabel: UILabel!
    @IBOutlet weak var inputHelpButton: UIButton!
    @IBOutlet weak var nextInputButton: UIButton!
    @IBOutlet weak var enterDataButton: UIButton!
    @IBOutlet weak var cancelDataButton: UIButton!
    
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var categoryInputView: UIView!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    
    @IBOutlet weak var dateInputView: UIView!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var imageInputView: UIView!
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var useImageButton: UIButton!
    @IBOutlet weak var useMaskButton: UIButton!
    
    
    //
    // Other
    
    fileprivate var productRequest: SKProductsRequest?
    fileprivate var imagesForPurchace = [CKRecordID]() {
        didSet {
            if let _ = presentedViewController as? SelectImageViewController {
                fetchCloudImages(records: imagesForPurchace, imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
            }
        }
    }
    
    let labelTransition = CATransition()

    fileprivate var currentInputViewState: Inputs = .none {
        didSet {
            if currentInputViewState != oldValue {
                
                switch oldValue {
                case .category:
                    if eventCategory == nil {viewTransition(from: categoryLabel, to: categoryWaveEffectView)}
                case .title:
                    if eventTitle == nil {viewTransition(from: specialEventView!.titleLabel, to: specialEventView!.titleWaveEffectView!)}
                case .tagline:
                    if eventTagline == nil {viewTransition(from: specialEventView!.taglineLabel, to: specialEventView!.taglineWaveEffectView!)}
                case .date:
                    if eventDate == nil {
                        if let timerView = specialEventView?.timerContainerView {
                            specialEventView!.viewTransition(from: [timerView], to: [specialEventView!.timerWaveEffectView!, specialEventView!.timerLabelsWaveEffectView!])
                        }
                        else if let abridgedTimerView = specialEventView?.abridgedTimerContainerView {
                            specialEventView!.viewTransition(from: [abridgedTimerView], to: [specialEventView!.timerWaveEffectView!, specialEventView!.timerLabelsWaveEffectView!])
                        }
                    }
                case .image:
                    if selectedImage == nil {
                        if imagePlaceholderView == nil {addPlaceholderView()}
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.30,
                            delay: 0.0,
                            options: .curveLinear,
                            animations: { [weak self] in
                                self?.specialEventView!.viewWithMargins.layer.backgroundColor = Colors.lightGrayForFills.cgColor
                                self?.imagePlaceholderView?.layer.opacity = 0.5
                            },
                            completion: nil
                        )
                    }
                    else {specialEventView!.viewWithMargins.layer.backgroundColor = Colors.lightGrayForFills.cgColor}
                case .none: break
                }
                
                switch currentInputViewState {
                case .category:
                    if !categoryWaveEffectView.isHidden && !ignoreWaveView {
                        viewTransition(from: categoryWaveEffectView, to: categoryLabel)
                    }
                    oldDataValue = eventCategory
                    ignoreWaveView = false
                case .title:
                    if let titleWaveView = specialEventView?.titleWaveEffectView, !ignoreWaveView {
                        if !titleWaveView.isHidden {
                            viewTransition(from: titleWaveView, to: specialEventView!.titleLabel)
                        }
                    }
                    oldDataValue = eventTitle
                    ignoreWaveView = false
                case .tagline:
                    if let taglineWaveView = specialEventView?.taglineWaveEffectView, !ignoreWaveView {
                        if !taglineWaveView.isHidden {
                            viewTransition(from: taglineWaveView, to: specialEventView!.taglineLabel)
                        }
                        else if specialEventView!.taglineLabel.isHidden {fadeIn(view: specialEventView!.taglineLabel)}
                    }
                    oldDataValue = eventTagline
                    ignoreWaveView = false
                case .date:
                    oldDataValue = eventDate
                    if eventDate == nil {eventDate = defaultEventDate}
                    if let timerWaveView = specialEventView?.timerWaveEffectView, !ignoreWaveView {
                        if let timerLabelsWaveView = specialEventView?.timerLabelsWaveEffectView {
                            if !timerLabelsWaveView.isHidden && !timerWaveView.isHidden {
                                if abridgedDisplayMode {
                                    specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [specialEventView!.abridgedTimerContainerView])
                                }
                                else {
                                    specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [specialEventView!.timerContainerView])
                                }
                            }
                        }
                    }
                    ignoreWaveView = false
                case .image:
                    if let image = selectedImage {
                        if let appImage = image as? AppEventImage {oldDataValue = appImage}
                        else {oldDataValue = image}
                        specialEventView!.viewWithMargins.layer.backgroundColor = UIColor.black.cgColor
                    }
                    else {
                        oldDataValue = nil
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.30,
                            delay: 0.0,
                            options: .curveLinear,
                            animations: { [weak self] in
                                self?.specialEventView!.viewWithMargins.layer.backgroundColor = UIColor.black.cgColor
                                self?.imagePlaceholderView?.layer.opacity = 0.0
                            },
                            completion: nil
                        )
                    }
                case .none: break
                }
                
                transitionInputView(fromState: oldValue, toState: currentInputViewState)
            }
        }
    }
    
    var oldDataValue: Any?
    
    //
    // MARK: Gesture recognizer stuff
    var panGestureLastXLocation: CGFloat = 0.0
    var panGestureLastDirection: CGFloat?
    var panComplete = false
    var touchBegan: TimeInterval = 0.0
    
    //
    // MARK: Flags
    var initialLoad = true
    var needNewObject = true
    fileprivate var ignoreWaveView = false
    
    override var canBecomeFirstResponder: Bool {return true}
    override var canResignFirstResponder: Bool {return true}
    override var inputAccessoryView: UIView? {return textInputAccessoryView}
    
    //
    // Static Types
    enum Inputs: Int {
        case category = 0
        case title
        case date
        case tagline
        case image
        case none
    }
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Finish view config
        if let inputAccessoryNib = Bundle.main.loadNibNamed("TextInputAccessoryView", owner: self, options: nil) {
            if let textInputView = inputAccessoryNib[0] as? TextInputAccessoryView {
                textInputAccessoryView = textInputView
                textInputAccessoryView!.textInputField.delegate = self
                textInputAccessoryView!.doneButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
                textInputAccessoryView!.isHidden = true
                textInputAccessoryView!.isUserInteractionEnabled = false
            }
        }
        if let specialEventNib = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let view = specialEventNib[0] as? EventTableViewCell {
                specialEventView = view
                specialEventView!.isUserInteractionEnabled = true
                specialEventView!.translatesAutoresizingMaskIntoConstraints = false
                specialEventViewContainer.addSubview(specialEventView!)
                specialEventViewContainer.topAnchor.constraint(equalTo: specialEventView!.topAnchor).isActive = true
                specialEventViewContainer.rightAnchor.constraint(equalTo: specialEventView!.rightAnchor).isActive = true
                specialEventViewContainer.bottomAnchor.constraint(equalTo: specialEventView!.bottomAnchor).isActive = true
                specialEventViewContainer.leftAnchor.constraint(equalTo: specialEventView!.leftAnchor).isActive = true
                specialEventView!.configuration = .newEventsController
                
                specialEventView!.viewWithMargins.layer.cornerRadius = 3.0
                specialEventView!.viewWithMargins.layer.masksToBounds = true
                specialEventView!.viewWithMargins.layer.backgroundColor = Colors.lightGrayForFills.cgColor
                
                let bottomAnchorConstraint = specialEventView!.constraints.first {$0.secondAnchor == specialEventView!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                specialEventView!.bottomAnchor.constraint(equalTo: specialEventView!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
                
                specialEventView!.eventTitle = eventTitle
                specialEventView!.eventTagline = eventTagline
                specialEventView!.eventDate = eventDate
                specialEventView!.useMask = useMask
                if let image = selectedImage {
                    specialEventView!.setSelectedImage(image: image, locationForCellView: locationForCellView)
                }
                else {specialEventView!.clearEventImage()}
            }
        }
        
        doneButton = UIBarButtonItem()
        doneButton.target = self
        doneButton.action = #selector(finish(_:))
        doneButton.tintColor = Colors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: Fonts.contentSecondaryFontName, size: 14.0)! as Any]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.setTitleTextAttributes(attributes, for: .disabled)
        
        navigationItem.rightBarButtonItem = doneButton
        if locationForCellView == nil {doneButton.isEnabled = false}
        else {doneButton.isEnabled = false}
        
        if editingEvent {
            navigationItem.title = "Edit Event"
            finishButton.setTitle("CONFIRM CHANGES", for: .normal)
            doneButton.title = "CONFIRM"
        }
        else {
            navigationItem.title = "New Event"
            finishButton.setTitle("CREATE EVENT", for: .normal)
            doneButton.title = "CREATE"
        }
        
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        if screenHeight >= 667.0 && screenWidth >= 375.0 {navigationItem.largeTitleDisplayMode = .always}
        
        labelTransition.duration = 0.3
        labelTransition.type = kCATransitionFade

        configureCategoryWaveEffectView()
        setupGestureRecognizers()
        configureInputView()
        configureOptionsView()
        
        if let categories = userDefaultsContainer?.value(forKey: "Categories") as? [String] {
            for category in categories {
                if category != "Favorites" || category != "Previous" || category != "Uncategorized" {selectableCategories.append(category)}
            }
        }
        else {
            // TODO: Error Handling
            fatalError("Unable to fetch categories from user defaults in NewEventViewController")
        }
        
        // Odds and ends
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryPickerView.reloadAllComponents()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        localPersistentStore = try! Realm(configuration: realmConfig)
        fetchLocalImages()
        
        if specialEvent != nil {
            needNewObject = false
            
            categoryWaveEffectView.isHidden = true
            categoryWaveEffectView.isUserInteractionEnabled = false
            categoryLabel.isHidden = false
            categoryLabel.isUserInteractionEnabled = true
            eventCategory = specialEvent!.category
            
            specialEventView!.titleWaveEffectView?.isHidden = true
            specialEventView!.titleWaveEffectView?.isUserInteractionEnabled = false
            specialEventView!.titleLabel.isHidden = false
            specialEventView!.titleLabel.isUserInteractionEnabled = true
            eventTitle = specialEvent!.title
            
            specialEventView!.taglineWaveEffectView?.isHidden = true
            specialEventView!.taglineWaveEffectView?.isUserInteractionEnabled = false
            specialEventView!.taglineLabel.isHidden = false
            specialEventView!.taglineLabel.isUserInteractionEnabled = true
            if let tagline = specialEvent!.tagline {eventTagline = tagline}
            
            specialEventView!.timerWaveEffectView?.isHidden = true
            specialEventView!.timerWaveEffectView?.isUserInteractionEnabled = false
            specialEventView!.timerLabelsWaveEffectView?.isHidden = true
            specialEventView!.timerLabelsWaveEffectView?.isUserInteractionEnabled = false
            eventDate = EventDate(date: specialEvent!.date!.date, dateOnly: specialEvent!.date!.dateOnly)
            creationDate = specialEvent!.creationDate
            abridgedDisplayMode = specialEvent!.abridgedDisplayMode
            useMask = specialEvent!.useMask
            
            if let intLocationForCellView = specialEvent!.locationForCellView.value {
                locationForCellView = CGFloat(intLocationForCellView) / 100.0
            }
            
            if let imageInfo = specialEvent!.image {
                if imageInfo.isAppImage {selectedImage = AppEventImage(fromEventImageInfo: imageInfo)}
                else {selectedImage = UserEventImage(fromEventImageInfo: imageInfo)}
            }
            
            
            specialEventView!.update()
        }
        else {
            specialEventView!.creationDate = creationDate
            addPlaceholderView()
            imagePlaceholderView!.layer.opacity = 0.5
        }
        
        fetchProductIDs(fetchFailHandler: networkErrorHandler)
    }
    
    fileprivate func addPlaceholderView() {
        let imagePlaceholderImage = UIImage(named: "ImagePlaceholderImage")!
        let templateImage = imagePlaceholderImage.withRenderingMode(.alwaysTemplate)
        imagePlaceholderView = UIImageView(image: templateImage)
        imagePlaceholderView!.tintColor = UIColor.darkGray
        imagePlaceholderView!.layer.opacity = 0.0
        imagePlaceholderView!.translatesAutoresizingMaskIntoConstraints = false
        specialEventView!.addSubview(imagePlaceholderView!)
        specialEventView!.centerXAnchor.constraint(equalTo: imagePlaceholderView!.centerXAnchor, constant: -(1/3) * (specialEventViewContainer.bounds.width / 2)).isActive = true
        specialEventView!.centerYAnchor.constraint(equalTo: imagePlaceholderView!.centerYAnchor, constant: (1/3) * (specialEventViewContainer.bounds.height / 2)).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if eventDate != nil && eventTimer == nil {
            specialEventView?.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if initialLoad {
            categoryWaveEffectView.animate {}
            specialEventView!.titleWaveEffectView!.animate {}
            specialEventView!.taglineWaveEffectView!.animate {}
            specialEventView!.timerWaveEffectView!.animate {}
            specialEventView!.timerLabelsWaveEffectView!.animate {}
            initialLoad = false
        }
    }
    
    @objc fileprivate func applicationDidBecomeActive(notification: NSNotification) {
        if eventDate != nil && eventTimer == nil {
            specialEventView?.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
            }
        }
    }

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    override func viewWillDisappear(_ animated: Bool) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    @objc fileprivate func applicationWillResignActive(notification: NSNotification) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    deinit {
        eventTimer?.invalidate()
        eventTimer = nil
        productRequest?.cancel()
        productRequest?.delegate = nil
        
        let backgroundThread = DispatchQueue(label: "background", qos: .background, target: nil)
        backgroundThread.async {
            let realm = try! Realm(configuration: realmConfig)
            let allImages = realm.objects(EventImageInfo.self)
            for imageInfo in allImages {
                if imageInfo.specialEvents.isEmpty && imageInfo.isAppImage == false {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileName = imageInfo.title.convertToFileName()
                    let saveDest = documentsURL.appendingPathComponent(fileName + ".jpg", isDirectory: false)
                    do {
                        try FileManager.default.removeItem(at: saveDest)
                        try realm.write {realm.delete(imageInfo)}
                    }
                    catch {
                        // TODO: Error Handling
                        print(error.localizedDescription)
                        fatalError()
                    }
                }
            }
        }
    }
    
    
    //
    // MARK: - Delegate Methods
    //
    
    //
    // MARK: Store Kit Delegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if request == productRequest! {
            for id in response.invalidProductIdentifiers {
                for productID in productIDs {
                    if productID.id == id {productIDs.remove(productID); break}
                }
            }
            var recordsToFetch = [CKRecordID]()
            for product in productIDs {
                for record in product.includedRecords {
                    if !recordsToFetch.contains(record) {recordsToFetch.append(record)}
                }
            }
            for (i, record) in recordsToFetch.enumerated() {
                if cachedImages.contains(where: {$0.recordName == record.recordName}) {recordsToFetch.remove(at: i)}
            }
            fetchCloudImages(records: recordsToFetch, imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
        }
    }
    
    //
    // Date Picker
    
    @IBAction func datePickerDateDidChange(_ sender: UIDatePicker) {
        isUserChange = true
        var currentDateComponents: DateComponents!
        currentDateComponents = currentCalendar.dateComponents(calendarComponentsOfInterest, from: eventDate!.date)
        switch eventDatePicker.datePickerMode {
        case .date:
            let ymdDateComponents = currentCalendar.dateComponents(ymdCalendarComponents, from: eventDatePicker.date)
            currentDateComponents.year = ymdDateComponents.year!
            currentDateComponents.month = ymdDateComponents.month!
            currentDateComponents.day = ymdDateComponents.day!
        case .time:
            let hmsDateComponents = currentCalendar.dateComponents(hmsCalendarComponents, from: eventDatePicker.date)
            currentDateComponents.hour = hmsDateComponents.hour!
            currentDateComponents.minute = hmsDateComponents.minute!
            currentDateComponents.second = hmsDateComponents.second!
        default:
            // TODO: Error Handling
            os_log("DatePicker in NewEventController somehow got in an undefined mode.", log: OSLog.default, type: .error)
            fatalError()
        }
        eventDate = EventDate(date: currentCalendar.date(from: currentDateComponents)!, dateOnly: eventDate!.dateOnly)
    }
    
    //
    // Picker View
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        isUserChange = true
        eventCategory = selectableCategories[row]
    }
    
    //
    // Text Field
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if currentInputViewState == .title {
            specialEventView?.titleLabel.textColor = UIColor.white
            
            if string.isEmpty {
                if eventTitle != nil {
                    var stringRange: Range<String.Index>!
                    if range.location + range.length > eventTitle!.count {
                        stringRange = eventTitle!.index(eventTitle!.endIndex, insetBy: range.length)..<eventTitle!.endIndex
                    }
                    else {
                        stringRange = eventTitle!.index(eventTitle!.startIndex, offsetBy: range.location)..<eventTitle!.index(eventTitle!.startIndex, offsetBy: range.location + range.length)
                    }
                    eventTitle!.removeSubrange(stringRange)
                    if eventTitle!.isEmpty {eventTitle = nil}
                }
            }
            else {
                if eventTitle != nil {
                    eventTitle = textInputAccessoryView!.textInputField.text
                    if range.location > eventTitle!.count {eventTitle!.append(string)}
                    else {
                        eventTitle!.insert(contentsOf: string, at: eventTitle!.index(eventTitle!.startIndex, offsetBy: range.location))
                    }
                }
                else {eventTitle = string}
            }
        }
        else if currentInputViewState == .tagline {
            if string.isEmpty {
                if eventTagline != nil {
                    var stringRange: Range<String.Index>!
                    if range.location + range.length > eventTagline!.count {
                        stringRange = eventTagline!.index(eventTagline!.endIndex, insetBy: range.length)..<eventTagline!.endIndex
                    }
                    else {
                        stringRange = eventTagline!.index(eventTagline!.startIndex, offsetBy: range.location)..<eventTagline!.index(eventTagline!.startIndex, offsetBy: range.location + range.length)
                    }
                    eventTagline!.removeSubrange(stringRange)
                    if eventTagline!.isEmpty {eventTagline = nil}
                }
            }
            else {
                if eventTagline != nil {
                    eventTagline = textInputAccessoryView!.textInputField.text
                    if range.location > eventTagline!.count {eventTagline!.append(string)}
                    else {
                        eventTagline!.insert(contentsOf: string, at: eventTagline!.index(eventTagline!.startIndex, offsetBy: range.location))
                    }
                }
                else {eventTagline = string}
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if currentInputViewState == .title {eventTitle = nil}
        else if currentInputViewState == .tagline {eventTagline = nil}
        return true
    }
    
    //
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touchBegan = touch.timestamp; return true
    }
    
    //
    // MARK: CAAnimationDelegate
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let fadeOut = anim as? CABasicAnimation, let endValue = fadeOut.toValue as? Double {
            if fadeOut.keyPath == "opacity" && endValue == 0.0 {
                view.isHidden = true
                view.isUserInteractionEnabled = false
            }
        }
    }
    
    //
    // MARK: From storyboard actions
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
        if let sender = segue.source as? ImagePreviewViewController {
            locationForCellView = sender.locationForCellView
            selectedImage = sender.selectedImage
        }
    }
    
    
    //
    // MARK: - Data Source Methods
    //
    
    //
    // Picker View
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectableCategories.count
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let stringToReturn = selectableCategories[row]
        return NSAttributedString(string: stringToReturn, attributes: [NSAttributedStringKey.foregroundColor: Colors.orangeRegular])
    }
    
    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let ident = segue.identifier {
            let cancelButton = UIBarButtonItem()
            cancelButton.tintColor = Colors.orangeDark
            let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: Fonts.contentSecondaryFontName, size: 14.0)! as Any]
            cancelButton.setTitleTextAttributes(attributes, for: .normal)
            cancelButton.title = "CANCEL"
            navigationItem.backBarButtonItem = cancelButton
            switch ident {
            case "EditImageSegue":
                let destination = segue.destination as! ImagePreviewViewController
                destination.selectedImage = selectedImage
                destination.locationForCellView = locationForCellView
            case "Choose Image":
                let destination = segue.destination as! SelectImageViewController
                destination.selectedImage = selectedImage
                destination.locationForCellView = locationForCellView
                destination.catalogImages.addImages(cachedImages)
                destination.networkState = currentNetworkState
                selectImageController = destination
            default:
                // TODO: Error Handling
                print("Unhandled Segue: \(ident)")
                fatalError()
            }
        }
    }

    
    //
    // MARK: - Target-Action Methods
    //
    
    @objc fileprivate func handleTapsInCell(_ sender: UIGestureRecognizer) -> Void {
        
        if sender.view! == specialEventView {
            if specialEventView!.titleLabel.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .title
            }
            else if specialEventView!.taglineLabel.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .tagline
            }
            else if specialEventView!.timerContainerView.frame.contains(sender.location(in: specialEventView!)) || specialEventView!.abridgedTimerContainerView.frame.contains(sender.location(in: specialEventView!)) {
                if currentInputViewState == .date {abridgedDisplayMode = !abridgedDisplayMode}
                else {currentInputViewState = .date}
            }
            else if specialEventView!.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .image
            }
        }
        else if sender.view! == categoryWaveEffectView {currentInputViewState = .category}
        else if sender.view! == categoryLabel {currentInputViewState = .category}
    }
    
    @objc fileprivate func finish(_ sender: UIButton) {
        
        guard eventTitle != nil && eventDate != nil else {
            // TODO: Throw an alert to user that title and event date are requrired.
            let alert = UIAlertController(title: "Missing Information", message: "Please populate the event title and date.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Okay", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if needNewObject {
            let titlePredicate = NSPredicate(format: "title = %@", argumentArray: [eventTitle!])
            let existingEvent = localPersistentStore.objects(SpecialEvent.self).filter(titlePredicate)
            guard existingEvent.isEmpty else {
                let alert = UIAlertController(title: "Event Already Exists", message: "An event with this title already exists. Did you want to replace that event with this one?", preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes please!", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                    self.createNewObject(overwrite: true)
                    self.navigationController!.navigationController!.popViewController(animated: true)
                }
                let noAction = UIAlertAction(title: "No, Thanks.", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                    self.currentInputViewState = .title
                }
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            createNewObject(overwrite: false)
        }
        else {
            try! localPersistentStore.write {
                specialEvent!.category = eventCategory ?? "Uncatagorized"
                specialEvent!.tagline = eventTagline
                specialEvent!.date = eventDate!
                specialEvent!.abridgedDisplayMode = abridgedDisplayMode
                specialEvent!.useMask = useMask
                if let _selectedImage = selectedImage {
                    if specialEvent?.image == nil || specialEvent!.image!.title != _selectedImage.title {
                        let image = getEventImageInfo()
                        specialEvent!.image = image
                        // TODO: Consider deleting old EventImageInfo, or adding support in settings to purge this.
                    }
                }
                else {
                    specialEvent!.image = nil
                    // TODO: Consider deleting old EventImageInfo, or adding support in settings to purge this.
                }
                if let _locationForCellView = locationForCellView {
                    specialEvent!.locationForCellView.value = Int(_locationForCellView * 100.0)
                }
            }
        }
        
        navigationController!.popViewController(animated: true)
    }
    
    @objc fileprivate func handleInputToolbarButtonTap(_ sender: UIButton) {
        if sender == nextInputButton {
            if eventCategory == nil {
                if !categoryWaveEffectView.isHidden {
                    categoryWaveEffectView.animate {[weak self] in self?.viewTransition(from: self!.categoryWaveEffectView, to: self!.categoryLabel)}
                    ignoreWaveView = true
                }
                currentInputViewState = .category
            }
            else if eventTitle == nil {
                if let titleWaveView = specialEventView?.titleWaveEffectView {
                    if !titleWaveView.isHidden {
                        titleWaveView.animate {[weak self] in self?.viewTransition(from: titleWaveView, to: self!.specialEventView!.titleLabel)}
                    }
                    ignoreWaveView = true
                }
                currentInputViewState = .title
            }
            else if eventDate == nil {
                if let timerWaveView = specialEventView?.timerWaveEffectView {
                    if let timerLabelsWaveView = specialEventView?.timerLabelsWaveEffectView {
                        if !timerWaveView.isHidden && !timerLabelsWaveView.isHidden {
                            timerWaveView.animate {}
                            timerLabelsWaveView.animate {[weak self] in
                                if self!.abridgedDisplayMode {
                                    self?.specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [self!.specialEventView!.abridgedTimerContainerView])
                                }
                                else {
                                    self?.specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [self!.specialEventView!.timerContainerView])
                                }
                            }
                        }
                        ignoreWaveView = true
                    }
                }
                currentInputViewState = .date
            }
            else if eventTagline == nil {
                if let taglineWaveView = specialEventView?.taglineWaveEffectView {
                    if !taglineWaveView.isHidden {
                        taglineWaveView.animate {[weak self] in self?.viewTransition(from: taglineWaveView, to: self!.specialEventView!.taglineLabel)}
                    }
                    ignoreWaveView = true
                }
                currentInputViewState = .tagline
            }
            else if selectedImage == nil {currentInputViewState = .image}
            else {currentInputViewState = .none}
        }
        else if sender == enterDataButton {currentInputViewState = .none}
        else if sender == cancelDataButton {
            switch currentInputViewState {
            case .category:
                if let oldCategory = oldDataValue as? String {
                    if oldCategory != eventCategory {eventCategory = oldCategory}
                }
            case .title:
                if let oldTitle = oldDataValue as? String {
                    if oldTitle != eventTitle {eventTitle = oldTitle}
                }
            case .tagline:
                if let oldTagline = oldDataValue as? String {
                    if oldTagline != eventTagline {eventTagline = oldTagline}
                }
            case .date:
                if let oldDate = oldDataValue as? EventDate {
                    if oldDate != eventDate {eventDate = EventDate(date: oldDate.date, dateOnly: oldDate.dateOnly)}
                }
                else {eventDate = nil}
            case .image:
                if let appImage = oldDataValue as? AppEventImage {selectedImage = appImage}
                else if let userImage = oldDataValue as? UserEventImage {selectedImage = userImage}
                else {selectedImage = nil}
            case .none: break
            }
            currentInputViewState = .none
        }
        else if sender == inputHelpButton {
            
        }
    }
    
    @objc fileprivate func handleDatePickerSingleTap(_ sender: UIGestureRecognizer) {
        if let tapGesture = sender as? UITapGestureRecognizer {
            switch tapGesture.state {
            case .ended:
                let timeIntervalSinceSystemStart = ProcessInfo.processInfo.systemUptime
                if timeIntervalSinceSystemStart - touchBegan < 0.3 {
                    switch eventDatePicker.datePickerMode {
                    case .date:
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveLinear,
                            animations: {[weak self] in self!.eventDatePicker.layer.opacity = 0.0},
                            completion: { [weak self] (position) in
                                self!.eventDatePicker.datePickerMode = .time
                                if self!.eventDate!.dateOnly {
                                    var components = DateComponents()
                                    components.year = self!.currentCalendar.component(.year, from: self!.eventDate!.date)
                                    components.month = self!.currentCalendar.component(.month, from: self!.eventDate!.date)
                                    components.day = self!.currentCalendar.component(.day, from: self!.eventDate!.date)
                                    components.hour = 12
                                    components.minute = 0
                                    components.second = 0
                                    self!.eventDate = EventDate(date: self!.currentCalendar.date(from: components)!, dateOnly: false)
                                    self!.eventDatePicker.date = self!.eventDate!.date
                                    self!.abridgedDisplayMode = false
                                }
                                else {self!.eventDatePicker.date = self!.eventDate!.date}
                                UIViewPropertyAnimator.runningPropertyAnimator(
                                    withDuration: 0.15,
                                    delay: 0.0,
                                    options: .curveLinear,
                                    animations: {[weak self] in self!.eventDatePicker.layer.opacity = 1.0},
                                    completion: nil
                                )
                            }
                        )
                    case .time:
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveLinear,
                            animations: {[weak self] in self!.eventDatePicker.layer.opacity = 0.0},
                            completion: { [weak self] (position) in
                                self!.eventDatePicker.datePickerMode = .date
                                self!.eventDatePicker.date = self!.eventDate!.date
                                UIViewPropertyAnimator.runningPropertyAnimator(
                                    withDuration: 0.15,
                                    delay: 0.0,
                                    options: .curveLinear,
                                    animations: {[weak self] in self!.eventDatePicker.layer.opacity = 1.0},
                                    completion: nil
                                )
                            }
                        )
                    default: // Should never happen
                        os_log("WARNING: Date picker somehow got into an undefined state, noted during handleDatePickerButtonTap", log: .default, type: .error)
                        eventDatePicker.datePickerMode = .date
                        eventDatePicker.date = eventDate!.date
                    }
                    if eventDate!.dateOnly == true {eventDate = EventDate(date: eventDate!.date, dateOnly: false)}
                }
            default: break
            }
        }
    }
    
    @objc fileprivate func dismissKeyboard() {
        switch currentInputViewState {
        case .title:
            if eventTitle == nil {viewTransition(from: specialEventView!.titleLabel, to: specialEventView!.titleWaveEffectView!)}
        case .tagline:
            if eventTagline == nil {viewTransition(from: specialEventView!.taglineLabel, to: specialEventView!.taglineWaveEffectView!)}
        default: break
        }
        textInputAccessoryView?.textInputField.resignFirstResponder()
        textInputAccessoryView?.isHidden = true
        textInputAccessoryView?.textInputField.text = nil
        currentInputViewState = .none
    }
    
    @objc fileprivate func handleOptionsButtonTap(_ sender: UIButton) {
        switch sender.title(for: .selected) {
        case "CATEGORY":
            if !categoryWaveEffectView.isHidden {
                categoryWaveEffectView.animate {[weak self] in self?.viewTransition(from: self!.categoryWaveEffectView, to: self!.categoryLabel)}
                ignoreWaveView = true
            }
            currentInputViewState = .category
        case "TITLE":
            if let titleWaveView = specialEventView?.titleWaveEffectView {
                if !titleWaveView.isHidden {
                    titleWaveView.animate {[weak self] in self?.viewTransition(from: titleWaveView, to: self!.specialEventView!.titleLabel)}
                }
                ignoreWaveView = true
            }
            currentInputViewState = .title
        case "TAGLINE":
            if let taglineWaveView = specialEventView?.taglineWaveEffectView {
                if !taglineWaveView.isHidden {
                    taglineWaveView.animate {[weak self] in self?.viewTransition(from: taglineWaveView, to: self!.specialEventView!.taglineLabel)}
                }
                ignoreWaveView = true
            }
            currentInputViewState = .tagline
        case "DATE":
            if let timerWaveView = specialEventView?.timerWaveEffectView {
                if let timerLabelsWaveView = specialEventView?.timerLabelsWaveEffectView {
                    if !timerWaveView.isHidden && !timerLabelsWaveView.isHidden {
                        timerWaveView.animate {}
                        timerLabelsWaveView.animate {[weak self] in
                            if self!.abridgedDisplayMode {
                                self?.specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [self!.specialEventView!.abridgedTimerContainerView])
                            }
                            else {
                                self?.specialEventView!.viewTransition(from: [timerWaveView, timerLabelsWaveView], to: [self!.specialEventView!.timerContainerView])
                            }
                        }
                    }
                    ignoreWaveView = true
                }
            }
            currentInputViewState = .date
        case "IMAGE": currentInputViewState = .image
        default: fatalError()
        }
    }
    
    @objc fileprivate func handleDatePan(_ sender: UIGestureRecognizer) {
        if let panGesture = sender as? UIPanGestureRecognizer {
            switch panGesture.state {
            case .began: panGestureLastXLocation = panGesture.location(in: nil).x
            case .changed:
                if !panComplete {
                    if let lastDirection = panGestureLastDirection {
                        panGestureLastDirection = panGestureLastXLocation - panGesture.location(in: nil).x
                        if panGestureLastDirection! * lastDirection < 0 {
                            panComplete = true
                            panGestureLastXLocation = 0.0
                            panGestureLastDirection = nil
                        }
                        if panGestureLastDirection == 0.0 {panGestureLastDirection = lastDirection}
                    }
                    else {panGestureLastDirection = panGestureLastXLocation - panGesture.location(in: nil).x}
                    panGestureLastXLocation = panGesture.location(in: nil).x
                }
            case .ended:
                if panComplete {
                    isUserChange = true
                    var components = currentCalendar.dateComponents(calendarComponentsOfInterest, from: eventDate!.date)
                    components.hour = 0; components.minute = 0; components.second = 0
                    eventDate = EventDate(date: currentCalendar.date(from: components)!, dateOnly: true)
                    abridgedDisplayMode = true
                    if eventDatePicker.datePickerMode != .date {eventDatePicker.datePickerMode = .date}
                    panComplete = false
                }
                panGestureLastXLocation = 0.0
                panGestureLastDirection = nil
            default: break
            }
        }
    }
    
    @objc fileprivate func cancel() {self.dismiss(animated: true, completion: nil)}

    
    //
    // MARK: - Helper Functions
    //
    
    //
    // MARK: Initialization helpers
    
    fileprivate func setupGestureRecognizers() -> Void {
        
        let specialEventViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
        let categoryLabelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
        let categoryWaveEffectViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
        let singleTapDatePickerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDatePickerSingleTap(_:)))
        singleTapDatePickerTapGestureRecognizer.delegate = self
        let datePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDatePan(_:)))
        datePanGestureRecognizer.minimumNumberOfTouches = 1
        datePanGestureRecognizer.maximumNumberOfTouches = 1
        
        specialEventView?.addGestureRecognizer(specialEventViewTapGestureRecognizer)
        categoryLabel.addGestureRecognizer(categoryLabelTapGestureRecognizer)
        categoryWaveEffectView.addGestureRecognizer(categoryWaveEffectViewTapGestureRecognizer)
        eventDatePicker.addGestureRecognizer(singleTapDatePickerTapGestureRecognizer)
        dateLabel.addGestureRecognizer(datePanGestureRecognizer)
    }
    
    @objc fileprivate func handleImageOptionsButtonsTap(_ sender: UIButton) {
        switch sender.titleLabel!.text! {
        case "PREVIEW/EDIT IMAGES":
            performSegue(withIdentifier: "EditImageSegue", sender: self)
        case "TOGGLE IMAGE":
            isUserChange = true
            if let image = selectedImage {previousSelectedImage = image; selectedImage = nil; sender.tintColor = Colors.inactiveColor}
            else {selectedImage = previousSelectedImage; sender.tintColor = UIColor.green}
        case "TOGGLE MASK": useMask = !useMask
        default:
            // TODO: Error Handling, should never happen.
            fatalError("Fatal Error: Encountered and unknown image options button title")
        }
    }
    
    fileprivate func configureOptionsView() {
        
        categoryButton.addTarget(self, action: #selector(handleOptionsButtonTap(_:)), for: .touchUpInside)
        titleButton.addTarget(self, action: #selector(handleOptionsButtonTap(_:)), for: .touchUpInside)
        taglineButton.addTarget(self, action: #selector(handleOptionsButtonTap(_:)), for: .touchUpInside)
        dateButton.addTarget(self, action: #selector(handleOptionsButtonTap(_:)), for: .touchUpInside)
        imageButton.addTarget(self, action: #selector(handleOptionsButtonTap(_:)), for: .touchUpInside)
        
        configureButton(finishButton)
        
        let progressImage = #imageLiteral(resourceName: "InputProgressImage")
        let finishButtonProgressImage = #imageLiteral(resourceName: "FinishButtonProgressImage")
        let spacing: CGFloat = 15.0
        
        categoryProgressImageView = UIImageView(image: progressImage)
        categoryProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        categoryProgressImageView!.tintColor = Colors.inactiveColor
        optionsView.addSubview(categoryProgressImageView!)
        categoryButton.centerYAnchor.constraint(equalTo: categoryProgressImageView!.centerYAnchor).isActive = true
        categoryButton.leftAnchor.constraint(equalTo: categoryProgressImageView!.rightAnchor, constant: spacing).isActive = true
        
        titleProgressImageView = UIImageView(image: progressImage)
        titleProgressImageView!.tintColor = Colors.inactiveColor
        titleProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        optionsView.addSubview(titleProgressImageView!)
        titleButton.centerYAnchor.constraint(equalTo: titleProgressImageView!.centerYAnchor).isActive = true
        titleButton.leftAnchor.constraint(equalTo: titleProgressImageView!.rightAnchor, constant: spacing).isActive = true
        
        dateProgressImageView = UIImageView(image: progressImage)
        dateProgressImageView!.tintColor = Colors.inactiveColor
        dateProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        optionsView.addSubview(dateProgressImageView!)
        dateButton.centerYAnchor.constraint(equalTo: dateProgressImageView!.centerYAnchor).isActive = true
        dateButton.leftAnchor.constraint(equalTo: dateProgressImageView!.rightAnchor, constant: spacing).isActive = true
        
        taglineProgressImageView = UIImageView(image: progressImage)
        taglineProgressImageView!.tintColor = Colors.optionalTaskIncompleteColor
        taglineProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        optionsView.addSubview(taglineProgressImageView!)
        taglineButton.centerYAnchor.constraint(equalTo: taglineProgressImageView!.centerYAnchor).isActive = true
        taglineButton.leftAnchor.constraint(equalTo: taglineProgressImageView!.rightAnchor, constant: spacing).isActive = true
        
        imageProgressImageView = UIImageView(image: progressImage)
        imageProgressImageView!.tintColor = Colors.optionalTaskIncompleteColor
        imageProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        optionsView.addSubview(imageProgressImageView!)
        imageButton.centerYAnchor.constraint(equalTo: imageProgressImageView!.centerYAnchor).isActive = true
        imageButton.leftAnchor.constraint(equalTo: imageProgressImageView!.rightAnchor, constant: spacing).isActive = true
        
        finishProgressImageView = UIImageView(image: finishButtonProgressImage)
        finishProgressImageView!.tintColor = Colors.inactiveColor
        finishProgressImageView!.translatesAutoresizingMaskIntoConstraints = false
        optionsView.addSubview(finishProgressImageView!)
        finishButton.centerYAnchor.constraint(equalTo: finishProgressImageView!.centerYAnchor).isActive = true
        finishButton.leftAnchor.constraint(equalTo: finishProgressImageView!.rightAnchor, constant: spacing).isActive = true
    }
    
    fileprivate func configureInputView() -> Void {
    
        nextInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        enterDataButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        cancelDataButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        
        inputHelpButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        finishButton.addTarget(self, action: #selector(finish(_:)), for: .touchUpInside)
        
        configureButton(selectImageButton)
        
        editImageButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
        useImageButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
        useMaskButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
        
        disableButton(editImageButton)
        disableButton(useImageButton)
        disableButton(useMaskButton)
        
        eventDatePicker.backgroundColor = UIColor.clear
        eventDatePicker.isOpaque = false
        eventDatePicker.setValue(Colors.orangeRegular, forKey: "textColor")
        
        longDateFormater.dateStyle = .full
        longDateFormater.timeStyle = .short
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }
    
    fileprivate func configureCategoryWaveEffectView() {
        categoryWaveEffectView.translatesAutoresizingMaskIntoConstraints = false
        categoryWaveEffectView.isUserInteractionEnabled = true
        view.addSubview(categoryWaveEffectView)
        categoryWaveEffectView.topAnchor.constraint(equalTo: categoryLabel.topAnchor, constant: 8.0).isActive = true
        categoryWaveEffectView.leftAnchor.constraint(equalTo: categoryLabel.leftAnchor).isActive = true
        categoryWaveEffectView.rightAnchor.constraint(equalTo: categoryLabel.rightAnchor).isActive = true
        categoryWaveEffectView.bottomAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: -8.0).isActive = true
        if eventCategory != nil {
            categoryWaveEffectView.isHidden = true
            categoryWaveEffectView.isUserInteractionEnabled = false
        }
    }
    
    fileprivate func configureButton(_ button: UIButton) {
        button.layer.borderWidth = 1.0
        button.layer.borderColor = Colors.orangeDark.cgColor
        button.layer.cornerRadius = 3.0
    }
    
    //
    // MARK: Animation helpers
    
    fileprivate func viewTransition(from view1: UIView, to view2: UIView) {
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.5
        
        view1.layer.add(transition, forKey: "transition")
        view2.layer.add(transition, forKey: "transition")
        
        view1.isHidden = true
        view1.isUserInteractionEnabled = false
        view2.isHidden = false
        view2.isUserInteractionEnabled = true
    }
    
    fileprivate func transitionInputView(fromState state1: Inputs, toState state2: Inputs) {
        let duration = 0.15
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: duration,
            delay: 0.0,
            options: [.curveLinear],
            animations: { [weak self] in
                self!.dataInputView.layer.opacity = 0.0
                self!.currentInputLabel.layer.opacity = 0.0
                self!.inputHelpButton.layer.opacity = 0.0
            },
            completion: { [weak self] (position) in
                if self != nil {
                    if state2 == .none {
                        self!.cancelDataButton.layer.add(self!.labelTransition, forKey: nil)
                        self!.enterDataButton.layer.add(self!.labelTransition, forKey: nil)
                        self!.cancelDataButton.isEnabled = false
                        self!.enterDataButton.isEnabled = false
                    }
                    self!.dataInputView.isUserInteractionEnabled = false
                    switch state1 {
                    case .category:
                        self!.categoryInputView.isHidden = true
                        self!.categoryInputView.isUserInteractionEnabled = false
                    case .date:
                        self!.dateInputView.isHidden = true
                        self!.dateInputView.isUserInteractionEnabled = false
                    case .image:
                        self!.imageInputView.isHidden = true
                        self!.imageInputView.isUserInteractionEnabled = false
                    case .title, .tagline:
                        if self!.textInputAccessoryView?.textInputField.isFirstResponder ?? false {
                            self!.textInputAccessoryView!.textInputField.resignFirstResponder()
                            self!.textInputAccessoryView!.isHidden = true
                            self!.textInputAccessoryView!.textInputField.text = nil
                        }
                    case .none:
                        self!.optionsView.isHidden = true
                        self!.optionsView.isUserInteractionEnabled = false
                    }
                    
                    switch state2 {
                    case .category:
                        self!.currentInputLabel.text = "Category"
                        if self!.eventCategory != nil {self!.categoryPickerView.selectRow(self!.selectableCategories.index(of: self!.eventCategory!) ?? 0, inComponent: 0, animated: false)}
                        self!.categoryInputView.isHidden = false
                        self!.categoryInputView.isUserInteractionEnabled = true
                    case .date:
                        self!.currentInputLabel.text = "Date"
                        self!.dateInputView.isHidden = false
                        self!.dateInputView.isUserInteractionEnabled = true
                    case .image:
                        self!.currentInputLabel.text = "Image"
                        self!.imageInputView.isHidden = false
                        self!.imageInputView.isUserInteractionEnabled = true
                    case .title, .tagline:
                        if state2 == .title {
                            self!.currentInputLabel.text = "Title"
                            self!.textInputAccessoryView!.textInputField.autocapitalizationType = .words
                        }
                        else {
                            self!.currentInputLabel.text = "Tagline"
                            self!.textInputAccessoryView!.textInputField.autocapitalizationType = .sentences
                        }
                        self!.textInputAccessoryView?.textInputField.becomeFirstResponder()
                        if self!.currentInputViewState == .title {self!.textInputAccessoryView?.textInputField.text = self!.eventTitle}
                        else if self!.currentInputViewState == .tagline {self!.textInputAccessoryView?.textInputField.text = self!.eventTagline}
                        if self!.textInputAccessoryView != nil {
                            if self!.textInputAccessoryView!.isHidden {
                                self!.textInputAccessoryView!.isHidden = false
                                self!.textInputAccessoryView!.isUserInteractionEnabled = true
                            }
                        }
                    case .none:
                        self!.currentInputLabel.text = "Select Option"
                        self!.optionsView.isHidden = false
                        self!.optionsView.isUserInteractionEnabled = true
                    }
                }
                
                self!.dataInputView.isHidden = false
                self!.dataInputView.isUserInteractionEnabled = true
                
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: duration,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: { [weak self] in
                        self!.dataInputView.layer.opacity = 1.0
                        self!.currentInputLabel.layer.opacity = 1.0
                        self!.inputHelpButton.layer.opacity = 1.0
                    },
                    completion: { [weak self] (position) in
                        if state2 != .none {
                            self!.cancelDataButton.layer.add(self!.labelTransition, forKey: nil)
                            self!.enterDataButton.layer.add(self!.labelTransition, forKey: nil)
                            self!.cancelDataButton.isEnabled = true
                            self!.enterDataButton.isEnabled = true
                        }
                    }
                )
            }
        )
    }
    
    fileprivate func fadeIn(view: UIView) {
        view.isHidden = false
        view.isUserInteractionEnabled = true
        
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.3,
            delay: 0.0,
            options: [.curveLinear],
            animations: {view.layer.opacity = 1.0},
            completion: nil
        )
    }
    
    fileprivate func fadeOut(view: UIView) {
        let duration = 0.3
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: duration,
            delay: 0.0,
            options: [.curveLinear],
            animations: {view.layer.opacity = 0.0},
            completion: {(position) in
                switch position {
                case .end:
                    Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                        view.isHidden = true; view.isUserInteractionEnabled = false
                    }
                default: fatalError("...")
                }
        }
        )
    }
    
    fileprivate func transitionText(inLabel label: UILabel, toText text: String) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveLinear],
            animations: {label.layer.opacity = 0.0},
            completion: { (position) in
                label.text = text
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.15,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {label.layer.opacity = 1.0},
                    completion: nil
                )
        }
        )
    }
    
    //
    // MARK: Cloud helpers
    
    fileprivate func fetchLocalImages() {
        
        let filterPredicate = NSPredicate(format: "isAppImage = %@", argumentArray: [true])
        localImageInfo = localPersistentStore.objects(EventImageInfo.self).filter(filterPredicate)
        
        var imagesToReturn = [AppEventImage]()
        
        for imageInfo in localImageInfo {
            if !cachedImages.contains(where: {$0.title == imageInfo.title}) {
                if let newEventImage = AppEventImage(fromEventImageInfo: imageInfo) {
                    imagesToReturn.append(newEventImage)
                }
                else {
                    // TODO: - Error handling
                    fatalError("Unable to locate \(imageInfo.title)'s thumbnail image on the disk!")
                }
            }
        }
        cachedImages.append(contentsOf: imagesToReturn)
    }
    
    fileprivate func fetchProductIDs(_ previousNetworkFetchAtempts: Int = 0, fetchFailHandler completion: @escaping (_ error: NSError) -> Void) {
        
        // Get productIdentifiers from cloud
        let getAllPredicate = NSPredicate(value: true)
        let productIdsQuerry = CKQuery(recordType: "Product", predicate: getAllPredicate)
        
        publicCloudDatabase.perform(productIdsQuerry, inZoneWith: nil) { [weak weakSelf = self] (records, error) in
            
            if error != nil {
                // TODO: Add error handling, retry network errors gracefully.
                if let nsError = error as NSError? {
                    os_log("There was an error fetching products from CloudKit", log: OSLog.default, type: .error)
                    print("Error Code: \(nsError.code)")
                    print("Error Description: \(nsError.debugDescription)")
                    print("Error Domain: \(nsError.domain)")
                    print("Error Recovery Suggestions: \(nsError.localizedRecoverySuggestion ?? "No recovery suggestions.")")
                    
                    switch nsError.code {
                    // Error code 1: Internal error, couldn't send a valid signature. No recovery suggestions.
                    // Error code 3: Network Unavailable.
                    // Error code 4: CKErrorDoman, invalid server certificate. No recovery suggestions.
                    // Error code 4097: Error connecting to cloudKitService. Recovery suggestion: Try your operation again. If that fails, quit and relaunch the application and try again.
                    case 1, 4, 4097:
                        if previousNetworkFetchAtempts <= 1 {weakSelf?.fetchProductIDs(previousNetworkFetchAtempts + 1, fetchFailHandler: completion); return}
                        else {completion(nsError); return}
                    case 3: completion(nsError); return
                    default: return
                    }
                }
            }
            
            if let returnedRecords = records {
                var setToReturn = Set<Product>()
                for record in returnedRecords {
                    let productId = record.object(forKey: "productIdentifier") as! String
                    let containedRecords = record.object(forKey: "containedRecords") as! [CKReference]
                    var recordsArray = [CKRecordID]()
                    for reference in containedRecords {recordsArray.append(reference.recordID)}
                    let newProduct = Product(id: productId, includedRecords: recordsArray)
                    setToReturn.insert(newProduct)
                }
                guard !setToReturn.isEmpty else {os_log("Nothing for sale!", log: .default, type: .error); return}
                weakSelf?.productIDs = setToReturn
                weakSelf?.checkStoreProductIds()
            }
            else {os_log("No network error, but found no productID's!", log: .default, type: .error)}
        }
    }
    
    fileprivate func checkStoreProductIds() {
        guard !productIDs.isEmpty else {fatalError("products was empty when querry to store was made!")} // TODO: Error handling
        var setToQuerry = Set<String>()
        for product in productIDs {setToQuerry.insert(product.id)}
        productRequest = SKProductsRequest(productIdentifiers: setToQuerry)
        productRequest!.delegate = self
        productRequest!.start()
    }
    
    func reFetchCloudImages() {fetchProductIDs(fetchFailHandler: networkErrorHandler)}
    
    fileprivate func fetchCloudImages(records ids: [CKRecordID], imageTypes: [CountdownImage.ImageType], completionHandler completion: @escaping (_ eventImage: AppEventImage?, _ error: CloudErrors?) -> Void) {
        
        guard !ids.isEmpty else {completion(nil, .noRecords); return}
        
        let fetchOperation = CKFetchRecordsOperation(recordIDs: ids)
        
        var desiredKeys = [
            AppEventImage.CloudKitKeys.EventImageKeys.title,
            AppEventImage.CloudKitKeys.EventImageKeys.fileRootName,
            AppEventImage.CloudKitKeys.EventImageKeys.category,
            AppEventImage.CloudKitKeys.EventImageKeys.locationForCellView
            ]
        for imageType in imageTypes {
            desiredKeys.append(contentsOf: [imageType.recordKey, imageType.extensionRecordKey])
        }
        fetchOperation.desiredKeys = desiredKeys
        
        fetchOperation.fetchRecordsCompletionBlock = { (_records, error) in
            if let records = _records {
                if records.isEmpty {completion(nil, .noRecords)}
                for record in records {
                    let recordID = record.key
                    let title = record.value[AppEventImage.CloudKitKeys.EventImageKeys.title] as! String
                    let fileRootName = record.value[AppEventImage.CloudKitKeys.EventImageKeys.fileRootName] as! String
                    let category = record.value[AppEventImage.CloudKitKeys.EventImageKeys.category] as! String
                    let intLocationForCellView = record.value[AppEventImage.CloudKitKeys.EventImageKeys.locationForCellView] as! Int
                    let locationForCellView = CGFloat(intLocationForCellView) / 100.0
                    
                    var images = [CountdownImage]()
                    var cloudError: CloudErrors?
                    for imageType in imageTypes {
                        let imageAsset = record.value[imageType.recordKey] as! CKAsset
                        let imageFileExtension = record.value[imageType.extensionRecordKey] as! String
                        
                        do {
                            let imageData = try Data(contentsOf: imageAsset.fileURL)
                            let newImage = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: imageFileExtension, imageData: imageData)
                            images.append(newImage)
                        }
                        catch {cloudError = .imageCreationFailure; break}
                    }
                    
                    if let newEventImage = AppEventImage(category: category, title: title, recordName: recordID.recordName, recommendedLocationForCellView: locationForCellView, images: images), cloudError == nil {
                        completion(newEventImage, nil)
                    }
                    else {completion(nil, cloudError)}
                }
            }
            else {completion(nil, .noRecords)}
            
        }
        publicCloudDatabase.add(fetchOperation)
    }
    
    fileprivate func networkErrorHandler(_ error: NSError) {
        switch error.code {
            // Error code 1: Internal error, couldn't send a valid signature. No recovery suggestions.
            // Error code 3: Network Unavailable.
            // Error code 4: CKErrorDoman, invalid server certificate. No recovery suggestions.
            // Error code 4097: Error connecting to cloudKitService. Recovery suggestion: Try your operation again. If that fails, quit and relaunch the application and try again.
        case 1, 4, 4097: DispatchQueue.main.async { [weak self] in self?.currentNetworkState = .failed(nil)}
        case 3:
            DispatchQueue.main.async { [weak self] in
                self?.currentNetworkState = .failed("Network unavailable, tap to retry.")
            }
        default: DispatchQueue.main.async { [weak self] in self?.currentNetworkState = .failed(nil)}
        }
    }
    
    fileprivate func thumbnailLoadComplete(_ image: AppEventImage?, _ error: CloudErrors?) {
        if image != nil && error == nil {
            DispatchQueue.main.async { [weak weakSelf = self] in
                weakSelf?.cachedImages.append(image!)
                weakSelf?.currentNetworkState = .complete
            }
        }
        else {
            if error == .noRecords {
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.currentNetworkState = .complete}
            }
            else {
                // TODO: - Error handling
                fatalError("There was an error fetching images from the cloud")
            }
        }
    }
    
    //
    // MARK: Utility helpers
    
    fileprivate func setDefaultTime() -> Date {
        let localTimeIntervalAdjustment = TimeZone.current.secondsFromGMT()
        var timeIntervalToReturn = 43200 - Double(localTimeIntervalAdjustment)
        if timeIntervalToReturn.isLess(than: 0.0) {timeIntervalToReturn += 3600}
        return Date(timeIntervalSinceReferenceDate: timeIntervalToReturn)
    }
    
    fileprivate func getEventImageInfo() -> EventImageInfo {
        if !selectedImage!.imagesAreSavedToDisk {
            let results = selectedImage!.saveToDisk(imageTypes: [.main, .mask, .thumbnail])
            if results.contains(false) {
                // TODO: Error Handling
                fatalError("Images were unable to be saved to the disk!")
            }
        }
        if let appImage = selectedImage! as? AppEventImage {
            if let i = localImageInfo.index(where: {$0.title == appImage.title}) {return localImageInfo[i]}
            else {return EventImageInfo(fromEventImage: appImage)}
        }
        else {
            let localUserImagesPredicate = NSPredicate(format: "isAppImage = %@", argumentArray: [false])
            let localUserImageInfos = localPersistentStore.objects(EventImageInfo.self).filter(localUserImagesPredicate)
            if let i = localUserImageInfos.index(where: {$0.title == selectedImage!.title}) {
                return localUserImageInfos[i]
            }
            else {return EventImageInfo(fromEventImage: selectedImage!)}
        }
    }
    
    fileprivate func createNewObject(overwrite: Bool) {
        if let _eventTitle = eventTitle, let _eventDate = eventDate {
            let imageInfo = getEventImageInfo()
            let newEvent = SpecialEvent(
                category: eventCategory ?? "Uncatagorized",
                title: _eventTitle,
                tagline: eventTagline,
                date: _eventDate,
                abridgedDisplayMode: abridgedDisplayMode,
                useMask: useMask,
                image: imageInfo,
                locationForCellView: locationForCellView
            )
            try! localPersistentStore.write {localPersistentStore.add(newEvent, update: overwrite)}
        }
        else {
            // TODO: Remove for production, should never hit this if earlier guards work.
            fatalError("Fatal Error: selectedImage or locationForCellView were nil when trying to create new event!")
        }
    }
    
    fileprivate func checkFinishButtonEnable() {
        if eventCategory != nil && eventTitle != nil && eventDate != nil {
            enableButton(finishButton)
            doneButton.isEnabled = true
            finishProgressImageView?.tintColor = UIColor.green
        }
        else {
            disableButton(finishButton)
            doneButton.isEnabled = false
            finishProgressImageView?.tintColor = Colors.inactiveColor
        }
    }
    
    fileprivate func enableButton(_ button: UIButton) {
        button.isEnabled = true; button.layer.opacity = 1.0
    }
    
    fileprivate func disableButton(_ button: UIButton) {
        button.isEnabled = false; button.layer.opacity = 0.5
    }

}
