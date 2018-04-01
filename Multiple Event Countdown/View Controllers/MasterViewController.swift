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
    
    // Typealiases
    typealias ActiveCategory = String
    
    //
    // Types
    enum EventSortMethods {
        case chronologicalNewestFirst, chronologicalOldestFirst
        
        var sortPredicate: (SpecialEvent, SpecialEvent) -> Bool {
            switch self {
            case .chronologicalNewestFirst:
                return {$0.date!.date < $1.date!.date}
            case .chronologicalOldestFirst:
                return {$0.date!.date > $1.date!.date}
            }
        }
    }
    
    // Data Model
    var specialEvents: Results<SpecialEvent>!
    var activeCategories = [String]()
    var allCategories = [String]()
    var eventSortMethod = EventSortMethods.chronologicalNewestFirst
    var lastIndexPath = IndexPath(row: 0, section: 0)

    // Persistence
    var localPersistentStore: Realm!
    var localPersistentStoreNotificationsToken: NotificationToken!
    let userDefaultsContainer = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")
    
    //References and Outlets
    var detailViewController: DetailViewController? = nil
    
    //
    // Constants
    fileprivate struct SegueIdentifiers {
        static let showDetail = "ShowDetail"
        static let addNewEventSegue = "Add New Event Segue"
    }
    
    // Flags
    var isUserChange = false
    
    // Timers
    var eventTimer: Timer?
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    fileprivate func extractedFunc() {
        setupDataModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extractedFunc()
        
        let specialEventNib = UINib(nibName: "SpecialEventCell", bundle: nil)
        tableView.register(specialEventNib, forCellReuseIdentifier: "Event")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        addButton.tintColor = UIColor.orange
        navigationItem.rightBarButtonItem = addButton
        
        let editButton = editButtonItem
        editButton.tintColor = UIColor.orange
        navigationItem.leftBarButtonItem = editButton
        
        tableView.tableFooterView = UIView() // To get rid of extra row separators
        tableView.rowHeight = 170.0
        tableView.sectionHeaderHeight = 45.0
        
        // Reference to detail view controller
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !specialEvents.isEmpty && eventTimer == nil {
            eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
        }
        
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    deinit {
        localPersistentStoreNotificationsToken?.invalidate()
        eventTimer?.invalidate()
    }
    
    
    //
    // MARK: - Segues
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case SegueIdentifiers.showDetail:
            if let indexPath = tableView.indexPathForSelectedRow {
                let eventToDetail = items(forSection: indexPath.section)[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = eventToDetail
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        case SegueIdentifiers.addNewEventSegue:
            if let cell = sender as? EventTableViewCell {
                let navController = segue.destination as! UINavigationController
                let dest = navController.viewControllers[0] as! NewEventViewController
                dest.selectedImage = cell.eventImage
            }
        default: break
        }
    }
    
    
    //
    // MARK: - Table View Functions
    //
    
    override func numberOfSections(in tableView: UITableView) -> Int {return activeCategories.count}
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items(forSection: section).count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        
        let headerLabel = UILabel(frame: CGRect(x: 5.0, y: 5.0, width: 100.0, height: 100.0))
        headerLabel.backgroundColor = UIColor.clear
        headerLabel.textColor = UIColor.white
        headerLabel.font = UIFont(name: "FiraSans-Light", size: 30.0)
        headerLabel.text = activeCategories[section]
        headerLabel.textAlignment = .left
        
        headerView.addSubview(headerLabel)
        headerLabel.sizeToFit()
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        cell.configuration = .tableView
        cell.eventTitle = items(forSection: indexPath.section)[indexPath.row].title
        cell.eventTagline = items(forSection: indexPath.section)[indexPath.row].tagline
        cell.eventDate = items(forSection: indexPath.section)[indexPath.row].date
        cell.creationDate = items(forSection: indexPath.section)[indexPath.row].creationDate
        if items(forSection: indexPath.section)[indexPath.row].image != nil {
            cell.eventImage = EventImage(fromEventImageInfo: items(forSection: indexPath.section)[indexPath.row].image!)
        }
        
        if indexPath == lastIndexPath {
            if eventTimer == nil {
                eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
            }
        }
        return cell
    }
    
    /*override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 170.0
    }*/
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! localPersistentStore.write {
                localPersistentStore.delete(items(forSection: indexPath.section)[indexPath.row])
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        if tableView.isEditing {
            performSegue(withIdentifier: SegueIdentifiers.addNewEventSegue, sender: cell)
        }
        else {
            splitViewController?.showDetailViewController(detailViewController!, sender: cell)
        }
    }
    
    
    //
    // MARK: - Delegation Methods
    //
    
    
    //
    // MARK: - Private Methods
    //
    
    //
    // MARK: Target-action methods
    @objc fileprivate func timerBlock(timerFireMethod: Timer) {
        for cell in tableView.visibleCells {
            if let eventCell = cell as? EventTableViewCell {eventCell.update()}
        }
    }
    
    // Function to check cloud for updates on startup.
    fileprivate func syncRealmWithCloud () -> Void {
        
    }
    
    // Function to setup data model on startup.
    fileprivate func setupDataModel() -> Void {
        do {
            
            if let temp = userDefaultsContainer?.value(forKey: "Categories") as? [String] {allCategories = temp}
            else { // Perform initial app load setup
                if userDefaultsContainer != nil {
                    userDefaultsContainer!.set(["Favorites", "Holidays", "Travel", "Business", "Pleasure", "Birthdays", "Aniversaries", "Wedding", "Family", "Other", "Uncategorized"], forKey: "Categories")
                }
                else {
                    // TODO: Error Handling
                    fatalError("Unable to get the categories from the user defaults container.")
                }
            }
            
            try localPersistentStore = Realm(configuration: realmConfig)
            syncRealmWithCloud()
            
            specialEvents = localPersistentStore!.objects(SpecialEvent.self)
            updateActiveCategories()
            tableView.reloadData()
            
            addOrRemoveNewCellPrompt()
            
            // Setup notification token for database changes
            localPersistentStoreNotificationsToken = specialEvents._observe { [weak weakSelf = self] (changes: RealmCollectionChange) in
                if !weakSelf!.isUserChange {
                    switch changes {
                    case .error(let error):
                        fatalError("Error with Realm notifications: \(error.localizedDescription)")
                    case .initial: break
                    case .update(_, _, _, _):
                        DispatchQueue.main.async { [weak weakSelf = self] in
                            if weakSelf != nil {
                                weakSelf!.updateActiveCategories()
                                weakSelf!.tableView.reloadData()
                            }
                        }
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
    fileprivate func updateActiveCategories() {
        activeCategories.removeAll()
        for event in specialEvents {
            if !activeCategories.contains(event.category) {activeCategories.append(event.category)}
        }
        
        if !activeCategories.isEmpty {
            orderActiveCategories()
            
            let lastSection = activeCategories.count - 1
            let lastRow = items(forSection: lastSection).count - 1
            lastIndexPath = IndexPath(row: lastRow, section: lastSection)
        }
        else {eventTimer = nil}
    }
    
    fileprivate func orderActiveCategories() {
        let unorderedCategories = activeCategories
        activeCategories.removeAll()
        for category in allCategories {
            if unorderedCategories.contains(category) {
                activeCategories.append(category)
            }
        }
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
        switch eventSortMethod {
        case .chronologicalNewestFirst:
            return specialEvents.filter("category = %@", activeCategories[section]).sorted(byKeyPath: "date.date", ascending: true)
        case .chronologicalOldestFirst:
            return specialEvents.filter("category = %@", activeCategories[section]).sorted(byKeyPath: "date.date", ascending: false)
        }
    }
}


