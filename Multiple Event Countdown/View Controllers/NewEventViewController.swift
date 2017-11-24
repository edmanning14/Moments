//
//  NewEventViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/15/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift

class NewEventViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    //
    // MARK: - Properties
    //
    
    // Data Model
    var categories: Results<Categories>!
    var eventCategory: EventCategory? {
        didSet {
            if eventCategory != nil {if oldValue == nil {modelAndGate += 0b00000001}}
            else {if oldValue != nil {modelAndGate -= 0b00000001}}
        }
    }
    var eventTitle: String? {
        didSet {
            if eventTitle != nil {if oldValue == nil {modelAndGate += 0b00000010}}
            else {if oldValue != nil {modelAndGate -= 0b00000010}}
        }
    }
    var eventTagline: String? {
        didSet {
            if eventTagline != nil {if oldValue == nil {modelAndGate += 0b00000100}}
            else {if oldValue != nil {modelAndGate -= 0b00000100}}
        }
    }
    var eventDate: EventDate? {
        didSet {
            if let date = eventDate {
                if date.dateOnly {goalDateFormatter.timeStyle = .none}
                else if !date.dateOnly {goalDateFormatter.timeStyle = defaultTimeStyle}
            }
            if eventDate != nil {if oldValue == nil {modelAndGate += 0b00001000}}
            else {if oldValue != nil {modelAndGate -= 0b00001000}}
        }
    }
    var eventMainImage: EventImage? {
        didSet {
            if eventMainImage != nil {if oldValue == nil {modelAndGate += 0b00010000}}
            else {if oldValue != nil {modelAndGate -= 0b00010000}}
        }
    }
    
    let newEventImageHandler = ImageHandler(forJob: .newEventControllerImageRetrieval)
    var selectableCategories = [String]()
    
    var modelAndGate: UInt8 = 0b00000000 {
        didSet {
            if modelAndGate == 0b00011111 {if oldValue != 0b00011111 {showHidePromptAndButtons()}}
            if modelAndGate != 0b00011111 {if oldValue == 0b00011111 {showHidePromptAndButtons()}}
        }
    }
    
    // Persistence
    var localPersistentStore: Realm!
    
    // String constants
    struct DefaultStrings {
        static let categoryLabel = "Travel"
        static let titleLabel = "Vacation to Jupiter!"
        static let taglineLabel = "Windsurfing trip!"
        static var dateLabel = "Date"
        static let imageLabel = "4D Teleporter.png"
        
        static let categoryInputViewTitle = "Category"
        static let titleInputViewTitle = "Title"
        static let taglineInputViewTitle = "Tagline"
        static let dateInputViewTitle = "Date and Time"
        static let imageInputViewTitle = "Backgrounds"
    }
    
    // References and outlets
    @IBOutlet weak var categoryTextView: UITextView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var taglineTextView: UITextView!
    @IBOutlet weak var dateTextView: UITextView!
    @IBOutlet weak var imageTextView: UITextView!
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var taglineView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var createEventButton: UIButton!
    @IBOutlet weak var editSettngsButton: UIButton!
    
    // Input Views
    let categoryInputView = UIPickerView()
    var dateInputView: DateInputView?
    var imageInputView: ImageInputView?
    let theInputAccessoryView = UINavigationBar()
    
    // Other
    var goalDateFormatter = DateFormatter()
    let defaultTimeStyle = DateFormatter.Style.short
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataModel()
        
        goalDateFormatter.dateStyle = .long
        goalDateFormatter.timeStyle = defaultTimeStyle
        DefaultStrings.dateLabel = goalDateFormatter.string(from: Date(timeIntervalSinceNow: 15768000000.0))
        
        navigationItem.backBarButtonItem!.title = "Cancel"
        
        // Setup default texts
        categoryTextView.text = DefaultStrings.categoryLabel
        titleTextView.text = DefaultStrings.titleLabel
        taglineTextView.text = DefaultStrings.taglineLabel
        dateTextView.text = DefaultStrings.dateLabel
        imageTextView.text = DefaultStrings.imageLabel
        
        setupInputViews()
        
        createEventButton.isHidden = true
        editSettngsButton.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {categoryTextView.becomeFirstResponder()}

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    

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
    // MARK: - Delegate Functions
    //
    
    // Picker View
    //
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectableCategories.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selectableCategories[row]
    }
    
    // Text View
    //
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        func selectText() -> Void {
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)
            textView.textColor = UIColor.black
        }
        
        if textView == categoryTextView {
            theInputAccessoryView.items![0].title = DefaultStrings.categoryInputViewTitle
            if let rowToSelect = selectableCategories.index(of: textView.text) {
                categoryInputView.selectRow(rowToSelect, inComponent: 0, animated: false)
            }
            if eventTitle != nil {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Done"}
            else {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Next"}
            selectText()
        }
        else if textView == titleTextView {
            theInputAccessoryView.items![0].title = DefaultStrings.titleInputViewTitle
            if eventTagline != nil {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Done"}
            else {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Next"}
            if titleTextView.text == DefaultStrings.titleLabel {selectText()}
        }
        else if textView == taglineTextView {
            theInputAccessoryView.items![0].title = DefaultStrings.taglineInputViewTitle
            if eventDate != nil {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Done"}
            else {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Next"}
            if taglineTextView.text == DefaultStrings.taglineLabel {selectText()}
        }
        else if textView == dateTextView {
            theInputAccessoryView.items![0].title = DefaultStrings.dateInputViewTitle
            if eventMainImage != nil {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Done"}
            else {theInputAccessoryView.items![0].rightBarButtonItem!.title = "Next"}
            selectText()
        }
        else if textView == imageTextView {
            theInputAccessoryView.items![0].title = DefaultStrings.imageInputViewTitle
            theInputAccessoryView.items![0].rightBarButtonItem!.title = "Done"
            selectText()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {if textView.text == "" {createPlaceholderText(inTextView: textView)}}
    
    // Collection View
    //
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return newEventImageHandler.eventImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Image Input View Collection View Cell", for: indexPath) as! ImageInputViewCollectionViewCell
        
        cell.cellLabel.text = newEventImageHandler.eventImages[indexPath.row].title
        cell.cellImageView.image = newEventImageHandler.eventImages[indexPath.row].uiImage
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        eventMainImage = newEventImageHandler.eventImages[indexPath.row]
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
        
        // Fetch app provided images
        DispatchQueue.global(qos: .userInitiated).async {
        }
    }
    
    fileprivate func setupInputViews() -> Void {
        
        // Delegation and data source setup
        //
        
        categoryInputView.dataSource = self
        
        categoryInputView.delegate = self
        categoryTextView.delegate = self
        titleTextView.delegate = self
        taglineTextView.delegate = self
        dateTextView.delegate = self
        imageTextView.delegate = self
        
        // Configure input acessory view
        //
        
        theInputAccessoryView.frame = CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: 40.0)
        theInputAccessoryView.isTranslucent = true
        theInputAccessoryView.backgroundColor = UIColor.lightGray
        let doneButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.done, target: self, action: #selector(handleAccessoryViewButtonClick(_:)))
        //doneButton.tintColor = UIColor.orange
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleAccessoryViewButtonClick(_:)))
        //cancelButton.tintColor = UIColor.orange
        theInputAccessoryView.items = [UINavigationItem(title: "Event Category")]
        theInputAccessoryView.items![0].leftBarButtonItem = cancelButton
        theInputAccessoryView.items![0].rightBarButtonItem = doneButton
        
        categoryTextView.inputAccessoryView = theInputAccessoryView
        titleTextView.inputAccessoryView = theInputAccessoryView
        taglineTextView.inputAccessoryView = theInputAccessoryView
        dateTextView.inputAccessoryView = theInputAccessoryView
        imageTextView.inputAccessoryView = theInputAccessoryView
        
        // Category input view
        //
        
        categoryTextView.inputView = categoryInputView
        
        // Title input view
        //
        
        // Tagline input view
        //
        
        // Date input view
        //
        
        if let loadedDateView = Bundle.main.loadNibNamed("DateInputView", owner: self, options: nil)?[0] as? DateInputView {
            dateInputView = loadedDateView
            dateInputView!.delegate = self
            dateTextView.inputView = dateInputView
        }
        else {displayErrorView(forTextView: dateTextView)}
        
        // Image input View
        //
        
        if let loadedImageView = Bundle.main.loadNibNamed("ImageInputView", owner: self, options: nil)?[0] as? ImageInputView {
            imageInputView = loadedImageView
            imageTextView.inputView = imageInputView!
            let collectionViewCell = UINib(nibName: "ImageInputViewCollectionViewCell", bundle: nil)
            imageInputView!.imageCollectionView.register(collectionViewCell, forCellWithReuseIdentifier: "Image Input View Collection View Cell")
        }
        else {displayErrorView(forTextView: imageTextView)}
    }
    
    @objc fileprivate func handleAccessoryViewButtonClick(_ sender: UIBarButtonItem) -> Void {
        switch theInputAccessoryView.items![0].title! {
        case DefaultStrings.categoryInputViewTitle:
            switch sender.title! {
            case "Next":
                eventCategory = categories[0].list.filter("title = '\(selectableCategories[categoryInputView.selectedRow(inComponent: 0)])'")[0]
                categoryTextView.text = eventCategory!.title
                categoryTextView.resignFirstResponder()
                titleTextView.becomeFirstResponder()
            case "Done":
                eventCategory = categories[0].list.filter("title = '\(selectableCategories[categoryInputView.selectedRow(inComponent: 0)])'")[0]
                categoryTextView.text = eventCategory!.title
                categoryTextView.resignFirstResponder()
            case "Cancel":
                if eventCategory == nil {createPlaceholderText(inTextView: categoryTextView)}
                else {categoryTextView.text = eventCategory!.title!}
                categoryTextView.resignFirstResponder()
            default:
                break
            }
        case DefaultStrings.titleInputViewTitle:
            switch sender.title! {
            case "Next":
                eventTitle = titleTextView.text
                titleTextView.resignFirstResponder()
                taglineTextView.becomeFirstResponder()
            case "Done":
                eventTitle = titleTextView.text
                titleTextView.resignFirstResponder()
            case "Cancel":
                if eventTitle == nil {createPlaceholderText(inTextView: titleTextView)}
                else {titleTextView.text = eventTitle!}
                titleTextView.resignFirstResponder()
            default:
                break
            }
        case DefaultStrings.taglineInputViewTitle:
            switch sender.title! {
            case "Next":
                eventTagline = taglineTextView.text
                taglineTextView.resignFirstResponder()
                dateTextView.becomeFirstResponder()
            case "Done":
                eventTagline = taglineTextView.text
                taglineTextView.resignFirstResponder()
            case "Cancel":
                if eventTagline == nil {createPlaceholderText(inTextView: taglineTextView)}
                else {taglineTextView.text = eventTagline!}
                taglineTextView.resignFirstResponder()
            default:
                break
            }
        case DefaultStrings.dateInputViewTitle:
            switch sender.title! {
            case "Next":
                if dateInputView != nil {
                    eventDate = dateInputView!.eventDate
                    dateTextView.text = goalDateFormatter.string(from: eventDate!.date)
                }
                dateTextView.resignFirstResponder()
                imageTextView.becomeFirstResponder()
            case "Done":
                if dateInputView != nil {
                    eventDate = dateInputView!.eventDate
                    dateTextView.text = goalDateFormatter.string(from: eventDate!.date)
                }
                dateTextView.resignFirstResponder()
            case "Cancel":
                if eventDate == nil {createPlaceholderText(inTextView: dateTextView)}
                else {dateTextView.text = goalDateFormatter.string(from: eventDate!.date)}
                dateTextView.resignFirstResponder()
            default:
                break
            }
        case DefaultStrings.imageInputViewTitle:
            switch sender.title! {
            case "Done":
                if imageInputView != nil {
                    
                }
                imageTextView.resignFirstResponder()
            case "Cancel":
                if eventMainImage == nil {createPlaceholderText(inTextView: imageTextView)}
                else {
                    // Get title of old image and set here.
                }
                imageTextView.resignFirstResponder()
            default:
                break
            }
        default:
            print("There was an error determining which textView is first responder!")
            self.resignFirstResponder()
        }
    }
    
    fileprivate func showHidePromptAndButtons() -> Void {
        if promptLabel.isHidden {
            promptLabel.isHidden = false
            createEventButton.isHidden = true
            editSettngsButton.isHidden = true
        }
        else {
            promptLabel.isHidden = true
            createEventButton.isHidden = false
            editSettngsButton.isHidden = false
        }
    }
    
    fileprivate func createPlaceholderText(inTextView textView: UITextView) -> Void {
        if textView == categoryTextView {
            eventCategory = nil
            textView.text = DefaultStrings.categoryLabel
        }
        else if textView == titleTextView {
            eventTitle = nil
            textView.text = DefaultStrings.titleLabel
        }
        else if textView == taglineTextView {
            eventTagline = nil
            textView.text = DefaultStrings.taglineLabel
        }
        else if textView == dateTextView {
            eventDate = nil
            textView.text = DefaultStrings.dateLabel
        }
        else if textView == imageTextView {
            eventMainImage = nil
            textView.text = DefaultStrings.imageLabel
        }
        textView.textColor = UIColor.lightGray
    }
    
    fileprivate func displayErrorView(forTextView textView: UITextView) -> Void {
        let errorView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 150.0))
        let errorLabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100.0))
        errorLabel.text = "Whoops! I was unable to load this view.  Please help me get better by submitting a bug report to the developer!"
        errorLabel.lineBreakMode = NSLineBreakMode.byClipping
        errorLabel.sizeToFit()
        errorView.addSubview(errorLabel)
        errorLabel.centerXAnchor.constraint(equalTo: errorView.centerXAnchor).isActive = true
        errorLabel.centerYAnchor.constraint(equalTo: errorView.centerYAnchor).isActive = true
        textView.inputView = errorView
    }
}
