//
//  MasterViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift

class MasterViewController: UITableViewController {
    
    
    //
    // MARK: - Properties
    //
    
    // Data Model
    var categories: Results<Categories>!
    var activeCategories = [EventCategory]() {didSet {addOrRemoveNewCellPrompt()}}
    let imageHandler = ImageHandler()

    // Persistence
    var localPersistentStore: Realm!
    var localPersistentStoreNotificationsToken: NotificationToken!
    let userDefaultsContainer = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")
    
    //References and Outlets
    var detailViewController: DetailViewController? = nil
    
    // Other
    var isUserChange = false
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataModel()
        
        // Configure navigation controller
        let editButton = editButtonItem
        editButton.tintColor = UIColor.orange
        navigationItem.leftBarButtonItem = editButton
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        addButton.tintColor = UIColor.orange
        navigationItem.rightBarButtonItem = addButton
        
        tableView.tableFooterView = UIView() // To get rid of extra row separators
        
        // Reference to detail view controller
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    deinit {localPersistentStoreNotificationsToken?.invalidate()}
    
    
    //
    // MARK: - Segues
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let eventToDetail = categories[0].list.filter("title = '\(activeCategories[indexPath.section].title!)'")[0].includedSpecialEvents[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = eventToDetail
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    
    //
    // MARK: - Table View Functions
    //
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return activeCategories.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeCategories[section].includedSpecialEvents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        cell.eventTitle = activeCategories[indexPath.section].includedSpecialEvents[indexPath.row].title
        cell.eventDate = activeCategories[indexPath.section].includedSpecialEvents[indexPath.row].date
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170.0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    /*override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                let categoryToSearch = categories[0].list.filter("title = '\(activeCategories[indexPath.section].title!)'")[0]
                try localPersistentStore.write {
                    localPersistentStore.delete(categoryToSearch.includedSpecialEvents[indexPath.row])
                }
            }
            catch {
                // TODO: - Add some error handling
                fatalError("Error deleting entry from database: \(error.localizedDescription)")
            }
        }
    }*/
    
    
    //
    // MARK: - Delegation Methods
    //
    
    
    //
    // MARK: - Helper Methods
    //
    
    // Function to check cloud for updates on startup.
    fileprivate func syncRealmWithCloud () -> Void {
        
    }
    
    // Function to setup data model on startup.
    fileprivate func setupDataModel() -> Void {
        do {
            try localPersistentStore = Realm(configuration: realmConfig)
            
            // If the realm is empty (first app load) enter in default categories.
            if localPersistentStore.isEmpty {
                let newDataModel = Categories()
                newDataModel.list.append(objectsIn:
                    [
                        EventCategory(title: "Favorites", newEvent: nil),
                        EventCategory(title: "Travel", newEvent: nil),
                        EventCategory(title: "Business", newEvent: nil),
                        EventCategory(title: "Pleasure", newEvent: nil),
                        EventCategory(title: "Birthdays", newEvent: nil),
                        EventCategory(title: "Wedding", newEvent: nil),
                        EventCategory(title: "Family", newEvent: nil),
                        EventCategory(title: "Other", newEvent: nil),
                        EventCategory(title: "Previous", newEvent: nil)
                    ]
                )
                try! localPersistentStore.write {localPersistentStore.add(newDataModel)}
            }
            
            syncRealmWithCloud()
            
            // Get the data model from the database
            categories = localPersistentStore!.objects(Categories.self)
            updateActiveCategories()
            
            // Configure image handler
            for event in categories[0].list {
                
            }
            
            // Setup notification token for database changes
            localPersistentStoreNotificationsToken = categories._observe { [weak weakSelf = self] (changes: RealmCollectionChange) in
                guard let tableView = weakSelf?.tableView else {return}
                if !weakSelf!.isUserChange {
                    switch changes {
                    case .error(let error):
                        fatalError("Error with Realm notifications: \(error.localizedDescription)")
                    default:
                        weakSelf!.updateActiveCategories()
                        tableView.reloadData()
                    }
                }
                else {weakSelf!.isUserChange = false}
            }
        }
        catch {
            // TODO: - Add a popup to user saying an error fetching timer data occured, please help the developer by submitting crash data.
            let realmCreationError = error as NSError
            print("Unable to create local persistent store! Error: \(realmCreationError), \(realmCreationError.localizedDescription)")
        }
    }
    
    // Function to update the active categories when changes to the data model occur.
    fileprivate func updateActiveCategories() -> Void {
        var arrayToReturn = [EventCategory]()
        for category in categories[0].list {
            if !category.includedSpecialEvents.isEmpty {
                arrayToReturn.append(category)
                print(category.title! + " has " + String(category.includedSpecialEvents.count) + " special events")
            }
            else {print(category.title! + " has no special events!")}
        }
        activeCategories = arrayToReturn
    }
    
    // Function to add a new event from the events page.
    @objc fileprivate func insertNewObject(_ sender: Any) {performSegue(withIdentifier: "Add New Event Segue", sender: self)}
    
    fileprivate func addOrRemoveNewCellPrompt() -> Void {
        if activeCategories.isEmpty {
            let addNewCellPrompt = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: 300.0))
            addNewCellPrompt.text = "Tap the '+' in the upper right to create a new event!"
            addNewCellPrompt.textColor = UIColor.white
            addNewCellPrompt.font = UIFont(name: "FiraSans-Light", size: 18.0)
            addNewCellPrompt.numberOfLines = 0
            addNewCellPrompt.lineBreakMode = .byClipping
            addNewCellPrompt.textAlignment = .center
            self.tableView.backgroundView = addNewCellPrompt
        }
        else {self.tableView.backgroundView = nil}
    }
    
    fileprivate func configureCell(atIndexPath indexPath: IndexPath) -> Void {
        
    }
    
}


