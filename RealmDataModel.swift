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
    @objc dynamic var recordName: String? = nil
    @objc dynamic var locationForCellView = 50
    @objc dynamic var hasMask = true
    
    // Initializers
    convenience init(imageTitle aTitle: String, fileRootName: String, imageCategory category: String) {
        self.init()
        self.title = aTitle
        self.fileRootName = fileRootName
        self.category = category
    }
    
    convenience init(imageTitle aTitle: String, fileRootName: String, imageCategory category: String, isAppImage: Bool, recordName: String?, locationForCellView: Int, hasMask: Bool) {
        self.init()
        self.title = aTitle
        self.fileRootName = fileRootName
        self.category = category
        self.isAppImage = isAppImage
        self.recordName = recordName
        self.locationForCellView = locationForCellView
        self.hasMask = hasMask
    }
    
    convenience init(fromEventImage image: EventImage) {
        self.init()
        self.title = image.title
        self.fileRootName = image.fileRootName
        self.category = image.category
        self.isAppImage = image.isAppImage
        self.recordName = image.recordName
        self.locationForCellView = Int(image.locationForCellView * 100.0)
        self.hasMask = {if image.maskImage != nil {return true} else {return false}}()
    }
    
    override static func primaryKey() -> String? {return "title"}
}

class SpecialEvent: Object {
    
    // Stored Properties
    @objc dynamic var title = ""
    @objc dynamic var tagline: String?
    @objc dynamic var creationDate = Date()
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
