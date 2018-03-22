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
    @objc dynamic var fileRootName = ""
    @objc dynamic var category = ""
    @objc dynamic var isAppImage = true
    @objc dynamic var hasMask = true
    
    // Initializers
    convenience init(imageTitle aTitle: String, fileRootName: String, imageCategory category: String) {
        self.init()
        self.title = aTitle
        self.fileRootName = fileRootName
        self.category = category
    }
    
    convenience init(imageTitle aTitle: String, fileRootName: String, imageCategory category: String, isAppImage: Bool, hasMask: Bool) {
        self.init()
        self.title = aTitle
        self.fileRootName = fileRootName
        self.category = category
        self.isAppImage = isAppImage
        self.hasMask = hasMask
    }
    
    override static func primaryKey() -> String? {return "title"}
}

class SpecialEvent: Object {
    
    // Stored Properties
    @objc dynamic var title = ""
    @objc dynamic var tagline: String?
    @objc dynamic var date: EventDate?
    @objc dynamic var category = ""
    @objc dynamic var image: EventImageInfo?
    
    convenience init(category: String, title: String, tagline: String?, date: EventDate, image: EventImageInfo?) {
        self.init()
        self.category = category
        self.title = title
        self.tagline = tagline
        self.date = date
        self.image = image
    }
    
        override static func primaryKey() -> String? {return "title"}
}
