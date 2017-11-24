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

class SpecialEvent: Object {
    @objc dynamic var title: String?
    @objc dynamic var tagline: String?
    @objc dynamic var date: Date?
    @objc dynamic var category: EventCategory?
    @objc dynamic var imageTitle: String?
    @objc dynamic var traceImageTitle: String?
    
    override static func primaryKey() -> String? {return "title"}
    
    convenience init(category: EventCategory, title: String?, tagline: String?, date: Date?, imageTitle: String?) {
        self.init()
        self.category = category
        self.title = title
        self.tagline = tagline
        self.date = date
        self.imageTitle = imageTitle
    }
}

class EventCategory: Object {
    @objc dynamic var title: String?
    let includedSpecialEvents = List<SpecialEvent>()
    
    override static func primaryKey() -> String? {return "title"}
    
    convenience init(title: String?, newEvent: SpecialEvent?) {
        self.init()
        self.title = title
        if newEvent != nil {includedSpecialEvents.append(newEvent!)}
    }
}

class Categories: Object {
    let list = List<EventCategory>()
}


//
// MARK: - Realm helper funcitons
//

public func deletePersistentData(atIndexPath: IndexPath) -> Void {
    
}
