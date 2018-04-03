//
//  NewEventViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/3/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift
import QuartzCore
import os.log
import CloudKit
import StoreKit

class NewEventViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, SKProductsRequestDelegate {

    
    //
    // MARK: - Parameters
    //
    
    //
    // MARK: Data Model
    
    var specialEvent: SpecialEvent?
    
    var eventCategory: String? {
        didSet {
            if eventCategory != nil && eventCategory != "" {
                if !categoryWaveEffectView.isHidden {
                    swapStateOf(view: categoryWaveEffectView)
                    swapStateOf(view: categoryLabel)
                }
                categoryLabel.text = eventCategory
            }
            else {
                if categoryWaveEffectView.isHidden {
                    swapStateOf(view: categoryWaveEffectView)
                    swapStateOf(view: categoryLabel)
                }
                categoryLabel.text = nil
            }
        }
    }
    
    var eventTitle: String? {didSet {specialEventView?.eventTitle = eventTitle}}
    var eventTagline: String? {didSet {specialEventView?.eventTagline = eventTagline}}
    
    var eventDate: EventDate? {
        didSet {
            specialEventView?.eventDate = eventDate
            if eventDate != nil && oldValue == nil {
                eventTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                    DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.specialEventView?.update()}
                }
            }
            else if eventDate == nil && oldValue != nil {
                eventTimer?.invalidate()
                eventTimer = nil
            }
        }
    }
    
    var selectedImage: EventImage? {didSet{specialEventView?.eventImage = selectedImage}}
    
    var cachedImages = [EventImage]() {
        didSet {
            selectImageController?.catalogImages = cachedImages
        }
    }
    
    fileprivate let defaultImageTitle = "Desert Dunes"
    fileprivate var selectableCategories = [String]()
    fileprivate var productIDs = Set<Product>()
    fileprivate weak var selectImageController: SelectImageViewController?
    var editingEvent = false
    
    //
    // Types
    
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
    
    //
    // MARK: Persistence
    
    fileprivate var localPersistentStore: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    fileprivate let userDefaultsContainer = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // MARK: UI Elements
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var specialEventViewContainer: UIView!
    fileprivate var specialEventView: EventTableViewCell?
    
    @IBOutlet weak var buttonsView: ButtonsView!
    fileprivate var textInputAccessoryView: TextInputAccessoryView?
    
    fileprivate var categoryButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Category", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "CategoryButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    fileprivate var titleButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Title", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "TitleButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 50.0, height: 30.0))
    fileprivate var dateButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Date", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "DateButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    fileprivate var taglineButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Tagline", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "TaglineButtonImage", isDataRequired: false, sizeOfGlyph: CGSize(width: 50.0, height: 30.0))
    fileprivate var imageButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Image", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "ImageButtonImage", isDataRequired: false, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    
    @IBOutlet weak var categoryLabel: UILabel!
    let categoryWaveEffectView = WaveEffectView()
    
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var datePickerStackView: UIStackView!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var eventDateButtonsStackView: UIStackView!
    @IBOutlet weak var setTimeButton: UIButton!
    fileprivate var cancelSetTimeButton: UIButton?
    @IBOutlet weak var selectImageButton: UIButton!
    
    //
    // Gesture Recognizers
    
    let cellTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
    
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

    fileprivate var currentInputViewState: Inputs = .none {
        didSet {
            if currentInputViewState != oldValue {
                
                buttonToStateAssociations[oldValue]?.isSelected = false
                buttonToStateAssociations[currentInputViewState]?.isSelected = true
                
                switch currentInputViewState {
                case .category:
                    if initialLoad {
                        categoryWaveEffectView.animate()
                        if let titleWaveView = specialEventView?.titleWaveEffectView {titleWaveView.animate()}
                        if let timerWaveView = specialEventView?.timerWaveEffectView {timerWaveView.animate()}
                        if let timerLabelsWaveView = specialEventView?.timerLabelsWaveEffectView {timerLabelsWaveView.animate()}
                        if let taglineWaveView = specialEventView?.taglineWaveEffectView {taglineWaveView.animate()}
                    }
                    else if !categoryWaveEffectView.isHidden {
                        categoryWaveEffectView.animate()
                    }
                case .title:
                    if let titleWaveView = specialEventView?.titleWaveEffectView {
                        if !titleWaveView.isHidden {titleWaveView.animate()}
                    }
                case .date:
                    if let timerWaveView = specialEventView?.timerWaveEffectView {
                        if !timerWaveView.isHidden {timerWaveView.animate()}
                    }
                    if let timerLabelsWaveView = specialEventView?.timerLabelsWaveEffectView {
                        if !timerLabelsWaveView.isHidden {timerLabelsWaveView.animate()}
                    }
                case .tagline:
                    if let taglineWaveView = specialEventView?.taglineWaveEffectView {
                        if !taglineWaveView.isHidden {taglineWaveView.animate()}
                    }
                case .image: break
                case .none: break
                }
                
                if activationTable[currentInputViewState.rawValue][UIElements.firstResponder.rawValue] == true {
                    textInputAccessoryView?.textInputField.becomeFirstResponder()
                    if currentInputViewState == .title {textInputAccessoryView?.textInputField.text = eventTitle}
                    else if currentInputViewState == .tagline {textInputAccessoryView?.textInputField.text = eventTagline}
                    if textInputAccessoryView != nil {swapStateOf(view: textInputAccessoryView!)}
                }
                else {
                    if textInputAccessoryView?.textInputField.isFirstResponder ?? false {
                        textInputAccessoryView!.textInputField.resignFirstResponder()
                        textInputAccessoryView!.isHidden = true
                        textInputAccessoryView!.textInputField.text = nil
                    }
                }
                
                if activationTable[currentInputViewState.rawValue][UIElements.pickerView.rawValue] == true {
                    categoryPickerView.isHidden = false
                    categoryPickerView.isUserInteractionEnabled = true
                }
                else {
                    categoryPickerView.isHidden = true
                    categoryPickerView.isUserInteractionEnabled = false
                }
                
                if activationTable[currentInputViewState.rawValue][UIElements.datePicker.rawValue] == true {
                    datePickerStackView.isHidden = false
                    datePickerStackView.isUserInteractionEnabled = true
                    
                }
                else {
                    datePickerStackView.isHidden = true
                    datePickerStackView.isUserInteractionEnabled = false
                }
                
                if activationTable[currentInputViewState.rawValue][UIElements.imageSelector.rawValue] == true {
                    selectImageButton.isHidden = false
                    selectImageButton.isUserInteractionEnabled = true
                }
                else {
                    selectImageButton.isHidden = true
                    selectImageButton.isUserInteractionEnabled = false
                }
                
                if currentInputViewState == .none {
                    categoryButton.isSelected = false
                    titleButton.isSelected = false
                    dateButton.isSelected = false
                    taglineButton.isSelected = false
                    imageButton.isSelected = false
                }
            }
        }
    }
    
    var initialLoad = true
    
    var cloudThumbnailsFetched = false {
        didSet {
            if cloudThumbnailsFetched != oldValue {
                selectImageController?.catalogLoadComplete = cloudThumbnailsFetched
            }
        }
    }
    
    override var canBecomeFirstResponder: Bool {return true}
    override var canResignFirstResponder: Bool {return true}
    override var inputAccessoryView: UIView? {return textInputAccessoryView}
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let timeFormatter = DateFormatter()
    fileprivate var calendarDayHolder: Date?
    fileprivate var timeHolder: Date?
    fileprivate var eventTimer: Timer?
    
    //
    // Static Types
    
    struct StringConstants {
        static let eventImageViewAccessibilityIdentifier = "Event Image"
        
        static let categoryVisualEffectViewAccessibilityIdentifier = "Category Blur"
        static let titleVisualEffectViewAccessibilityIdentifier = "Title Blur"
        static let taglineVisualEffectViewAccessibilityIdentifier = "Tagline Blur"
        static let timerVisualEffectViewAccessibilityIdentifier = "Timer Blur"
        static let labelsVisualEffectViewAccessibilityIdentifier = "Labels Blur"
        
        static let categoryLabelAccessibilityIdentifier = "Category Label"
        static let titleLabelAccessibilityIdentifier = "Title Label"
        static let taglineLabelAccessibilityIdentifier = "Tagline Label"
        static let timerStackViewAccessibilityIdentifier = "Timer Stack View"
        static let labelsStackViewAccessibilityIdentifier = "Labels Stack View"
        static let abridgedTimerAccessibilityIdentifier = "Abridged Timer"
        
        static let categoryButtonAccessibilityIdentifier = "Category Button"
        static let titleButtonAccessibilityIdentifier = "Title Button"
        static let dateButtonAccessibilityIdentifier = "Date Button"
        static let taglineButtonAccessibilityIdentifier = "Tagline Button"
        static let imageButtonAccessibilityIdentifier = "Image Button"
    }
    
    enum Inputs: Int {
        case category = 0
        case title
        case date
        case tagline
        case image
        case none
    }
    enum UIElements: Int {
        case firstResponder = 0
        case pickerView
        case datePicker
        case imageSelector
    }
    
    var buttonToStateAssociations: [Inputs: NewEventInputsControl] = [:]
    
    let accessibilityTitlesToStateAssociations = [
        Inputs.category: [StringConstants.categoryLabelAccessibilityIdentifier, StringConstants.categoryButtonAccessibilityIdentifier, StringConstants.categoryVisualEffectViewAccessibilityIdentifier],
        Inputs.title: [StringConstants.titleLabelAccessibilityIdentifier, StringConstants.titleButtonAccessibilityIdentifier, StringConstants.titleVisualEffectViewAccessibilityIdentifier],
        Inputs.date: [StringConstants.dateButtonAccessibilityIdentifier, StringConstants.timerStackViewAccessibilityIdentifier, StringConstants.timerVisualEffectViewAccessibilityIdentifier, StringConstants.abridgedTimerAccessibilityIdentifier, StringConstants.labelsStackViewAccessibilityIdentifier, StringConstants.labelsVisualEffectViewAccessibilityIdentifier],
        Inputs.tagline: [StringConstants.taglineLabelAccessibilityIdentifier, StringConstants.taglineButtonAccessibilityIdentifier, StringConstants.taglineVisualEffectViewAccessibilityIdentifier],
        Inputs.image: [StringConstants.imageButtonAccessibilityIdentifier, StringConstants.eventImageViewAccessibilityIdentifier]
    ]
    
    let activationTable = [
        // FR    PV     DP     IS
        [false, true, false, false], // Category
        [true, false, false, false], // Title
        [false, false, true, false], // Date
        [true, false, false, false], // Tagline
        [false, false, false, true], // Image
        [false, false, false, false] // None
    ]
    
    
    
    
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
            }
        }
        if let specialEventNib = Bundle.main.loadNibNamed("SpecialEventCell", owner: self, options: nil) {
            if let view = specialEventNib[0] as? EventTableViewCell {
                specialEventView = view
                specialEventView!.translatesAutoresizingMaskIntoConstraints = false
                specialEventViewContainer.addSubview(specialEventView!)
                specialEventViewContainer.topAnchor.constraint(equalTo: specialEventView!.topAnchor).isActive = true
                specialEventViewContainer.rightAnchor.constraint(equalTo: specialEventView!.rightAnchor).isActive = true
                specialEventViewContainer.bottomAnchor.constraint(equalTo: specialEventView!.bottomAnchor).isActive = true
                specialEventViewContainer.leftAnchor.constraint(equalTo: specialEventView!.leftAnchor).isActive = true
                specialEventView!.configuration = .newEventsController
                
                specialEventView!.eventTitle = eventTitle
                specialEventView!.eventTagline = eventTagline
                specialEventView!.eventDate = eventDate
                specialEventView!.eventImage = selectedImage
            }
        }
        setAccessibilityIdentifiers()
        configureCategoryWaveEffectView()
        setupTapGestureRecognizers()
        configureButtons()
        configureInputView()
        hideStuff()
        
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
        
        buttonToStateAssociations[.category] = categoryButton
        buttonToStateAssociations[.title] = titleButton
        buttonToStateAssociations[.date] = dateButton
        buttonToStateAssociations[.tagline] = taglineButton
        buttonToStateAssociations[.image] = imageButton
        
        if specialEvent != nil {
            eventCategory = specialEvent!.category
            eventTitle = specialEvent!.title
            eventTagline = specialEvent!.tagline
            eventDate = specialEvent!.date
            
            calendarDayHolder = eventDate?.date
            deconstructDateAndTime()
            switch eventDatePicker.datePickerMode {
            case .date: if calendarDayHolder != nil {eventDatePicker.date = calendarDayHolder!}
            case .time: if timeHolder != nil {eventDatePicker.date = timeHolder!}
            default:
                // TODO: Error Handling
                os_log("DatePicker in NewEventController somehow got in an undefined mode.", log: OSLog.default, type: .error)
                fatalError()
            }
            
            if specialEvent!.image != nil {selectedImage = EventImage(fromEventImageInfo: specialEvent!.image!)}
        }
        
        localPersistentStore = try! Realm(configuration: realmConfig)
        fetchLocalImages()
        fetchProductIDs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !editingEvent {currentInputViewState = .category}
    }

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    deinit {eventTimer?.invalidate()}
    
    
    //
    // MARK: - Delegate Methods
    //
    
    //
    // Store Kit
    
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
        switch eventDatePicker.datePickerMode {
        case .date:
            calendarDayHolder = eventDatePicker.date
            if timeHolder == nil {eventDate = EventDate(date: calendarDayHolder!, dateOnly: true)}
            else {eventDate = EventDate(date: combineDateAndTime(), dateOnly: false)}
        case .time:
            timeHolder = eventDatePicker.date
            eventDate = EventDate(date: combineDateAndTime(), dateOnly: false)
        default:
            // TODO: Error Handling
            os_log("DatePicker in NewEventController somehow got in an undefined mode.", log: OSLog.default, type: .error)
            fatalError()
        }
    }
    
    //
    // Picker View
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        eventCategory = selectableCategories[row]
    }
    
    //
    // Text Field
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if currentInputViewState == .title {
            if string.isEmpty {eventTitle = eventTitle?.removeCharsFromEnd(numberToRemove: range.length)}
            else {eventTitle = (textInputAccessoryView?.textInputField.text ?? "") + string}
        }
        else if currentInputViewState == .tagline {
            if string.isEmpty {eventTagline = eventTagline?.removeCharsFromEnd(numberToRemove: range.length)}
            else {eventTagline = (textInputAccessoryView?.textInputField.text ?? "") + string}
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
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
        return NSAttributedString(string: stringToReturn, attributes: [NSAttributedStringKey.foregroundColor:UIColor.white])
    }
    
    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as! UINavigationController
        let destination = navController.viewControllers[0] as! SelectImageViewController
        destination.selectedImage = selectedImage
        destination.catalogImages = cachedImages
        destination.catalogLoadComplete = cloudThumbnailsFetched
        selectImageController = destination
    }

    
    //
    // MARK: - Target-Action Methods
    //
    
    @objc fileprivate func handleTapsInCell(_ sender: UIView) -> Void {
        if sender.accessibilityIdentifier != nil {
            switch sender.accessibilityIdentifier! {
            case StringConstants.categoryVisualEffectViewAccessibilityIdentifier, StringConstants.categoryLabelAccessibilityIdentifier:
                categoryButton.sendActions(for: .touchUpInside)
            case StringConstants.titleVisualEffectViewAccessibilityIdentifier, StringConstants.titleLabelAccessibilityIdentifier:
                titleButton.sendActions(for: .touchUpInside)
            case StringConstants.taglineVisualEffectViewAccessibilityIdentifier, StringConstants.taglineLabelAccessibilityIdentifier:
                taglineButton.sendActions(for: .touchUpInside)
            case StringConstants.timerStackViewAccessibilityIdentifier, StringConstants.labelsStackViewAccessibilityIdentifier, StringConstants.abridgedTimerAccessibilityIdentifier:
                dateButton.sendActions(for: .touchUpInside)
            case StringConstants.eventImageViewAccessibilityIdentifier:
                imageButton.sendActions(for: .touchUpInside)
            default: break // Should never happen
            }
        }
    }
    
    @objc fileprivate func handleDoneButtonTap(_ sender: UIButton) {
        
        func createEventImageInfo() -> EventImageInfo {
            if !selectedImage!.imagesAreSavedToDisk {
                let results = selectedImage!.saveToDisk(imageTypes: [.main, .mask, .thumbnail])
                if results.contains(false) {
                    // TODO: Error Handling
                    fatalError("Images were unable to be saved to the disk!")
                }
            }
             return EventImageInfo(fromEventImage: selectedImage!)
        }
        
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
        
        if editingEvent {
            try! localPersistentStore.write {
                specialEvent!.category = eventCategory ?? "Uncatagorized"
                specialEvent!.title = eventTitle!
                specialEvent!.tagline = eventTagline
                specialEvent!.date = eventDate!
                if selectedImage != nil && specialEvent!.image != nil {
                    if selectedImage!.title != specialEvent!.image!.title {
                        let image = createEventImageInfo()
                        specialEvent!.image = image
                        // TODO: Consider deleting old EventImageInfo, or adding support in settings to purge this.
                    }
                }
            }
        }
        else {
            if selectedImage != nil {
                let image = createEventImageInfo()
                let newEvent = SpecialEvent(
                    category: eventCategory ?? "Uncatagorized",
                    title: eventTitle!,
                    tagline: eventTagline,
                    date: eventDate!,
                    image: image
                )
                try! localPersistentStore.write {localPersistentStore.add(newEvent, update: true)}
            }
        }
        
        navigationController!.navigationController?.popViewController(animated: true)
    }
    
    @objc fileprivate func handleInputButtonTap(_ sender: UIButton) {
        if !sender.isSelected {
            if let id = sender.accessibilityIdentifier {
                for entry in accessibilityTitlesToStateAssociations {
                    if entry.value.contains(id) {
                        currentInputViewState = entry.key
                    }
                }
            }
        }
        else {currentInputViewState = .none}
    }
    
    @objc fileprivate func handleDatePickerButtonTap(_ sender: UIButton?) {
        if let button = sender {
            if button == setTimeButton {
                switch eventDatePicker.datePickerMode {
                case .date:
                    if calendarDayHolder == nil {
                        calendarDayHolder = eventDatePicker.date
                        eventDate = EventDate(date: calendarDayHolder!, dateOnly: true)
                    }
                    button.isSelected = true
                    button.setTitle(dateFormatter.string(from: calendarDayHolder!), for: UIControlState.selected)
                    eventDatePicker.datePickerMode = .time
                    eventDatePicker.date = timeHolder ?? setDefaultTime()
                    if cancelSetTimeButton == nil {initializeCancelSetTimeButton()}
                    if !cancelSetTimeButton!.isDescendant(of: eventDateButtonsStackView) {
                        eventDateButtonsStackView.addArrangedSubview(cancelSetTimeButton!)
                        eventDateButtonsStackView.sizeToFit()
                    }
                case .time:
                    if timeHolder == nil {
                        timeHolder = eventDatePicker.date
                        eventDate = EventDate(date: combineDateAndTime(), dateOnly: false)
                    }
                    button.setTitle(timeFormatter.string(from: timeHolder!), for: UIControlState.selected)
                    eventDatePicker.datePickerMode = .date
                    eventDatePicker.date = calendarDayHolder ?? Date()
                default: // Should never happen
                    os_log("WARNING: Date picker somehow got into an undefined state, noted during handleDatePickerButtonTap", log: .default, type: .error)
                    eventDatePicker.datePickerMode = .date
                }
            }
            else if button == cancelSetTimeButton {
                timeHolder = nil
                eventDate = EventDate(date: calendarDayHolder!, dateOnly: true)
                setTimeButton.isSelected = false
                if eventDatePicker.datePickerMode != .date {
                    eventDatePicker.datePickerMode = .date
                    eventDatePicker.date = calendarDayHolder ?? Date()
                }
                cancelSetTimeButton!.removeFromSuperview()
                eventDateButtonsStackView.sizeToFit()
            }
        }
    }
    
    @objc fileprivate func dismissKeyboard() {
        switch currentInputViewState {
        case .title: specialEventView!.updateShadow(for: specialEventView!.titleLabel)
        case .tagline: specialEventView!.updateShadow(for: specialEventView!.taglineLabel)
        default: break
        }
        textInputAccessoryView?.textInputField.resignFirstResponder()
        textInputAccessoryView?.isHidden = true
        textInputAccessoryView?.textInputField.text = nil
        currentInputViewState = .none
    }

    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func setAccessibilityIdentifiers() -> Void {
        
        categoryWaveEffectView.accessibilityIdentifier = StringConstants.categoryVisualEffectViewAccessibilityIdentifier
        specialEventView?.titleWaveEffectView?.accessibilityIdentifier = StringConstants.titleVisualEffectViewAccessibilityIdentifier
        specialEventView?.taglineWaveEffectView?.accessibilityIdentifier = StringConstants.taglineVisualEffectViewAccessibilityIdentifier
        specialEventView?.timerWaveEffectView?.accessibilityIdentifier = StringConstants.timerVisualEffectViewAccessibilityIdentifier
        specialEventView?.timerLabelsWaveEffectView?.accessibilityIdentifier = StringConstants.labelsVisualEffectViewAccessibilityIdentifier
        
        categoryLabel.accessibilityIdentifier = StringConstants.categoryLabelAccessibilityIdentifier
        specialEventView?.titleLabel.accessibilityIdentifier = StringConstants.titleLabelAccessibilityIdentifier
        specialEventView?.taglineLabel.accessibilityIdentifier = StringConstants.taglineLabelAccessibilityIdentifier
        specialEventView?.timerContainerView.accessibilityIdentifier = StringConstants.timerStackViewAccessibilityIdentifier
        specialEventView?.timerLabelsStackView.accessibilityIdentifier = StringConstants.labelsStackViewAccessibilityIdentifier
        specialEventView?.abridgedTimerContainerView.accessibilityIdentifier = StringConstants.abridgedTimerAccessibilityIdentifier
        
        categoryButton.accessibilityIdentifier = StringConstants.categoryButtonAccessibilityIdentifier
        titleButton.accessibilityIdentifier = StringConstants.titleButtonAccessibilityIdentifier
        dateButton.accessibilityIdentifier = StringConstants.dateButtonAccessibilityIdentifier
        taglineButton.accessibilityIdentifier = StringConstants.taglineButtonAccessibilityIdentifier
        imageButton.accessibilityIdentifier = StringConstants.imageButtonAccessibilityIdentifier
    }
    
    fileprivate func hideStuff() -> Void {
        swapStateOf(view: datePickerStackView)
        swapStateOf(view: categoryPickerView)
        if textInputAccessoryView != nil {swapStateOf(view: textInputAccessoryView!)}
    }
    
    fileprivate func setupTapGestureRecognizers() -> Void {
        categoryLabel.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.titleLabel.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.taglineLabel.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.timerContainerView.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.abridgedTimerContainerView.addGestureRecognizer(cellTapGestureRecognizer)
        
        categoryWaveEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.titleWaveEffectView?.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.taglineWaveEffectView?.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.timerWaveEffectView?.addGestureRecognizer(cellTapGestureRecognizer)
        specialEventView?.timerLabelsWaveEffectView?.addGestureRecognizer(cellTapGestureRecognizer)
    }
    
    fileprivate func configureButtons() {
        
        doneButton.target = self
        doneButton.action = #selector(handleDoneButtonTap(_:))
        
        buttonsView.addSubview(categoryButton)
        buttonsView.addSubview(titleButton)
        buttonsView.addSubview(dateButton)
        buttonsView.addSubview(taglineButton)
        buttonsView.addSubview(imageButton)
        
        categoryButton.addTarget(self, action: #selector(handleInputButtonTap(_:)), for: .touchUpInside)
        titleButton.addTarget(self, action: #selector(handleInputButtonTap(_:)), for: .touchUpInside)
        dateButton.addTarget(self, action: #selector(handleInputButtonTap(_:)), for: .touchUpInside)
        taglineButton.addTarget(self, action: #selector(handleInputButtonTap(_:)), for: .touchUpInside)
        imageButton.addTarget(self, action: #selector(handleInputButtonTap(_:)), for: .touchUpInside)
    }
    
    fileprivate func configureInputView() -> Void {
        eventDatePicker.backgroundColor = UIColor.clear
        eventDatePicker.isOpaque = false
        eventDatePicker.setValue(UIColor.white, forKey: "textColor")
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        setTimeButton.addTarget(self, action: #selector(handleDatePickerButtonTap(_:)), for: .touchUpInside)
    }
    
    fileprivate func configureCategoryWaveEffectView() {
        categoryWaveEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(categoryWaveEffectView)
        categoryWaveEffectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8.0).isActive = true
        categoryWaveEffectView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0).isActive = true
        categoryWaveEffectView.heightAnchor.constraint(equalToConstant: 17.0).isActive = true
        categoryWaveEffectView.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        if eventCategory != nil {swapStateOf(view: categoryWaveEffectView)}
    }
    
    fileprivate func swapStateOf(view: UIView) -> Void {
        if view.isHidden {view.isHidden = false; view.isUserInteractionEnabled = true}
        else {view.isHidden = true; view.isUserInteractionEnabled = false}
    }
    
    fileprivate func initializeCancelSetTimeButton() -> Void {
        cancelSetTimeButton = UIButton(type: .system)
        cancelSetTimeButton!.setTitle("Clear Time", for: UIControlState.normal)
        cancelSetTimeButton!.sizeToFit()
        cancelSetTimeButton!.addTarget(self, action: #selector(handleDatePickerButtonTap(_:)), for: .touchUpInside)
        cancelSetTimeButton!.titleLabel!.font = UIFont(name: "FiraSans-Light", size: 18.0)
        cancelSetTimeButton!.titleLabel!.textColor = UIColor.white
    }
    
    fileprivate func fetchLocalImages() {
        
        localImageInfo = localPersistentStore.objects(EventImageInfo.self)
        
        var imagesToReturn = [EventImage]()
        
        for imageInfo in localImageInfo {
            if !cachedImages.contains(where: {$0.title == imageInfo.title}) {
                if let newEventImage = EventImage(fromEventImageInfo: imageInfo) {
                    imagesToReturn.append(newEventImage)
                    if newEventImage.title == defaultImageTitle {selectedImage = newEventImage}
                }
                else {
                    // TODO: - Error handling
                    fatalError("Unable to locate \(imageInfo.title)'s thumbnail image on the disk!")
                }
            }
        }
        cachedImages.append(contentsOf: imagesToReturn)
    }
    
    fileprivate func fetchProductIDs(_ previousNetworkFetchAtempts: Int = 0) {
        
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
                        if previousNetworkFetchAtempts <= 1 {weakSelf?.fetchProductIDs(previousNetworkFetchAtempts + 1); return}
                        else {return}
                    case 3:
                        // TODO: Need to tell user to check network connection on select image view controller.
                        return
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
    
    fileprivate func fetchCloudImages(records ids: [CKRecordID], imageTypes: [CountdownImage.ImageType], completionHandler completion: @escaping (_ eventImage: EventImage?, _ error: CloudErrors?) -> Void) {
        
        guard !ids.isEmpty else {completion(nil, .noRecords); return}
        
        cloudThumbnailsFetched = false
        
        let fetchOperation = CKFetchRecordsOperation(recordIDs: ids)
        
        var desiredKeys = [
            EventImage.CloudKitKeys.EventImageKeys.title,
            EventImage.CloudKitKeys.EventImageKeys.fileRootName,
            EventImage.CloudKitKeys.EventImageKeys.category,
            EventImage.CloudKitKeys.EventImageKeys.locationForCellView
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
                    let title = record.value[EventImage.CloudKitKeys.EventImageKeys.title] as! String
                    let fileRootName = record.value[EventImage.CloudKitKeys.EventImageKeys.fileRootName] as! String
                    let category = record.value[EventImage.CloudKitKeys.EventImageKeys.category] as! String
                    let locationForCellView = record.value[EventImage.CloudKitKeys.EventImageKeys.locationForCellView] as! Int
                    
                    var images = [CountdownImage]()
                    var cloudError: CloudErrors?
                    for imageType in imageTypes {
                        let imageAsset = record.value[imageType.recordKey] as! CKAsset
                        let imageFileExtension = record.value[imageType.extensionRecordKey] as! String
                        
                        do {
                            let imageData = try Data(contentsOf: imageAsset.fileURL)
                            if let newImage = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: imageFileExtension, imageData: imageData) {
                                images.append(newImage)
                            }
                        }
                        catch {cloudError = .imageCreationFailure; break}
                    }
                    
                    if let newEventImage = EventImage(title: title, fileRootName: fileRootName, category: category, isAppImage: true, locationForCellView: locationForCellView, recordName: recordID.recordName, images: images), cloudError == nil {
                        completion(newEventImage, nil)
                    }
                    else {completion(nil, cloudError)}
                }
                DispatchQueue.main.async { [weak weakSelf = self] in
                    weakSelf?.cloudThumbnailsFetched = true
                }
            }
            else {completion(nil, .noRecords)}
        }
        publicCloudDatabase.add(fetchOperation)
    }
    
    fileprivate func thumbnailLoadComplete(_ image: EventImage?, _ error: CloudErrors?) {
        if image != nil && error == nil {
            DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.cachedImages.append(image!)}
        }
        else {
            if error == .noRecords {
                DispatchQueue.main.async { [weak weakSelf = self] in weakSelf?.cloudThumbnailsFetched = true}
            }
            else {
                // TODO: - Error handling
                fatalError("There was an error fetching images from the cloud")
            }
        }
    }
    
    fileprivate func setDefaultTime() -> Date {
        let localTimeIntervalAdjustment = TimeZone.current.secondsFromGMT()
        var timeIntervalToReturn = 43200 - Double(localTimeIntervalAdjustment)
        if timeIntervalToReturn.isLess(than: 0.0) {timeIntervalToReturn += 3600}
        return Date(timeIntervalSinceReferenceDate: timeIntervalToReturn)
    }
    
    fileprivate func combineDateAndTime() -> Date {
        let selectedTime = timeHolder!.timeIntervalSinceReferenceDate
        let days = (selectedTime/86400.0).rounded(.down)
        let timeIntervalFromMidnight = selectedTime - (days * 86400.0)
        
        var selectedDate = calendarDayHolder!.timeIntervalSinceReferenceDate
        let days2 = (selectedDate/86400.0).rounded(.down)
        let timeIntervalFromMidnight2 = selectedDate - (days2 * 86400.0)
        selectedDate -= timeIntervalFromMidnight2
        
        return Date(timeIntervalSinceReferenceDate: timeIntervalFromMidnight + selectedDate)
    }
    
    fileprivate func deconstructDateAndTime() {
        guard eventDate != nil else {return}
        calendarDayHolder = eventDate!.date
        if !eventDate!.dateOnly {timeHolder = eventDate!.date}
    }
}
