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

class NewEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, SKProductsRequestDelegate, CAAnimationDelegate, UITableViewDelegate, UITableViewDataSource, SettingsTableViewCellDelegate, EventTableViewCellDelegate {
    
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
                
                categoryInputViewLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                categoryInputViewLabel.text = eventCategory
                categoryInputViewLabel.textColor = GlobalColors.cyanRegular
            }
            else {
                categoryLabel.layer.add(GlobalAnimations.labelTransition, forKey: "transition")
                categoryLabel.text = Constants.InactiveCellTextTitles.category
                categoryLabel.font = Constants.Fonts.smallEmphasis
            }
            
            let row = DataSource.data[0].rows.index(where: {$0.rowType == .category})!
            optionsTableView.beginUpdates()
            optionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            optionsTableView.endUpdates()
            
            checkFinishButtonEnable()
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
            
            let row = DataSource.data[0].rows.index(where: {$0.rowType == .title})!
            optionsTableView.beginUpdates()
            optionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            optionsTableView.endUpdates()
            
            checkFinishButtonEnable()
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
            
            let row = DataSource.data[0].rows.index(where: {$0.rowType == .tagline})!
            optionsTableView.beginUpdates()
            optionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            optionsTableView.endUpdates()
            
            checkFinishButtonEnable()
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
            
            let row = DataSource.data[0].rows.index(where: {$0.rowType == .date})!
            optionsTableView.beginUpdates()
            optionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            optionsTableView.endUpdates()
            
            checkFinishButtonEnable()
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
                specialEventView?.setSelectedImage(image: image, locationForCellView: locationForCellView)
                imageTitleLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                imageTitleLabel.textColor = GlobalColors.orangeRegular
                enableButton(editImageButton)
                enableButton(useImageButton)
                enableButton(useMaskButton)
                
                if let appImage = selectedImage as? AppEventImage {imageTitleLabel.text = "\"\(appImage.title)\""}
                else {imageTitleLabel.text = Constants.defaultUserImageTitle}
                
                useImageButton.tintColor = UIColor.green
                if useMask {useMaskButton.tintColor = UIColor.green} else {useMaskButton.tintColor = GlobalColors.inactiveColor}
                
                if !isUserChange {currentInputViewState = .none}
            }
            else {
                specialEventView?.clearEventImage()
                showImageNilLabel()
                imageTitleLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                imageTitleLabel.text = noImageSelectedTextForTitle
                imageTitleLabel.textColor = GlobalColors.inactiveColor
                disableButton(editImageButton)
                if previousSelectedImage == nil {disableButton(useImageButton)}
                disableButton(useMaskButton)
                useImageButton.tintColor = GlobalColors.inactiveColor
                useMaskButton.tintColor = GlobalColors.inactiveColor
            }
            isUserChange = false
            
            let row = DataSource.data[0].rows.index(where: {$0.rowType == .image})!
            optionsTableView.beginUpdates()
            optionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            optionsTableView.endUpdates()
            
            checkFinishButtonEnable()
        }
    }
    
    var locationForCellView: CGFloat?
    
    fileprivate var previousSelectedImage: UserEventImage?
    
    var useMask = true {
        didSet {
            specialEventView!.useMask = useMask
            if useMask {useMaskButton.tintColor = UIColor.green} else {useMaskButton.tintColor = GlobalColors.inactiveColor}
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
    fileprivate var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var specialEventViewContainer: UIView!
    fileprivate var specialEventView: EventTableViewCell?
    
    fileprivate var textInputAccessoryView: TextInputAccessoryView?
    
    @IBOutlet weak var categoryLabel: UILabel!
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
    @IBOutlet weak var imageTitleLabel: UILabel!
    
    @IBOutlet weak var optionsTableView: UITableView!
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var dataInputView: UIView!
    
    @IBOutlet weak var currentInputLabel: UILabel!
    @IBOutlet weak var nextInputButton: UIButton!
    @IBOutlet weak var enterDataButton: UIButton!
    @IBOutlet weak var previousInputButton: UIButton!
    @IBOutlet weak var cancelDataButton: UIButton!
    
    @IBOutlet weak var optionsView: UIView!
    
    @IBOutlet weak var categoryInputViewLabel: UILabel!
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
    
    var masterViewController: MasterViewController?
    fileprivate var productRequest: SKProductsRequest?
    fileprivate var imagesForPurchace = [CKRecordID]() {
        didSet {
            if let _ = presentedViewController as? SelectImageViewController {
                fetchCloudImages(records: imagesForPurchace, imageTypes: [.thumbnail], completionHandler: thumbnailLoadComplete(_:_:))
            }
        }
    }
    
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
                case .none: break
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
                case .image:
                    oldDataValue = selectedImage
                    formatHighlight(label: imageNilLabel)
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
    
    var expandedCellIndexPath: IndexPath? {
        didSet {
            if expandedCellIndexPath != oldValue {
                if let _oldValue = oldValue, let oldCell = optionsTableView.cellForRow(at: _oldValue) as? SettingsTableViewCell {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {oldCell.optionsPickerView.layer.opacity = 0.0},
                        completion: {(position) in
                            oldCell.optionsPickerView.isHidden = true; oldCell.optionsPickerView.layer.opacity = 1.0
                        }
                    )
                }
                if let newValue = expandedCellIndexPath, let newCell = optionsTableView.cellForRow(at: newValue) as? SettingsTableViewCell {
                    newCell.optionsPickerView.layer.opacity = 0.0
                    newCell.optionsPickerView.isHidden = false
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {newCell.optionsPickerView.layer.opacity = 1.0},
                        completion: nil
                    )
                }
                optionsTableView.beginUpdates(); optionsTableView.endUpdates()
            }
        }
    }
    
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
                textInputAccessoryView!.nextInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
                textInputAccessoryView!.doneInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
                textInputAccessoryView!.cancelInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
                textInputAccessoryView!.previousInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
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
                specialEventView!.configuration = .cell
                specialEventView!.delegate = self
                
                specialEventView!.viewWithMargins.layer.cornerRadius = 3.0
                specialEventView!.viewWithMargins.layer.masksToBounds = true
                specialEventView!.viewWithMargins.layer.backgroundColor = GlobalColors.lightGrayForFills.cgColor
                
                let bottomAnchorConstraint = specialEventView!.constraints.first {$0.secondAnchor == specialEventView!.viewWithMargins.bottomAnchor}
                bottomAnchorConstraint!.isActive = false
                specialEventView!.bottomAnchor.constraint(equalTo: specialEventView!.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
            }
        }
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        optionsTableView.sectionHeaderHeight = 40.0
        let settingsRowNib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
        optionsTableView.register(settingsRowNib, forCellReuseIdentifier: DataSource.ReuseIdentifiers.section2)
        
        doneButton = UIBarButtonItem()
        doneButton.target = self
        doneButton.action = #selector(finish(_:))
        doneButton.tintColor = GlobalColors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
        doneButton.setTitleTextAttributes(attributes, for: .normal)
        doneButton.setTitleTextAttributes(attributes, for: .disabled)
        
        finishButton.layer.cornerRadius = GlobalCornerRadii.material
        
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

        setupGestureRecognizers()
        configureInputView()
        //configureOptionsView()
        
        if let categories = userDefaults.value(forKey: "Categories") as? [String] {
            for category in categories {
                if !immutableCategories.contains(category) {selectableCategories.append(category)}
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
        
        mainRealm = try! Realm(configuration: realmConfig)
        fetchLocalImages()
        defaultNotificationsConfig = mainRealm.objects(DefaultNotificationsConfig.self)
        
        if let event = specialEvent{
            needNewObject = false

            eventCategory = event.category
            eventTitle = event.title
            if let tagline = event.tagline {eventTagline = tagline}
            else {eventTagline = nil; specialEventView!.taglineLabel.textColor = GlobalColors.inactiveColor}
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
        
        fetchProductIDs(fetchFailHandler: networkErrorHandler)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if eventDate != nil && eventTimer == nil {
            specialEventView?.update()
            eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
            }
        }
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
            let imageCleanupRealm = try! Realm(configuration: realmConfig)
            let allImages = imageCleanupRealm.objects(EventImageInfo.self)
            for imageInfo in allImages {
                if imageInfo.specialEvents.isEmpty && imageInfo.isAppImage == false {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileName = imageInfo.title.convertToFileName()
                    let saveDest = documentsURL.appendingPathComponent(fileName + ".jpg", isDirectory: false)
                    imageInfo.cascadeDelete()
                    do {
                        try FileManager.default.removeItem(at: saveDest)
                        try imageCleanupRealm.write {imageCleanupRealm.delete(imageInfo)}
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
        let todaysDate = Date()
        let timeInterval = sender.date.timeIntervalSince(todaysDate)
        if timeInterval < 0.0 {repeats = .never}
        
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
        if let indexPath = optionsTableView.indexPath(for: cell), let selectedOption = cell.selectedOption {
            switch DataSource.data[indexPath.section].rows[indexPath.row].rowType {
            case .repeats:
                switch selectedOption.text {
                case RepeatingOptions.never.displayText: repeats = .never
                case RepeatingOptions.monthly.displayText: repeats = .monthly
                case RepeatingOptions.yearly.displayText: repeats = .yearly
                default:
                    // TODO: log an error
                    fatalError("Unexpected option encountered! Do you need to add a new one?")
                }
            case .timerDisplayMode:
                switch selectedOption {
                case DataSource.data[1].rows[1].options![0]: abridgedDisplayMode = false //Detailed
                case DataSource.data[1].rows[1].options![1]: abridgedDisplayMode = true //Abridged
                default:
                    // TODO: log an error
                    fatalError("Unexpected option encountered! Do you need to add a new one?")
                }
            case .infoDisplayed:
                switch selectedOption.text {
                case DisplayInfoOptions.none.displayText: infoDisplayed = .none
                case DisplayInfoOptions.tagline.displayText: infoDisplayed = .tagline
                case DisplayInfoOptions.date.displayText: infoDisplayed = .date
                default:
                    // TODO: log an error
                    fatalError("Unexpected option encountered! Do you need to add a new one?")
                }
            case .notifications:
                switch selectedOption {
                case DataSource.data[1].rows[3].options![0]: break //Default
                case DataSource.data[1].rows[3].options![1]: break //Custom
                default:
                    // TODO: log an error
                    fatalError("Unexpected option encountered! Do you need to add a new one?")
                }
            default:
                // TODO: break //it's section 1
                fatalError("Unexpected cell encountered! Do you need to add a new one?")
            }
        }
    }
    
    //
    // MARK: EventTableViewCellDelegate
    func eventDateRepeatTriggered(cell: EventTableViewCell, newDate: EventDate) {
        let master = navigationController!.viewControllers[0] as! MasterViewController
        master.dateDidChange = true
        eventDate = newDate
    }
    
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
            
            let section = DataSource.data.index(where: {$0.title == "Configure Event"})!
            let row = DataSource.data[section].rows.index(where: {$0.rowType == .notifications})!
            let cellToModify = optionsTableView.cellForRow(at: IndexPath(row: row, section: section)) as! SettingsTableViewCell
            
            if !eventNotificationsConfig.eventNotificationsOn {
                let index = DataSource.data[section].rows[row].options!.index(where: {$0.text == NotificationsOptions.off.displayText})!
                cellToModify.selectedOption = DataSource.data[section].rows[row].options![index]
            }
            else if eventNotificationsConfig.isCustom {
                let index = DataSource.data[section].rows[row].options!.index(where: {$0.text == NotificationsOptions.custom.displayText})!
                cellToModify.selectedOption = DataSource.data[section].rows[row].options![index]
            }
            else {
                let index = DataSource.data[section].rows[row].options!.index(where: {$0.text == NotificationsOptions._default.displayText})!
                cellToModify.selectedOption = DataSource.data[section].rows[row].options![index]
            }
        }
    }
    
    
    //
    // MARK: - Data Source Methods
    //
    
    //
    // Table View
    
    
    struct DataSource {
        
        struct Section {
            let title: String
            let rows: [Row]
            
            init(title: String, rows: [Row]) {self.title = title; self.rows = rows}
        }
        struct Row {
            enum RowTypes {
                case title, date, image, category, tagline, repeats, timerDisplayMode, infoDisplayed, notifications
                
                var title: String {
                    switch self {
                    case .title: return Constants.InactiveCellTextTitles.title
                    case .date: return Constants.InactiveCellTextTitles.date
                    case .image: return Constants.InactiveCellTextTitles.image
                    case .category: return Constants.InactiveCellTextTitles.category
                    case .tagline: return Constants.InactiveCellTextTitles.tagline
                    case .repeats: return "Repeats"
                    case .timerDisplayMode: return "Timer Display Mode"
                    case .infoDisplayed: return "Info Displayed"
                    case .notifications: return "Notifications"
                    }
                }
                
                var options: [SettingsTypeDataSource.Option]? {
                    switch self {
                    case .title: return nil
                    case .date: return nil
                    case .image: return nil
                    case .category: return nil
                    case .tagline: return nil
                    case .repeats: return [
                        SettingsTypeDataSource.Option(text: RepeatingOptions.never.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: RepeatingOptions.monthly.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: RepeatingOptions.yearly.displayText, action: nil)
                    ]
                    case .timerDisplayMode: return [
                        SettingsTypeDataSource.Option(text: "Detailed", action: nil),
                        SettingsTypeDataSource.Option(text: "Abridged", action: nil),
                    ]
                    case .infoDisplayed: return [
                        SettingsTypeDataSource.Option(text: DisplayInfoOptions.none.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: DisplayInfoOptions.tagline.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: DisplayInfoOptions.date.displayText, action: nil)
                    ]
                    case .notifications: return [
                        SettingsTypeDataSource.Option(text: NotificationsOptions._default.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: NotificationsOptions.custom.displayText, action: nil),
                        SettingsTypeDataSource.Option(text: NotificationsOptions.off.displayText, action: nil)
                    ]
                    }
                }
            }
            
            let rowType: RowTypes
            let title: String
            let options: [SettingsTypeDataSource.Option]?
            
            init(rowType: RowTypes) {self.rowType = rowType; self.title = rowType.title; self.options = rowType.options}
        }
        //static let eventInfoData = [Inputs.title, Inputs.date, Inputs.image, Inputs.category, Inputs.tagline]

        struct ReuseIdentifiers {
            static let section1 = "Title Only"
            static let section2 = "Title/Detail"
        }
        
        static let data = [
            Section(title: "Event Info", rows: [
                Row(rowType: .title),
                Row(rowType: .date),
                Row(rowType: .image),
                Row(rowType: .category),
                Row(rowType: .tagline)
                ]
            ),
            Section(title: "Configure Event", rows: [
                Row(rowType: .repeats),
                Row(rowType: .timerDisplayMode),
                Row(rowType: .infoDisplayed),
                Row(rowType: .notifications)
                ]
            )
        ]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {return DataSource.data.count}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataSource.data[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let options = DataSource.data[indexPath.section].rows[indexPath.row].options { // It's section 2
            if let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
                switch cell.rowType {
                case .selectOption:
                    if options.count > 2 {
                        if expandedCellIndexPath != indexPath {
                            expandedCellIndexPath = indexPath
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                        }
                        else {expandedCellIndexPath = nil}
                    }
                    else {expandedCellIndexPath = nil; cell.selectNextOption()}
                case .segue:
                    performSegue(withIdentifier: "Configure Notifications", sender: self)
                case .action, .onOrOff:
                    // TODO: break
                    fatalError("Need implementation!")
                }
            }
        }
        else { // It's section 1
            expandedCellIndexPath = nil
            switch DataSource.data[indexPath.section].rows[indexPath.row].rowType {
            case .title: currentInputViewState = .title
            case .date: currentInputViewState = .date
            case .image: currentInputViewState = .image
            case .category: currentInputViewState = .category
            case .tagline: currentInputViewState = .tagline
            default:
                // TODO: break
                fatalError("Unexpected cell title encountered!")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            if let selectedIP = expandedCellIndexPath, indexPath == selectedIP {
                return SettingsTableViewCell.expandedHeight
            }
            else {return SettingsTableViewCell.collapsedHeight}
        }
        else if indexPath.section == 0 {return TitleOnlyTableViewCell.cellHeight}
        else {
            // TODO: Remove this, provide a standard height.
            fatalError("Unknown cell encoutntered!")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return titleOnlyHeaderView(title: DataSource.data[section].title)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
            headerView.textLabel!.textColor = GlobalColors.orangeRegular
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let options = DataSource.data[indexPath.section].rows[indexPath.row].options {
            let cell = tableView.dequeueReusableCell(withIdentifier: DataSource.ReuseIdentifiers.section2) as! SettingsTableViewCell
            cell.selectionStyle = .none
            cell.optionsPickerView.dataSource = cell
            cell.optionsPickerView.delegate = cell
            if !cell.optionsPickerView.constraints.contains(where: {$0.firstAnchor == cell.optionsPickerView.widthAnchor}) {
                cell.optionsPickerView.widthAnchor.constraint(equalToConstant: optionsView.bounds.width / 2).isActive = true
            }
            cell.optionsPickerView.backgroundColor = GlobalColors.lightGrayForFills
            cell.optionsPickerView.layer.cornerRadius = GlobalCornerRadii.material
            cell.title = DataSource.data[indexPath.section].rows[indexPath.row].title
            cell.options = options
            cell.delegate = self
            
            switch DataSource.data[indexPath.section].rows[indexPath.row].rowType {
            case .repeats:
                cell.rowType = .selectOption
                cell.selectedOption = options[options.index(where: {$0.text == repeats.displayText})!]
            case .timerDisplayMode:
                cell.rowType = .selectOption
                if abridgedDisplayMode {cell.selectedOption = options[1]}
                else {cell.selectedOption = options[0]}
            case .infoDisplayed:
                cell.rowType = .selectOption
                cell.selectedOption = options[options.index(where: {$0.text == infoDisplayed.displayText})!]
            case .notifications:
                cell.rowType = .segue
                if let config = specialEvent?.notificationsConfig {
                    if config.eventNotificationsOn {
                        if config.isCustom {cell.selectedOption = options[1]}
                        else {cell.selectedOption = options[0]}
                    }
                    else {cell.selectedOption = options[2]}
                }
            default:
                // TODO: break // it's section 1
                fatalError("Unexpected option encountered! Do you need to add a new one?")
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: DataSource.ReuseIdentifiers.section1) as! TitleOnlyTableViewCell
            switch DataSource.data[indexPath.section].rows[indexPath.row].rowType {
            case .title:
                if let title = eventTitle {
                    cell.title = title
                    cell.titleLabel.textColor = GlobalColors.cyanRegular
                }
                else {
                    cell.title = Constants.InactiveCellTextTitles.title
                    cell.titleLabel.textColor = GlobalColors.inactiveColor
                }
            case .date:
                if let date = eventDate {
                    cell.title = longDateFormater.string(from: date.date)
                    cell.titleLabel.textColor = GlobalColors.cyanRegular
                }
                else {
                    cell.title = Constants.InactiveCellTextTitles.date
                    cell.titleLabel.textColor = GlobalColors.inactiveColor
                }
            case .image:
                if let image = selectedImage {
                    if let appImage = image as? AppEventImage {cell.title = "\"\(appImage.title)\""}
                    else {cell.title = Constants.defaultUserImageTitle}
                    cell.titleLabel.textColor = GlobalColors.cyanRegular
                }
                else {
                    cell.title = Constants.InactiveCellTextTitles.image
                    cell.titleLabel.textColor = GlobalColors.inactiveColor
                }
            case .category:
                if let category = eventCategory {
                    cell.title = category
                    cell.titleLabel.textColor = GlobalColors.cyanRegular
                }
                else {
                    cell.title = Constants.InactiveCellTextTitles.category
                    cell.titleLabel.textColor = GlobalColors.inactiveColor
                }
            case .tagline:
                if let tagline = eventTagline {
                    cell.title = tagline
                    cell.titleLabel.textColor = GlobalColors.cyanRegular
                }
                else {
                    cell.title = Constants.InactiveCellTextTitles.tagline
                    cell.titleLabel.textColor = GlobalColors.inactiveColor
                }
            default:
                // TODO: break
                fatalError("Unrecognized options title handled!")
            }
            return cell
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
            if pickerView == categoryPickerView {_viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayLight, size: 20.0)}
            else {_viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayLight, size: 14.0)}
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
            let cancelButton = UIBarButtonItem()
            cancelButton.tintColor = GlobalColors.orangeDark
            let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
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
            case "Configure Notifications":
                let destination = segue.destination as! ConfigureNotificationsTableViewController
                destination.modifiedEventNotifications = eventNotificationsConfig.eventNotifications
                destination.configuring = .eventReminders
                destination.segueFrom = .individualEvent
                destination.globalToggleOn = eventNotificationsConfig.eventNotificationsOn
                destination.useCustomNotifications = eventNotificationsConfig.isCustom
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
                if currentInputViewState == .tagline {
                    switch infoDisplayed {
                    case .tagline: infoDisplayed = .date
                    case .date: infoDisplayed = .tagline
                    case .none: break
                    }
                    let row = DataSource.data[1].rows.index(where: {$0.rowType == .infoDisplayed})!
                    optionsTableView.beginUpdates()
                    optionsTableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
                    optionsTableView.endUpdates()
                }
                else {currentInputViewState = .tagline}
            }
            else if specialEventView!.timerContainerView.frame.contains(sender.location(in: specialEventView!)) || specialEventView!.abridgedTimerContainerView.frame.contains(sender.location(in: specialEventView!)) {
                if currentInputViewState == .date {
                    abridgedDisplayMode = !abridgedDisplayMode
                    let row = DataSource.data[1].rows.index(where: {$0.rowType == .timerDisplayMode})!
                    optionsTableView.beginUpdates()
                    optionsTableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
                    optionsTableView.endUpdates()
                }
                else {currentInputViewState = .date}
            }
            else if specialEventView!.frame.contains(sender.location(in: specialEventView!)) {
                currentInputViewState = .image
            }
        }
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
            specialEvent!.cascadeDelete()
            print("Notifications stored after special event cascade delete:")
            let allEventNotifications = mainRealm.objects(RealmEventNotification.self)
            for (i, realmNotif) in allEventNotifications.enumerated() {
                print("\(i + 1): \(realmNotif.uuid)")
            }
            try! mainRealm.write {
                specialEvent!.category = eventCategory ?? "Uncatagorized"
                specialEvent!.tagline = eventTagline
                specialEvent!.date = eventDate!
                specialEvent!.abridgedDisplayMode = abridgedDisplayMode
                specialEvent!.infoDisplayed = infoDisplayed.displayText
                specialEvent!.repeats = repeats.displayText
                specialEvent!.notificationsConfig = RealmEventNotificationConfig(fromEventNotificationConfig: eventNotificationsConfig)
                
                print("Notifications stored after special event new config add:")
                for (i, realmNotif) in allEventNotifications.enumerated() {
                    print("\(i + 1): \(realmNotif.uuid)")
                }
                
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
            
            scheduleNewEvents(titled: [eventTitle!])
        }
        
        masterViewController?.updateActiveCategories()
        masterViewController?.updateIndexPathMap()
        masterViewController?.tableView.reloadData()
        navigationController!.popViewController(animated: true)
    }
    
    @objc fileprivate func handleInputToolbarButtonTap(_ sender: UIButton) {
        if textInputAccessoryView?.isFirstResponder ?? false {dismissKeyboard()}
        if sender == nextInputButton || sender == textInputAccessoryView?.nextInputButton {
            if eventTitle == nil {currentInputViewState = .title}
            else if eventDate == nil {currentInputViewState = .date}
            else if selectedImage == nil {currentInputViewState = .image}
            else if eventCategory == nil {currentInputViewState = .category}
            else if eventTagline == nil {currentInputViewState = .tagline}
            else {currentInputViewState = .none}
        }
        else if sender == enterDataButton || sender == textInputAccessoryView?.doneInputButton {currentInputViewState = .none}
        else if sender == cancelDataButton || sender == textInputAccessoryView?.cancelInputButton {
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
        else if sender == previousInputButton || sender == textInputAccessoryView?.previousInputButton {
            switch currentInputViewState {
            case .category: currentInputViewState = .image
            case .title: currentInputViewState = .tagline
            case .tagline: currentInputViewState = .category
            case .date: currentInputViewState = .title
            case .image: currentInputViewState = .date
            case .none:
                // TODO: Error handling
                fatalError("Previous button should have never been visible!")
            }
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
        textInputAccessoryView?.textInputField.resignFirstResponder()
        textInputAccessoryView?.isHidden = true
        textInputAccessoryView?.textInputField.text = nil
    }
    
    /*@objc fileprivate func handleDateTap(_ sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            switch sender.view {
            case dateLabel:
                if eventDatePicker.datePickerMode != .date {
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
                }
            case timeLabel:
                if eventDatePicker.datePickerMode != .time {
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
                }
            default:
                // TODO: Error handling
                fatalError("Unknown View Handled!")
            }
        default: break
        }
    }*/
    
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
        let singleTapDatePickerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDatePickerSingleTap(_:)))
        singleTapDatePickerTapGestureRecognizer.delegate = self
        
        let datePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDatePan(_:)))
        datePanGestureRecognizer.minimumNumberOfTouches = 1
        datePanGestureRecognizer.maximumNumberOfTouches = 1
        
        specialEventView?.addGestureRecognizer(specialEventViewTapGestureRecognizer)
        categoryLabel.addGestureRecognizer(categoryLabelTapGestureRecognizer)
        eventDatePicker.addGestureRecognizer(singleTapDatePickerTapGestureRecognizer)
        dateLabel.addGestureRecognizer(datePanGestureRecognizer)
    }
    
    @objc fileprivate func handleImageOptionsButtonsTap(_ sender: UIButton) {
        switch sender.titleLabel!.text! {
        case "PREVIEW/EDIT IMAGES":
            performSegue(withIdentifier: "EditImageSegue", sender: self)
        case "TOGGLE IMAGE":
            isUserChange = true
            if let image = selectedImage {previousSelectedImage = image; selectedImage = nil; sender.tintColor = GlobalColors.inactiveColor}
            else {selectedImage = previousSelectedImage; sender.tintColor = UIColor.green}
        case "TOGGLE MASK": useMask = !useMask
        default:
            // TODO: Error Handling, should never happen.
            fatalError("Fatal Error: Encountered and unknown image options button title")
        }
    }
    
    fileprivate func configureInputView() -> Void {
    
        nextInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        enterDataButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        cancelDataButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
        previousInputButton.addTarget(self, action: #selector(handleInputToolbarButtonTap(_:)), for: .touchUpInside)
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
        eventDatePicker.setValue(GlobalColors.orangeRegular, forKey: "textColor")
        
        longDateFormater.dateStyle = .full
        longDateFormater.timeStyle = .short
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }
    
    fileprivate func configureButton(_ button: UIButton) {
        button.layer.borderWidth = 1.0
        button.layer.borderColor = GlobalColors.orangeDark.cgColor
        button.layer.cornerRadius = 3.0
    }
    
    fileprivate func showImageNilLabel(animated: Bool = true) {
        
        imageNilLabel.layer.opacity = 0.0
        if !specialEventView!.subviews.contains(imageNilLabel) {
            specialEventView!.addSubview(imageNilLabel)
            specialEventView!.centerXAnchor.constraint(equalTo: imageNilLabel.centerXAnchor, constant: -(1/3) * (specialEventViewContainer.bounds.width / 2)).isActive = true
            specialEventView!.centerYAnchor.constraint(equalTo: imageNilLabel.centerYAnchor, constant: (1/3) * (specialEventViewContainer.bounds.height / 2)).isActive = true
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
    
    fileprivate func transitionInputView(fromState state1: Inputs, toState state2: Inputs) {
        let duration = 0.15
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: duration,
            delay: 0.0,
            options: [.curveLinear],
            animations: { [weak self] in
                if !self!.dataInputView.isHidden {self!.dataInputView.layer.opacity = 0.0}
                if !self!.optionsView.isHidden {self!.optionsView.layer.opacity = 0.0}
                if self!.textInputAccessoryView?.textInputField.isFirstResponder ?? false {
                    self!.textInputAccessoryView!.textInputField.resignFirstResponder()
                    self!.textInputAccessoryView!.isHidden = true
                    self!.textInputAccessoryView!.textInputField.text = nil
                }
            },
            completion: { [weak self] (position) in
                if self != nil {
                    self!.expandedCellIndexPath = nil
                    self!.dataInputView.isUserInteractionEnabled = false
                    self!.dataInputView.isHidden = true
                    self!.optionsView.isUserInteractionEnabled = false
                    self!.optionsView.isHidden = true
                    
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
                    case .title, .tagline: break
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
                            self!.textInputAccessoryView!.currentInputTitleLabel.text = "Title"
                            self!.textInputAccessoryView!.textInputField.autocapitalizationType = .words
                        }
                        else {
                            self!.textInputAccessoryView!.currentInputTitleLabel.text = "Tagline"
                            self!.textInputAccessoryView!.textInputField.autocapitalizationType = .sentences
                        }
                        if self!.currentInputViewState == .title {self!.textInputAccessoryView?.textInputField.text = self!.eventTitle}
                        else if self!.currentInputViewState == .tagline {self!.textInputAccessoryView?.textInputField.text = self!.eventTagline}
                    case .none:
                        self!.optionsView.isHidden = false
                        self!.optionsView.isUserInteractionEnabled = true
                    }
                }
                
                switch state2 {
                case .title, .tagline:
                    self!.textInputAccessoryView?.textInputField.becomeFirstResponder()
                    if self!.textInputAccessoryView != nil {
                        if self!.textInputAccessoryView!.isHidden {
                            self!.textInputAccessoryView!.isHidden = false
                            self!.textInputAccessoryView!.isUserInteractionEnabled = true
                        }
                    }
                case .none:
                    self!.optionsView.isHidden = false
                    self!.optionsView.isUserInteractionEnabled = true
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: duration,
                        delay: 0.0,
                        options: [.curveLinear],
                        animations: { [weak self] in
                            self!.optionsView.layer.opacity = 1.0
                        },
                        completion: nil
                    )
                default:
                    self!.dataInputView.isHidden = false
                    self!.dataInputView.isUserInteractionEnabled = true
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: duration,
                        delay: 0.0,
                        options: [.curveLinear],
                        animations: { [weak self] in
                            self!.dataInputView.layer.opacity = 1.0
                        },
                        completion: nil
                    )
                }
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
        localImageInfo = mainRealm.objects(EventImageInfo.self).filter(filterPredicate)
        
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
    
    fileprivate func getEventImageInfo() -> EventImageInfo? {
        if let image = selectedImage {
            if !image.imagesAreSavedToDisk {
                let results = image.saveToDisk(imageTypes: [.main, .mask, .thumbnail])
                if results.contains(false) {
                    // TODO: return nil Error Handling
                    fatalError("Images were unable to be saved to the disk!")
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
            scheduleNewEvents(titled: [_eventTitle])
        }
        else {
            // TODO: Remove for production, should never hit this if earlier guards work.
            fatalError("Fatal Error: selectedImage or locationForCellView were nil when trying to create new event!")
        }
    }
    
    fileprivate func checkFinishButtonEnable() {
        if eventTitle != nil && eventDate != nil {
            enableButton(finishButton)
            doneButton.isEnabled = true
        }
        else {
            disableButton(finishButton)
            doneButton.isEnabled = false
        }
    }
    
    fileprivate func enableButton(_ button: UIButton) {
        button.isEnabled = true; button.layer.opacity = 1.0
    }
    
    fileprivate func disableButton(_ button: UIButton) {
        button.isEnabled = false; button.layer.opacity = 0.5
    }

}
