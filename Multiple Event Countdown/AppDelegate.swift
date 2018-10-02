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
import os

//
// MARK: Global Constants
//
//
// MARK: Data Management
enum EventFilters: String {
    case all = "All Moments"
    case upcoming = "Upcoming"
    case past = "Past"
}
enum SortMethods: String {
    case chronologically = "Chronologically"
    case byCategory = "By Category"
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

func scheduleNewEvents (titled eventTitles: [String]) {
    #if DEBUG
    print("Creating notifs for: \(eventTitles)")
    #endif
    var notifsThatNeedBadge = [Date: [(String, UNMutableNotificationContent, UNNotificationTrigger)]]()
    autoreleasepool {
        let scheduleAndUpdateRealm = try! Realm(configuration: appRealmConfig)
        let defaultNotificationsConfig = scheduleAndUpdateRealm.objects(DefaultNotificationsConfig.self)[0]
        
        #if DEBUG
        print("Notifications stored at start of add event cycle:")
        let allEventNotifications = scheduleAndUpdateRealm.objects(RealmEventNotification.self)
        for (i, realmNotif) in allEventNotifications.enumerated() {
            print("\(i + 1): \(realmNotif.uuid)")
        }
        #endif
        
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
                            os_log("Notification creation failed, type was nil when creating \"%@\".", log: .default, type: .error, eventTitle)
                            continue
                        }
                        
                        switch type {
                        case .beforeEvent:
                            setValuePrecisionComponent()
                            guard let value = _value, let precision = _precision, let calendarComponent = _calendarComponent else {
                                os_log("Notification creation failed, value or precision was nil when creating \"%@\".", log: .default, type: .error, eventTitle)
                                continue
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
                                os_log("Notification creation failed, couldn't create trigger date for \"%@\".", log: .default, type: .error, eventTitle)
                                continue
                            }
                        case .afterEvent:
                            setValuePrecisionComponent()
                            guard let value = _value, let precision = _precision, let calendarComponent = _calendarComponent else {
                                os_log("Notification creation failed, value or precision was nil when creating \"%@\".", log: .default, type: .error, eventTitle)
                                continue
                            }
                            
                            if let newDate = Calendar.current.date(byAdding: calendarComponent, value: value, to: specialEventDate, wrappingComponents: false) {
                                let triggerComponents = Calendar.current.dateComponents(yearToSecondsComponents, from: newDate)
                                trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                                
                                notificationContent.title = "Fond Memories ❤️"
                                let bodyString = "\"\(localManagedSpecialEvent.title)\" happened \(value) \(precision) ago."
                                notificationContent.body = bodyString
                            }
                            else {
                                os_log("Notification creation failed, couldn't create trigger date for \"%@\".", log: .default, type: .error, eventTitle)
                                continue
                            }
                        case .dayOfEvent:
                            guard let hour = realmEventNotification.notificationComponents?.hour.value else {
                                os_log("Notification creation failed, hour was nil when creating \"%@\".", log: .default, type: .error, eventTitle)
                                continue
                            }
                            guard let minute = realmEventNotification.notificationComponents?.hour.value else {
                                os_log("Notification creation failed, minute was nil when creating \"%@\".", log: .default, type: .error, eventTitle)
                                continue
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
                            
                            #if DEBUG
                            print("Written uuid: \(localManagedSpecialEvent.notificationsConfig!.eventNotifications[i].uuid)")
                            print("Notifications stored after write:")
                            let allEventNotifications = scheduleAndUpdateRealm.objects(RealmEventNotification.self)
                            for (i, realmNotif) in allEventNotifications.enumerated() {
                                print("\(i + 1): \(realmNotif.uuid)")
                            }
                            #endif
                            
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
            
            #if DEBUG
            print("Trigger group count: \(notifsThatNeedBadge.count)")
            for value in notifsThatNeedBadge.values {
                print("Number of values in each trigger group: \(value.count)")
            }
            #endif
            
            if !notifsThatNeedBadge.isEmpty {
                UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                    var updateBadgesToZero = false
                    for request in requests {
                        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger, let triggerDate = calendarTrigger.nextTriggerDate() {
                            for keyDate in notifsThatNeedBadge.keys {
                                if currentCalendar.isDate(triggerDate, inSameDayAs: keyDate) {
                                    
                                    if request.content.title == dailyNotificationsTitle {updateBadgesToZero = true; continue}
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = request.content.title
                                    content.body = request.content.body
                                    content.sound = request.content.sound
                                    let newIdent = UUID().uuidString
                                    
                                    autoreleasepool {
                                        let changeUUIDRealm = try! Realm(configuration: appRealmConfig)
                                        #if DEBUG
                                        print("Looking for: \(request.identifier)")
                                        #endif
                                        let notifOfInterestResult = changeUUIDRealm.objects(RealmEventNotification.self).filter("uuid = %@", request.identifier)
                                        guard notifOfInterestResult.count == 1 else {
                                            // Realm data corrupted somehow, remove all pending requests and do a full reschedule.
                                            os_log("Found a scheduled UUID that was not found in Realm during getPendingNotificationRequests run, performing full reschedule", log: .default, type: .error)
                                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: requests.map({$0.identifier}))
                                            
                                            let changeUUIDSpecialEvents = changeUUIDRealm.objects(SpecialEvent.self)
                                            updateDailyNotifications(async: false)
                                            scheduleNewEvents(titled: changeUUIDSpecialEvents.map({$0.title}))
                                            return
                                        }
                                        let notifOfInterest = notifOfInterestResult[0]
                                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifOfInterest.uuid])
                                        do {try! changeUUIDRealm.write {notifOfInterest.uuid = newIdent}}
                                        
                                        #if DEBUG
                                        print("Written ident: \(newIdent)")
                                        print("Notifications stored during old notifications fetch:")
                                        let allEventNotifications = changeUUIDRealm.objects(RealmEventNotification.self)
                                        for (i, realmNotif) in allEventNotifications.enumerated() {
                                            print("\(i + 1): \(realmNotif.uuid)")
                                        }
                                        #endif
                                    }
                                    
                                    notifsThatNeedBadge[keyDate]!.append((newIdent, content, calendarTrigger))
                                }
                            }
                        }
                        else {
                            os_log("Notification creation failed, unexpected or no trigger type found when creating \"%@\".", log: .default, type: .error, request.content)
                            continue
                        }
                    }
                    
                    guard !notifsThatNeedBadge.isEmpty else {return}
                    
                    //
                    // Order requests
                    if updateBadgesToZero {for data in notifsThatNeedBadge.values {
                        for notif in data {notif.1.badge = NSNumber(integerLiteral: 0)}}
                    }
                    else {
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
                                #if DEBUG
                                print("\(data.1.body) triggers \(triggerDate)")
                                #endif
                            }
                        }
                        
                        for triggerGroup in notifsThatNeedBadge {
                            for (i, value) in triggerGroup.value.enumerated() {
                                value.1.badge = NSNumber(integerLiteral: i + 1)
                            }
                        }
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
        if let error = _error {os_log("%@", log: .default, type: .error, error.localizedDescription)}
    }
}

func updatePendingNotifcationsBadges(forDate date: Date) {
    #if DEBUG
    print("Updating pending notification requests")
    #endif
    //
    // Get pending notifs that trigger on the date.
    UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
        
        var updateBadgesToZero = false
        var notificationDataToReschedule = [(String, UNMutableNotificationContent, UNNotificationTrigger)]()
        for request in requests {
            if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger, let triggerDate = calendarTrigger.nextTriggerDate() {
                if currentCalendar.isDate(triggerDate, inSameDayAs: date) {
                    
                    if request.content.title == dailyNotificationsTitle {updateBadgesToZero = true; continue}
                    
                    let content = UNMutableNotificationContent()
                    content.title = request.content.title
                    content.body = request.content.body
                    content.sound = request.content.sound
                    let newIdent = UUID().uuidString
                    
                    autoreleasepool {
                        let changeUUIDRealm = try! Realm(configuration: appRealmConfig)
                        #if DEBUG
                        print("Looking for: \(request.identifier)")
                        #endif
                        let notifOfInterestResult = changeUUIDRealm.objects(RealmEventNotification.self).filter("uuid = %@", request.identifier)
                        guard notifOfInterestResult.count == 1 else {
                            // Realm data corrupted somehow, remove all pending requests and do a full reschedule.
                            os_log("Found a scheduled UUID that was not found in Realm during getPendingNotificationRequests run, performing full reschedule", log: .default, type: .error)
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: requests.map({$0.identifier}))
                            
                            let changeUUIDSpecialEvents = changeUUIDRealm.objects(SpecialEvent.self)
                            updateDailyNotifications(async: false)
                            scheduleNewEvents(titled: changeUUIDSpecialEvents.map({$0.title}))
                            return
                        }
                        let notifOfInterest = notifOfInterestResult[0]
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifOfInterest.uuid])
                        do {try! changeUUIDRealm.write {notifOfInterest.uuid = newIdent}}
                        
                        #if DEBUG
                        print("Written uuid: \(newIdent)")
                        print("Notifications stored during pending notifications reset:")
                        let allEventNotifications = changeUUIDRealm.objects(RealmEventNotification.self)
                        for (i, realmNotif) in allEventNotifications.enumerated() {
                            print("\(i + 1): \(realmNotif.uuid)")
                        }
                        #endif
                    }
                    
                    notificationDataToReschedule.append((newIdent, content, calendarTrigger))
                }
            }
            else {
                os_log("Unexpected trigger type or no trigger for \"%@\"", log: .default, type: .error, request.content)
                continue
            }
        }
        
        guard !notificationDataToReschedule.isEmpty else {return}
        
        if updateBadgesToZero {for data in notificationDataToReschedule {data.1.badge = NSNumber(integerLiteral: 0)}}
        else {
            notificationDataToReschedule.sort { (request1, request2) -> Bool in
                let request1Trigger = request1.2 as! UNCalendarNotificationTrigger
                let request2Trigger = request2.2 as! UNCalendarNotificationTrigger
                let request1TriggerDate = currentCalendar.date(from: request1Trigger.dateComponents)!
                let request2TriggerDate = currentCalendar.date(from: request2Trigger.dateComponents)!
                
                if request1TriggerDate < request2TriggerDate {return true} else {return false}
            }
            
            for (i, data) in notificationDataToReschedule.enumerated() {data.1.badge = NSNumber(integerLiteral: i + 1)}
        }
        
        //
        // Reschedule requests
        for data in notificationDataToReschedule {
            let newRequest = UNNotificationRequest(identifier: data.0, content: data.1, trigger: data.2)
            schedule(request: newRequest)
        }
        
    }
}

let dailyNotificationsTitle = "Daily Update 🗞"
let currentCalendar = Calendar.current
let yearToSecondsComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]

func updateDailyNotificationsIfNeeded(async: Bool) {
    let dateNow = Date()
    if let notificationTimeAsDate = userDefaults.value(forKey: UserDefaultKeys.notificationTimeAsDateKey) as? Date {
        if dateNow > notificationTimeAsDate {updateDailyNotifications(async: async)}
    }
    else {updateDailyNotifications(async: async)}
}

func updateDailyNotifications(async: Bool, updatePending: Bool = true) {
    func performWork() {
        //autoreleasepool {
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
                    guard var day = todaysDateComponents.day else {userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey); return}
                    guard let currentHour = todaysDateComponents.hour else {userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey); return}
                    guard let hour = components.hour.value else {userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey); return}
                    guard let minute = components.minute.value else {userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey); return}
                    
                    if currentHour > hour {day += 1}
                    
                    var notificationTimeDateComponents = todaysDateComponents
                    notificationTimeDateComponents.day = day
                    notificationTimeDateComponents.hour = hour
                    notificationTimeDateComponents.minute = minute
                    notificationTimeDateComponents.second = 0
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: notificationTimeDateComponents, repeats: false)
                    let defaultEventNotification = UNMutableNotificationContent()
                    defaultEventNotification.sound = UNNotificationSound.default()
                    defaultEventNotification.title = dailyNotificationsTitle
                    
                    let newNotificationDate = currentCalendar.date(from: notificationTimeDateComponents)!
                    
                    if !chronologicalUpcomingSpecialEvents.isEmpty {
                        notificationTimeDateComponents.day! += 1
                        let nextDayNewNotificationDate = currentCalendar.date(from: notificationTimeDateComponents)!
                        if currentCalendar.isDate(chronologicalUpcomingSpecialEvents[0].date!.date, inSameDayAs: newNotificationDate) { // First notif format
                            
                            var eventTitlesSameDay = [String]()
                            for event in chronologicalUpcomingSpecialEvents {
                                if let eventDate = event.date {
                                    if currentCalendar.isDate(eventDate.date, inSameDayAs: newNotificationDate) {eventTitlesSameDay.append(event.title)}
                                    else {break}
                                }
                            }
                            
                            defaultEventNotification.badge = NSNumber(integerLiteral: eventTitlesSameDay.count)
                            switch eventTitlesSameDay.count {
                            case 1: defaultEventNotification.body = "Get excited! \"\(eventTitlesSameDay[0])\" is today!"
                            case 2: defaultEventNotification.body = "Get excited! \"\(eventTitlesSameDay[0])\" and 1 other event are today!"
                            default: defaultEventNotification.body = "Get excited! \"\(eventTitlesSameDay[0])\" and \(eventTitlesSameDay.count - 1) other events are today!"
                            }
                        }
                            
                        else if currentCalendar.isDate(chronologicalUpcomingSpecialEvents[0].date!.date, inSameDayAs: nextDayNewNotificationDate) { // Second notif format
                            
                            var eventTitlesNextDay = [String]()
                            for event in chronologicalUpcomingSpecialEvents {
                                if let eventDate = event.date {
                                    if currentCalendar.isDate(eventDate.date, inSameDayAs: nextDayNewNotificationDate) {eventTitlesNextDay.append(event.title)}
                                    else {break}
                                }
                            }
                            
                            switch eventTitlesNextDay.count {
                            case 1: defaultEventNotification.body = "Almost there! \"\(eventTitlesNextDay[0])\" is tomorrow."
                            case 2: defaultEventNotification.body = "Almost there! \"\(eventTitlesNextDay[0])\" and 1 other event are tomorrow."
                            default: defaultEventNotification.body = "Almost there! \"\(eventTitlesNextDay[0])\" and \(eventTitlesNextDay.count - 1) other events are tomorrow"
                            }
                        }
                            
                        else { // Third notif format
                            let date = chronologicalUpcomingSpecialEvents[0].date!.date
                            let eventDateComponents = currentCalendar.dateComponents(yearToSecondsComponents, from: date)
                            
                            var days = Double(eventDateComponents.day! - notificationTimeDateComponents.day!)
                            var months = 0.0
                            var years = 0.0
                            
                            if days < 0.0 {
                                months -= 1.0
                                let eventDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: date)!
                                let daysInEventDatePreviousMonth = currentCalendar.range(of: .day, in: .month, for: eventDatePreviousMonth)!.count
                                let daysLeftInEventDatePreviousMonth = daysInEventDatePreviousMonth - notificationTimeDateComponents.day!
                                days = Double(daysLeftInEventDatePreviousMonth + eventDateComponents.day!)
                            }
                            
                            months += Double(eventDateComponents.month! - notificationTimeDateComponents.month!)
                            if months < 0.0 {
                                years -= 1.0
                                months = 12 + months
                            }
                            
                            years += Double(eventDateComponents.year! - notificationTimeDateComponents.year!)
                            
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
                        
                        
                    }
                    else {
                        defaultEventNotification.body = "You have no upcoming events. Open the app to create one!"
                    }

                    let ident = UUID().uuidString
                    
                    let request = UNNotificationRequest(identifier: ident, content: defaultEventNotification, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { (_error) in
                        if let error = _error {
                            os_log("Error adding daily notifications request to notification center: %@", log: .default, type: .error, error.localizedDescription)
                            userDefaults.set(nil, forKey: UserDefaultKeys.currentlyScheduledUUIDKey)
                            userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey)
                        }
                        else {
                            userDefaults.set(ident, forKey: UserDefaultKeys.currentlyScheduledUUIDKey)
                            userDefaults.set(newNotificationDate, forKey: UserDefaultKeys.notificationTimeAsDateKey)
                            if let currentlyScheduledUUID = userDefaults.value(forKey: UserDefaultKeys.currentlyScheduledUUIDKey) as? String {
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [currentlyScheduledUUID])
                            }
                            if updatePending {updatePendingNotifcationsBadges(forDate: newNotificationDate)}
                        }
                    }
                }
                else {userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey)}
                    
            }
            else {
                if let currentlyScheduledUUID = userDefaults.value(forKey: UserDefaultKeys.currentlyScheduledUUIDKey) as? String {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [currentlyScheduledUUID])
                }
                userDefaults.set(nil, forKey: UserDefaultKeys.notificationTimeAsDateKey)
            }
                
        //}
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
        
        let numLaunches = userDefaults.integer(forKey: UserDefaultKeys.numberOfLaunches)
        if numLaunches == 0 {
            userDefaults.set(EventFilters.all.rawValue, forKey: UserDefaultKeys.DataManagement.currentFilter)
            userDefaults.set(SortMethods.chronologically.rawValue, forKey: UserDefaultKeys.DataManagement.currentSort)
            userDefaults.set(true, forKey: UserDefaultKeys.DataManagement.futureToPast)
            userDefaults.set(Defaults.DateDisplayMode.short, forKey: UserDefaultKeys.dateDisplayMode)
        }
        userDefaults.set(numLaunches + 1, forKey: UserDefaultKeys.numberOfLaunches)
        
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
            
            #if DEBUG
            print("Notifications stored after initial realm init:")
            let allEventNotifications = launchRealm.objects(RealmEventNotification.self)
            for (i, realmNotif) in allEventNotifications.enumerated() {
                print("\(i + 1): \(realmNotif.uuid)")
            }
            #endif
        }
        
        //
        // MARK: Data model config
        let eventImages = launchRealm.objects(EventImageInfo.self)
        
        if eventImages.count == 0 {
            do {try FileManager.default.createDirectory(at: sharedImageLocationURL, withIntermediateDirectories: false, attributes: nil)}
            catch {
                os_log("FATAL ERROR: Unable to create group directory, terminating app with error: %@", log: .default, type: .error, error.localizedDescription)
                fatalError()
            }
            
            // Add image info for images on the disk to the persistent store
            for imageInfo in AppEventImage.bundleMainImageInfo {
                let fileRootName = imageInfo.title.convertToFileName()
                if let mainImageSourceURL = Bundle.main.url(forResource: fileRootName, withExtension: ".jpg") {
                    var imageInfoToAdd = imageInfo
                    if imageInfo.hasMask {
                        if let maskImageSourceURL = Bundle.main.url(forResource: fileRootName + "Mask", withExtension: ".png") {
                            let maskDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Mask.png", isDirectory: false)
                            do {try FileManager.default.copyItem(at: maskImageSourceURL, to: maskDestinationURL)}
                            catch {
                                os_log("Unable to copy bundle mask image to group directory: %@", log: .default, type: .error, error.localizedDescription)
                            }
                        }
                        else {
                            imageInfoToAdd = EventImageInfo(
                                imageTitle: imageInfo.title,
                                imageCategory: imageInfo.category,
                                isAppImage: imageInfo.isAppImage,
                                recordName: nil,
                                hasMask: imageInfo.hasMask,
                                recommendedLocationForCellView: imageInfo.recommendedLocationForCellView.value
                            )
                        }
                    }
                
                    let mainDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + ".jpg", isDirectory: false)
                    do {
                        try FileManager.default.copyItem(at: mainImageSourceURL, to: mainDestinationURL)
                        try! launchRealm.write {launchRealm.add(imageInfoToAdd)}
                    }
                    catch {
                        os_log("Unable to copy bundle main image to group directory: %@", log: .default, type: .error, error.localizedDescription)
                    }
                    
                    if let mainThumbnail1xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@1x", withExtension: ".jpg") {
                        let mainThumbnail1xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@1x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail1xSourceURL, to: mainThumbnail1xDestinationURL)}
                        catch {
                            os_log("Unable to copy bundle @1x thumbnail image to group directory: %@", log: .default, type: .error, error.localizedDescription)
                        }
                    }
                    if let mainThumbnail2xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@2x", withExtension: ".jpg") {
                        let mainThumbnail2xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@2x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail2xSourceURL, to: mainThumbnail2xDestinationURL)}
                        catch {
                            os_log("Unable to copy bundle @2x thumbnail image to group directory: %@", log: .default, type: .error, error.localizedDescription)
                        }
                    }
                    if let mainThumbnail3xSourceURL = Bundle.main.url(forResource: fileRootName + "Thumbnail@3x", withExtension: ".jpg") {
                        let mainThumbnail3xDestinationURL = sharedImageLocationURL.appendingPathComponent(fileRootName + "Thumbnail@3x.jpg", isDirectory: false)
                        do {try FileManager.default.copyItem(at: mainThumbnail3xSourceURL, to: mainThumbnail3xDestinationURL)}
                        catch {
                            os_log("Unable to copy bundle @3x thumbnail image to group directory: %@", log: .default, type: .error, error.localizedDescription)
                        }
                    }
                }
            }
            
            // Create the default event.
            struct DefaultEvent {
                static let category = "Holidays"
                static let title = "New Years Day!"
                static let tagline = "Party like it's 1999 🎉"
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
                static let imageTitle = "Sparkler Art"
                static let useMask: Bool = false
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
                os_log("Default image for the default event was not on the disk.", log: .default, type: .default)
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
        if let notificationTimeAsDate = userDefaults.value(forKey: UserDefaultKeys.notificationTimeAsDateKey) as? Date {
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

