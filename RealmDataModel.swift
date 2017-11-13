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
    @objc dynamic var date: Date?
    @objc dynamic var category: EventCategory?
    
    override static func primaryKey() -> String? {return "title"}
    
    convenience init(title: String?, date: Date?, category: EventCategory) {
        self.init()
        self.title = title
        self.date = date
        self.category = category
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
