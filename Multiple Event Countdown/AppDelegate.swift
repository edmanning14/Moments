//
//  AppDelegate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift
import Foundation
import UserNotifications

//
// MARK: Global Constants
//
//
// MARK: Data Management
enum EventFilters {
    case all, upcoming, past
    
    var string: String {
        switch self {
        case .all: return "All Events"
        case .upcoming: return "Upcoming Events"
        case .past: return "Past Events"
        }
    }
    
    static func type(from: String) -> EventFilters? {
        switch from {
        case EventFilters.all.string: return EventFilters.all
        case EventFilters.upcoming.string: return EventFilters.upcoming
        case EventFilters.past.string: return EventFilters.past
        default: return nil
        }
    }
}
enum SortMethods {
    case chronologically, byCategory
    
    var string: String {
        switch self {
        case .chronologically: return "Chronologically"
        case .byCategory: return "By Category"
        }
    }
    
    static func type(from: String) -> SortMethods? {
        switch from {
        case SortMethods.chronologically.string: return SortMethods.chronologically
        case SortMethods.byCategory.string: return SortMethods.byCategory
        default: return nil
        }
    }
}

// MARK: Shared UI
func titleOnlyHeaderView(title: String) -> UIView {
    let headerView = UITableViewHeaderFooterView()
    let bgView = UIView()
    bgView.translatesAutoresizingMaskIntoConstraints = false
    bgView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
    headerView.backgroundView = bgView
    
    headerView.textLabel?.text = title
    headerView.textLabel?.backgroundColor = UIColor.clear
    headerView.textLabel?.textAlignment = .left
    
    return headerView
}

func createHeaderDropdownButton() -> UIButton {
    let navItemTitleButton = UIButton()
    navItemTitleButton.showsTouchWhenHighlighted = false
    navItemTitleButton.setImage(#imageLiteral(resourceName: "ExpandSelectionImage"), for: .normal)
    navItemTitleButton.contentEdgeInsets.left = 26.0
    navItemTitleButton.contentEdgeInsets.top = 8.0
    navItemTitleButton.contentEdgeInsets.bottom = 8.0
    navItemTitleButton.contentEdgeInsets.right = 16
    navItemTitleButton.imageEdgeInsets.left = -20.0
    navItemTitleButton.tintColor = GlobalColors.orangeRegular
    navItemTitleButton.setTitleColor(GlobalColors.orangeRegular, for: .normal)
    navItemTitleButton.titleLabel!.textAlignment = .center
    navItemTitleButton.backgroundColor = UIColor.clear
    navItemTitleButton.titleLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
    return navItemTitleButton
}

//
// MARK: Notifications
var shouldUpdateDailyNotifications = false

func scheduleNewEvents  (titled eventTitles: [String]) {
    var notifsThatNeedBadge = [Date: [(String, UNMutableNotificationContent, UNNotificationTrigger)]]()
    autoreleasepool {
        let scheduleAndUpdateRealm = try! Realm(configuration: appRealmConfig)
        let defaultNotificationsConfig = scheduleAndUpdateRealm.objects(DefaultNotificationsConfig.self)[0]
        
        print("Notifications stored at start of add event cycle:")
        let allEventNotifications = scheduleAndUpdateRealm.objects(RealmEventNotification.self)
        for (i, realmNotif) in allEventNotifications.enumerated() {
            print("\(i + 1): \(realmNotif.uuid)")
        }
        
        if defaultNotificationsConfig.allOn && defaultNotificationsConfig.individualEventRemindersOn {
            for eventTitle in eventTitles {
                
                let localManagedSpecialEvent = scheduleAndUpdateRealm.objects(SpecialEvent.self).filter("title = %@", eventTitle)[0]
                let specialEventDate = localManagedSpecialEvent.date!.date
                let scheduleAndUpdateSpecialEvents = scheduleAndUpdateRealm.objects(SpecialEvent.self)
                
                //
                // Create notifs for the new event.
                if let specialEventConfig = localManagedSpecialEvent.notificationsConfig, specialEventConfig.eventNotificationsOn {
                    
                    for (i, realmEventNotification) in specialEventConfig.eventNotifications.enumerated() {
                        
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.sound = UNNotificationSound.default()
                        var trigger: UNCalendarNotificationTrigger!
                        let eventDateComponents = Calendar.current.dateComponents(yearToSecondsComponents, from: specialEventDate)
                        
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [realmEventNotification.uuid])
                        
                        let _type = EventNotification.Types(string: realmEventNotification.type)
                        var _value: Int?
                        var _precision: String?
                        var _calendarComponent: Calendar.Component?
                        
                        func setValuePrecisionComponent() {
                            if let month = realmEventNotification.notificationComponents?.month.value {
                                _value = month
                                if month == 1 {_precision = "month"} else {_precision = "months"}
                                _calendarComponent = .month
                            }
                            else if let day = realmEventNotification.notificationComponents?.day.value {
                                _value = day
                                if day == 1 {_precision = "day"} else {_precision = "days"}
                                _calendarComponent = .day
                            }
                            else if let hour = realmEventNotification.notificationComponents?.hour.value {
                                _value = hour
                                if hour == 1 {_precision = "hour"} else {_precision = "hours"}
                                _calendarComponent = .hour
                            }
                            else if let minute = realmEventNotification.notificationComponents?.minute.value {
                                _value = minute
                                if minute == 1 {_precision = "minute"} else {_precision = "minutes"}
                                _calendarComponent = .minute
                            }
                            else if let second = realmEventNotification.notificationComponents?.second.value {
                                _value = second
                                if second == 1 {_precision = "second"} else {_precision = "seconds"}
                                _calendarComponent = .second
                            }
                        }
                        
                        guard let type = _type else {
                            // TODO: Log, don't create notification.
                            fatalError("Type was nil!")
                        }
                        
                        switch type {
                        case .beforeEvent:
                            setValuePrecisionComponent()
                            guard let value = _value, let precision = _precision, let calendarComponent = _calendarComponent else {
                                // TODO: Log, don't create notification.
                                fatalError("Value or precision was nil!")
                            }
                            if let newDate = Calendar.current.date(byAdding: calendarComponent, value: -value, to: specialEventDate, wrappingComponents: false) {
                                let triggerComponents = Calendar.current.dateComponents(yearToSecondsComponents, from: newDate)
                                trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                                
                                if precision == "month" || precision == "months" {notificationContent.title = "Your Special Moment is Coming Up! ⏳"}
                                else {notificationContent.title = "It's Almost Time! ⌛️"}
                                
                                let bodyString = "\"\(localManagedSpecialEvent.title)\" is in \(value) \(precision)!"
                                notificationContent.body = bodyString
                            }
                            else {
                                // TODO: Log, don't create notification
                                fatalError("Couldn't create new date!")
                            }
                        case .afterEvent:
                            setValuePrecisionComponent()
                            guard let value = _value, let precision = _precision, let calendarComponent = _calendarComponent else {
                                // TODO: Log, don't create notification.
                                fatalError("Value or precision was nil!")
                            }
                            
                            if let newDate = Calendar.current.date(byAdding: calendarComponent, value: value, to: specialEventDate, wrappingComponents: false) {
                                let triggerComponents = Calendar.current.dateComponents(yearToSecondsComponents, from: newDate)
                                trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                                
                                notificationContent.title = "Fond Memories ❤️"
                                let bodyString = "\"\(localManagedSpecialEvent.title)\" happened \(value) \(precision) ago."
                                notificationContent.body = bodyString
                            }
                            else {
                                // TODO: Log, don't create notification
                                fatalError("Couldn't create new date!")
                            }
                        case .dayOfEvent:
                            guard let hour = realmEventNotification.notificationComponents?.hour.value else {
                                // TODO: Log, don't create notification.
                                fatalError("hour was nil!")
                            }
                            guard let minute = realmEventNotification.notificationComponents?.hour.value else {
                                // TODO: Log, don't create notification.
                                fatalError("minute was nil!")
                            }
                            
                            trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, era: nil, year: eventDateComponents.year, month: eventDateComponents.month, day: eventDateComponents.day, hour: hour, minute: minute, second: 0, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil), repeats: false)
                            notificationContent.title = "Get Excited! 🎉"
                            let bodyString = "\"\(localManagedSpecialEvent.title)\" is today!!!"
                            notificationContent.body = bodyString
                        case .timeOfEvent:
                            trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(calendar: Calendar.current, timeZone: TimeZone.current, era: nil, year: eventDateComponents.year, month: eventDateComponents.month, day: eventDateComponents.day, hour: eventDateComponents.hour, minute: eventDateComponents.minute, second: eventDateComponents.second, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil), repeats: false)
                            notificationContent.title = "Time to Celebrate! 🎉"
                            let bodyString = "\"\(localManagedSpecialEvent.title)\" is happening RIGHT NOW! Congratulations!"
                            notificationContent.body = bodyString
                        }
                        
                        if let triggerDate = trigger.nextTriggerDate() {
                            let newIdent =  UUID().uuidString
                            do {try! scheduleAndUpdateRealm.write {localManagedSpecialEvent.notificationsConfig!.eventNotifications[i].uuid = newIdent}}
                            print("written uuid: \(localManagedSpecialEvent.notificationsConfig!.eventNotifications[i].uuid)")

                            print("Notifications stored during add event cycle:")
                            let allEventNotifications = scheduleAndUpdateRealm.objects(RealmEventNotification.self)
                            for (i, realmNotif) in allEventNotifications.enumerated() {
                                print("\(i + 1): \(realmNotif.uuid)")
                            }
                            
                            if currentCalendar.isDate(localManagedSpecialEvent.date!.date, inSameDayAs: triggerDate) {
                                var addNew = true
                                for date in notifsThatNeedBadge.keys {
                                    if currentCalendar.isDate(date, inSameDayAs: triggerDate) {
                                        notifsThatNeedBadge[date]!.append((newIdent, notificationContent, trigger)); addNew = false
                                    }
                                }
                                if addNew {notifsThatNeedBadge[triggerDate] = [(newIdent, notificationContent, trigger)]}
                            }
                            else {
                                let newRequest = UNNotificationRequest(identifier: newIdent, content: notificationContent, trigger: trigger)
                                schedule(request: newRequest)
                            }
                        }
                    }
                }
            }
            
            print("Trigger group count: \(notifsThatNeedBadge.count)")
            for value in notifsThatNeedBadge.values {
                print("Number of values in each trigger group: \(value.count)")
            }
            
            if !notifsThatNeedBadge.isEmpty {
                UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                    
                    for request in requests {
                        guard request.content.title != dailyNotificationsTitle else {continue}
                        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger, let triggerDate = calendarTrigger.nextTriggerDate() {
                            for keyDate in notifsThatNeedBadge.keys {
                                if currentCalendar.isDate(triggerDate, inSameDayAs: keyDate) {
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = request.content.title
                                    content.body = request.content.body
                                    content.sound = request.content.sound
                                    let newIdent = UUID().uuidString
                                    
                                    autoreleasepool {
                                        let changeUUIDRealm = try! Realm(configuration: appRealmConfig)
                                        print("Looking for: \(request.identifier)")
                                        let notifOfInterest = changeUUIDRealm.objects(RealmEventNotification.self).filter("uuid = %@", request.identifier)[0]
                                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifOfInterest.uuid])
                                        do {try! changeUUIDRealm.write {notifOfInterest.uuid = newIdent}}
                                        print("Written ident: \(newIdent)")
                                        
                                        print("Notifications stored during old notifications fetch:")
                                        let allEventNotifications = changeUUIDRealm.objects(RealmEventNotification.self)
                                        for (i, realmNotif) in allEventNotifications.enumerated() {
                                            print("\(i + 1): \(realmNotif.uuid)")
                                        }
                                    }
                                    
                                    notifsThatNeedBadge[keyDate]!.append((newIdent, content, calendarTrigger))
                                }
                            }
                        }
                        else {
                            // TODO: Log, continue
                            fatalError("Unexpected trigger type or no trigger!")
                        }
                    }
                    
                    guard !notifsThatNeedBadge.isEmpty else {return}
                    
                    //
                    // Order requests
                    for triggerGroup in notifsThatNeedBadge {
                        let newValue = triggerGroup.value.sorted { (request1, request2) -> Bool in
                            let request1Trigger = request1.2 as! UNCalendarNotificationTrigger
                            let request2Trigger = request2.2 as! UNCalendarNotificationTrigger
                            let request1TriggerDate = currentCalendar.date(from: request1Trigger.dateComponents)!
                            let request2TriggerDate = currentCalendar.date(from: request2Trigger.dateComponents)!
                            if request1TriggerDate < request2TriggerDate {return true} else {return false}
                        }
                        notifsThatNeedBadge[triggerGroup.key] = newValue
                    }
                    
                    for value in notifsThatNeedBadge.values {
                        for data in value {
                            let trigger = data.2 as! UNCalendarNotificationTrigger
                            let triggerDate = currentCalendar.date(from: trigger.dateComponents)!
                            print("\(data.1.body) triggers \(triggerDate)")
                        }
                    }
                    
                    for triggerGroup in notifsThatNeedBadge {
                        for (i, value) in triggerGroup.value.enumerated() {
                            value.1.badge = NSNumber(integerLiteral: i + 1)
                        }
                    }
                    
                    for triggerGroup in notifsThatNeedBadge {
                        for value in triggerGroup.value {print("\(value.1.body) Badge num: \(Int(truncating: value.1.badge ?? 0))")}
                    }
                    
                    //
                    // Schedule the new requests
                    for value in notifsThatNeedBadge.values {
                        for data in value {
                            let newRequest = UNNotificationRequest(identifier: data.0, content: data.1, trigger: data.2)
                            schedule(request: newRequest)
                        }
                    }
                }
            }
            
        }
    }
}

fileprivate func schedule(request: UNNotificationRequest) {
    UNUserNotificationCenter.current().add(request) { (_error) in
        if let error = _error {
            // TODO: Log, continue, maybe alert user that notifs are not working properly.
            print("Request \"\(request.content.body)\" had an error:")
            print(error.localizedDescription)
            fatalError("^ Check error")
        }
    }
}

func updatePendingNotifcationsBadges(forDate date: Date) {
    
    //
    // Get pending notifs that trigger on the date.
    UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
        
        var notificationDataToReschedule = [(String, UNMutableNotificationContent, UNNotificationTrigger)]()
        for request in requests {
            guard request.content.title != dailyNotificationsTitle else {continue}
            if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger, let triggerDate = calendarTrigger.nextTriggerDate() {
                if currentCalendar.isDate(triggerDate, inSameDayAs: date) {
                    
                    let content = UNMutableNotificationContent()
                    content.title = request.content.title
                    content.body = request.content.body
                    content.sound = request.content.sound
                    let newIdent = UUID().uuidString
                    
                    autoreleasepool {
                        let changeUUIDRealm = try! Realm(configuration: appRealmConfig)
                        let notifOfInterest = changeUUIDRealm.objects(RealmEventNotification.self).filter("uuid = %@", request.identifier)[0]
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifOfInterest.uuid])
                        do {try! changeUUIDRealm.write {notifOfInterest.uuid = newIdent}}
                        
                        print("Notifications stored during pending notifications reset:")
                        let allEventNotifications = changeUUIDRealm.objects(RealmEventNotification.self)
                        for (i, realmNotif) in allEventNotifications.enumerated() {
                            print("\(i + 1): \(realmNotif.uuid)")
                        }
                    }
                    
                    notificationDataToReschedule.append((newIdent, content, calendarTrigger))
                }
            }
            else {
                // TODO: Log, continue
                fatalError("Unexpected trigger type or no trigger!")
            }
        }
        
        guard !notificationDataToReschedule.isEmpty else {return}
        
        //
        // Order requests
        notificationDataToReschedule.sort { (request1, request2) -> Bool in
            let request1Trigger = request1.2 as! UNCalendarNotificationTrigger
            let request2Trigger = request2.2 as! UNCalendarNotificationTrigger
            let request1TriggerDate = currentCalendar.date(from: request1Trigger.dateComponents)!
            let request2TriggerDate = currentCalendar.date(from: request2Trigger.dateComponents)!
            
            if request1TriggerDate < request2TriggerDate {return true} else {return false}
        }
        
        /*for request in notificationDataToReschedule {
            let trigger = request.2 as! UNCalendarNotificationTrigger
            let triggerDate = currentCalendar.date(from: trigger.dateComponents)!
            print("\(request.1.body) triggers \(triggerDate)")
        }*/
        
        for (i, data) in notificationDataToReschedule.enumerated() {data.1.badge = NSNumber(integerLiteral: i + 1)}
        
        //for request in notificationDataToReschedule {print("\(request.1.body) Badge num: \(Int(truncating: request.1.badge ?? 0))")}
        
        //
        // Reschedule requests
        for data in notificationDataToReschedule {
            let newRequest = UNNotificationRequest(identifier: data.0, content: data.1, trigger: data.2)
            schedule(request: newRequest)
        }
        
    }
}

let dailyNotificationsTitle = "Daily Update 🗞"
let notificationTimeAsDateKey = "Notification Time As Date"
let currentlyScheduledUUIDKey = "currently Scheduled UUID"
let userDefaults = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")!
let currentCalendar = Calendar.current
let yearToSecondsComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]

func updateDailyNotificationsIfNeeded(async: Bool) {
    let dateNow = Date()
    if let notificationTimeAsDate = userDefaults.value(forKey: notificationTimeAsDateKey) as? Date {
        if dateNow > notificationTimeAsDate {updateDailyNotifications(async: async)}
    }
    else {updateDailyNotifications(async: async)}
}

func updateDailyNotifications(async: Bool) {
    func performWork() {
        autoreleasepool {
            let dailyNotifsRealm = try! Realm(configuration: appRealmConfig)
            let dailyNotifsDefaultNotificationsConfig = dailyNotifsRealm.objects(DefaultNotificationsConfig.self)[0]
            
            if dailyNotifsDefaultNotificationsConfig.allOn && dailyNotifsDefaultNotificationsConfig.dailyNotificationOn {
                if let components = dailyNotifsDefaultNotificationsConfig.dailyNotificationsScheduledTime {
                    
                    let chronologicalUpcomingSpecialEvents = dailyNotifsRealm.objects(SpecialEvent.self).sorted { (event1, event2) in
                        if let eventDate1 = event1.date, let eventDate2 = event2.date {
                            if eventDate1.date < eventDate2.date {return true} else {return false}
                        }
                        else {return false}
                    }.filter { (event) -> Bool in
                            let todaysDate = Date()
                            if event.date!.date.timeIntervalSinceReferenceDate - todaysDate.timeIntervalSinceReferenceDate < 0.0 {
                                return false
                            }
                            else {return true}
                    }
                    
                    let dateNow = Date()
                    let todaysDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: dateNow)
                    guard let previousNotificationTimeAsDate = userDefaults.value(forKey: notificationTimeAsDateKey) as? Date else {
                        userDefaults.set(nil, forKey: notificationTimeAsDateKey);return
                    }
                    var notificationTimeDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: previousNotificationTimeAsDate)
                    guard let day = notificationTimeDateComponents.day else {userDefaults.set(nil, forKey: notificationTimeAsDateKey); return}
                    guard let hour = components.hour.value else {userDefaults.set(nil, forKey: notificationTimeAsDateKey); return}
                    guard let minute = components.minute.value else {userDefaults.set(nil, forKey: notificationTimeAsDateKey); return}
                    
                    notificationTimeDateComponents.day = day + 1
                    notificationTimeDateComponents.hour = hour
                    notificationTimeDateComponents.minute = minute
                    notificationTimeDateComponents.second = 0
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: notificationTimeDateComponents, repeats: false)
                    let defaultEventNotification = UNMutableNotificationContent()
                    defaultEventNotification.sound = UNNotificationSound.default()
                    defaultEventNotification.title = dailyNotificationsTitle
                    
                    let newNotificationDate = currentCalendar.date(from: notificationTimeDateComponents)!
                    notificationTimeDateComponents.day! += 1
                    let nextDayNewNotificationDate = currentCalendar.date(from: notificationTimeDateComponents)!
                    if currentCalendar.isDate(chronologicalUpcomingSpecialEvents[0].date!.date, inSameDayAs: newNotificationDate) { // First notif format
                        
                        var eventTitlesToday = [String]()
                        for event in chronologicalUpcomingSpecialEvents {
                            if let eventDate = event.date {
                                if currentCalendar.isDateInToday(eventDate.date) {eventTitlesToday.append(event.title)}
                                else {break}
                            }
                        }
                        
                        defaultEventNotification.badge = NSNumber(integerLiteral: eventTitlesToday.count)
                        switch eventTitlesToday.count {
                        case 1: defaultEventNotification.body = "Get excited! \"\(eventTitlesToday[0])\" is today!"
                        case 2: defaultEventNotification.body = "Get excited! \"\(eventTitlesToday[0])\" and 1 other event are today!"
                        default: defaultEventNotification.body = "Get excited! \"\(eventTitlesToday[0])\" and \(eventTitlesToday.count - 1) other events are today!"
                        }
                    }
                        
                    else if currentCalendar.isDate(chronologicalUpcomingSpecialEvents[0].date!.date, inSameDayAs: nextDayNewNotificationDate) { // Second notif format
                        
                        var eventTitlesTomorrow = [String]()
                        for event in chronologicalUpcomingSpecialEvents {
                            if let eventDate = event.date {
                                if currentCalendar.isDateInTomorrow(eventDate.date) {eventTitlesTomorrow.append(event.title)}
                                else {break}
                            }
                        }
                        
                        switch eventTitlesTomorrow.count {
                        case 1: defaultEventNotification.body = "Almost there! \"\(eventTitlesTomorrow[0])\" is tomorrow."
                        case 2: defaultEventNotification.body = "Almost there! \"\(eventTitlesTomorrow[0])\" and 1 other event are tomorrow."
                        default: defaultEventNotification.body = "Almost there! \"\(eventTitlesTomorrow[0])\" and \(eventTitlesTomorrow.count - 1) other events are tomorrow"
                        }
                    }
                        
                    else { // Third notif format                        
                        let date = chronologicalUpcomingSpecialEvents[0].date!.date
                        let eventDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: date)
                        
                        var days = Double(eventDateComponents.day! - todaysDateComponents.day!)
                        var months = 0.0
                        var years = 0.0
                        
                        if days < 0.0 {
                            months -= 1.0
                            let eventDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: date)!
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
                        
                        defaultEventNotification.body = "Your next event \"\(chronologicalUpcomingSpecialEvents[0].title)\" is in "
                        
                        if years != 0 {
                            if years == 1.0 {defaultEventNotification.body += "1 year"}
                            else {defaultEventNotification.body += "\(Int(years)) years"}
                            
                            if months != 0 {
                                if months == 1.0 {defaultEventNotification.body += ", 1 month"}
                                else {defaultEventNotification.body += ", \(Int(months)) months"}
                            }
                            
                            if days != 0 {
                                if days == 1.0 {defaultEventNotification.body += ", 1 day"}
                                else {defaultEventNotification.body += ", \(Int(days)) days"}
                            }
                            
                            defaultEventNotification.body += "."
                        }
                            
                        else if months != 0 {
                            if months == 1.0 {defaultEventNotification.body += "1 month"}
                            else {defaultEventNotification.body += "\(Int(months)) months"}
                            
                            if days != 0 {
                                if days == 1.0 {defaultEventNotification.body += ", 1 day"}
                                else {defaultEventNotification.body += ", \(Int(days)) days"}
                            }
                            
                            defaultEventNotification.body += "."
                        }
                            
                        else { // Days must not be equal to 0.
                            if days == 1.0 {defaultEventNotification.body += "1 day."}
                            else {defaultEventNotification.body += "\(Int(days)) days."}
                        }
                    }
                    
                    if let notificationTimeDate = currentCalendar.date(from: notificationTimeDateComponents) {
                        userDefaults.set(notificationTimeDate, forKey: notificationTimeAsDateKey)
                    }
                    else {
                        // TODO: Log and return false
                        fatalError("Date couldn't be created!")
                    }
                    
                    if let currentlyScheduledUUID = userDefaults.value(forKey: currentlyScheduledUUIDKey) as? String {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [currentlyScheduledUUID])
                    }
                    
                    let ident = UUID().uuidString
                    
                    let request = UNNotificationRequest(identifier: ident, content: defaultEventNotification, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { (_error) in
                        if let error = _error {
                            // TODO: Log, send failed to completion handler, remove lastFetchAtempt so that another attempt can be made.
                            print(error.localizedDescription)
                            fatalError("^ Check error")
                        }
                    }
                    
                    userDefaults.set(ident, forKey: currentlyScheduledUUIDKey)
                }
                else {userDefaults.set(nil, forKey: notificationTimeAsDateKey)}
            }
            else {
                if let currentlyScheduledUUID = userDefaults.value(forKey: currentlyScheduledUUIDKey) as? String {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [currentlyScheduledUUID])
                }
                userDefaults.set(nil, forKey: notificationTimeAsDateKey)
            }
        }
    }
    
    if async {DispatchQueue.global(qos: .background).async {performWork()}}
    else {performWork()}
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        /*for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }*/
        
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 60 * 8)
        UITableViewCell.appearance().backgroundColor = .clear
        
        //
        // MARK: initial app setup.
        //
        //
        // MARK: User defaults config
        let userDefaults = UserDefaults.standard
        if userDefaults.string(forKey: UserDefaultKeys.DataManagement.currentFilter) == nil {
            userDefaults.set(EventFilters.all.string, forKey: UserDefaultKeys.DataManagement.currentFilter)
            userDefaults.set(SortMethods.chronologically.string, forKey: UserDefaultKeys.DataManagement.currentSort)
            userDefaults.set(true, forKey: UserDefaultKeys.DataManagement.futureToPast)
            userDefaults.set(Defaults.DateDisplayMode.short, forKey: UserDefaultKeys.dateDisplayMode)
        }
        
        //
        // MARK: Notification config
        let launchRealm = try! Realm(configuration: appRealmConfig)
        let defaultNotificationConfig = launchRealm.objects(DefaultNotificationsConfig.self)
        
        if defaultNotificationConfig.count == 0 {
            let newConfig = DefaultNotificationsConfig()
            newConfig.allOn = Defaults.Notifications.allOn
            newConfig.dailyNotificationOn = Defaults.Notifications.dailyNotificationsOn
            let newRealmComponents = RealmEventNotificationComponents(fromDateComponents: Defaults.Notifications.dailyNotificationsScheduledTime)
            newConfig.dailyNotificationsScheduledTime = newRealmComponents
            newConfig.individualEventRemindersOn = Defaults.Notifications.individualEventRemindersOn
            let realmNotifTimes = List<RealmEventNotification>()
            for eventNotif in Defaults.Notifications.eventNotifications {
                realmNotifTimes.append(RealmEventNotification(fromEventNotification: eventNotif))
            }
            newConfig.eventNotifications.append(objectsIn: realmNotifTimes)
            newConfig.categoriesToNotify = Defaults.Notifications.categoriesToNotify
            
            do {try! launchRealm.write {launchRealm.add(newConfig)}}
            
            print("Notifications stored after initial realm init:")
            let allEventNotifications = launchRealm.objects(RealmEventNotification.self)
            for (i, realmNotif) in allEventNotifications.enumerated() {
                print("\(i + 1): \(realmNotif.uuid)")
            }
        }
        
        //
        // MARK: Data model config
        let eventImages = launchRealm.objects(EventImageInfo.self)
        
        if eventImages.count == 0 {
            
            print(sharedImageLocationURL)
            do {try FileManager.default.createDirectory(at: sharedImageLocationURL, withIntermediateDirectories: false, attributes: nil)}
            catch {
                // TODO: Error handling.
                print(error.localizedDescription)
                fatalError()
            }
            
            // Add image info for images on the disk to the persistent store
            for imageInfo in AppEventImage.bundleMainImageInfo {
                let fileRootName = imageInfo.title.convertToFileName()
                if let mainImageSourceURL = Bundle.main.url(forResource: fileRootName, withExtension: ".jpg") {
                    if imageInfo.hasMask {
                        if let maskImageSourceURL = Bundle.main.url(forResource: fileRootName + "Mask", withExtension: ".png") {
                            do {try! launchRealm.write {launchRealm.add(imageInfo)}}
                            
                            let maskDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Mask.png", isDirectory: false)
                            do {try FileManager.default.copyItem(at: maskImageSourceURL, to: maskDestinationURL)}
                            catch {
                                // TODO: Error handling.
                                print(error.localizedDescription)
                                fatalError()
                            }
                        }
                        else {
                            let imageInfoToAdd = EventImageInfo(
                                imageTitle: imageInfo.title,
                                imageCategory: imageInfo.category,
                                isAppImage: imageInfo.isAppImage,
                                recordName: nil,
                                hasMask: imageInfo.hasMask,
                                recommendedLocationForCellView: imageInfo.recommendedLocationForCellView.value
                            )
                            do {try! launchRealm.write {launchRealm.add(imageInfoToAdd)}}
                        }
                    }
                    else {do {try! launchRealm.write {launchRealm.add(imageInfo)}}}
                
                    let mainDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + ".jpg", isDirectory: false)
                    do {try FileManager.default.copyItem(at: mainImageSourceURL, to: mainDestinationURL)}
                    catch {
                        // TODO: Error handling.
                        print(error.localizedDescription)
                        fatalError()
                    }
                    
                    if let mainThumbnail1xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@1x", withExtension: ".jpg") {
                        let mainThumbnail1xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@1x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail1xSourceURL, to: mainThumbnail1xDestinationURL)}
                        catch {
                            // TODO: Error handling.
                            print(error.localizedDescription)
                            fatalError()
                        }
                    }
                    if let mainThumbnail2xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@2x", withExtension: ".jpg") {
                        let mainThumbnail2xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@2x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail2xSourceURL, to: mainThumbnail2xDestinationURL)}
                        catch {
                            // TODO: Error handling.
                            print(error.localizedDescription)
                            fatalError()
                        }
                    }
                    if let mainThumbnail3xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@3x", withExtension: ".jpg") {
                        let mainThumbnail3xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@3x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail3xSourceURL, to: mainThumbnail3xDestinationURL)}
                        catch {
                            // TODO: Error handling.
                            print(error.localizedDescription)
                            fatalError()
                        }
                    }
                }
            }
            
            // Create the default event.
            struct DefaultEvent {
                static let category = "Holidays"
                static let title = "New Years!"
                static let tagline = "Party like it's 1989"
                static var date: EventDate = {
                    let calender = Calendar.current
                    var dateComponents = DateComponents()
                    dateComponents.second = 0
                    dateComponents.minute = 0
                    dateComponents.hour = 0
                    dateComponents.day = 1
                    dateComponents.month = 1
                    dateComponents.year = calender.component(.year, from: Date()) + 1
                    let newYearsDay = calender.date(from: dateComponents)!
                    return EventDate(date: newYearsDay, dateOnly: true)
                }()
                static var notificationsConfig: RealmEventNotificationConfig = {
                    var eventNotifs = [RealmEventNotification]()
                    for eventNotif in Defaults.Notifications.eventNotifications {
                        let realmEventNotif = RealmEventNotification(copyingEventNotification: eventNotif)
                        eventNotifs.append(realmEventNotif)
                    }
                    return RealmEventNotificationConfig(eventNotifications: eventNotifs)
                }()
                static let imageTitle = "Desert Dunes"
                static let useMask: Bool = true
            }
            
            if let i = eventImages.index(where: {$0.title == DefaultEvent.imageTitle}) {
                let defaultImageInfo = eventImages[i]
                var locationForCellView: CGFloat?
                if let intRecommendedLocationForCellView = defaultImageInfo.recommendedLocationForCellView.value {
                    locationForCellView = CGFloat(intRecommendedLocationForCellView) / 100.0
                }
                let defaultEvent = SpecialEvent(
                    category: DefaultEvent.category,
                    title: DefaultEvent.title,
                    tagline: DefaultEvent.tagline,
                    date: DefaultEvent.date,
                    abridgedDisplayMode: false,
                    infoDisplayed: .tagline,
                    repeats: .never,
                    notificationsConfig: DefaultEvent.notificationsConfig,
                    useMask: DefaultEvent.useMask,
                    image: defaultImageInfo,
                    locationForCellView: locationForCellView
                )
                try! launchRealm.write {launchRealm.add(defaultEvent)}
            }
            else {
                // TODO: error handling
                fatalError("Default Image for the default event was not on the disk!")
            }
        }
        
        // Setup split view controller.
        let splitViewController = window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if shouldUpdateDailyNotifications {updateDailyNotifications(async: false); shouldUpdateDailyNotifications = false}
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    updateDailyNotificationsIfNeeded(async: true)
                    if UIApplication.shared.applicationIconBadgeNumber != 0 {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        updatePendingNotifcationsBadges(forDate: Date())
                    }
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let dateNow = Date()
        let backgroundFetchRealm = try! Realm(configuration: appRealmConfig)
        let backgroundFetchDefaultNotificationsConfig = backgroundFetchRealm.objects(DefaultNotificationsConfig.self)[0]
        if let notificationTimeAsDate = userDefaults.value(forKey: notificationTimeAsDateKey) as? Date {
            if dateNow > notificationTimeAsDate {
                updateDailyNotifications(async: false)
                if backgroundFetchDefaultNotificationsConfig.allOn && backgroundFetchDefaultNotificationsConfig.dailyNotificationOn {
                    completionHandler(.newData)
                }
                else {completionHandler(.noData)}
            }
            else {completionHandler(.noData)}
        }
        else {
            updateDailyNotifications(async: false)
            if backgroundFetchDefaultNotificationsConfig.allOn && backgroundFetchDefaultNotificationsConfig.dailyNotificationOn {
                completionHandler(.newData)
            }
            else {completionHandler(.noData)}
        }
    }
    
    
    //
    // MARK: - Split view
    //

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.specialEvent == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

