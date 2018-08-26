//
//  SettingsTypeDataSource.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import RealmSwift

class EventNotificationConfig {
    var eventNotificationsOn = true
    var isCustom = false
    var eventNotifications: [EventNotification]
    
    init() {
        let initRealm = try! Realm(configuration: appRealmConfig)
        let defaultNotificationsConfig = initRealm.objects(DefaultNotificationsConfig.self)[0]
        
        eventNotifications = [EventNotification]()
        for realmEventNotif in defaultNotificationsConfig.eventNotifications {
            if let eventNotif = EventNotification(copying: realmEventNotif) {eventNotifications.append(eventNotif)}
        }
    }
    
    init(eventNotifications: [EventNotification], eventNotificationsOn: Bool = true, isCustom: Bool = true) {
        self.eventNotifications = eventNotifications
        self.eventNotificationsOn = eventNotificationsOn
        self.isCustom = isCustom
    }
    
    init(fromRealmEventNotificationConfig config: RealmEventNotificationConfig) {
        
        eventNotificationsOn = config.eventNotificationsOn
        isCustom = config.isCustom
        
        eventNotifications = [EventNotification]()
        for realmEventNotif in config.eventNotifications {
            if let eventNotif = EventNotification(fromRealmEventNotification: realmEventNotif) {
                eventNotifications.append(eventNotif)
            }
        }
    }
}

struct EventNotification {
    enum Types {
        case timeOfEvent, dayOfEvent, beforeEvent, afterEvent
        
        var stringEquivalent: String {
            switch self {
            case .timeOfEvent: return "At Time of Event"
            case .dayOfEvent: return "Day of Event"
            case .beforeEvent: return "Before Event"
            case .afterEvent: return "After Event"
            }
        }
        
        init?(string: String) {
            switch string {
            case Types.timeOfEvent.stringEquivalent: self = .timeOfEvent
            case Types.dayOfEvent.stringEquivalent: self = .dayOfEvent
            case Types.beforeEvent.stringEquivalent: self = .beforeEvent
            case Types.afterEvent.stringEquivalent: self = .afterEvent
            default: return nil
            }
        }
    }
    
    var type: Types
    var uuid: String
    var components: DateComponents?
    
    init(type: Types, components: DateComponents?) {
        self.type = type; self.components = components; uuid = UUID().uuidString
    }
    
    init?(fromRealmEventNotification notif: RealmEventNotification) {
        if let _type = Types(string: notif.type) {
            type = _type
            uuid = notif.uuid
            if let notifComponents = notif.notificationComponents {
                components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: notifComponents.month.value, day: notifComponents.day.value, hour: notifComponents.hour.value, minute: notifComponents.minute.value, second: notifComponents.second.value, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
            }
        }
        else {return nil}
    }
    
    init(copying eventNotification: EventNotification) {
        self.init(type: eventNotification.type, components: eventNotification.components)
    }
    
    init?(copying realmEventNotification: RealmEventNotification) {
        if let type = EventNotification.Types(string: realmEventNotification.type) {
            let components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: realmEventNotification.notificationComponents?.month.value, day: realmEventNotification.notificationComponents?.day.value, hour: realmEventNotification.notificationComponents?.hour.value, minute: realmEventNotification.notificationComponents?.minute.value, second: realmEventNotification.notificationComponents?.second.value, nanosecond: nil, weekday: nil, weekdayOrdinal:  nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
            self.init(type: type, components: components)
        }
        else {return nil}
    }
}

class SettingsTypeDataSource: Collection {
    
    enum RowTypes {case segue, action, onOrOff, selectOption}
    
    private var sections = [Section]()
    
    var startIndex = 0
    var endIndex: Int {return sections.count}
    subscript(section: Int) -> Section {get {return sections[section]}}
    var count: Int {return sections.count}
    func index(after i: Int) -> Int {return i + 1}
    
    class Section {
        var title: String?
        var rows: [Row]
        
        init(title: String?, rows: [Row]) {self.title = title; self.rows = rows}
        
        func addRow(type: RowTypes, title: String, options: [Option] = [Option]()) -> Int {
            rows.append(Row(type: type, title: title, options: options)); return rows.endIndex - 1
        }
    }
    
    class Row {
        var title: String
        var options: [Option]
        var type: RowTypes
        
        init(type: RowTypes, title: String, options: [Option]) {self.type = type; self.title = title; self.options = options}
        
        func addOption(text: String?, action: (() -> Void)?) {options.append(Option(text: text, action: action))}
    }
    
    class Option: NSObject {
        var text: String?
        var action: (() -> Void)?
        
        init(text: String?, action: (() -> Void)?) {self.text = text; self.action = action}
        
        func runAction() {action?()}
    }
    
    func addSection(title: String?, rows: [Row] = [Row]()) -> Int {sections.append(Section(title: title, rows: rows)); return sections.endIndex - 1}
}
