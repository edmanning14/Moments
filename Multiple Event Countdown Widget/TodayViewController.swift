//
//  TodayViewController.swift
//  Multiple Event Countdown Widget
//
//  Created by Edward Manning on 8/23/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import NotificationCenter
import RealmSwift

//
// Realm Config
let widgetRealmConfig = Realm.Configuration(
    fileURL: realmDBURL,
    inMemoryIdentifier: nil,
    syncConfiguration: nil,
    encryptionKey: nil,
    readOnly: false,
    schemaVersion: 0,
    migrationBlock: nil,
    deleteRealmIfMigrationNeeded: false,
    shouldCompactOnLaunch: nil,
    objectTypes: [EventDate.self, EventImageInfo.self, SpecialEvent.self, RealmEventNotificationConfig.self, RealmEventNotification.self, RealmEventNotificationComponents.self]
)

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
    
    //
    // MARK: Data Model
    fileprivate let maxEventsDisplayed = 1
    fileprivate var numberOfEventsToday = 0 {
        didSet {
            if numberOfEventsToday > 0 {
                compactViewNumberLabel.text = String(numberOfEventsToday)
                compactViewNumberLabel.isHidden = false
                compactViewMasterLabel.text = "Events Today!"
            }
            else {
                compactViewNumberLabel.isHidden = true
                compactViewMasterLabel.text = "No Events Today."
            }
        }
    }
    //fileprivate var mainRealm: Realm!
    
    /*fileprivate lazy var upcomingEventsMainRealm: Results<SpecialEvent> = {
        return mainRealm.objects(SpecialEvent.self)
    }()*/
    fileprivate var changesToUpcomingEventsToken: NotificationToken!
    
    fileprivate struct Section {
        var title: String?
        var data: [EventData]
        
        init(title: String?, data: [EventData]) {self.title = title; self.data = data}
    }
    
    fileprivate struct EventData {
        let title: String
        let date: Date
        var tagline: String?
        var image: UIImage?
        
        init(title: String, date: Date, tagline: String?, image: UIImage?) {self.title = title; self.date = date; self.tagline = tagline; self.image = image}
    }
    
    fileprivate var dataModel = [Section]() {
        didSet {
            if let i = dataModel.index(where: {$0.title == SectionTitles.todaysTitle}) {
                switch dataModel[i].data.count {
                case 1: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" is today!"
                case 2: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" and 1 other event are today!"
                default: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" and \(numberOfEventsToday) other events are today!"
                }
            }
            else if let i = dataModel.index(where: {$0.title == SectionTitles.tomorrowsTitle}) {
                let numberOfEventsTomorrow = dataModel[i].data.count
                switch numberOfEventsTomorrow {
                case 1: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" is tomorrow."
                case 2: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" and 1 other event are tomorrow."
                default: compactViewDetailLabel.text = "\"\(dataModel[i].data[0].title)\" and \(numberOfEventsTomorrow) other events are tomorrow."
                }
            }
            else if let i = dataModel.index(where: {$0.title == SectionTitles.upcomingsTitle}) {
                let yearToSecondsComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
                let event = dataModel[i].data[0]
                let dateNow = Date()
                let todaysDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: dateNow)
                let eventDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: event.date)
                
                var detailLabelText = ""
                var days = Double(eventDateComponents.day! - todaysDateComponents.day!)
                var months = 0.0
                var years = 0.0
                
                if days < 0.0 {
                    months -= 1.0
                    let eventDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: event.date)!
                    let daysInEventDatePreviousMonth = currentCalendar.range(of: .day, in: .month, for: eventDatePreviousMonth)!.count
                    let daysLeftInEventDatePreviousMonth = daysInEventDatePreviousMonth - todaysDateComponents.day!
                    days = Double(daysLeftInEventDatePreviousMonth + eventDateComponents.day!)
                }
                
                months += Double(eventDateComponents.month! - todaysDateComponents.month!)
                if months < 0.0 {
                    years -= 1.0
                    months = 12 + months
                }
                
                years += Double(eventDateComponents.year! - todaysDateComponents.year!)
                
                detailLabelText = "Your next event \"\(event.title)\" is in "
                
                if years != 0 {
                    if years == 1.0 {detailLabelText += "1 year"}
                    else {detailLabelText += "\(Int(years)) years"}
                    
                    if months != 0 {
                        if months == 1.0 {detailLabelText += ", 1 month"}
                        else {detailLabelText += ", \(Int(months)) months"}
                    }
                    
                    if days != 0 {
                        if days == 1.0 {detailLabelText += ", 1 day"}
                        else {detailLabelText += ", \(Int(days)) days"}
                    }
                    
                    detailLabelText += "."
                }
                    
                else if months != 0 {
                    if months == 1.0 {detailLabelText += "1 month"}
                    else {detailLabelText += "\(Int(months)) months"}
                    
                    if days != 0 {
                        if days == 1.0 {detailLabelText += ", 1 day"}
                        else {detailLabelText += ", \(Int(days)) days"}
                    }
                    
                    detailLabelText += "."
                }
                    
                else { // Days must not be equal to 0.
                    if days == 1.0 {detailLabelText += "1 day."}
                    else {detailLabelText += "\(Int(days)) days."}
                }

                compactViewDetailLabel.text = detailLabelText
            }
            else {
                compactViewMasterLabel.text = "You have no events!"
                compactViewDetailLabel.text = "Tap to open app and create a new event!"
            }
            tableView.reloadData()
        }
    }
    
    //
    // MARK: GUI
    @IBOutlet weak var compactView: UIVisualEffectView!
    @IBOutlet weak var expandedView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonsStackViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var compactViewNumberLabel: UILabel!
    @IBOutlet weak var compactViewMasterLabel: UILabel!
    @IBOutlet weak var compactViewDetailLabel: UILabel!
    
    //
    // MARK: Other
    let currentCalendar = Calendar.current
    struct SectionTitles {
        static let todaysTitle = "Today"
        static let tomorrowsTitle = "Tomorrow"
        static let upcomingsTitle = "Upcoming"
    }
    var imageSize: CGSize {return CGSize(width: self.view.bounds.width, height: 160.0)}
    
    //
    // MARK: Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in self?.updateDataModel()}
        
        // Configure table view
        tableView.delegate = self
        tableView.dataSource = self
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        compactView.effect = UIVibrancyEffect.widgetPrimary()
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    //
    // MARK: NCWidgetProviding Delegate
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        switch activeDisplayMode {
        case .compact:
            preferredContentSize = maxSize
            compactView.isHidden = false
            expandedView.isHidden = true
        case .expanded:
            print(tableView.contentSize.height)
            let desiredHeight = tableView.contentSize.height + buttonsStackViewHeightConstraint.constant
            if maxSize.height > desiredHeight {
                preferredContentSize = CGSize(width: maxSize.width, height: desiredHeight)
            }
            else {preferredContentSize = maxSize}
            compactView.isHidden = true
            expandedView.isHidden = false
        }
    }
    
    //
    // MARK: UITableViewDataSource and Delegate
    func numberOfSections(in tableView: UITableView) -> Int {return dataModel.count}
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {return dataModel[section].data.count}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Widget Event Table View Cell", for: indexPath) as! WidgetEventTableViewCell
        let event = dataModel[indexPath.section].data[indexPath.row]
        
        if indexPath.row == dataModel[indexPath.section].data.count - 1 {cell.spacingConstraint.constant = 0.0}
        else {cell.spacingConstraint.constant = globalCellSpacing}
        
        cell.title = event.title
        cell.tagline = event.tagline
        cell.mainEventImage = event.image
        
        let desiredHeight = tableView.contentSize.height + buttonsStackViewHeightConstraint.constant
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: desiredHeight)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = dataModel[section].title {
            let headerView = UITableViewHeaderFooterView()
            let standardMargin: CGFloat = 20.0
            let underlineThickness: CGFloat = 2.0
            
            let bgView = UIView()
            bgView.backgroundColor = UIColor.clear
            headerView.backgroundView = bgView
            
            let underline = UIView()
            underline.translatesAutoresizingMaskIntoConstraints = false
            underline.backgroundColor = GlobalColors.orangeRegular
            underline.layer.cornerRadius = underlineThickness / 2
            
            headerView.contentView.addSubview(underline)
            headerView.contentView.bottomAnchor.constraint(equalTo: underline.bottomAnchor, constant: standardMargin / 2).isActive = true
            headerView.contentView.leftAnchor.constraint(equalTo: underline.leftAnchor, constant: -standardMargin).isActive = true
            headerView.contentView.rightAnchor.constraint(equalTo: underline.rightAnchor, constant: standardMargin).isActive = true
            underline.heightAnchor.constraint(equalToConstant: underlineThickness).isActive = true
            
            let titleLabel = UILabel()
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0)
            titleLabel.textColor = GlobalColors.orangeRegular
            titleLabel.text = title
            
            headerView.contentView.addSubview(titleLabel)
            titleLabel.leftAnchor.constraint(equalTo: underline.leftAnchor).isActive = true
            titleLabel.bottomAnchor.constraint(equalTo: underline.topAnchor, constant: -4.0).isActive = true
            
            let shareAllButton = UIButton(type: .system)
            shareAllButton.translatesAutoresizingMaskIntoConstraints = false
            shareAllButton.setTitle("Share All", for: .normal)
            shareAllButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayMedium, size: 16.0)
            shareAllButton.addTarget(self, action: #selector(handleShareAllButtonTap(_:)), for: .touchUpInside)
            
            headerView.contentView.addSubview(shareAllButton)
            shareAllButton.rightAnchor.constraint(equalTo: underline.rightAnchor).isActive = true
            shareAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
            
            return headerView
        }
        else {return nil}
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == dataModel[indexPath.section].data.count - 1 {return 170 - globalCellSpacing}
        return 170
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataModel[section].title != nil {return 70.0} else {return 0.0}
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Implement overlay
    }
    
    //
    // MARK: Actions
    @objc fileprivate func handleShareAllButtonTap(_ sender: UIButton) {
        if let header = sender.superview as? UITableViewHeaderFooterView {
            if let i = dataModel.index(where: {$0.title == header.textLabel?.text}) {
                share(events: dataModel[i].data)
            }
        }
    }
    
    //
    // MARK: Helper methods
    fileprivate func updateDataModel() {
        
        autoreleasepool {
            func convertToEventData(_ specialEvent: SpecialEvent) -> EventData {
                var image: UIImage?
                if let imageInfo = specialEvent.image, let locationForCellView = specialEvent.locationForCellView.value {
                    image = createImage(fromImageInfo: imageInfo, locationForCellView: CGFloat(locationForCellView) / 100.0)
                }
                return EventData(title: specialEvent.title, date: specialEvent.date!.date, tagline: specialEvent.tagline, image: image)
            }
            
            let updateDataRealm = try! Realm(configuration: widgetRealmConfig)
            var eventsToReturn = [Section]()
            var eventsLeft = maxEventsDisplayed
            
            let eventsToday = updateDataRealm.objects(SpecialEvent.self).sorted { (event1, event2) -> Bool in
                if let eventDate1 = event1.date, let eventDate2 = event2.date {
                    if eventDate1.date < eventDate2.date {return true} else {return false}
                }
                else {return false}
                }.filter { (event) -> Bool in
                    if currentCalendar.isDateInToday(event.date!.date) {return true}
                    else {return false}
            }
            guard eventsToday.count < eventsLeft else {
                let clippedEventsToday = eventsToday.removedAfter(index: eventsLeft - 1)
                let convertedEventsToday = clippedEventsToday.map {(specialEvent) -> EventData in convertToEventData(specialEvent)}
                eventsToReturn.append(Section(title: SectionTitles.todaysTitle, data: convertedEventsToday))
                numberOfEventsToday = maxEventsDisplayed
                DispatchQueue.main.async {[weak self] in self?.dataModel = eventsToReturn}
                return
            }
            if !eventsToday.isEmpty {
                let convertedEventsToday = eventsToday.map {(specialEvent) -> EventData in convertToEventData(specialEvent)}
                eventsToReturn.append(Section(title: SectionTitles.todaysTitle, data: convertedEventsToday))
            }
            numberOfEventsToday = eventsToday.count
            eventsLeft -= eventsToday.count
            
            let eventsTomorrow = updateDataRealm.objects(SpecialEvent.self).sorted { (event1, event2) -> Bool in
                if let eventDate1 = event1.date, let eventDate2 = event2.date {
                    if eventDate1.date < eventDate2.date {return true} else {return false}
                }
                else {return false}
                }.filter { (event) -> Bool in
                    if currentCalendar.isDateInTomorrow(event.date!.date) {return true}
                    else {return false}
            }
            guard eventsTomorrow.count < eventsLeft else {
                let clippedEventsTomorrow = eventsTomorrow.removedAfter(index: eventsLeft - 1)
                let convertedEventsTomorrow = clippedEventsTomorrow.map {(specialEvent) -> EventData in convertToEventData(specialEvent)}
                eventsToReturn.append(Section(title: SectionTitles.todaysTitle, data: convertedEventsTomorrow))
                DispatchQueue.main.async {[weak self] in self?.dataModel = eventsToReturn}
                return
            }
            if !eventsTomorrow.isEmpty {
                let convertedEventsTomorrow = eventsTomorrow.map {(specialEvent) -> EventData in convertToEventData(specialEvent)}
                eventsToReturn.append(Section(title: SectionTitles.tomorrowsTitle, data: convertedEventsTomorrow))}
            eventsLeft -= eventsTomorrow.count
            
            let upcomingEvents = updateDataRealm.objects(SpecialEvent.self).sorted { (event1, event2) -> Bool in
                if let eventDate1 = event1.date, let eventDate2 = event2.date {
                    if eventDate1.date < eventDate2.date {return true} else {return false}
                }
                else {return false}
                }.filter { (event) -> Bool in
                    if currentCalendar.isDateInToday(event.date!.date) {return false}
                    else if currentCalendar.isDateInTomorrow(event.date!.date) {return false}
                    else {return true}
            }
            if !upcomingEvents.isEmpty {
                let clippedUpcomingEvents = upcomingEvents.removedAfter(index: eventsLeft - 1)
                let convertedUpcomingEvents = clippedUpcomingEvents.map {(specialEvent) -> EventData in convertToEventData(specialEvent)}
                eventsToReturn.append(Section(title: SectionTitles.upcomingsTitle, data: convertedUpcomingEvents))
            }
            DispatchQueue.main.async {[weak self] in self?.dataModel = eventsToReturn}
        }
    }
    
    fileprivate func createImage(fromImageInfo imageInfo: EventImageInfo, locationForCellView: CGFloat) -> UIImage? {
        //let renderer = UIGraphicsImageRenderer(size: imageSize, format: UIGraphicsImageRendererFormat.preferred())
        
        let fileName = imageInfo.title.convertToFileName() + ".jpg"
        let fileURL = sharedImageLocationURL.appendingPathComponent(fileName, isDirectory: false)
        guard let originalImage = UIImage(contentsOfFile: fileURL.path) else {
            // TODO: return nil. Label saying there was an error loading image?
            fatalError("There was an error loading the image from the path provided.")
        }
        
        let cropRectHeight = imageSize.height
        let cropRect = CGRect(x: 0, y: (originalImage.size.height * locationForCellView) - (cropRectHeight / 2), width: originalImage.size.width, height: cropRectHeight)
        return originalImage.croppedImage(inRect: cropRect)
    }
    
    fileprivate func share(events: [EventData]) {
        
    }
}
