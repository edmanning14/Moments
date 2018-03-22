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
    var specialEvents: Results<SpecialEvent>!
    var activeCategories = [String]() {didSet {tableView.reloadData()}}
    var allCategories = [String]() {didSet{updateActiveCategories()}}

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
        
        let specialEventNib = UINib(nibName: "SpecialEventCell", bundle: nil)
        tableView.register(specialEventNib, forCellReuseIdentifier: "Event")
        
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
                let eventToDetail = items(forSection: indexPath.section)[indexPath.row]
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
        return items(forSection: section).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        cell.configuration = .tableView
        cell.eventTitle = items(forSection: indexPath.section)[indexPath.row].title
        cell.eventTagline = items(forSection: indexPath.section)[indexPath.row].tagline
        cell.eventDate = items(forSection: indexPath.section)[indexPath.row].date
        if items(forSection: indexPath.section)[indexPath.row].image != nil {
            cell.eventImage = EventImage(fromEventImageInfo: items(forSection: indexPath.section)[indexPath.row].image!)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170.0
    }
    
    
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
            
            syncRealmWithCloud()
            
            specialEvents = localPersistentStore!.objects(SpecialEvent.self)
            
            if let temp = userDefaultsContainer?.value(forKey: "Categories") as? [String] {allCategories = temp}
            else { // Perform initial app load setup
                if userDefaultsContainer != nil {
                    userDefaultsContainer!.set(["Favorites", "Holidays", "Travel", "Business", "Pleasure", "Birthdays", "Aniversaries", "Wedding", "Family", "Other"], forKey: "Categories")
                }
                else {
                    // TODO: Error Handling
                    fatalError("Unable to get the categories from the user defaults container.")
                }
            }
            
            addOrRemoveNewCellPrompt()
            
            // Setup notification token for database changes
            localPersistentStoreNotificationsToken = specialEvents._observe { [weak weakSelf = self] (changes: RealmCollectionChange) in
                guard let tableView = weakSelf?.tableView else {return}
                if !weakSelf!.isUserChange {
                    switch changes {
                    case .error(let error):
                        fatalError("Error with Realm notifications: \(error.localizedDescription)")
                    default:
                        weakSelf?.updateActiveCategories()
                        tableView.reloadData()
                        weakSelf?.addOrRemoveNewCellPrompt()
                    }
                }
                else {weakSelf!.isUserChange = false}
            }
        }
        catch {
            // TODO: - Add a popup to user saying an error fetching timer data occured, please help the developer by submitting crash data.
            let realmCreationError = error as NSError
            fatalError("Unable to create local persistent store! Error: \(realmCreationError), \(realmCreationError.localizedDescription)")
        }
    }
    
    // Function to update the active categories when changes to the data model occur.
    fileprivate func updateActiveCategories() -> Void {
        var arrayToReturn = [String]()
        for event in specialEvents {if !arrayToReturn.contains(event.category) {arrayToReturn.append(event.category)}}
        for category in allCategories {
            if let i = arrayToReturn.index(of: category) {
                arrayToReturn.remove(at: i)
                arrayToReturn.append(category)
            }
        }
        activeCategories = arrayToReturn
    }
    
    // Function to add a new event from the events page.
    @objc fileprivate func insertNewObject(_ sender: Any) {performSegue(withIdentifier: "Add New Event Segue", sender: self)}
    
    fileprivate func addOrRemoveNewCellPrompt() -> Void {
        // TODO: Make this a soft and comfortable glyph instead of harsh text.
        if specialEvents.isEmpty {
            let addNewCellPrompt = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: 300.0))
            addNewCellPrompt.text = "Tap the '+' in the upper right to create a new event!"
            addNewCellPrompt.textColor = UIColor.white
            addNewCellPrompt.font = UIFont(name: "FiraSans-Light", size: 16.0)
            addNewCellPrompt.numberOfLines = 0
            addNewCellPrompt.lineBreakMode = .byClipping
            addNewCellPrompt.textAlignment = .center
            self.tableView.backgroundView = addNewCellPrompt
        }
        else {self.tableView.backgroundView = nil}
    }
    
    fileprivate func items(forSection section: Int) -> Results<SpecialEvent> {
        return specialEvents.filter("category = %@", activeCategories[section]).sorted(byKeyPath: "date.date")
    }
    
}


