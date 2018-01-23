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

class NewEventViewController: UIViewController, ImageHandlerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    
    //
    // MARK: - Parameters
    //
    
    //
    // Data Model
    
    var categories: Results<Categories>!
    var eventCategory: EventCategory?
    var eventTitle: String?
    var eventTagline: String?
    var eventDate: EventDate?
    var eventMainImage: EventImage?
    
    let newEventImageHandler = ImageHandler()
    var selectableCategories = [String]()
    
    //
    // Persistence
    
    var localPersistentStore: Realm!
    
    //
    // UI Elements
    
    @IBOutlet weak var eventImageView: UIImageView!

    @IBOutlet weak var buttonsView: ButtonsView!
    
    var categoryButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Category", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "CategoryButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    var titleButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Title", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "TitleButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 50.0, height: 30.0))
    var dateButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Date", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "DateButtonImage", isDataRequired: true, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    var taglineButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Tagline", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "TaglineButtonImage", isDataRequired: false, sizeOfGlyph: CGSize(width: 50.0, height: 30.0))
    var imageButton = NewEventInputsControl(frame: CGRect(x: 0.0, y: 0.0, width: 90.0, height: 50.0) , buttonTitle: "Image", font: UIFont(name: "FiraSans-Light", size: 14.0), buttonImageTitled: "ImageButtonImage", isDataRequired: false, sizeOfGlyph: CGSize(width: 30.0, height: 30.0))
    
    @IBOutlet weak var categoryVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var titleVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var taglineVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var timerVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var labelsVisualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var taglineLabel: UILabel!
    @IBOutlet weak var timerStackView: UIStackView!
    @IBOutlet weak var labelsStackView: UIStackView!
    @IBOutlet weak var abridgedStackView: UIStackView!
    
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var datePickerStackView: UIStackView!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var eventDateButtonsStackView: UIStackView!
    @IBOutlet weak var setTimeButton: UIButton!
   
    //
    // Gesture Recognizers
    
    let cellTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapsInCell(_:)))
    
    //
    // Other

    var currentInputViewState: Inputs = .none {
        didSet {
            if currentInputViewState != oldValue {
                
                buttonToStateAssociations[oldValue]?.isSelected = false
                buttonToStateAssociations[currentInputViewState]?.isSelected = true
                
                if activationTable[currentInputViewState.rawValue][UIElements.firstResponder.rawValue] == true {
                    self.becomeFirstResponder()
                }
                else {self.resignFirstResponder()}
                
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
    override var canBecomeFirstResponder: Bool {return true}
    override var canResignFirstResponder: Bool {return true}
    
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
        // FR    PV     DP
        [false, true, false], // Category
        [true, false, false], // Title
        [false, false, true], // Date
        [true, false, false], // Tagline
        [false, false, false], // Image
        [false, false, false] // None
    ]
    
    
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Finish view config
        setAccessibilityIdentifiers()
        setupTapGestureRecognizers()
        configureButtons()
        configureInputView()
        hideStuff()
        
        // Fetch data
        setupDataModel()
        newEventImageHandler.delegate = self
        newEventImageHandler.fetchOriginalsFromCloud()
        
        // Odds and ends
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryPickerView.reloadAllComponents()
        
        buttonToStateAssociations[.category] = categoryButton
        buttonToStateAssociations[.title] = titleButton
        buttonToStateAssociations[.date] = dateButton
        buttonToStateAssociations[.tagline] = taglineButton
        buttonToStateAssociations[.image] = imageButton
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if initialLoad {
            currentInputViewState = .category
            initialLoad = false
        }
    }

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    
    //
    // MARK: - Delegate Methods
    //
    
    //
    // Image Handler
    
    func cloudLoadBegan() {
        
    }
    
    func cloudLoadEnded(imagesLoaded: Bool) {
        if imagesLoaded {
            eventImageView.image = newEventImageHandler.eventImages[0].uiImage
        }
        else {
            // TODO: Display prompt stating images have not been loaded.
        }
    }
    
    //
    // Date Picker
    
    @IBAction func datePickerDateDidChange(_ sender: UIDatePicker) {
        
    }
    
    //
    // Picker View
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if !categoryVisualEffectView.isHidden {
            swapStateOf(view: categoryVisualEffectView)
            swapStateOf(view: categoryLabel)
        }
        categoryLabel.text = selectableCategories[row]
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
    
    /*
    //
    // MARK: - Navigation
    //

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
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
    
    @objc fileprivate func handleButtonTap(_ sender: UIButton) {
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

    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func setupDataModel() -> Void {
        do {
            try localPersistentStore = Realm(configuration: realmConfig)
            categories = localPersistentStore!.objects(Categories.self)
        }
        catch {
            // TODO: - Add a popup to user saying an error fetching timer data occured, please help the developer by submitting crash data.
            let realmCreationError = error as NSError
            print("Unable to create local persistent store! Error: \(realmCreationError), \(realmCreationError.localizedDescription)")
        }
        
        // Set up selectable categories
        for category in categories[0].list {
            if category.title != "Favorites" && category.title != "Previous" {
                if let title = category.title {selectableCategories.append(title)}
            }
        }
    }
    
    fileprivate func setAccessibilityIdentifiers() -> Void {
        eventImageView.accessibilityIdentifier = StringConstants.eventImageViewAccessibilityIdentifier
        
        categoryVisualEffectView.accessibilityIdentifier = StringConstants.categoryVisualEffectViewAccessibilityIdentifier
        titleVisualEffectView.accessibilityIdentifier = StringConstants.titleVisualEffectViewAccessibilityIdentifier
        taglineVisualEffectView.accessibilityIdentifier = StringConstants.taglineVisualEffectViewAccessibilityIdentifier
        timerVisualEffectView.accessibilityIdentifier = StringConstants.timerVisualEffectViewAccessibilityIdentifier
        labelsVisualEffectView.accessibilityIdentifier = StringConstants.labelsVisualEffectViewAccessibilityIdentifier
        
        categoryLabel.accessibilityIdentifier = StringConstants.categoryLabelAccessibilityIdentifier
        titleLabel.accessibilityIdentifier = StringConstants.titleLabelAccessibilityIdentifier
        taglineLabel.accessibilityIdentifier = StringConstants.taglineLabelAccessibilityIdentifier
        timerStackView.accessibilityIdentifier = StringConstants.timerStackViewAccessibilityIdentifier
        labelsStackView.accessibilityIdentifier = StringConstants.labelsStackViewAccessibilityIdentifier
        abridgedStackView.accessibilityIdentifier = StringConstants.abridgedTimerAccessibilityIdentifier
        
        categoryButton.accessibilityIdentifier = StringConstants.categoryButtonAccessibilityIdentifier
        titleButton.accessibilityIdentifier = StringConstants.titleButtonAccessibilityIdentifier
        dateButton.accessibilityIdentifier = StringConstants.dateButtonAccessibilityIdentifier
        taglineButton.accessibilityIdentifier = StringConstants.taglineButtonAccessibilityIdentifier
        imageButton.accessibilityIdentifier = StringConstants.imageButtonAccessibilityIdentifier
    }
    
    fileprivate func hideStuff() -> Void {
        swapStateOf(view: categoryLabel)
        swapStateOf(view: titleLabel)
        swapStateOf(view: taglineLabel)
        swapStateOf(view: timerStackView)
        swapStateOf(view: labelsStackView)
        swapStateOf(view: abridgedStackView)
    }
    
    fileprivate func setupTapGestureRecognizers() -> Void {
        eventImageView.addGestureRecognizer(cellTapGestureRecognizer)
        
        categoryVisualEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        titleVisualEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        taglineVisualEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        timerVisualEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        labelsVisualEffectView.addGestureRecognizer(cellTapGestureRecognizer)
        
        categoryLabel.addGestureRecognizer(cellTapGestureRecognizer)
        titleLabel.addGestureRecognizer(cellTapGestureRecognizer)
        taglineLabel.addGestureRecognizer(cellTapGestureRecognizer)
        timerStackView.addGestureRecognizer(cellTapGestureRecognizer)
        labelsStackView.addGestureRecognizer(cellTapGestureRecognizer)
        abridgedStackView.addGestureRecognizer(cellTapGestureRecognizer)
    }
    
    fileprivate func configureButtons() {
        buttonsView.addSubview(categoryButton)
        buttonsView.addSubview(titleButton)
        buttonsView.addSubview(dateButton)
        buttonsView.addSubview(taglineButton)
        buttonsView.addSubview(imageButton)
        
        categoryButton.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        titleButton.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        dateButton.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        taglineButton.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
        imageButton.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)
    }
    
    fileprivate func configureInputView() -> Void {
        eventDatePicker.backgroundColor = UIColor.clear
        eventDatePicker.isOpaque = false
        eventDatePicker.setValue(UIColor.white, forKey: "textColor")
    }
    
    fileprivate func swapStateOf(view: UIView) -> Void {
        if view.isHidden {view.isHidden = false; view.isUserInteractionEnabled = true}
        else {view.isHidden = true; view.isUserInteractionEnabled = false}
    }
}
