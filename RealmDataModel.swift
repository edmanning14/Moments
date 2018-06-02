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

let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ed_Manning.Multiple_Event_Countdown")!.appendingPathComponent("db.realm")
let realmConfig = Realm.Configuration(
    fileURL: url,
    inMemoryIdentifier: nil,
    syncConfiguration: nil,
    encryptionKey: nil,
    readOnly: false,
    schemaVersion: 0,
    migrationBlock: nil,
    deleteRealmIfMigrationNeeded: false,
    shouldCompactOnLaunch: nil,
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
}

class EventImageInfo: Object {
    
    // Stored Properties
    @objc dynamic var title = ""
    @objc dynamic var category: String? = nil
    @objc dynamic var isAppImage = false
    @objc dynamic var recordName: String? = nil
    @objc dynamic var locationForCellView = 50
    @objc dynamic var hasMask = false
    let specialEvents = LinkingObjects(fromType: SpecialEvent.self, property: "image")
    
    // Initializers
    
    convenience init(locationForCellView: CGFloat, imageTitle aTitle: String, imageCategory category: String? = nil, isAppImage: Bool = false, recordName: String? = nil, hasMask: Bool = false) {
        self.init()
        self.locationForCellView = Int(locationForCellView * 100.0)
        self.title = aTitle
        
        self.category = category
        self.isAppImage = isAppImage
        self.recordName = recordName
        self.hasMask = hasMask
    }
    
    convenience init(fromEventImage image: UserEventImage) {
        self.init()
        
        title = image.title
        if let location = image.locationForCellView {locationForCellView = Int(location * 100.0)}
        
        if let appImage = image as? AppEventImage {
            category = appImage.category
            isAppImage = true
            if appImage.maskImage != nil {hasMask = true}
            recordName = appImage.recordName
        }
    }
    
    override static func primaryKey() -> String? {return "title"}
}

class SpecialEvent: Object {
    
    // Stored Properties
    @objc dynamic var category = ""
    @objc dynamic var title = ""
    @objc dynamic var tagline: String?
    @objc dynamic var creationDate = Date()
    @objc dynamic var date: EventDate?
    @objc dynamic var abridgedDisplayMode = false
    @objc dynamic var useMask = true
    @objc dynamic var image: EventImageInfo?
    
    convenience init(category: String, title: String, tagline: String?, date: EventDate, abridgedDisplayMode: Bool, useMask: Bool, image: EventImageInfo?) {
        self.init()
        self.category = category
        self.title = title
        self.tagline = tagline
        self.date = date
        self.abridgedDisplayMode = abridgedDisplayMode
        self.useMask = useMask
        self.image = image
    }
    
    override static func primaryKey() -> String? {return "title"}
}
