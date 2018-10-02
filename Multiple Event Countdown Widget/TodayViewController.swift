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

class TodayViewController: UIViewController, NCWidgetProviding {
    
    //
    // MARK: Data Model
    fileprivate var mainRealm: Realm!
    fileprivate var allSpecialEvents: Results<SpecialEvent>!
    
    fileprivate var numberOfEventsToday = 0 {
        didSet {
            if numberOfEventsToday > 0 {
                compactViewNumberLabel.text = String(numberOfEventsToday)
                numberLabelContainerView.isHidden = false
                compactViewMasterLabel.text = "Events Today!"
            }
            else {
                numberLabelContainerView.isHidden = true
                compactViewMasterLabel.text = "No Events Today"
            }
        }
    }
    
    //
    // MARK: GUI
    @IBOutlet weak var compactView: UIVisualEffectView!
    @IBOutlet weak var numberLabelContainerView: UIView!
    @IBOutlet weak var compactViewNumberLabel: UILabel!
    @IBOutlet weak var compactViewMasterLabel: UILabel!
    @IBOutlet weak var compactViewDetailLabel: UILabel!
    
    //
    // MARK: Other
    let currentCalendar = Calendar.current
    
    //
    // MARK: Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainRealm = try! Realm(configuration: widgetRealmConfig)
        allSpecialEvents = mainRealm.objects(SpecialEvent.self)
        
        populateCompactView()
        let openAppTap = UITapGestureRecognizer(target: self, action: #selector(openApp))
        view.addGestureRecognizer(openAppTap)
        
        extensionContext?.widgetLargestAvailableDisplayMode = .compact
        compactView.effect = UIVibrancyEffect.widgetPrimary()
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    //
    // MARK: NCWidgetProviding Delegate
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {completionHandler(NCUpdateResult.noData)}
    
    //
    // MARK: Actions
    
    //
    // MARK: Helper methods
    @objc fileprivate func openApp() {
        if let appURL = URL(string: "Moments://") {extensionContext?.open(appURL, completionHandler: nil)}
    }
    
    fileprivate func populateCompactView() {
        let chronologicalUpcomingEvents = allSpecialEvents.sorted { (event1, event2) -> Bool in
            if let eventDate1 = event1.date, let eventDate2 = event2.date {
                if eventDate1.date < eventDate2.date {return true} else {return false}
            }
            else {return false}
        }.filter { (specialEvent) -> Bool in
            if specialEvent.date!.date > Date() {return true} else {return false}
        }
        
        if !chronologicalUpcomingEvents.isEmpty {
            let eventsToday = chronologicalUpcomingEvents.filter { (specialEvent) -> Bool in
                if currentCalendar.isDateInToday(specialEvent.date!.date) {return true}
                else {return false}
            }
            numberOfEventsToday = eventsToday.count
            if !eventsToday.isEmpty {
                switch eventsToday.count {
                case 0: break
                case 1: compactViewDetailLabel.text = "\"\(eventsToday[0].title)\" is today!"
                case 2: compactViewDetailLabel.text = "\"\(eventsToday[0].title)\" and 1 other event are today!"
                default: compactViewDetailLabel.text = "\"\(eventsToday[0].title)\" and \(numberOfEventsToday - 1) other events are today!"
                }
            }
            else {
                let eventsTomorrow = chronologicalUpcomingEvents.filter { (specialEvent) -> Bool in
                    if currentCalendar.isDateInTomorrow(specialEvent.date!.date) {return true}
                    else {return false}
                }
                if !eventsTomorrow.isEmpty {
                    switch eventsTomorrow.count {
                    case 1: compactViewDetailLabel.text = "\"\(eventsTomorrow[0].title)\" is tomorrow."
                    case 2: compactViewDetailLabel.text = "\"\(eventsTomorrow[0].title)\" and 1 other event are tomorrow."
                    default: compactViewDetailLabel.text = "\"\(eventsTomorrow[0].title)\" and \(eventsTomorrow.count - 1) other events are tomorrow."
                    }
                }
                else {
                    let eventsNotTodayOrTomorrow = chronologicalUpcomingEvents.filter { (event) -> Bool in
                        if currentCalendar.isDateInToday(event.date!.date) {return false}
                        else if currentCalendar.isDateInTomorrow(event.date!.date) {return false}
                        else {return true}
                    }
                    if !eventsNotTodayOrTomorrow.isEmpty {
                        let yearToSecondsComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
                        let event = eventsNotTodayOrTomorrow[0]
                        let dateNow = Date()
                        let todaysDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: dateNow)
                        let eventDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: event.date!.date)
                        
                        var detailLabelText = ""
                        var days = Double(eventDateComponents.day! - todaysDateComponents.day!)
                        var months = 0.0
                        var years = 0.0
                        
                        if days < 0.0 {
                            months -= 1.0
                            let eventDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: event.date!.date)!
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
                }
            }
        }
        else {
            compactViewNumberLabel.isHidden = true
            compactViewMasterLabel.text = "You have no events!"
            compactViewDetailLabel.text = "Tap to open app and create a new event!"
        }
    }
}
