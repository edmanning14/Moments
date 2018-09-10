//
//  ProjectGlobals.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/23/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import UIKit

//
// MARK: URLs
let sharedImageLocationURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ed_Manning.Multiple_Event_Countdown")!.appendingPathComponent("EventImageData", isDirectory: true)

//
// MARK: Defaults
let userDefaults = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")!


struct Defaults {
    struct Notifications {
        static let allOn = true
        static let dailyNotificationsOn = true
        static let dailyNotificationsScheduledTime = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: 9, minute: 0, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        static let individualEventRemindersOn = true
        static let eventNotifications = [
            EventNotification(type: .timeOfEvent, components: nil),
            EventNotification(type: .beforeEvent, components: DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: 1, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil))
        ]
        static let categoriesToNotify = "All"
    }
    struct DateDisplayMode {
        static let short = "Short"
        static let long = "Long"
    }
}
struct UserDefaultKeys {
    struct DataManagement {
        static let currentFilter = "Current Filter"
        static let currentSort = "Current Sort"
        static let futureToPast = "Future to Past"
    }
    static let dateDisplayMode = "Date Display Mode"
    static let widgetConfiguration = "Widget Configuration"
    static let numberOfLaunches = "Number of Launches"
    static let tipShown = "Tip Shown"
}
let defaultCategories = ["Holidays", "Travel", "Business", "Pleasure", "Birthdays", "Anniversaries", "Wedding", "Family", "Other"]
let immutableCategories = ["Favorites", "Uncategorized", "All"]

//
// MARK: Layout
let globalCellSpacing: CGFloat = 15.0
let globalCellHeight: CGFloat = 160.0

//
// MARK: Colors
struct GlobalColors {
    static let orangeRegular = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
    static let orangeDark = UIColor(red: 230/255, green: 81/255, blue: 0.0, alpha: 1.0)
    static let cyanRegular = UIColor(red: 100/255, green: 1.0, blue: 218/255, alpha: 1.0)
    static let lightGrayForFills = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let gray = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1.0)
    static let purplePrimary = UIColor(red: 118/255, green: 75/255, blue: 162/255, alpha: 1.0)
    static let darkPurpleForFills = UIColor(red: 66/255, green: 23/255, blue: 66/255, alpha: 1.0)
    static let taskCompleteColor = UIColor.green
    static let optionalTaskIncompleteColor = UIColor.darkGray
    static let inactiveColor = UIColor.lightText
    static let unselectedButtonColor = UIColor.lightGray
    static let shareButtonColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0) //Facebook Blue
}

// MARK: Fonts
struct GlobalFontNames {
    static let ComfortaaLight = "Comfortaa-Light" // Headings
    static let ralewayLight = "Raleway-Light" // Small Text
    static let ralewayRegular = "Raleway-Regular" // Text
    static let ralewayMedium = "Raleway-Medium" // Cell Title
    static let ralewayMediumItalic = "Raleway-MediumItalic" // Modified category2
    static let ralewaySemiBold = "Raleway-SemiBold"
}


// MARK: Animation
struct GlobalAnimations {
    static let labelTransition: CATransition = {
        let trans = CATransition()
        trans.duration = 0.3
        trans.type = kCATransitionFade
        return trans
    }()
}

// MARK: Geometry
struct GlobalCornerRadii {
    static let material: CGFloat = 15.0
}
let standardDirectionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)

// MARK: User photos defaults
let userPhotosCellSpacing: CGFloat = 1.0
let numberOfUserPhotoCellsPerColumn: CGFloat = 4.0
