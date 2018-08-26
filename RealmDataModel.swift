//
//  RealmDataModel.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import Foundation
import RealmSwift


//
// MARK: - Realm Configurations
//

let realmDBURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ed_Manning.Multiple_Event_Countdown")!.appendingPathComponent("db.realm")
let appRealmConfig = Realm.Configuration(
    fileURL: realmDBURL,
    inMemoryIdentifier: nil,
    syncConfiguration: nil,
    encryptionKey: nil,
    readOnly: false,
    schemaVersion: 0,
    migrationBlock: nil,
    deleteRealmIfMigrationNeeded: false,
    shouldCompactOnLaunch: { totalBytes, usedBytes in
        // totalBytes refers to the size of the file on disk in bytes (data + free space)
        // usedBytes refers to the number of bytes used by data in the file
        
        // Compact if the file is over 100MB in size and less than 50% 'used'
        let oneHundredMB = 100 * 1024 * 1024
        return (totalBytes > oneHundredMB) && (Double(usedBytes) / Double(totalBytes)) < 0.5
    },
    objectTypes: nil
)


//
// MARK: - Data Model
//

class EventDate: Object {
    @objc dynamic var date = Date()
    @objc dynamic var dateOnly = true
    
    convenience init(date: Date, dateOnly: Bool) {
        self.init()
        self.date = date
        self.dateOnly = dateOnly
    }
    
    func cascadeDelete() {}

}

class DefaultNotificationsConfig: Object {
    @objc dynamic var allOn = true
    @objc dynamic var dailyNotificationOn = true
    @objc dynamic var dailyNotificationsScheduledTime: RealmEventNotificationComponents?
    @objc dynamic var individualEventRemindersOn = true
    let eventNotifications = List<RealmEventNotification>()
    @objc dynamic var categoriesToNotify = "All"
    
    func cascadeDelete() {
        autoreleasepool {
            let deletionRealm = try! Realm(configuration: appRealmConfig)
            if dailyNotificationsScheduledTime != nil {
                dailyNotificationsScheduledTime?.cascadeDelete()
                do {try! deletionRealm.write {deletionRealm.delete(dailyNotificationsScheduledTime!)}}
            }
            if !eventNotifications.isEmpty {
                for realmEventNotif in eventNotifications {realmEventNotif.cascadeDelete()}
                do {try! deletionRealm.write {deletionRealm.delete(eventNotifications)}}
            }
        }
    }
    
}

class RealmEventNotificationConfig: Object {
    @objc dynamic var eventNotificationsOn = true
    @objc dynamic var isCustom = false
    let eventNotifications = List<RealmEventNotification>()
    
    convenience init(eventNotifications: [RealmEventNotification], eventNotificationsOn: Bool = true, isCustom: Bool = false) {
        self.init()
        self.eventNotifications.append(objectsIn: eventNotifications)
        self.eventNotificationsOn = eventNotificationsOn
        self.isCustom = isCustom
    }
    
    convenience init(fromEventNotificationConfig config: EventNotificationConfig) {
        self.init()
        self.eventNotificationsOn = config.eventNotificationsOn
        self.isCustom = config.isCustom
        
        for eventNotif in config.eventNotifications {
            eventNotifications.append(RealmEventNotification(fromEventNotification: eventNotif))
        }
    }
    
    func cascadeDelete() {
        autoreleasepool {
            let deletionRealm = try! Realm(configuration: appRealmConfig)
            if !eventNotifications.isEmpty {
                for realmEventNotif in eventNotifications {realmEventNotif.cascadeDelete()}
                do {try! deletionRealm.write {deletionRealm.delete(eventNotifications)}}
            }
        }
    }
    
}

class RealmEventNotification: Object {
    @objc dynamic var type = ""
    @objc dynamic var uuid = ""
    @objc dynamic var notificationComponents: RealmEventNotificationComponents?
    
    convenience init(fromEventNotification notif: EventNotification) {
        self.init()
        self.type = notif.type.stringEquivalent
        self.uuid = notif.uuid
        self.notificationComponents = RealmEventNotificationComponents(fromDateComponents: notif.components)
    }
    
    convenience init(copyingEventNotification notif: EventNotification) {
        self.init()
        self.type = notif.type.stringEquivalent
        self.uuid = UUID().uuidString
        self.notificationComponents = RealmEventNotificationComponents(fromDateComponents: notif.components)
    }
    
    func cascadeDelete() {
        autoreleasepool {
            let deletionRealm = try! Realm(configuration: appRealmConfig)
            if notificationComponents != nil {
                notificationComponents!.cascadeDelete()
                do {try! deletionRealm.write {deletionRealm.delete(notificationComponents!)}}
            }
        }
    }
    
}

class RealmEventNotificationComponents: Object {
    let month = RealmOptional<Int>()
    let day = RealmOptional<Int>()
    let hour = RealmOptional<Int>()
    let minute = RealmOptional<Int>()
    let second = RealmOptional<Int>()
    
    convenience init(month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        self.init()
        self.month.value = month
        self.day.value = day
        self.hour.value = hour
        self.minute.value = minute
        self.second.value = second
    }
    
    convenience init(fromDateComponents components: DateComponents?) {
        self.init()
        self.month.value = components?.month
        self.day.value = components?.day
        self.hour.value = components?.hour
        self.minute.value = components?.minute
        self.second.value = components?.second
    }
    
    func cascadeDelete() {}
    
}

class EventImageInfo: Object {
    
    // Stored Properties
    @objc dynamic var title = ""
    @objc dynamic var category: String? = nil
    @objc dynamic var isAppImage = false
    @objc dynamic var recordName: String? = nil
    @objc dynamic var hasMask = false
    let recommendedLocationForCellView = RealmOptional<Int>()
    let specialEvents = LinkingObjects(fromType: SpecialEvent.self, property: "image")
    
    // Initializers
    
    convenience init(imageTitle aTitle: String, imageCategory category: String? = nil, isAppImage: Bool = false, recordName: String? = nil, hasMask: Bool = false, recommendedLocationForCellView: Int?) {
        self.init()
        self.title = aTitle
        
        self.category = category
        self.isAppImage = isAppImage
        self.recordName = recordName
        self.hasMask = hasMask
        self.recommendedLocationForCellView.value = recommendedLocationForCellView
    }
    
    convenience init(fromEventImage image: UserEventImage) {
        self.init()
        
        title = image.title
        
        if let appImage = image as? AppEventImage {
            category = appImage.category
            isAppImage = true
            if appImage.maskImage != nil {hasMask = true}
            recordName = appImage.recordName
            if let _recommendedLocationForCellView = appImage.recommendedLocationForCellView {
                recommendedLocationForCellView.value = Int(_recommendedLocationForCellView * 100.0)
            }
        }
    }
    
    override static func primaryKey() -> String? {return "title"}
    
    func cascadeDelete() {}
    
}

class SpecialEvent: Object {
    
    // Stored Properties
    @objc dynamic var category = ""
    @objc dynamic var title = ""
    @objc dynamic var tagline: String?
    @objc dynamic var creationDate = Date()
    @objc dynamic var date: EventDate?
    @objc dynamic var abridgedDisplayMode = false
    @objc dynamic var infoDisplayed = "Tagline"
    @objc dynamic var repeats = "Never"
    @objc dynamic var notificationsConfig: RealmEventNotificationConfig?
    @objc dynamic var useMask = true
    @objc dynamic var image: EventImageInfo?
    let locationForCellView = RealmOptional<Int>()
    
    convenience init(category: String, title: String, tagline: String?, date: EventDate, abridgedDisplayMode: Bool, infoDisplayed: DisplayInfoOptions, repeats: RepeatingOptions, notificationsConfig: RealmEventNotificationConfig?, useMask: Bool, image: EventImageInfo?, locationForCellView: CGFloat?) {
        self.init()
        self.category = category
        self.title = title
        self.tagline = tagline
        self.date = date
        self.abridgedDisplayMode = abridgedDisplayMode
        self.infoDisplayed = infoDisplayed.displayText
        self.repeats = repeats.displayText
        self.notificationsConfig = notificationsConfig
        if let _locationForCellView = locationForCellView {self.locationForCellView.value = Int(_locationForCellView * 100.0)}
        self.useMask = useMask
        self.image = image
    }
    
    override static func primaryKey() -> String? {return "title"}
    
    func cascadeDelete() {
        autoreleasepool {
            let deletionRealm = try! Realm(configuration: appRealmConfig)
            if date != nil {
                date!.cascadeDelete()
                do {try! deletionRealm.write {deletionRealm.delete(date!)}}
            }
            if notificationsConfig != nil {
                notificationsConfig!.cascadeDelete()
                do {try! deletionRealm.write {deletionRealm.delete(notificationsConfig!)}}
            }
        }
    }
}
