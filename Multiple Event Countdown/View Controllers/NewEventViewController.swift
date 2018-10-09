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
import UserNotifications
import Photos

class NewEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, CAAnimationDelegate, UITableViewDelegate, UITableViewDataSource, SettingsTableViewCellDelegate, EventTableViewCellDelegate, EMContentExpandableMaterialManagerDelegate {
    
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
                categoryLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                categoryLabel.text = eventCategory
                categoryLabel.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
            }
            else {
                categoryLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                categoryLabel.text = Constants.InactiveCellTextTitles.category
                categoryLabel.font = Constants.Fonts.smallEmphasis
            }
            
            checkFinishButtonEnable()
            determineNextInput()
            isUserChange = false
        }
    }
    
    var eventTitle: String? {
        didSet {
            if eventTitle != oldValue && !initialLoad && specialEvent != nil {
                specialEvent!.cascadeDelete()
                try! mainRealm.write {
                    mainRealm.delete(specialEvent!)
                    specialEvent = nil
                }
                needNewObject = true
            }
            
            if eventTitle != nil {
                specialEventView!.titleLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                specialEventView!.eventTitle = eventTitle
                specialEventView!.titleLabel.font = UIFont(name: GlobalFontNames.ralewayMedium, size: 22.0)
            }
            else {
                specialEventView!.titleLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                specialEventView!.eventTitle = Constants.InactiveCellTextTitles.title
                specialEventView!.titleLabel.font = Constants.Fonts.largeEmphasis

            }
            
            checkFinishButtonEnable()
            determineNextInput()
        }
    }
    
    var eventTagline: String? {
        didSet {
            if eventTagline != nil {
                specialEventView!.taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                specialEventView!.eventTagline = eventTagline
                specialEventView!.taglineLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 18.0)
                
            }
            else {
                specialEventView!.taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                specialEventView!.eventTagline = Constants.InactiveCellTextTitles.tagline
                specialEventView!.taglineLabel.font = Constants.Fonts.smallEmphasis
            }
            
            checkFinishButtonEnable()
            determineNextInput()
        }
    }
    
    var eventDate: EventDate? {
        didSet {
            specialEventView?.eventDate = eventDate
            if let date = eventDate?.date {
                let newStringDate = dateFormatter.string(from: date)
                if dateInputView.dateButton.title(for: .normal) != newStringDate {
                    dateInputView.dateButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                    dateInputView.dateButton.setTitle(newStringDate, for: .normal)
                }
                
                if eventDate!.dateOnly {
                    if dateInputView.timeButton.title(for: .normal) != "All Day" {
                        dateInputView.timeButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                        dateInputView.timeButton.setTitle("All Day", for: .normal)
                    }
                    abridgedDisplayMode = true
                    if !dateInputView.allDayButton.isHidden {
                        let fadeOutAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.dateInputView.allDayButton.layer.opacity = 0.0}
                        fadeOutAnim.addCompletion { (position) in self.dateInputView.allDayButton.isHidden = true}
                        fadeOutAnim.startAnimation()
                    }
                    if let index = eventNotificationsConfig.eventNotifications.index(where: {$0.type == .timeOfEvent}) {
                        eventNotificationsConfig.eventNotifications.remove(at: index)
                        let components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: 9, minute: 0, second: 0, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                        let newNotif = EventNotification(type: .dayOfEvent, components: components)
                        eventNotificationsConfig.eventNotifications.insert(newNotif, at: index)
                    }
                }
                else {
                    let newStringTime = timeFormatter.string(from: date)
                    if dateInputView.timeButton.title(for: .normal) != newStringTime {
                        dateInputView.timeButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                        dateInputView.timeButton.setTitle(newStringTime, for: .normal)
                    }
                    abridgedDisplayMode = false
                    if dateInputView.allDayButton.isHidden && dateInputView.datePicker.datePickerMode == .time {
                        dateInputView.allDayButton.layer.opacity = 0.0
                        dateInputView.allDayButton.isHidden = false
                        let fadeInAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.dateInputView.allDayButton.layer.opacity = 1.0}
                        fadeInAnim.startAnimation()
                    }
                    if !eventNotificationsConfig.isCustom {eventNotificationsConfig = EventNotificationConfig()}
                }
                
                if !isUserChange {
                    dateInputView.datePicker.datePickerMode = .date
                    dateInputView.datePicker.date = date
                }
            }
            else {isUserChange = false}
            
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
            determineNextInput()
            isUserChange = false
        }
    }
    
    var creationDate = Date() {didSet {specialEventView!.creationDate = creationDate}}
    
    var abridgedDisplayMode = false {didSet {specialEventView?.abridgedDisplayMode = abridgedDisplayMode}}
    var infoDisplayed = DisplayInfoOptions.tagline {
        didSet {
            specialEventView?.infoDisplayed = infoDisplayed
            switch infoDisplayed {
            case .date:
                if currentInputViewState == .tagline {
                    specialEventView?.taglineLabel.textColor = GlobalColors.taskCompleteColor
                }
                else {specialEventView?.taglineLabel.textColor = GlobalColors.cyanRegular}
                specialEventView?.taglineLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 18.0)
            case .tagline:
                if eventTagline == nil {
                    if currentInputViewState == .tagline {
                        specialEventView?.taglineLabel.textColor = GlobalColors.taskCompleteColor
                    }
                    else {specialEventView?.taglineLabel.textColor = GlobalColors.inactiveColor}
                    specialEventView?.taglineLabel.font = Constants.Fonts.smallEmphasis
                }
                else {
                    if currentInputViewState == .tagline {
                        specialEventView?.taglineLabel.textColor = GlobalColors.taskCompleteColor
                    }
                    else {specialEventView?.taglineLabel.textColor = GlobalColors.cyanRegular}
                    specialEventView?.taglineLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 18.0)
                }
            case .none: break
            }
            
        }
    }
    var repeats = RepeatingOptions.never {didSet {specialEventView?.repeats = repeats}}
    
    var selectedImage: UserEventImage? {
        didSet {
            if let image = selectedImage {
                hideImageNilLabel(animated: false)
                if let appImage = image as? AppEventImage, appImage.maskImage != nil {useMask = true}
                else {useMask = false}
                specialEventView?.setSelectedImage(image: image, locationForCellView: locationForCellView)
                if !isUserChange {currentInputViewState = .none}
            }
            else {
                specialEventView?.clearEventImage()
                showImageNilLabel()
            }
            isUserChange = false
            
            checkFinishButtonEnable()
            determineNextInput()
        }
    }
    
    var locationForCellView: CGFloat?
    
    fileprivate var previousSelectedImage: UserEventImage?
    
    var useMask = true {
        didSet {
            specialEventView!.useMask = useMask
            if !isUserChange {configureCellInputViewTableView.reloadData()}
            isUserChange = false
        }
    }
    
    var cachedImages = [AppEventImage]() {
        didSet {selectImageController?.catalogImages.addImages(cachedImages)}
    }
    
    var loadedUserMoments: PHFetchResult<PHAssetCollection>? {
        didSet {selectImageController?.loadedUserMoments = loadedUserMoments}
    }
    var loadedUserAlbums: PHFetchResult<PHAssetCollection>? {
        didSet {selectImageController?.loadedUserAlbums = loadedUserAlbums}
    }
    
    var momentsPhotoAssets = [PHFetchResult<PHAsset>]() {
        didSet {selectImageController?.momentsPhotoAssets = momentsPhotoAssets}
    }
    
    var albumsPhotoAssets = [PHFetchResult<PHAsset>]() {
        didSet {selectImageController?.albumsPhotoAssets = albumsPhotoAssets}
    }
    
    var userPhotosImageManager: PHCachingImageManager? {
        didSet {selectImageController?.userPhotosImageManager = userPhotosImageManager}
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
        dateComponents.hour = 0
        dateComponents.day = calendar.component(.day, from: today) + 1
        dateComponents.month = calendar.component(.month, from: today)
        dateComponents.year = calendar.component(.year, from: today)
        let tomorrow = calendar.date(from: dateComponents)!
        
        eventDate.date = tomorrow
        eventDate.dateOnly = true
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
    
    fileprivate enum AssetFetchErrors: Error {
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
    fileprivate var currentNetworkState = NetworkStates.loading {didSet{selectImageController?.networkState = currentNetworkState}}
    
    //
    // MARK: Constants
    struct Constants {
        struct InactiveCellTextTitles {
            static let title = "1. Title"
            static let date = "2. Date"
            static let image = "3. Image"
            static let category = "4. Category"
            static let tagline = "5. Tagline"
        }
        struct Fonts {
            static let largeEmphasis = UIFont(name: GlobalFontNames.ralewayMedium, size: 24.0)!
            static let smallEmphasis = UIFont(name: GlobalFontNames.ralewayRegular, size: 18.0)!
        }
        static let defaultUserImageTitle = "Your cool moment!"
    }
    
    //
    // MARK: Persistence
    
    fileprivate var mainRealm: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    fileprivate var defaultNotificationsConfig: Results<DefaultNotificationsConfig>!
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: GUI
    fileprivate var mainScrollView: UIScrollView!
    fileprivate var mainScrollViewContentView: UIView!
    fileprivate var bottomContentViewConstraint: NSLayoutConstraint?
    fileprivate var topSpacerView: UIView!
    fileprivate var centerSpacerView: UIView!
    fileprivate var bottomSpacerView: UIView!
    
    //fileprivate var resizableEventContainer: UIView!
    fileprivate var eventAndCategoryLabelHuggingView: UIView!
    fileprivate var topToCenterSpacerEqualHeightConstraint: NSLayoutConstraint!
    fileprivate var topSpacerHeightConstraint: NSLayoutConstraint?
    var specialEventView: EventTableViewCell!
    
    var categoryLabel: UILabel!
    fileprivate lazy var dateNilLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = GlobalColors.inactiveColor
        label.text = Constants.InactiveCellTextTitles.date
        label.font = Constants.Fonts.largeEmphasis
        return label
    }()
    fileprivate lazy var imageNilLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = GlobalColors.inactiveColor
        label.text = Constants.InactiveCellTextTitles.image
        label.font = Constants.Fonts.smallEmphasis
        return label
    }()
    
    fileprivate var textInputAccessoryView: TextInputAccessoryView!
    
    var inputInfoMaterialManagerView: EMContentExpandableMaterialManagerView!
    //fileprivate var inputInfoMaterialManagerViewTopConstraint: NSLayoutConstraint!
    //fileprivate var contentViewBottomAnchor: NSLayoutConstraint!
    //fileprivate var equalHeightConstraint: NSLayoutConstraint!
    
    fileprivate var withDataViewIsInitialized = false
    fileprivate var withDataViewIsVisible = false
    var configureEventMaterialManagerView: EMContentExpandableMaterialManagerView?
    
    fileprivate var inputInfoMaterial: EMContentExpandableMaterial!
    fileprivate var configureEventMaterial: EMContentExpandableMaterial?
    
    fileprivate var categoryInputView: UIView!
    fileprivate var categoryInputViewPickerView: UIPickerView!
    
    fileprivate var dateInputView: DateInputViewClass!
    
    //fileprivate var imageInputView: ImageInputViewClass!
    
    fileprivate var configureCellInputView: UIView!
    fileprivate var configureCellInputViewTableView: UITableView!
    fileprivate var configureCellInputViewTableViewHeightConstraint: NSLayoutConstraint!
    fileprivate var configureCellInputViewTableViewWidthConstraint: NSLayoutConstraint!
    
    var confirmButton: UIButton?
    
    
    //
    // Other
    
    var masterViewController: MasterViewController?
    //fileprivate var productRequest: SKProductsRequest?
    /*fileprivate var imagesForPurchace = [CKRecordID]() {
        didSet {
            if let _ = presentedViewController as? SelectImageViewController {
                fetchCloudImages(imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
            }
        }
    }*/
    
    //
    // MARK: Notifications
    fileprivate var eventNotificationsConfig = EventNotificationConfig()

    //
    // MARK: Input View State
    fileprivate var currentInputViewState: Inputs = .none {
        didSet {
            if currentInputViewState != oldValue {
                switch oldValue {
                case .category:
                    categoryLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                    if eventCategory == nil {categoryLabel.textColor = GlobalColors.inactiveColor}
                    else {categoryLabel.textColor = GlobalColors.cyanRegular}
                case .title:
                    specialEventView!.titleLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                    if eventTitle == nil {specialEventView!.titleLabel.textColor = GlobalColors.inactiveColor}
                    else {specialEventView!.titleLabel.textColor = GlobalColors.cyanRegular}
                case .tagline:
                    specialEventView!.taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                    if eventTagline == nil {specialEventView!.taglineLabel.textColor = GlobalColors.inactiveColor}
                    else {specialEventView!.taglineLabel.textColor = GlobalColors.cyanRegular}
                case .date:
                    specialEventView!.abridgedInLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedYearsLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedMonthsLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedDaysLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedYearsTextLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedMonthsTextLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedDaysTextLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.abridgedAgoLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.tomorrowLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.agoLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.inLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.weeksLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.weeksColon.textColor = GlobalColors.cyanRegular
                    specialEventView!.daysLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.daysColon.textColor = GlobalColors.cyanRegular
                    specialEventView!.hoursLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.hoursColon.textColor = GlobalColors.cyanRegular
                    specialEventView!.minutesLabel.textColor = GlobalColors.cyanRegular
                    specialEventView!.minutesColon.textColor = GlobalColors.cyanRegular
                    specialEventView!.secondsLabel.textColor = GlobalColors.cyanRegular
                case .image:
                    if selectedImage == nil {
                        imageNilLabel.textColor = GlobalColors.inactiveColor
                        showImageNilLabel()
                    }
                case .configure, .none: break
                }
                
                switch currentInputViewState {
                case .category:
                    oldDataValue = eventCategory
                    formatHighlight(label: categoryLabel)
                case .title:
                    oldDataValue = eventTitle
                    formatHighlight(label: specialEventView!.titleLabel)
                case .tagline:
                    oldDataValue = eventTagline
                    formatHighlight(label: specialEventView!.taglineLabel)
                case .date:
                    if eventDate == nil {eventDate = defaultEventDate}
                    oldDataValue = eventDate
                    formatHighlight(label: specialEventView!.abridgedInLabel)
                    formatHighlight(label: specialEventView!.abridgedYearsLabel)
                    formatHighlight(label: specialEventView!.abridgedMonthsLabel)
                    formatHighlight(label: specialEventView!.abridgedDaysLabel)
                    formatHighlight(label: specialEventView!.abridgedYearsTextLabel)
                    formatHighlight(label: specialEventView!.abridgedMonthsTextLabel)
                    formatHighlight(label: specialEventView!.abridgedDaysTextLabel)
                    formatHighlight(label: specialEventView!.abridgedAgoLabel)
                    formatHighlight(label: specialEventView!.tomorrowLabel)
                    formatHighlight(label: specialEventView!.agoLabel)
                    formatHighlight(label: specialEventView!.inLabel)
                    formatHighlight(label: specialEventView!.weeksLabel)
                    formatHighlight(label: specialEventView!.weeksColon)
                    formatHighlight(label: specialEventView!.daysLabel)
                    formatHighlight(label: specialEventView!.daysColon)
                    formatHighlight(label: specialEventView!.hoursLabel)
                    formatHighlight(label: specialEventView!.hoursColon)
                    formatHighlight(label: specialEventView!.minutesLabel)
                    formatHighlight(label: specialEventView!.minutesColon)
                    formatHighlight(label: specialEventView!.secondsLabel)
                    if abridgedDisplayMode {
                        viewTransition(from: dateNilLabel, to: specialEventView!.abridgedTimerContainerView)
                    }
                    else {
                        viewTransition(from: dateNilLabel, to: specialEventView!.timerContainerView)
                    }
                case .image, .configure, .none: break
                }
                
                transitionViews(fromState: oldValue, toState: currentInputViewState)
            }
        }
    }
    
    fileprivate var nextInput: Inputs = .title {didSet {if nextInput != oldValue {updateInfoInputMaterialTitle()}}}
    
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
    var momentsAssetFetchComplete = false {didSet {selectImageController?.momentsAssetFetchComplete = momentsAssetFetchComplete}}
    var albumsAssetFetchComplete = false {didSet {selectImageController?.albumsAssetFetchComplete = albumsAssetFetchComplete}}
    
    var expandedCellIndexPath: IndexPath? {
        didSet {
            if expandedCellIndexPath != oldValue {
                if let _oldValue = oldValue, let oldCell = configureCellInputViewTableView.cellForRow(at: _oldValue) as? SettingsTableViewCell {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.15,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {oldCell.optionsPickerView.layer.opacity = 0.0},
                        completion: {(position) in
                            oldCell.optionsPickerView.isHidden = true; oldCell.optionsPickerView.layer.opacity = 1.0
                        }
                    )
                }
                if let newValue = expandedCellIndexPath, let newCell = configureCellInputViewTableView.cellForRow(at: newValue) as? SettingsTableViewCell {
                    newCell.optionsPickerView.layer.opacity = 0.0
                    newCell.optionsPickerView.isHidden = false
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.15,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {newCell.optionsPickerView.layer.opacity = 1.0},
                        completion: nil
                    )
                }
                //configureCellInputViewTableView.beginUpdates(); configureCellInputViewTableView.endUpdates()
                
                configureCellInputViewTableView.reloadData()
                
                /*mainScrollViewContentView.setNeedsLayout()
                let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                    self.configureEventMaterialManagerView.invalidateIntrinsicContentSize()
                    self.mainScrollViewContentView.layoutIfNeeded()
                }
                materialAnim.startAnimation()*/
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {return true}
    override var canResignFirstResponder: Bool {return true}
    override var inputAccessoryView: UIView? {return textInputAccessoryView}
    
    //
    // Static Types
    enum Inputs: String {
        case category = "Set Category"
        case title = "Set Title"
        case date = "Set Date"
        case tagline = "Set Tagline"
        case image = "Set Image"
        case configure = "Event Settings"
        case none = "None"
    }
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        setupDataModel()

        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        if editingEvent {
            presentWithDataViewIfNotPresent()
            navigationItem.title = "Edit Event"
        }
        else {navigationItem.title = "New Event"}
    }
    
    //
    // MARK: View Loaders
    fileprivate func loadNibs() {
        if let inputAccessoryNib = Bundle.main.loadNibNamed("TextInputAccessoryView", owner: self, options: nil) {
            if let textInputView = inputAccessoryNib[0] as? TextInputAccessoryView {
                textInputAccessoryView = textInputView
                textInputAccessoryView!.textInputField.delegate = self
                textInputAccessoryView!.borderView.layer.borderColor = GlobalColors.orangeRegular.cgColor
                textInputAccessoryView!.borderView.layer.borderWidth = 1.0
                textInputAccessoryView!.borderView.layer.cornerRadius = GlobalCornerRadii.material
                textInputAccessoryView!.nextInputButton.addTarget(self, action: #selector(selectNextInput), for: .touchUpInside)
                textInputAccessoryView!.nextInputButton.imageView?.contentMode = .scaleAspectFit
                textInputAccessoryView!.cancelInputButton.addTarget(self, action: #selector(colapseKeyboard), for: .touchUpInside)
                textInputAccessoryView!.cancelInputButton.imageView?.contentMode = .scaleAspectFit
                textInputAccessoryView!.isHidden = true
                textInputAccessoryView!.isUserInteractionEnabled = false
            }
        }
        
        if let specialEventNib = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let view = specialEventNib[0] as? EventTableViewCell {
                specialEventView = view
                specialEventView.isUserInteractionEnabled = true
                specialEventView.translatesAutoresizingMaskIntoConstraints = false
                specialEventView.configuration = .cell
                specialEventView.delegate = self
                specialEventView.viewWithMargins.layer.cornerRadius = 3.0
                specialEventView.viewWithMargins.layer.masksToBounds = true
                specialEventView.viewWithMargins.layer.backgroundColor = GlobalColors.lightGrayForFills.cgColor
                
                let bottomAnchorConstraint = specialEventView!.constraints.first {$0.secondAnchor == specialEventView!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                specialEventView!.bottomAnchor.constraint(equalTo: specialEventView!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
            }
        }
        
        if let categoryInputViewNib = Bundle.main.loadNibNamed("CategoryInputView", owner: self, options: nil) {
            if let view = categoryInputViewNib[0] as? UIView {
                categoryInputView = view
                categoryInputView.translatesAutoresizingMaskIntoConstraints = false
                categoryInputView.backgroundColor = UIColor.clear
                if let pickerIndex = view.subviews.index(where: {$0 is UIPickerView}) {
                    categoryInputViewPickerView = (view.subviews[pickerIndex] as! UIPickerView)
                    categoryInputViewPickerView.delegate = self
                    categoryInputViewPickerView.dataSource = self
                    categoryInputViewPickerView.reloadAllComponents()
                }
            }
        }
        
        if let dateInputViewNib = Bundle.main.loadNibNamed("DateInputView", owner: self, options: nil) {
            if let view = dateInputViewNib[0] as? DateInputViewClass {
                dateInputView = view
                dateInputView.translatesAutoresizingMaskIntoConstraints = false
                dateInputView.backgroundColor = UIColor.clear
                
                dateInputView.datePicker.addTarget(self, action: #selector(datePickerDateDidChange(_:)), for: .valueChanged)
                dateInputView.datePicker.backgroundColor = UIColor.clear
                dateInputView.datePicker.isOpaque = false
                dateInputView.datePicker.setValue(GlobalColors.orangeRegular, forKey: "textColor")
                
                dateInputView.allDayButton.addTarget(self, action: #selector(allDayButtonTapped), for: .touchUpInside)
                dateInputView.dateButton.addTarget(self, action: #selector(changeDatePickerToDate), for: .touchUpInside)
                dateInputView.timeButton.addTarget(self, action: #selector(changeDatePickerToTime), for: .touchUpInside)
                
                dateInputView.dateButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                dateInputView.dateButton.setTitleColor(UIColor.green, for: .normal)
            }
        }
        
        /*if let imageInputViewNib = Bundle.main.loadNibNamed("ImageInputView", owner: self, options: nil) {
            if let view = imageInputViewNib[0] as? ImageInputViewClass {
                imageInputView = view
                imageInputView.translatesAutoresizingMaskIntoConstraints = false
                imageInputView.chooseImageButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
                imageInputView.previewEditImagesButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
                imageInputView.toggleImageButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
                imageInputView.toggleMaskButton.addTarget(self, action: #selector(handleImageOptionsButtonsTap(_:)), for: .touchUpInside)
                
                imageInputView.chooseImageButton.emphasisedFormat()
                disableButton(imageInputView.previewEditImagesButton)
                disableButton(imageInputView.toggleImageButton)
                disableButton(imageInputView.toggleMaskButton)
            }
        }*/
        
        if let configureCellInputViewNib = Bundle.main.loadNibNamed("ConfigureCellInputView", owner: self, options: nil) {
            if let view = configureCellInputViewNib[0] as? UIView {
                configureCellInputView = view
                configureCellInputView.translatesAutoresizingMaskIntoConstraints = false
                if let tableViewIndex = view.subviews.index(where: {$0 is UITableView}) {
                    configureCellInputViewTableView = (view.subviews[tableViewIndex] as! UITableView)
                    configureCellInputViewTableView.translatesAutoresizingMaskIntoConstraints = false
                    configureCellInputViewTableView.delegate = self
                    configureCellInputViewTableView.dataSource = self
                    configureCellInputViewTableView.sectionHeaderHeight = 40.0
                    let settingsRowNib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
                    configureCellInputViewTableView.register(settingsRowNib, forCellReuseIdentifier: ReuseIdentifiers.titleDetail)
                    
                    configureCellInputViewTableViewHeightConstraint = configureCellInputView.heightAnchor.constraint(equalToConstant: 150.0)
                    configureCellInputViewTableViewWidthConstraint = configureCellInputView.widthAnchor.constraint(equalToConstant: 200.0)
                    configureCellInputViewTableViewHeightConstraint.isActive = true
                    configureCellInputViewTableViewWidthConstraint.isActive = true
                }
            }
        }
    }
    
    fileprivate func createNoDataView() {
        
        //
        // Top level Container View so nav bar doesn't dissapear
        let wierdBufferView = UIView()
        wierdBufferView.translatesAutoresizingMaskIntoConstraints = false
        wierdBufferView.backgroundColor = UIColor.clear
        
        view.addSubview(wierdBufferView)
        wierdBufferView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        wierdBufferView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        wierdBufferView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        wierdBufferView.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
        
        let topLevelContainer = UIView()
        topLevelContainer.translatesAutoresizingMaskIntoConstraints = false
        topLevelContainer.backgroundColor = UIColor.clear
        
        view.addSubview(topLevelContainer)
        topLevelContainer.topAnchor.constraint(equalTo: wierdBufferView.topAnchor).isActive = true
        topLevelContainer.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        topLevelContainer.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        topLevelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        //
        // Spacer views
        topSpacerView = UIView()
        topSpacerView.translatesAutoresizingMaskIntoConstraints = false
        topSpacerView.backgroundColor = UIColor.clear
        
        centerSpacerView = UIView()
        centerSpacerView.translatesAutoresizingMaskIntoConstraints = false
        centerSpacerView.backgroundColor = UIColor.clear
        
        bottomSpacerView = UIView()
        bottomSpacerView.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacerView.backgroundColor = UIColor.clear
        
        //
        // Special Event Container View
        /*resizableEventContainer = UIView()
        resizableEventContainer.translatesAutoresizingMaskIntoConstraints = false
        resizableEventContainer.backgroundColor = UIColor.clear*/
        
        eventAndCategoryLabelHuggingView = UIView()
        eventAndCategoryLabelHuggingView.translatesAutoresizingMaskIntoConstraints = false
        eventAndCategoryLabelHuggingView.backgroundColor = UIColor.clear
        
        categoryLabel = UILabel()
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.textColor = GlobalColors.cyanRegular
        categoryLabel.textAlignment = .left
        categoryLabel.isUserInteractionEnabled = true
        
        eventAndCategoryLabelHuggingView.addSubview(categoryLabel)
        eventAndCategoryLabelHuggingView.addSubview(specialEventView)
        
        specialEventView.bottomAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.bottomAnchor).isActive = true
        specialEventView.leftAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.leftAnchor).isActive = true
        specialEventView.rightAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.rightAnchor).isActive = true
        specialEventView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8.0).isActive = true
        specialEventView.heightAnchor.constraint(equalToConstant: globalCellHeight).isActive = true
        
        categoryLabel.topAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.topAnchor).isActive = true
        categoryLabel.leftAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.leftAnchor, constant: 8.0).isActive = true
        categoryLabel.rightAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.rightAnchor, constant: -8.0).isActive = true
        
        //resizableEventContainer.addSubview(eventAndCategoryLabelHuggingView)
        
        /*eventAndCategoryLabelHuggingView.leftAnchor.constraint(equalTo: resizableEventContainer.leftAnchor).isActive = true
        eventAndCategoryLabelHuggingView.rightAnchor.constraint(equalTo: resizableEventContainer.rightAnchor).isActive = true
        eventAndCategoryLabelHuggingViewCenteringConstraint = eventAndCategoryLabelHuggingView.centerYAnchor.constraint(equalTo: resizableEventContainer.centerYAnchor)
        eventAndCategoryLabelHuggingViewCenteringConstraint.isActive = true
        
        resizableEventContainer.heightAnchor.constraint(greaterThanOrEqualTo: eventAndCategoryLabelHuggingView.heightAnchor, constant: 40.0).isActive = true*/
        
        //
        // Material Manager View
        inputInfoMaterialManagerView = EMContentExpandableMaterialManagerView()
        inputInfoMaterialManagerView.translatesAutoresizingMaskIntoConstraints = false
        inputInfoMaterialManagerView.delegate = self
        inputInfoMaterialManagerView.backgroundColor = UIColor.clear
        inputInfoMaterialManagerView.axis = .vertical
        inputInfoMaterialManagerView.distribution = .center
        inputInfoMaterialManagerView.alignment = .center
        
        inputInfoMaterial = EMContentExpandableMaterial()
        inputInfoMaterial.translatesAutoresizingMaskIntoConstraints = false
        inputInfoMaterial.regularFormat()
        updateInfoInputMaterialTitle()
        
        inputInfoMaterial.colapseButton.directionalLayoutMargins = standardDirectionalLayoutMargins
        inputInfoMaterial.colapseButton.contentEdgeInsets = UIEdgeInsets(top: standardDirectionalLayoutMargins.top, left: standardDirectionalLayoutMargins.leading, bottom: standardDirectionalLayoutMargins.bottom, right: standardDirectionalLayoutMargins.trailing)
        inputInfoMaterial.colapseButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)
        inputInfoMaterial.colapseButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
        inputInfoMaterial.colapseButton.setTitle("CONFIRM", for: .normal)
        //inputInfoMaterial.colapseButton.setImage(#imageLiteral(resourceName: "CloseImage"), for: .normal)
        //inputInfoMaterial.colapseButton.tintColor = GlobalColors.orangeDark

        let nextButton = UIButton()
        nextButton.directionalLayoutMargins = standardDirectionalLayoutMargins
        nextButton.contentEdgeInsets = UIEdgeInsets(top: standardDirectionalLayoutMargins.top, left: standardDirectionalLayoutMargins.leading, bottom: standardDirectionalLayoutMargins.bottom, right: standardDirectionalLayoutMargins.trailing)
        nextButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)
        nextButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
        nextButton.setTitle("NEXT", for: .normal)
        //nextButton.setImage(#imageLiteral(resourceName: "NextInputButtonImage"), for: .normal)
        nextButton.addTarget(self, action: #selector(selectNextInput), for: .touchUpInside)
        inputInfoMaterial.addRightButtonItem(nextButton)
        
        inputInfoMaterialManagerView.addManagedMaterialView(inputInfoMaterial)
        
        //
        // Scroll View
        mainScrollView = UIScrollView()
        mainScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black
        mainScrollView.backgroundColor = UIColor.clear
        
        topLevelContainer.addSubview(mainScrollView)
        mainScrollView.topAnchor.constraint(equalTo: topLevelContainer.topAnchor).isActive = true
        mainScrollView.leftAnchor.constraint(equalTo: topLevelContainer.leftAnchor).isActive = true
        mainScrollView.rightAnchor.constraint(equalTo: topLevelContainer.rightAnchor).isActive = true
        mainScrollView.bottomAnchor.constraint(equalTo: topLevelContainer.bottomAnchor).isActive = true
        
        //
        // Scroll View Content View
        mainScrollViewContentView = UIView()
        mainScrollViewContentView.translatesAutoresizingMaskIntoConstraints = false
        mainScrollViewContentView.backgroundColor = UIColor.clear
        
        mainScrollView.addSubview(mainScrollViewContentView)
        mainScrollViewContentView.topAnchor.constraint(equalTo: mainScrollView.topAnchor).isActive = true
        mainScrollViewContentView.leftAnchor.constraint(equalTo: mainScrollView.leftAnchor).isActive = true
        mainScrollViewContentView.rightAnchor.constraint(equalTo: mainScrollView.rightAnchor).isActive = true
        mainScrollViewContentView.bottomAnchor.constraint(equalTo: mainScrollView.bottomAnchor).isActive = true
        mainScrollViewContentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        mainScrollViewContentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor).isActive = true
        
        mainScrollViewContentView.addSubview(topSpacerView)
        mainScrollViewContentView.addSubview(eventAndCategoryLabelHuggingView)
        mainScrollViewContentView.addSubview(centerSpacerView)
        mainScrollViewContentView.addSubview(inputInfoMaterialManagerView)
        mainScrollViewContentView.addSubview(bottomSpacerView)
        
        /*resizableEventContainer.topAnchor.constraint(equalTo: mainScrollViewContentView.topAnchor).isActive = true
        resizableEventContainer.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        resizableEventContainer.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true*/
        
        topSpacerView.topAnchor.constraint(equalTo: mainScrollViewContentView.topAnchor).isActive = true
        topSpacerView.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        topSpacerView.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true
        topSpacerView.bottomAnchor.constraint(equalTo: eventAndCategoryLabelHuggingView.topAnchor).isActive = true
        
        eventAndCategoryLabelHuggingView.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        eventAndCategoryLabelHuggingView.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true
        eventAndCategoryLabelHuggingView.bottomAnchor.constraint(equalTo: centerSpacerView.topAnchor).isActive = true
        
        centerSpacerView.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        centerSpacerView.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true
        centerSpacerView.bottomAnchor.constraint(equalTo: inputInfoMaterialManagerView.topAnchor).isActive = true
        
        /*inputInfoMaterialManagerViewTopConstraint = inputInfoMaterialManagerView.topAnchor.constraint(equalTo: resizableEventContainer.bottomAnchor)
        inputInfoMaterialManagerViewTopConstraint.isActive = true*/
        inputInfoMaterialManagerView.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        inputInfoMaterialManagerView.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true
        inputInfoMaterialManagerView.bottomAnchor.constraint(equalTo: bottomSpacerView.topAnchor).isActive = true
        /*inputInfoMaterialManagerViewBottomConstraint = inputInfoMaterialManagerView.bottomAnchor.constraint(equalTo: mainScrollViewContentView.bottomAnchor)
        inputInfoMaterialManagerViewBottomConstraint.isActive = true*/
        
        bottomSpacerView.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor).isActive = true
        bottomSpacerView.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor).isActive = true
        bottomContentViewConstraint = bottomSpacerView.bottomAnchor.constraint(equalTo: mainScrollViewContentView.bottomAnchor)
        bottomContentViewConstraint?.isActive = true
        
        topToCenterSpacerEqualHeightConstraint = topSpacerView.heightAnchor.constraint(equalTo: centerSpacerView.heightAnchor)
        topToCenterSpacerEqualHeightConstraint.isActive = true
        bottomSpacerView.heightAnchor.constraint(equalTo: centerSpacerView.heightAnchor).isActive = true
        centerSpacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: globalCellSpacing).isActive = true
    }
    
    fileprivate func initWithDataViewIfNeeded() {
        if !withDataViewIsInitialized {
            //
            // Configure Event Material and Manager View
            configureEventMaterialManagerView = EMContentExpandableMaterialManagerView()
            configureEventMaterialManagerView!.translatesAutoresizingMaskIntoConstraints = false
            configureEventMaterialManagerView!.delegate = self
            configureEventMaterialManagerView!.backgroundColor = UIColor.clear
            configureEventMaterialManagerView!.axis = .vertical
            configureEventMaterialManagerView!.distribution = .trailing
            configureEventMaterialManagerView!.alignment = .center
            
            configureEventMaterial = EMContentExpandableMaterial()
            configureEventMaterial!.translatesAutoresizingMaskIntoConstraints = false
            configureEventMaterial!.regularFormat()
            configureEventMaterial!.title = Inputs.configure.rawValue
            configureEventMaterial!.expandedViewContent = configureCellInputView
            
            configureEventMaterial!.colapseButton.directionalLayoutMargins = standardDirectionalLayoutMargins
            configureEventMaterial!.colapseButton.contentEdgeInsets = UIEdgeInsets(top: standardDirectionalLayoutMargins.top, left: standardDirectionalLayoutMargins.leading, bottom: standardDirectionalLayoutMargins.bottom, right: standardDirectionalLayoutMargins.trailing)
            configureEventMaterial!.colapseButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)
            configureEventMaterial!.colapseButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
            configureEventMaterial!.colapseButton.setTitle("CONFIRM", for: .normal)
            
            configureEventMaterialManagerView!.addManagedMaterialView(configureEventMaterial!)
            configureEventMaterialManagerView!.setContentHuggingPriority(.defaultHigh, for: .vertical)
            configureEventMaterialManagerView!.constrainWidth(ofMaterial: nil, to: view.bounds.width - 40.0)
            
            //
            // Confirm Button
            confirmButton = UIButton()
            confirmButton!.translatesAutoresizingMaskIntoConstraints = false
            confirmButton!.emphasisedFormat()
            if editingEvent {confirmButton!.setTitle("CONFIRM CHANGES", for: .normal)}
            else {confirmButton!.setTitle("CREATE EVENT", for: .normal)}
            confirmButton!.setContentHuggingPriority(.defaultHigh, for: .vertical)
            confirmButton!.addTarget(self, action: #selector(finish(_:)), for: .touchUpInside)
            
            withDataViewIsInitialized = true
        }
    }
    
    fileprivate func presentWithDataViewIfNotPresent() {
        if !withDataViewIsVisible {
            initWithDataViewIfNeeded()
            
            bottomContentViewConstraint?.isActive = false
            
            mainScrollViewContentView.addSubview(configureEventMaterialManagerView!)
            mainScrollViewContentView.addSubview(confirmButton!)
            
            configureEventMaterialManagerView!.topAnchor.constraint(equalTo: bottomSpacerView.bottomAnchor).isActive = true
            configureEventMaterialManagerView!.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor, constant: 20.0).isActive = true
            configureEventMaterialManagerView!.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor, constant: -20.0).isActive = true
            configureEventMaterialManagerView!.bottomAnchor.constraint(equalTo: confirmButton!.topAnchor, constant: -globalCellSpacing).isActive = true
            
            confirmButton!.leftAnchor.constraint(equalTo: mainScrollViewContentView.leftAnchor, constant: 20.0).isActive = true
            confirmButton!.rightAnchor.constraint(equalTo: mainScrollViewContentView.rightAnchor, constant: -20.0).isActive = true
            bottomContentViewConstraint = confirmButton!.bottomAnchor.constraint(equalTo: mainScrollViewContentView.bottomAnchor, constant: -2 * globalCellSpacing)
            bottomContentViewConstraint?.isActive = true
            
            withDataViewIsVisible = true
        }
    }
    
    fileprivate func removeWithDataViewIfPresent() {
        if withDataViewIsVisible {
            bottomContentViewConstraint?.isActive = false
            configureCellInputViewTableViewWidthConstraint?.isActive = false
            
            configureEventMaterialManagerView?.removeFromSuperview()
            confirmButton?.removeFromSuperview()
            
            bottomContentViewConstraint = bottomSpacerView.bottomAnchor.constraint(equalTo: mainScrollViewContentView.bottomAnchor)
            bottomContentViewConstraint?.isActive = true
        }
    }
    
    fileprivate func configureView() {
        
        //
        // NavBar config
        _ = addBackButton(action: #selector(defaultPop), title: "CANCEL", target: self)
        
        let screenHeight = UIScreen.main.bounds.size.height
        let screenWidth = UIScreen.main.bounds.size.width
        if screenHeight >= 667.0 && screenWidth >= 375.0 {navigationItem.largeTitleDisplayMode = .always}
        
        loadNibs()
        createNoDataView()
        setupGestureRecognizers()
    }
    
    fileprivate func configureButton(_ button: UIButton) {
        button.layer.borderWidth = 1.0
        button.layer.borderColor = GlobalColors.orangeDark.cgColor
        button.layer.cornerRadius = 3.0
    }
    
    fileprivate func setupGestureRecognizers() -> Void {
        let specialEventViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
        let categoryLabelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
        
        specialEventView?.addGestureRecognizer(specialEventViewTapGestureRecognizer)
        categoryLabel.addGestureRecognizer(categoryLabelTapGestureRecognizer)
    }
    
    //
    // MARK: Data Model Loaders
    fileprivate func setupDataModel() {
        
        if let categories = userDefaults.value(forKey: "Categories") as? [String] {
            for category in categories {
                if !immutableCategories.contains(category) {selectableCategories.append(category)}
            }
        }
        else {
            os_log("Unable to fetch categories from user defaults, error setting them in appDelegate maybe?", log: .default, type: .error)
            selectableCategories.append(contentsOf: immutableCategories)
        }
        
        mainRealm = try! Realm(configuration: appRealmConfig)
        defaultNotificationsConfig = mainRealm.objects(DefaultNotificationsConfig.self)
        fetchLocalImages()
        fetchCloudImages(imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
        fetchUserPhotos()
        
        if let event = specialEvent{
            needNewObject = false
            
            eventCategory = event.category
            eventTitle = event.title
            if let tagline = event.tagline {eventTagline = tagline}
            else {
                eventTagline = nil
                specialEventView!.taglineLabel.textColor = GlobalColors.inactiveColor
            }
            eventDate = EventDate(date: event.date!.date, dateOnly: event.date!.dateOnly)
            
            creationDate = event.creationDate
            abridgedDisplayMode = event.abridgedDisplayMode
            useMask = event.useMask
            
            if let RealmNotificationsConfig = event.notificationsConfig {
                eventNotificationsConfig = EventNotificationConfig(fromRealmEventNotificationConfig: RealmNotificationsConfig)
            }
            
            if let intLocationForCellView = event.locationForCellView.value {
                locationForCellView = CGFloat(intLocationForCellView) / 100.0
            }
            
            if let imageInfo = event.image {
                if imageInfo.isAppImage {selectedImage = AppEventImage(fromEventImageInfo: imageInfo)}
                else {selectedImage = UserEventImage(fromEventImageInfo: imageInfo)}
            }
            else {specialEventView!.clearEventImage(); showImageNilLabel(animated: false)}
            
            specialEventView!.update()
            
            
        }
        else {
            var newNotifs = [RealmEventNotification]()
            for realmNotif in defaultNotificationsConfig[0].eventNotifications {
                newNotifs.append(realmNotif)
            }
            
            specialEventView!.viewWithMargins.addSubview(dateNilLabel)
            specialEventView!.viewWithMargins.bottomAnchor.constraint(equalTo: dateNilLabel.bottomAnchor, constant: 8.0).isActive = true
            specialEventView!.viewWithMargins.rightAnchor.constraint(equalTo: dateNilLabel.rightAnchor, constant: 8.0).isActive = true
            specialEventView!.timerContainerView.isHidden = true
            specialEventView!.abridgedTimerContainerView.isHidden = true
            specialEventView!.useMask = true
            
            categoryLabel.text = Constants.InactiveCellTextTitles.category
            categoryLabel.textColor = GlobalColors.inactiveColor
            categoryLabel.font = Constants.Fonts.smallEmphasis
            
            specialEventView!.eventTitle = Constants.InactiveCellTextTitles.title
            specialEventView!.titleLabel.textColor = GlobalColors.inactiveColor
            specialEventView!.titleLabel.font = Constants.Fonts.largeEmphasis
            
            specialEventView!.eventTagline = Constants.InactiveCellTextTitles.tagline
            specialEventView!.taglineLabel.textColor = GlobalColors.inactiveColor
            specialEventView!.taglineLabel.font = Constants.Fonts.smallEmphasis
            
            showImageNilLabel(animated: false)
            
            specialEventView!.creationDate = creationDate
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if eventDate != nil && eventTimer == nil {
            specialEventView?.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {initialLoad = false}
    
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
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        configureCellInputViewTableViewHeightConstraint.constant = configureCellInputViewTableView.contentSize.height
        configureCellInputViewTableViewWidthConstraint.constant = view.bounds.width - 40.0 - standardDirectionalLayoutMargins.leading - standardDirectionalLayoutMargins.trailing
    }
    
    @objc fileprivate func applicationWillResignActive(notification: NSNotification) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    @objc fileprivate func keyboardChangeFrame(notification: NSNotification) {
        if !initialLoad, let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let animDuration: Double? = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
            let animCurveRawValue: Int? = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int
            
            let keyboardFrame = keyboardFrame.cgRectValue
            let totalKeyboardHeight = keyboardFrame.height
            
            let specialEventViewDistanceFromBottom = mainScrollView.frame.height - (eventAndCategoryLabelHuggingView.frame.origin.y + eventAndCategoryLabelHuggingView.frame.height)
            
            if totalKeyboardHeight > specialEventViewDistanceFromBottom {
                let height = max(mainScrollView.frame.height - totalKeyboardHeight - eventAndCategoryLabelHuggingView.frame.height, 1.0)
                topToCenterSpacerEqualHeightConstraint.isActive = false
                topSpacerHeightConstraint = topSpacerView.heightAnchor.constraint(equalToConstant: height)
                topSpacerHeightConstraint?.priority = .defaultHigh
                topSpacerHeightConstraint?.isActive = true
                mainScrollViewContentView.setNeedsLayout()
                let moveViewAnim = UIViewPropertyAnimator(duration: animDuration ?? 0.35, curve: UIViewAnimationCurve(rawValue: animCurveRawValue ?? 0)!) {
                    self.mainScrollViewContentView.layoutIfNeeded()
                }
                moveViewAnim.startAnimation()
            }
            else {
                if topToCenterSpacerEqualHeightConstraint == nil || !topToCenterSpacerEqualHeightConstraint!.isActive {
                    topSpacerHeightConstraint?.isActive = false
                    topToCenterSpacerEqualHeightConstraint = topSpacerView.heightAnchor.constraint(equalTo: centerSpacerView.heightAnchor)
                    topToCenterSpacerEqualHeightConstraint.isActive = true
                    mainScrollViewContentView.setNeedsLayout()
                    let moveViewAnim = UIViewPropertyAnimator(duration: animDuration ?? 0.35, curve: UIViewAnimationCurve(rawValue: animCurveRawValue ?? 0)!) {
                        self.mainScrollViewContentView.layoutIfNeeded()
                    }
                    moveViewAnim.startAnimation()
                }
            }
        }
    }
    
    deinit {
        eventTimer?.invalidate()
        eventTimer = nil
        
        let backgroundThread = DispatchQueue(label: "background", qos: .background, target: nil)
        backgroundThread.async {
            let imageCleanupRealm = try! Realm(configuration: appRealmConfig)
            let allImages = imageCleanupRealm.objects(EventImageInfo.self)
            for imageInfo in allImages {
                if imageInfo.specialEvents.isEmpty && imageInfo.isAppImage == false {
                    let fileName = imageInfo.title.convertToFileName()
                    let saveDest = sharedImageLocationURL.appendingPathComponent(fileName + ".jpg", isDirectory: false)
                    imageInfo.cascadeDelete()
                    do {
                        try FileManager.default.removeItem(at: saveDest)
                        try imageCleanupRealm.write {imageCleanupRealm.delete(imageInfo)}
                    }
                    catch {
                        os_log("Error removing image on disk and/or image info from realm: %@", log: .default, type: .error, error.localizedDescription)
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
    
    /*func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
            fetchCloudImages(imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
        }
    }*/
    
    //
    // Date Picker
    
    @objc func datePickerDateDidChange(_ sender: UIDatePicker) {
        let todaysDate = Date()
        let timeInterval = sender.date.timeIntervalSince(todaysDate)
        if timeInterval < 0.0 {repeats = .never}
        
        isUserChange = true
        var currentDateComponents: DateComponents!
        currentDateComponents = currentCalendar.dateComponents(calendarComponentsOfInterest, from: eventDate!.date)
        switch dateInputView.datePicker.datePickerMode {
        case .date:
            let ymdDateComponents = currentCalendar.dateComponents(ymdCalendarComponents, from: dateInputView.datePicker.date)
            currentDateComponents.year = ymdDateComponents.year!
            currentDateComponents.month = ymdDateComponents.month!
            currentDateComponents.day = ymdDateComponents.day!
        case .time:
            let hmsDateComponents = currentCalendar.dateComponents(hmsCalendarComponents, from: dateInputView.datePicker.date)
            currentDateComponents.hour = hmsDateComponents.hour!
            currentDateComponents.minute = hmsDateComponents.minute!
            currentDateComponents.second = hmsDateComponents.second!
        default:
            os_log("DatePicker in NewEventController somehow got in an undefined mode.", log: OSLog.default, type: .error)
            dateInputView.datePicker.datePickerMode = .date
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
        currentInputViewState = .none
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
    // MARK: TitleDetailTableViewCellDelegate
    func selectedOptionDidUpdate(cell: SettingsTableViewCell) {
        if let indexPath = configureCellInputViewTableView.indexPath(for: cell), let selectedOption = cell.selectedOption {
            switch tableViewDataSource[indexPath.section].rows[indexPath.row].title {
            case StaticData.Text.RowTitles.repeats:
                if let optionString = selectedOption.text, let temp = RepeatingOptions(rawValue: optionString) {repeats = temp}
            case StaticData.Text.RowTitles.timerDisplayMode:
                switch selectedOption {
                case StaticData.Options.TimerDisplayMode.detailed: abridgedDisplayMode = false
                case StaticData.Options.TimerDisplayMode.abridged: abridgedDisplayMode = true
                default:
                    os_log("Unexpected option encountered in table view cell!", log: .default, type: .error)
                    break
                }
            case StaticData.Text.RowTitles.infoDiplayed:
                if let optionString = selectedOption.text, let temp = DisplayInfoOptions(rawValue: optionString) {infoDisplayed = temp}
            case StaticData.Text.RowTitles.toggleMask:
                break
            case StaticData.Text.RowTitles.notifications:
                switch selectedOption {
                case StaticData.Options.Notifications._default: break
                case StaticData.Options.Notifications.custom: break
                case StaticData.Options.Notifications.off: break
                default:
                    os_log("Unexpected option encountered in table view cell!", log: .default, type: .error)
                    break
                }
            default:
                os_log("Unexpected title encountered in table view cell!", log: .default, type: .error)
                break
            }
        }
    }
    
    @objc fileprivate func cellSwitchFlipped(_ sender: UISwitch) {
        let cell = sender.superview as! SettingsTableViewCell
        switch cell.title {
        case StaticData.Text.RowTitles.toggleMask: isUserChange = true; useMask = sender.isOn
        default:
            os_log("Unexpected title encountered in table view cell!", log: .default, type: .error)
            break
        }
    }
    
    //
    // MARK: EventTableViewCellDelegate
    func eventDateRepeatTriggered(cell: EventTableViewCell, newDate: EventDate) {eventDate = newDate}
    
    //
    // MARK: From storyboard actions
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
        if let sender = segue.source as? ImagePreviewViewController {
            locationForCellView = sender.locationForCellView
            selectedImage = sender.selectedImage
        }
    }
    
    @IBAction func unwindFromCustomEventNotifications(segue: UIStoryboardSegue) {
        
        if let configureNotificationsController = segue.source as? ConfigureNotificationsTableViewController {
            
            eventNotificationsConfig.eventNotifications = configureNotificationsController.modifiedEventNotifications
            eventNotificationsConfig.eventNotificationsOn = configureNotificationsController.globalToggleOn
            eventNotificationsConfig.isCustom = configureNotificationsController.useCustomNotifications
            
            let section = 0
            let row = tableViewDataSource[section].rows.index(where: {$0.title == StaticData.Text.RowTitles.notifications})!
            let cellToModify = configureCellInputViewTableView.cellForRow(at: IndexPath(row: row, section: section)) as! SettingsTableViewCell
            
            if !eventNotificationsConfig.eventNotificationsOn {
                let index = tableViewDataSource[section].rows[row].options.index(where: {$0.text == NotificationsOptions.off.rawValue})!
                cellToModify.selectedOption = tableViewDataSource[section].rows[row].options[index]
            }
            else if eventNotificationsConfig.isCustom {
                let index = tableViewDataSource[section].rows[row].options.index(where: {$0.text == NotificationsOptions.custom.rawValue})!
                cellToModify.selectedOption = tableViewDataSource[section].rows[row].options[index]
            }
            else {
                let index = tableViewDataSource[section].rows[row].options.index(where: {$0.text == NotificationsOptions._default.rawValue})!
                cellToModify.selectedOption = tableViewDataSource[section].rows[row].options[index]
            }
        }
    }
    
    //
    // MARK: EMContentExpandableMaterialManagerDelegate
    func shouldSelectMaterial(_ material: EMContentExpandableMaterial) -> Bool {
        if material == inputInfoMaterial {currentInputViewState = nextInput}
        else if material == configureEventMaterial {currentInputViewState = .configure}
        else {os_log("Unexpected material encountered!", log: .default, type: .error)}
        return false
    }
    
    func shouldColapseMaterial(_ material: EMContentExpandableMaterial) -> Bool {
        currentInputViewState = .none
        return true
    }
    
    
    //
    // MARK: - Data Source Methods
    //
    
    //
    // MARK: Table View Data Source
    struct StaticData {
        struct Text {
            struct SectionTitles {
                static let section1: String? = nil
            }
            struct RowTitles {
                static let repeats = "Repeats"
                static let timerDisplayMode = "Timer Display Mode"
                static let infoDiplayed = "Info Displayed"
                static let toggleMask = "Toggle Mask"
                static let notifications = "Notifications"
            }
        }
        
        struct Options {
            struct Repeats {
                static let never = SettingsTypeDataSource.Option(text: RepeatingOptions.never.rawValue, action: nil)
                static let monthly = SettingsTypeDataSource.Option(text: RepeatingOptions.monthly.rawValue, action: nil)
                static let yearly = SettingsTypeDataSource.Option(text: RepeatingOptions.yearly.rawValue, action: nil)
            }
            struct TimerDisplayMode {
                static let detailed = SettingsTypeDataSource.Option(text: "Detailed", action: nil)
                static let abridged = SettingsTypeDataSource.Option(text: "Abridged", action: nil)
            }
            struct InfoDisplayed {
                static let none = SettingsTypeDataSource.Option(text: DisplayInfoOptions.none.rawValue, action: nil)
                static let tagline = SettingsTypeDataSource.Option(text: DisplayInfoOptions.tagline.rawValue, action: nil)
                static let date = SettingsTypeDataSource.Option(text: DisplayInfoOptions.date.rawValue, action: nil)
            }
            struct UseMask {
                static let on = SettingsTypeDataSource.Option(text: ToggleMaskOptions.on.rawValue, action: nil)
                static let off = SettingsTypeDataSource.Option(text: ToggleMaskOptions.off.rawValue, action: nil)
            }
            struct Notifications {
                static let _default = SettingsTypeDataSource.Option(text: NotificationsOptions._default.rawValue, action: nil)
                static let custom = SettingsTypeDataSource.Option(text: NotificationsOptions.custom.rawValue, action: nil)
                static let off = SettingsTypeDataSource.Option(text: NotificationsOptions.off.rawValue, action: nil)
            }
        }
    }
    
    var tableViewDataSource: SettingsTypeDataSource {
        let dataSource = SettingsTypeDataSource()
        
        // Section 1
        let s1 = dataSource.addSection(title: StaticData.Text.SectionTitles.section1)
        
        let s1r1 = dataSource[s1].addRow(type: .selectOption, title: StaticData.Text.RowTitles.repeats)
        dataSource[s1].rows[s1r1].options.append(StaticData.Options.Repeats.never)
        dataSource[s1].rows[s1r1].options.append(StaticData.Options.Repeats.monthly)
        dataSource[s1].rows[s1r1].options.append(StaticData.Options.Repeats.yearly)
        
        let s1r2 = dataSource[s1].addRow(type: .selectOption, title: StaticData.Text.RowTitles.timerDisplayMode)
        dataSource[s1].rows[s1r2].options.append(StaticData.Options.TimerDisplayMode.detailed)
        dataSource[s1].rows[s1r2].options.append(StaticData.Options.TimerDisplayMode.abridged)
        
        let s1r3 = dataSource[s1].addRow(type: .selectOption, title: StaticData.Text.RowTitles.infoDiplayed)
        dataSource[s1].rows[s1r3].options.append(StaticData.Options.InfoDisplayed.tagline)
        dataSource[s1].rows[s1r3].options.append(StaticData.Options.InfoDisplayed.date)
        dataSource[s1].rows[s1r3].options.append(StaticData.Options.InfoDisplayed.none)
        
        if let appImage = selectedImage as? AppEventImage, appImage.maskImage != nil {
            let s1r4 = dataSource[s1].addRow(type: .onOrOff, title: StaticData.Text.RowTitles.toggleMask)
            dataSource[s1].rows[s1r4].options.append(StaticData.Options.UseMask.on)
            dataSource[s1].rows[s1r4].options.append(StaticData.Options.UseMask.off)
        }
        
        let s1r5 = dataSource[s1].addRow(type: .segue, title: StaticData.Text.RowTitles.notifications)
        dataSource[s1].rows[s1r5].options.append(StaticData.Options.Notifications._default)
        dataSource[s1].rows[s1r5].options.append(StaticData.Options.Notifications.custom)
        dataSource[s1].rows[s1r5].options.append(StaticData.Options.Notifications.off)
        
        return dataSource
    }
    
    struct ReuseIdentifiers {
        static let titleDetail = "Title/Detail"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if configureCellInputViewTableViewHeightConstraint.constant != configureCellInputViewTableView.contentSize.height {
            configureCellInputViewTableViewHeightConstraint.constant = configureCellInputViewTableView.contentSize.height
            configureCellInputViewTableViewWidthConstraint.constant = view.bounds.width - 40.0 - standardDirectionalLayoutMargins.leading - standardDirectionalLayoutMargins.trailing
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
        return tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDataSource[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let options = tableViewDataSource[indexPath.section].rows[indexPath.row].options
        if let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            switch cell.rowType {
            case .selectOption:
                if options.count > 2 {
                    if expandedCellIndexPath != indexPath {expandedCellIndexPath = indexPath}
                    else {expandedCellIndexPath = nil}
                }
                else {expandedCellIndexPath = nil; cell.selectNextOption()}
            case .segue:
                performSegue(withIdentifier: "Configure Notifications", sender: self)
            case .action, .onOrOff:
                os_log("SettingsTableViewCell .onOrOff rowType is not implemented, yet it was selected!", log: .default, type: .error)
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if let selectedIP = expandedCellIndexPath, indexPath == selectedIP {
                return SettingsTableViewCell.expandedHeight
            }
            else {return SettingsTableViewCell.collapsedHeight}
        }
        else {
            os_log("Unexpected tableView section encountered! Using a default cell height", log: .default, type: .error)
            return 60.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableViewDataSource[section].title != nil {return 50.0} else {return 0.0}
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = tableViewDataSource[section].title {return titleOnlyHeaderView(title: title)} else {return nil}
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
            headerView.textLabel!.textColor = GlobalColors.orangeRegular
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowData = tableViewDataSource[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.titleDetail) as! SettingsTableViewCell
        cell.selectionStyle = .none
        cell.optionsPickerView.dataSource = cell
        cell.optionsPickerView.delegate = cell
        cell.rowType = rowData.type
        if cell.onOffSwitch.allTargets.isEmpty {
            cell.onOffSwitch.addTarget(self, action: #selector(cellSwitchFlipped(_:)), for: .valueChanged)
        }
        cell.optionsPickerView.backgroundColor = GlobalColors.lightGrayForFills
        cell.optionsPickerView.layer.cornerRadius = GlobalCornerRadii.material
        cell.title = rowData.title
        cell.options = rowData.options
        cell.delegate = self
        
        switch rowData.type {
        case .action: break
        case .onOrOff, .segue, .selectOption:
            switch rowData.title {
            case StaticData.Text.RowTitles.repeats:
                cell.selectedOption = rowData.options[rowData.options.index(where: {$0.text == repeats.rawValue})!]
            case StaticData.Text.RowTitles.timerDisplayMode:
                if abridgedDisplayMode {cell.selectedOption = rowData.options[1]}
                else {cell.selectedOption = rowData.options[0]}
            case StaticData.Text.RowTitles.infoDiplayed:
                cell.selectedOption = rowData.options[rowData.options.index(where: {$0.text == infoDisplayed.rawValue})!]
            case StaticData.Text.RowTitles.toggleMask:
                cell.selectedOption = useMask ? rowData.options[0] : rowData.options[1]
            case StaticData.Text.RowTitles.notifications:
                if let config = specialEvent?.notificationsConfig {
                    if config.eventNotificationsOn {
                        if config.isCustom {cell.selectedOption = rowData.options[1]}
                        else {cell.selectedOption = rowData.options[0]}
                    }
                    else {cell.selectedOption = rowData.options[2]}
                }
                else {cell.selectedOption = rowData.options[0]}
            default:
                os_log("Unexepcted row title encountered!", log: .default, type: .error)
                break
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableViewDataSource[indexPath.section].rows.count - 1 {
            if configureCellInputViewTableViewHeightConstraint.constant != configureCellInputViewTableView.contentSize.height {
                configureCellInputViewTableViewHeightConstraint.constant = configureCellInputViewTableView.contentSize.height
                configureCellInputViewTableViewWidthConstraint.constant = view.bounds.width - 40.0 - standardDirectionalLayoutMargins.leading - standardDirectionalLayoutMargins.trailing
                configureEventMaterialManagerView?.invalidateIntrinsicContentSize()
                view.setNeedsLayout()
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: .curveEaseInOut,
                    animations: {self.view.layoutIfNeeded()},
                    completion: nil
                )
            }
        }
    }
    
    //
    // Picker View
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectableCategories.count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var _viewToReturn = view as? UILabel
        if _viewToReturn == nil {
            _viewToReturn = UILabel()
            if pickerView == categoryInputViewPickerView {_viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayLight, size: 20.0)}
            else {_viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)}
            _viewToReturn!.textColor = GlobalColors.cyanRegular
            _viewToReturn!.textAlignment = .center
        }
        let viewToReturn = _viewToReturn!
        viewToReturn.text = selectableCategories[row]
        return viewToReturn
    }
    
    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let ident = segue.identifier {
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
                destination.loadedUserMoments = loadedUserMoments
                destination.loadedUserAlbums = loadedUserAlbums
                destination.momentsPhotoAssets = momentsPhotoAssets
                destination.albumsPhotoAssets = albumsPhotoAssets
                destination.userPhotosImageManager = userPhotosImageManager
                destination.networkState = currentNetworkState
                destination.momentsAssetFetchComplete = momentsAssetFetchComplete
                destination.albumsAssetFetchComplete = albumsAssetFetchComplete
                selectImageController = destination
            case "Configure Notifications":
                let destination = segue.destination as! ConfigureNotificationsTableViewController
                destination.modifiedEventNotifications = eventNotificationsConfig.eventNotifications
                destination.configuring = .eventReminders
                destination.segueFrom = .individualEvent
                destination.globalToggleOn = eventNotificationsConfig.eventNotificationsOn
                destination.useCustomNotifications = eventNotificationsConfig.isCustom
                destination.dateOnly = eventDate!.dateOnly
            case "Unwind To Master": break
            default:
                os_log("Unhandled segue: %@", log: .default, type: .error, ident)
                break
            }
        }
    }

    
    //
    // MARK: - Target-Action Methods
    //
    
    @objc fileprivate func handleTapsInCell(_ sender: UIGestureRecognizer) {
        
        if sender.view! == specialEventView {
            if specialEventView!.titleLabel.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .title
            }
            else if specialEventView!.taglineLabel.frame.contains(sender.location(in: specialEventView!)) {
                if currentInputViewState == .tagline {
                    switch infoDisplayed {
                    case .tagline: infoDisplayed = .date
                    case .date: infoDisplayed = .tagline
                    case .none: break
                    }
                    let row = tableViewDataSource[0].rows.index(where: {$0.title == StaticData.Text.RowTitles.infoDiplayed})!
                    configureCellInputViewTableView.beginUpdates()
                    configureCellInputViewTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                    configureCellInputViewTableView.endUpdates()
                }
                else {currentInputViewState = .tagline}
            }
            else if specialEventView!.timerContainerView.frame.contains(sender.location(in: specialEventView!)) || specialEventView!.abridgedTimerContainerView.frame.contains(sender.location(in: specialEventView!)) {
                if currentInputViewState == .date {
                    abridgedDisplayMode = !abridgedDisplayMode
                    let row = tableViewDataSource[0].rows.index(where: {$0.title == StaticData.Text.RowTitles.timerDisplayMode})!
                    configureCellInputViewTableView.beginUpdates()
                    configureCellInputViewTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                    configureCellInputViewTableView.endUpdates()
                }
                else {currentInputViewState = .date}
            }
            else if specialEventView!.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .image
            }
        }
        else if sender.view! == categoryLabel {currentInputViewState = .category}
    }
    
    @objc fileprivate func changeDatePickerToDate() {
        if dateInputView.datePicker.datePickerMode != .date {
            let fadeDuration = 0.15
            let fadeOutAnim = UIViewPropertyAnimator(duration: fadeDuration, curve: .linear) { [weak self] in
                self!.dateInputView.datePicker.layer.opacity = 0.0
                self!.dateInputView.allDayButton.layer.opacity = 0.0
            }
            let fadeInAnim = UIViewPropertyAnimator(duration: fadeDuration, curve: .linear) { [weak self] in
                self!.dateInputView.datePicker.layer.opacity = 1.0
            }
            
            fadeOutAnim.addCompletion { [weak self] (position) in
                self!.dateInputView.allDayButton.isHidden = true
                self!.dateInputView.datePicker.datePickerMode = .date
                self!.dateInputView.datePicker.date = self!.eventDate!.date
                fadeInAnim.startAnimation()
            }
            
            fadeOutAnim.startAnimation()
            dateInputView.dateButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
            dateInputView.dateButton.setTitleColor(UIColor.green, for: .normal)
            dateInputView.timeButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
            dateInputView.timeButton.setTitleColor(GlobalColors.cyanRegular, for: .normal)
        }
    }
    
    @objc fileprivate func changeDatePickerToTime() {
        if dateInputView.datePicker.datePickerMode != .time {
            let fadeDuration = 0.15
            let fadeOutAnim = UIViewPropertyAnimator(duration: fadeDuration, curve: .linear) { [weak self] in
                self!.dateInputView.datePicker.layer.opacity = 0.0
            }
            let fadeInAnim = UIViewPropertyAnimator(duration: fadeDuration, curve: .linear) { [weak self] in
                self!.dateInputView.datePicker.layer.opacity = 1.0
                self!.dateInputView.allDayButton.isHidden = false
                self!.dateInputView.allDayButton.layer.opacity = 1.0
            }
            
            fadeOutAnim.addCompletion { [weak self] (position) in
                self!.dateInputView.allDayButton.layer.opacity = 0.0
                self!.dateInputView.allDayButton.isHidden = false
                self!.dateInputView.datePicker.datePickerMode = .time
                
                if self!.eventDate!.dateOnly {
                    var components = DateComponents()
                    components.year = self!.currentCalendar.component(.year, from: self!.eventDate!.date)
                    components.month = self!.currentCalendar.component(.month, from: self!.eventDate!.date)
                    components.day = self!.currentCalendar.component(.day, from: self!.eventDate!.date)
                    components.hour = 12
                    components.minute = 0
                    components.second = 0
                    self!.isUserChange = true
                    self!.eventDate = EventDate(date: self!.currentCalendar.date(from: components)!, dateOnly: false)
                    self!.abridgedDisplayMode = false
                }
                
                self!.dateInputView.datePicker.date = self!.eventDate!.date
                
                fadeInAnim.startAnimation()
            }
            
            fadeOutAnim.startAnimation()
            
            dateInputView.timeButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
            dateInputView.timeButton.setTitleColor(UIColor.green, for: .normal)
            dateInputView.dateButton.titleLabel?.layer.add(GlobalAnimations.labelTransition, forKey: nil)
            dateInputView.dateButton.setTitleColor(GlobalColors.cyanRegular, for: .normal)
        }
    }
    
    @objc fileprivate func allDayButtonTapped() {
        if !eventDate!.dateOnly {
            var components = currentCalendar.dateComponents(calendarComponentsOfInterest, from: eventDate!.date)
            components.hour = 0; components.minute = 0; components.second = 0
            isUserChange = true
            eventDate = EventDate(date: currentCalendar.date(from: components)!, dateOnly: true)
            changeDatePickerToDate()
        }
    }
    
    @objc fileprivate func finish(_ sender: UIButton) {
        
        guard eventTitle != nil && eventDate != nil && selectedImage != nil else {
            os_log("finish method invoked even though title, date, or image were nil.", log: .default, type: .error)
            let alert = UIAlertController(title: "Missing Information", message: "Please populate the event title, date, and image.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Okay", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if let config = specialEvent?.notificationsConfig {
            var uuidsToDeschedule = [String]()
            for oldNotif in config.eventNotifications {uuidsToDeschedule.append(oldNotif.uuid)}
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: uuidsToDeschedule)
        }
        
        if needNewObject {
            let titlePredicate = NSPredicate(format: "title = %@", argumentArray: [eventTitle!])
            let existingEvent = mainRealm.objects(SpecialEvent.self).filter(titlePredicate)
            guard existingEvent.isEmpty else {
                let alert = UIAlertController(title: "Event Already Exists", message: "An event with this title already exists. Did you want to replace that event with this one?", preferredStyle: .alert)
                let yesAction = UIAlertAction(title: "Yes please!", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                    
                    self.createNewObject(overwrite: true)
                    scheduleNewEvents(titled: [self.eventTitle!])
                    updateDailyNotifications(async: true, updatePending: false)
                    self.performSegue(withIdentifier: "Unwind To Master", sender: self)
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
            specialEvent!.cascadeDelete()
            try! mainRealm.write {
                specialEvent!.category = eventCategory ?? "Uncatagorized"
                specialEvent!.tagline = eventTagline
                specialEvent!.date = eventDate!
                specialEvent!.abridgedDisplayMode = abridgedDisplayMode
                specialEvent!.infoDisplayed = infoDisplayed.rawValue
                specialEvent!.repeats = repeats.rawValue
                specialEvent!.notificationsConfig = RealmEventNotificationConfig(fromEventNotificationConfig: eventNotificationsConfig)
                
                specialEvent!.useMask = useMask
                if let _selectedImage = selectedImage {
                    if specialEvent?.image == nil || specialEvent!.image!.title != _selectedImage.title {
                        let image = getEventImageInfo()
                        specialEvent!.image = image
                    }
                }
                else {specialEvent!.image = nil}
                if let _locationForCellView = locationForCellView {
                    specialEvent!.locationForCellView.value = Int(_locationForCellView * 100.0)
                }
            }
        }
        
        scheduleNewEvents(titled: [eventTitle!])
        updateDailyNotifications(async: true, updatePending: false)
        performSegue(withIdentifier: "Unwind To Master", sender: self)
    }
    
    @objc fileprivate func selectNextInput() {if currentInputViewState != nextInput {currentInputViewState = nextInput}}
    @objc fileprivate func colapseKeyboard() {currentInputViewState = .none}

    @objc fileprivate func dismissKeyboard() {
        textInputAccessoryView?.textInputField.resignFirstResponder()
        textInputAccessoryView?.isHidden = true
        textInputAccessoryView?.textInputField.text = nil
    }
    
    @objc fileprivate func cancel() {self.dismiss(animated: true, completion: nil)}

    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func showImageNilLabel(animated: Bool = true) {
        
        imageNilLabel.layer.opacity = 0.0
        if !specialEventView!.subviews.contains(imageNilLabel) {
            specialEventView!.addSubview(imageNilLabel)
            imageNilLabel.leftAnchor.constraint(equalTo: specialEventView!.leftAnchor, constant: (2/3) * specialEventView.bounds.width).isActive = true
            imageNilLabel.topAnchor.constraint(equalTo: specialEventView!.topAnchor, constant: (1/3) * globalCellHeight).isActive = true
        }
        else {imageNilLabel.isHidden = false; imageNilLabel.isUserInteractionEnabled = true}
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.30,
                delay: 0.0,
                options: .curveLinear,
                animations: { [weak self] in
                    self?.specialEventView!.viewWithMargins.layer.backgroundColor = GlobalColors.lightGrayForFills.cgColor
                    self?.imageNilLabel.layer.opacity = 1.0
                },
                completion: nil
            )
        }
        else {
            specialEventView!.viewWithMargins.layer.backgroundColor = GlobalColors.lightGrayForFills.cgColor
            imageNilLabel.layer.opacity = 1.0
        }
    }
    
    fileprivate func hideImageNilLabel(animated: Bool = true) {
        if specialEventView!.subviews.contains(imageNilLabel) && !imageNilLabel.isHidden {
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.30,
                    delay: 0.0,
                    options: .curveLinear,
                    animations: { [weak self] in
                        self?.specialEventView!.viewWithMargins.layer.backgroundColor = UIColor.black.cgColor
                        self?.imageNilLabel.layer.opacity = 0.0
                    },
                    completion: { [weak self] (position) in
                        self?.imageNilLabel.isHidden = true
                        self?.imageNilLabel.isUserInteractionEnabled = false
                    }
                )
            }
            else {
                specialEventView!.viewWithMargins.layer.backgroundColor = UIColor.black.cgColor
                imageNilLabel.isHidden = true
                imageNilLabel.isUserInteractionEnabled = false
            }
        }
    }
    
    fileprivate func formatHighlight(label: UILabel) {
        label.layer.add(GlobalAnimations.labelTransition, forKey: nil)
        label.textColor = UIColor.green
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
    
    fileprivate func transitionViews(fromState state1: Inputs, toState state2: Inputs) {
        
        func commonToMaterial() {
            switch state2 {
            case .category: inputInfoMaterial.expandedViewContent = categoryInputView
            case .date: inputInfoMaterial.expandedViewContent = dateInputView
            default: break
            }
            mainScrollViewContentView.setNeedsLayout()
            let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                self.inputInfoMaterialManagerView.select(material: self.inputInfoMaterial, animated: false)
                self.configureEventMaterialManagerView?.deselectSelectedMaterial(animated: false)
                self.mainScrollViewContentView.layoutIfNeeded()
            }
            let contentFadeInAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.inputInfoMaterial.expandedViewContent?.layer.opacity = 1.0}
            
            materialAnim.addCompletion { (position) in
                contentFadeInAnim.startAnimation()
                let bottomOfMaterial = self.inputInfoMaterialManagerView.convert(self.inputInfoMaterial.frame.origin, to: self.mainScrollView).y + self.inputInfoMaterial.frame.height
                let diff = bottomOfMaterial - self.mainScrollView.bounds.height
                if diff > 0.0 {
                    let contentMoveAnim = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {self.mainScrollView.contentOffset.y += diff}
                    contentMoveAnim.startAnimation()
                }
            }
            materialAnim.startAnimation()
        }
        
        func commonToText() {
            if state2 == .title {
                textInputAccessoryView?.currentInputTitleLabel.text = "Title"
                textInputAccessoryView?.textInputField.autocapitalizationType = .words
                textInputAccessoryView?.textInputField.text = eventTitle
            }
            else {
                textInputAccessoryView?.currentInputTitleLabel.text = "Tagline"
                textInputAccessoryView?.textInputField.autocapitalizationType = .sentences
                textInputAccessoryView?.textInputField.text = eventTagline
            }
        }
        
        func materialToMaterial() {
            if state2 == .configure {
                mainScrollViewContentView.setNeedsLayout()
                let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                    self.configureEventMaterialManagerView?.select(material: self.configureEventMaterial!, animated: false)
                    self.inputInfoMaterialManagerView.deselectSelectedMaterial(animated: false)
                    self.mainScrollViewContentView.layoutIfNeeded()
                }
                let contentFadeInAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.configureEventMaterial?.expandedViewContent?.layer.opacity = 1.0}
                
                materialAnim.addCompletion { (position) in
                    contentFadeInAnim.startAnimation()
                    let bottomOfMaterial = self.configureEventMaterialManagerView!.convert(self.configureEventMaterial!.frame.origin, to: self.mainScrollView).y + self.inputInfoMaterial.frame.height
                    let diff = bottomOfMaterial - self.mainScrollView.bounds.height
                    if diff > 0.0 {
                        let contentMoveAnim = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {self.mainScrollView.contentOffset.y += diff}
                        contentMoveAnim.startAnimation()
                    }
                }
                materialAnim.startAnimation()
            }
            else if state1 == .configure {commonToMaterial()}
            else {
                let fadeOutAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.inputInfoMaterial.expandedViewContent?.layer.opacity = 0.0}
                fadeOutAnim.addCompletion { (position) in commonToMaterial()}
                
                fadeOutAnim.startAnimation()
            }
        }
        
        func materialToText() {
            mainScrollViewContentView.setNeedsLayout()
            let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                self.inputInfoMaterialManagerView.deselectSelectedMaterial(animated: false)
                self.mainScrollViewContentView.layoutIfNeeded()
            }
            materialAnim.startAnimation()
            commonToText()
            //eventViewAnimateForKeyboardIn()
            textInputAccessoryView?.textInputField.becomeFirstResponder()
            textInputAccessoryView?.isHidden = false
            textInputAccessoryView?.isUserInteractionEnabled = true
        }
        
        func textToMaterial() {
            textInputAccessoryView?.textInputField.resignFirstResponder()
            textInputAccessoryView?.isHidden = true
            textInputAccessoryView?.textInputField.text = nil
            commonToMaterial()
        }
        
        func textToText() {
            textInputAccessoryView.currentInputTitleLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
            commonToText()
        }
        
        func closeLast() {
            switch state1 {
            case .date, .category:
                let contentFadeOutAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.inputInfoMaterial.expandedViewContent?.layer.opacity = 0.0}
                let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                    self.inputInfoMaterialManagerView.deselectSelectedMaterial(animated: false)
                    self.mainScrollViewContentView.layoutIfNeeded()
                    self.updateInfoInputMaterialTitle()
                }
                
                contentFadeOutAnim.addCompletion { (position) in
                    self.mainScrollViewContentView.setNeedsLayout()
                    materialAnim.startAnimation()
                }
                contentFadeOutAnim.startAnimation()
            case .configure:
                let contentFadeOutAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.configureEventMaterial?.expandedViewContent?.layer.opacity = 0.0}
                let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                    self.configureEventMaterialManagerView?.deselectSelectedMaterial(animated: false)
                    self.mainScrollViewContentView.layoutIfNeeded()
                    self.updateInfoInputMaterialTitle()
                }
                
                contentFadeOutAnim.addCompletion { (position) in
                    self.mainScrollViewContentView.setNeedsLayout()
                    materialAnim.startAnimation()
                }
                contentFadeOutAnim.startAnimation()
            case .title, .tagline:
                textInputAccessoryView?.textInputField.resignFirstResponder()
                textInputAccessoryView?.isHidden = true
                textInputAccessoryView?.textInputField.text = nil
            case .image, .none: break
            }
        }
        
        func openNext() {
            switch state2 {
            case .category, .date: commonToMaterial(); updateInfoInputMaterialTitle()
            case .configure:
                mainScrollViewContentView.setNeedsLayout()
                let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {
                    self.configureEventMaterialManagerView?.select(material: self.configureEventMaterial!, animated: false)
                    self.mainScrollViewContentView.layoutIfNeeded()
                }
                let scrollAnim = UIViewPropertyAnimator(duration: 0.15, curve: .easeInOut) {
                    let bottomOfMaterial = self.configureEventMaterialManagerView!.convert(self.configureEventMaterial!.frame.origin, to: self.mainScrollView).y + self.configureEventMaterial!.frame.height
                    let diff = bottomOfMaterial - self.mainScrollView.bounds.height
                    if diff > 0.0 {self.mainScrollView.contentOffset.y += diff}
                }
                let contentFadeInAnim = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {self.configureEventMaterial?.expandedViewContent?.layer.opacity = 1.0}
                
                materialAnim.addCompletion { (position) in
                    contentFadeInAnim.startAnimation()
                    scrollAnim.startAnimation()
                }
                materialAnim.startAnimation()
            case .title, .tagline:
                commonToText()
                textInputAccessoryView?.textInputField.becomeFirstResponder()
                textInputAccessoryView?.isHidden = false
                textInputAccessoryView?.isUserInteractionEnabled = true
            case .image: performSegue(withIdentifier: "Choose Image", sender: self); currentInputViewState = .none
            case .none: break
            }
        }
        
        switch state1 {
        case .category, .date, .configure:
            switch state2 {
            case .category: materialToMaterial(); updateInfoInputMaterialTitle()
            case .date: materialToMaterial(); updateInfoInputMaterialTitle()
            case .title: materialToText(); updateInfoInputMaterialTitle()
            case .tagline: materialToText(); updateInfoInputMaterialTitle()
            case .configure: materialToMaterial(); updateInfoInputMaterialTitle()
            case .image:
                performSegue(withIdentifier: "Choose Image", sender: self)
                closeLast()
                updateInfoInputMaterialTitle()
                currentInputViewState = .none
            case .none: closeLast()
            }
        case .title, .tagline:
            switch state2 {
            case .category: textToMaterial(); updateInfoInputMaterialTitle()
            case .date: textToMaterial(); updateInfoInputMaterialTitle()
            case .title: textToText(); updateInfoInputMaterialTitle()
            case .tagline: textToText(); updateInfoInputMaterialTitle()
            case .configure: textToMaterial(); updateInfoInputMaterialTitle()
            case .image:
                performSegue(withIdentifier: "Choose Image", sender: self)
                closeLast()
                updateInfoInputMaterialTitle()
                currentInputViewState = .none
            case .none: closeLast(); updateInfoInputMaterialTitle()
            }
        case .image, .none: openNext()
        }
    }
    
    /*fileprivate func fadeIn(view: UIView) {
        view.isHidden = false
        view.isUserInteractionEnabled = true
        
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.3,
            delay: 0.0,
            options: [.curveLinear],
            animations: {view.layer.opacity = 1.0},
            completion: nil
        )
    }*/
    
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
    
    //
    // MARK: Cloud helpers
    
    fileprivate func fetchLocalImages() {
        
        let filterPredicate = NSPredicate(format: "isAppImage = %@", argumentArray: [true])
        localImageInfo = mainRealm.objects(EventImageInfo.self).filter(filterPredicate)
        
        var imagesToReturn = [AppEventImage]()
        
        for imageInfo in localImageInfo {
            if !cachedImages.contains(where: {$0.title == imageInfo.title}) {
                if let newEventImage = AppEventImage(fromEventImageInfo: imageInfo) {
                    imagesToReturn.append(newEventImage)
                }
                else {
                    os_log("Unable to locate %@'s thumbnail image on the disk!", log: .default, type: .error, imageInfo.title)
                }
            }
        }
        cachedImages.append(contentsOf: imagesToReturn)
    }
    
    /*fileprivate func fetchProductIDs(_ previousNetworkFetchAtempts: Int = 0, fetchFailHandler completion: @escaping (_ error: NSError) -> Void) {
        
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
    }*/
    
    /*fileprivate func cloudFetch(_ previousNetworkFetchAtempts: Int = 0, imageTypes: [CountdownImage.ImageType], forImage title: String, completionHandler completion: @escaping (_ eventImage: AppEventImage?, _ error: AssetFetchErrors?) -> Void) {
        
        let getImageTitledPredicate = NSPredicate(format: "title = %@", argumentArray: [title])
        let eventImageQuerry = CKQuery(recordType: "EventImage", predicate: getImageTitledPredicate)
        let queryOperation = CKQueryOperation(query: eventImageQuerry)
        
        var desiredKeys = [String]()
        for imageType in imageTypes {desiredKeys.append(contentsOf: [imageType.recordKey, imageType.extensionRecordKey])}
        queryOperation.desiredKeys = desiredKeys
        
        func queryCompletionBlock(_ weakSelf: NewEventViewController?, _ _cursor: CKQueryCursor?, _ error: Error?) {
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
                    if previousNetworkFetchAtempts <= 1 {weakSelf?.cloudFetch(previousNetworkFetchAtempts + 1, imageTypes: imageTypes, forImage: title, completionHandler: completion); return}
                    else {return}
                case 3: return
                default: return
                }
            }
            
            if let cursor = _cursor {
                let newQuerryOperation = CKQueryOperation(cursor: cursor)
                newQuerryOperation.desiredKeys = desiredKeys
                newQuerryOperation.queryCompletionBlock = { [weak self] (cursor, error) in queryCompletionBlock(self, cursor, error)}
                newQuerryOperation.recordFetchedBlock = recordFetchedBlock
                weakSelf?.publicCloudDatabase.add(newQuerryOperation)
            }
        }
        
        func recordFetchedBlock(_ record: CKRecord) {
            var images = [CountdownImage]()
            for imageType in imageTypes {
                if let imageAsset = record[imageType.recordKey] as? CKAsset {
                    let imageFileExtension = record[imageType.extensionRecordKey] as! String
                    
                    do {
                        let imageData = try Data(contentsOf: imageAsset.fileURL)
                        let newImage = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: imageFileExtension, imageData: imageData)
                        images.append(newImage)
                    }
                    catch {completion(nil, .imageCreationFailure); return}
                }
                else {completion(nil, .imageCreationFailure); return}
            }
            
            if let newEventImage = AppEventImage(category: category, title: title, recordName: recordID.recordName, recommendedLocationForCellView: locationForCellView, images: images) {
                completion(newEventImage, nil)
            }
            else {completion(nil, .assetCreationFailure)}
        }
        
        queryOperation.queryCompletionBlock = { [weak self] (cursor, error) in queryCompletionBlock(self, cursor, error)}
        queryOperation.recordFetchedBlock = recordFetchedBlock
        publicCloudDatabase.add(queryOperation)
    }*/
    
    func reFetchCloudImages() {fetchCloudImages(imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))}
    
    fileprivate func fetchCloudImages(_ previousNetworkFetchAtempts: Int = 0, imageTypes: [CountdownImage.ImageType], completionHandler completion: @escaping (_ eventImage: AppEventImage?, _ error: AssetFetchErrors?) -> Void) {
        
        let getAllPredicate = NSPredicate(value: true)
        let eventImageQuerry = CKQuery(recordType: "EventImage", predicate: getAllPredicate)
        let queryOperation = CKQueryOperation(query: eventImageQuerry)
        
        var desiredKeys = [
            AppEventImage.CloudKitKeys.EventImageKeys.title,
            AppEventImage.CloudKitKeys.EventImageKeys.fileRootName,
            AppEventImage.CloudKitKeys.EventImageKeys.category,
            AppEventImage.CloudKitKeys.EventImageKeys.locationForCellView
            ]
        for imageType in imageTypes {
            desiredKeys.append(contentsOf: [imageType.recordKey, imageType.extensionRecordKey])
        }
        queryOperation.desiredKeys = desiredKeys
        
        func queryCompletionBlock(_ weakSelf: NewEventViewController?, _ _cursor: CKQueryCursor?, _ error: Error?) {
            if let nsError = error as NSError? {
                switch nsError.code {
                // Error code 1: Internal error, couldn't send a valid signature. No recovery suggestions.
                // Error code 3: Network Unavailable.
                // Error code 4: CKErrorDoman, invalid server certificate. No recovery suggestions.
                // Error code 4097: Error connecting to cloudKitService. Recovery suggestion: Try your operation again. If that fails, quit and relaunch the application and try again.
                case 1, 4, 4097:
                    if previousNetworkFetchAtempts <= 1 {weakSelf?.fetchCloudImages(previousNetworkFetchAtempts + 1, imageTypes: imageTypes, completionHandler: completion); return}
                    else {weakSelf?.networkErrorHandler(nsError); return}
                case 3: weakSelf?.networkErrorHandler(nsError); return
                default:
                    os_log("There was an new error fetching products from CloudKit: %@", log: OSLog.default, type: .error, nsError.localizedDescription)
                    weakSelf?.networkErrorHandler(nsError)
                    return
                }
            }
            
            if let cursor = _cursor {
                let newQuerryOperation = CKQueryOperation(cursor: cursor)
                newQuerryOperation.desiredKeys = desiredKeys
                newQuerryOperation.queryCompletionBlock = { [weak self] (cursor, error) in queryCompletionBlock(self, cursor, error)}
                newQuerryOperation.recordFetchedBlock = recordFetchedBlock
                weakSelf?.publicCloudDatabase.add(newQuerryOperation)
            }
            else {DispatchQueue.main.async { [weak self] in self?.currentNetworkState = .complete}}
        }
        
        func recordFetchedBlock(_ record: CKRecord) {
            let recordID = record.recordID
            guard let title = record[AppEventImage.CloudKitKeys.EventImageKeys.title] as? String else {completion(nil, .assetCreationFailure); return}
            guard let fileRootName = record[AppEventImage.CloudKitKeys.EventImageKeys.fileRootName] as? String else {completion(nil, .assetCreationFailure); return}
            guard let category = record[AppEventImage.CloudKitKeys.EventImageKeys.category] as? String else {completion(nil, .assetCreationFailure); return}
            let intLocationForCellView = record[AppEventImage.CloudKitKeys.EventImageKeys.locationForCellView] as? Int
            var locationForCellView: CGFloat?
            if let intLoc = intLocationForCellView {locationForCellView = CGFloat(intLoc) / 100.0}
            
            var images = [CountdownImage]()
            for imageType in imageTypes {
                if let imageAsset = record[imageType.recordKey] as? CKAsset {
                    let imageFileExtension = record[imageType.extensionRecordKey] as! String
                    
                    do {
                        let imageData = try Data(contentsOf: imageAsset.fileURL)
                        let newImage = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: imageFileExtension, imageData: imageData)
                        images.append(newImage)
                    }
                    catch {completion(nil, .imageCreationFailure); return}
                }
                else {completion(nil, .imageCreationFailure); return}
            }
            
            if let newEventImage = AppEventImage(category: category, title: title, recordName: recordID.recordName, recommendedLocationForCellView: locationForCellView, images: images) {
                completion(newEventImage, nil)
            }
            else {completion(nil, .assetCreationFailure)}
        }
        
        queryOperation.queryCompletionBlock = { [weak self] (cursor, error) in queryCompletionBlock(self, cursor, error)}
        queryOperation.recordFetchedBlock = recordFetchedBlock
        publicCloudDatabase.add(queryOperation)
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
    
    fileprivate func thumbnailLoadComplete(_ _image: AppEventImage?, _ _error: AssetFetchErrors?) {
        if let error = _error {
            switch error {
            case .assetCreationFailure: os_log("There was an error creating the asset from the cloud", log: .default, type: .error)
            case .imageCreationFailure: os_log("There was an error creating the image from the cloud", log: .default, type: .error)
            case .noRecords: break
            }
        }
        else if let image = _image {
            DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.cachedImages.append(image)}
        }
    }
    
    //
    // MARK: User photos fetcher
    fileprivate func fetchUserPhotos() {
        let serialPhotosFetchQueue = DispatchQueue(label: "serialPhotosFetchQueue", qos: .utility)
        userPhotosImageManager = PHCachingImageManager()
        
        let dimension = (view.bounds.width - ((numberOfUserPhotoCellsPerColumn - 1) * userPhotosCellSpacing)) / numberOfUserPhotoCellsPerColumn
        let userPhotoCellSize = CGSize(width: dimension, height: dimension)
        
        func getPhotos() {
            let momentsFetchWorkItem = DispatchWorkItem { [weak self] in
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
                    self?.userPhotosImageManager?.startCachingImages(for: imagesToCache, targetSize: userPhotoCellSize, contentMode: .aspectFit, options: nil)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.momentsAssetFetchComplete = true
                    self?.momentsPhotoAssets = assets
                }
            }
            let albumsFetchWorkItem = DispatchWorkItem { [weak self] in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
                self?.loadedUserAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
                var assets = [PHFetchResult<PHAsset>]()
                self?.loadedUserAlbums?.enumerateObjects { [weak self] (collection, _, _) in
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", argumentArray: [PHAssetMediaType.image.rawValue])
                    fetchOptions.includeAllBurstAssets = false
                    let result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    assets.append(result)
                    var imagesToCache = [PHAsset]()
                    result.enumerateObjects { (asset, _, _) in imagesToCache.append(asset)}
                    self?.userPhotosImageManager?.startCachingImages(for: imagesToCache, targetSize: userPhotoCellSize, contentMode: .aspectFit, options: nil)
                }
                DispatchQueue.main.async { [weak self] in
                    self?.albumsAssetFetchComplete = true
                    self?.albumsPhotoAssets = assets
                }
            }
            serialPhotosFetchQueue.async(execute: momentsFetchWorkItem)
            serialPhotosFetchQueue.async(execute: albumsFetchWorkItem)
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined: PHPhotoLibrary.requestAuthorization { (status) in if status == .authorized {getPhotos()}}
        case .authorized: getPhotos()
        default: break
        }
    }
    
    //
    // MARK: Utility helpers
    
    fileprivate func getEventImageInfo() -> EventImageInfo? {
        if let image = selectedImage {
            if !image.imagesAreSavedToDisk {
                let imageTypes: [CountdownImage.ImageType] = [.main, .mask, .thumbnail]
                let results = image.saveToDisk(imageTypes: imageTypes)
                if let i = results.index(of: false) {
                    let type: String = {
                        switch imageTypes[i] {
                        case .main: return "main image"
                        case .mask: return "mask image"
                        case .thumbnail: return "thumbnail images"
                        }
                    }()
                    os_log("Failed to save %@ (at least) to disk!", log: .default, type: .error, type)
                }
            }
            if let appImage = image as? AppEventImage {
                if let i = localImageInfo.index(where: {$0.title == appImage.title}) {return localImageInfo[i]}
                else {return EventImageInfo(fromEventImage: appImage)}
            }
            else {
                let localUserImagesPredicate = NSPredicate(format: "isAppImage = %@", argumentArray: [false])
                let localUserImageInfos = mainRealm.objects(EventImageInfo.self).filter(localUserImagesPredicate)
                if let i = localUserImageInfos.index(where: {$0.title == image.title}) {
                    return localUserImageInfos[i]
                }
                else {return EventImageInfo(fromEventImage: image)}
            }
        }
        else {return nil}
    }
    
    fileprivate func createNewObject(overwrite: Bool) {
        if let _eventTitle = eventTitle, let _eventDate = eventDate {
            let realmNotificationsConfig = RealmEventNotificationConfig(fromEventNotificationConfig: eventNotificationsConfig)
            
            let imageInfo = getEventImageInfo()
            let newEvent = SpecialEvent(
                category: eventCategory ?? "Uncategorized",
                title: _eventTitle,
                tagline: eventTagline,
                date: _eventDate,
                abridgedDisplayMode: abridgedDisplayMode,
                infoDisplayed: infoDisplayed,
                repeats: repeats,
                notificationsConfig: realmNotificationsConfig,
                useMask: useMask,
                image: imageInfo,
                locationForCellView: locationForCellView
            )
            try! mainRealm.write {mainRealm.add(newEvent, update: overwrite)}
            #if DEBUG
            let specialEvents = mainRealm.objects(SpecialEvent.self)
            for event in specialEvents {print(event.title)}
            #endif
        }
    }
    
    fileprivate func checkFinishButtonEnable() {
        if eventTitle != nil && eventDate != nil && selectedImage != nil {presentWithDataViewIfNotPresent()}
        else {removeWithDataViewIfPresent()}
        
        mainScrollViewContentView.setNeedsLayout()
        let materialAnim = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) {self.mainScrollViewContentView.layoutIfNeeded()}
        materialAnim.startAnimation()
    }
    
    fileprivate func enableButton(_ button: UIButton) {
        button.isEnabled = true; button.layer.opacity = 1.0
    }
    
    fileprivate func disableButton(_ button: UIButton) {
        button.isEnabled = false; button.layer.opacity = 0.5
    }
    
    fileprivate func determineNextInput() {
        if eventTitle == nil {nextInput = .title}
        else if eventDate == nil {nextInput = .date}
        else if selectedImage == nil {nextInput = .image}
        else if eventCategory == nil {nextInput = .category}
        else if eventTagline == nil {nextInput = .tagline}
        else {nextInput = .none}
    }
    
    fileprivate func updateInfoInputMaterialTitle() {
        if inputInfoMaterialManagerView.currentlyExpandedMaterial != inputInfoMaterial {
            if nextInput == .none {
                if editingEvent {inputInfoMaterial.title = "Tap info in event to edit"}
                else {inputInfoMaterial.title = "All done!"}
                inputInfoMaterial.layer.borderWidth = 0.0
            }
            else {
                inputInfoMaterial.title = nextInput.rawValue
                inputInfoMaterial.layer.borderWidth = 1.0
            }
        }
        else {inputInfoMaterial.title = currentInputViewState.rawValue}
    }
    
}
