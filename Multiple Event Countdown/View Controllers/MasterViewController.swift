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
    
    //
    // MARK: Types
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
    
    //
    // MARK: Data Model
    var specialEvents: Results<SpecialEvent>!
    var activeCategories = [String]()
    var indexPathMap = [IndexPath]()
    var allCategories = [String]()
    var eventSortMethod = EventSortMethods.chronologicalNewestFirst
    var lastIndexPath = IndexPath(row: 0, section: 0)

    //
    // MARK: Persistence
    var localPersistentStore: Realm!
    var localPersistentStoreNotificationToken: NotificationToken!
    let userDefaultsContainer = UserDefaults(suiteName: "group.com.Ed_Manning.Multiple_Event_Countdown")
    
    //
    // MARK: References and Outlets
    var detailViewController: DetailViewController? = nil
    
    //
    // MARK: Constants
    fileprivate struct SegueIdentifiers {
        static let showDetail = "ShowDetail"
        static let addNewEventSegue = "Add New Event Segue"
    }
    
    //
    // MARK: - Design
    
    // MARK: Colors
    let primaryTextRegularColor = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
    let primaryTextDarkColor = UIColor(red: 230/255, green: 81/255, blue: 0.0, alpha: 1.0)
    let secondaryTextRegularColor = UIColor(red: 100/255, green: 1.0, blue: 218/255, alpha: 1.0)
    let secondaryTextLightColor = UIColor(red: 167/255, green: 1.0, blue: 235/255, alpha: 1.0)
    
    // MARK: Fonts
    let headingsFontName = "Comfortaa-Light"
    let contentSecondaryFontName = "Raleway-Regular"
    
    // MARK: Layout
    fileprivate let cellSpacing: CGFloat = 10.0
    
    //
    // MARK: Flags
    var isUserChange = false
    var dateDidChange = false
    var categoryDidChange = false
    
    //
    // MARK: Timers
    var eventTimer: Timer?
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataModel()
        
        let specialEventNib = UINib(nibName: "SpecialEventCell", bundle: nil)
        tableView.register(specialEventNib, forCellReuseIdentifier: "Event")
        
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont(name: headingsFontName, size: 18.0) as Any,
            .foregroundColor: primaryTextRegularColor
        ]
        tableView.backgroundColor = UIColor.black
        navigationController?.view.backgroundColor = UIColor.black
        if #available(iOS 11, *) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .font: UIFont(name: headingsFontName, size: 30.0) as Any,
                .foregroundColor: primaryTextRegularColor
            ]
        }
        
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: contentSecondaryFontName, size: 16.0)! as Any]
        
        let addEventImage = #imageLiteral(resourceName: "AddEventImage")
        let addButton = UIBarButtonItem(image: addEventImage, style: .plain, target: self, action: #selector(insertNewObject(_:)))
        addButton.tintColor = primaryTextDarkColor
        navigationItem.rightBarButtonItem = addButton
        
        let editButton = UIBarButtonItem(title: "EDIT", style: .plain, target: self, action: #selector(editTableView(_:)))
        editButton.tintColor = primaryTextDarkColor
        editButton.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.leftBarButtonItem = editButton
        
        let navItemTitleLabel = UILabel()
        navItemTitleLabel.text = "Moments"
        navItemTitleLabel.backgroundColor = UIColor.clear
        navItemTitleLabel.textColor = primaryTextRegularColor
        navItemTitleLabel.font = UIFont(name: headingsFontName, size: 20.0)
        navigationItem.titleView = navItemTitleLabel
        
        tableView.sectionHeaderHeight = 50.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
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
    
    @objc fileprivate func applicationDidBecomeActive(notification: NSNotification) {
        if !specialEvents.isEmpty && eventTimer == nil {
            eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
        }
    }
    
    @objc fileprivate func applicationWillResignActive(notification: NSNotification) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    override func didReceiveMemoryWarning() {
        if UIApplication.shared.applicationState == .background {
            eventTimer?.invalidate()
            eventTimer = nil
        }
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        localPersistentStoreNotificationToken?.invalidate()
        eventTimer?.invalidate()
        eventTimer = nil
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
            let cancelButton = UIBarButtonItem()
            cancelButton.tintColor = primaryTextDarkColor
            let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: contentSecondaryFontName, size: 14.0)! as Any]
            cancelButton.setTitleTextAttributes(attributes, for: .normal)
            cancelButton.title = "CANCEL"
            
            if let cell = sender as? EventTableViewCell {
                let ip = tableView.indexPath(for: cell)!
                let event = items(forSection: ip.section)[ip.row]
                let dest = segue.destination as! NewEventViewController
                dest.specialEvent = event
                dest.editingEvent = true
            }
            
            navigationItem.backBarButtonItem = cancelButton
            
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
        let headerView = UITableViewHeaderFooterView()
        let blurEffect = UIBlurEffect(style: .dark)
        let backgroundView = UIVisualEffectView(effect: blurEffect)
        headerView.backgroundView = backgroundView
        
        let headerLabel = UILabel(frame: CGRect(x: 5.0, y: 5.0, width: 100.0, height: 100.0))
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.backgroundColor = UIColor.clear
        headerLabel.textColor = secondaryTextRegularColor
        headerLabel.font = UIFont(name: headingsFontName, size: 30.0)
        headerLabel.text = activeCategories[section]
        headerLabel.textAlignment = .left
        
        headerView.contentView.addSubview(headerLabel)
        headerLabel.sizeToFit()
        headerView.leftAnchor.constraint(equalTo: headerLabel.leftAnchor, constant: -20.0).isActive = true
        headerView.topAnchor.constraint(equalTo: headerLabel.topAnchor, constant: 0.0).isActive = true
        headerView.rightAnchor.constraint(equalTo: headerLabel.rightAnchor, constant: 0.0).isActive = true
        headerView.bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 0.0).isActive = true
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == items(forSection: indexPath.section).count - 1 {return 160}
        return 170
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        cell.configuration = .tableView
        cell.configure()
        
        let bottomAnchorConstraint = cell.constraints.first {$0.secondAnchor == cell.viewWithMargins.bottomAnchor}
        bottomAnchorConstraint!.isActive = false
        if indexPath.row == items(forSection: indexPath.section).count - 1 {
            cell.bottomAnchor.constraint(equalTo: cell.viewWithMargins.bottomAnchor, constant: 0.0).isActive = true
        }
        else {
            cell.bottomAnchor.constraint(equalTo: cell.viewWithMargins.bottomAnchor, constant: cellSpacing).isActive = true
        }
        
        cell.eventTitle = items(forSection: indexPath.section)[indexPath.row].title
        cell.eventTagline = items(forSection: indexPath.section)[indexPath.row].tagline
        cell.eventDate = items(forSection: indexPath.section)[indexPath.row].date
        cell.abridgedDisplayMode = items(forSection: indexPath.section)[indexPath.row].abridgedDisplayMode
        cell.creationDate = items(forSection: indexPath.section)[indexPath.row].creationDate
        if let imageInfo = items(forSection: indexPath.section)[indexPath.row].image {
            if imageInfo.isAppImage {
                cell.useMask = items(forSection: indexPath.section)[indexPath.row].useMask
                cell.eventImage = AppEventImage(fromEventImageInfo: imageInfo)
            }
            else {
                cell.useMask = false
                cell.eventImage = UserEventImage(fromEventImageInfo: imageInfo)
            }
        }
        
        if let gestures = cell.timerContainerView.gestureRecognizers, gestures.isEmpty || cell.timerContainerView.gestureRecognizers == nil {
            let changeDateDisplayModeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleChangeDisplayModeTap(_:)))
            let changeDateDisplayModeTapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(handleChangeDisplayModeTap(_:)))
            cell.timerContainerView.addGestureRecognizer(changeDateDisplayModeTapGestureRecognizer)
            cell.abridgedTimerContainerView.addGestureRecognizer(changeDateDisplayModeTapGestureRecognizer2)
        }
        
        if indexPath == lastIndexPath, eventTimer == nil {
            eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let categoryOfDeletedItem = items(forSection: indexPath.section)[indexPath.row].category
            
            localPersistentStore.beginWrite()
            localPersistentStore.delete(items(forSection: indexPath.section)[indexPath.row])
            try! localPersistentStore.commitWrite(withoutNotifying: [localPersistentStoreNotificationToken])
            
            updateActiveCategories()
            updateIndexPathMap()
            
            tableView.beginUpdates()
            if !activeCategories.contains(categoryOfDeletedItem) {
                tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)
            }
            else {tableView.deleteRows(at: [indexPath], with: .fade)}
            tableView.endUpdates()
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
    
    @objc fileprivate func handleChangeDisplayModeTap(_ sender: UITapGestureRecognizer) {
        let cell = sender.view!.superview!.superview! as! EventTableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        cell.abridgedDisplayMode = !cell.abridgedDisplayMode
        localPersistentStore.beginWrite()
        items(forSection: indexPath.section)[indexPath.row].abridgedDisplayMode = !items(forSection: indexPath.section)[indexPath.row].abridgedDisplayMode
        try! localPersistentStore.commitWrite(withoutNotifying: [localPersistentStoreNotificationToken])
    }
    
    @objc fileprivate func cancel() {self.dismiss(animated: true, completion: nil)}
    
    // Function to check cloud for updates on startup.
    fileprivate func syncRealmWithCloud () -> Void {
        
    }
    
    // Function to setup data model on startup.
    fileprivate func setupDataModel() -> Void {
        do {
            
            if let temp = userDefaultsContainer?.value(forKey: "Categories") as? [String] {allCategories = temp}
            else { // Perform initial app load setup
                if userDefaultsContainer != nil {
                    allCategories = ["Favorites", "Holidays", "Travel", "Business", "Pleasure", "Birthdays", "Aniversaries", "Wedding", "Family", "Other", "Uncategorized"]
                    userDefaultsContainer!.set(allCategories, forKey: "Categories")
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
            updateIndexPathMap()
            tableView.reloadData()
            
            addOrRemoveNewCellPrompt()
            
            // Setup notification token for database changes
            localPersistentStoreNotificationToken = specialEvents._observe { [weak weakSelf = self] (changes: RealmCollectionChange) in
                if !weakSelf!.isUserChange {
                    switch changes {
                    case .error(let error):
                        fatalError("Error with Realm notifications: \(error.localizedDescription)")
                    case .initial: break
                    case .update(_, let deletions, let insertions, let modifications):
                        
                        let oldActiveCategories = weakSelf!.activeCategories
                        let oldIndexPathMap = weakSelf!.indexPathMap
                        var fullDataReload = false
                        var insertedSections = [Int]()
                        var sectionsToReload = [Int]()
                        var deletedSections = [Int]()
                        var indexPathsToDelete = [IndexPath]()
                        var indexPathsToInsert = [IndexPath]()
                        var indexPathsToModify = [IndexPath]()
                        
                        weakSelf!.updateActiveCategories()
                        weakSelf!.updateIndexPathMap()
                        
                        if weakSelf!.categoryDidChange {fullDataReload = true;  weakSelf!.categoryDidChange = false}
                        else if weakSelf!.activeCategories != oldActiveCategories {
                            let diff = weakSelf!.activeCategories.count - oldActiveCategories.count
                            if diff > 0 {
                                var j = 0
                                for i in 0..<weakSelf!.activeCategories.count {
                                    if weakSelf!.activeCategories[i] != oldActiveCategories[j] {insertedSections.append(i)}
                                    else {if j < oldActiveCategories.count - 1 {j += 1}}
                                }
                            }
                            else if diff < 0 {
                                var j = 0
                                for i in 0..<oldActiveCategories.count {
                                    if oldActiveCategories[i] != weakSelf!.activeCategories[j] {deletedSections.append(i)}
                                    else {if j < weakSelf!.activeCategories.count - 1 {j += 1}}
                                }
                            }
                            else {fullDataReload = true}
                        }
                        
                        if !fullDataReload {
                            for eventIndex in deletions {
                                if !deletedSections.contains(oldIndexPathMap[eventIndex].section) {
                                    indexPathsToDelete.append(oldIndexPathMap[eventIndex])
                                }
                            }
                            for eventIndex in insertions {
                                if !insertedSections.contains(weakSelf!.indexPathMap[eventIndex].section) {
                                    indexPathsToInsert.append(weakSelf!.indexPathMap[eventIndex])
                                    if weakSelf!.indexPathMap[eventIndex].row == weakSelf!.items(forSection: weakSelf!.indexPathMap[eventIndex].section).count - 1 {
                                        indexPathsToModify.append(IndexPath(row: weakSelf!.indexPathMap[eventIndex].row - 1, section: weakSelf!.indexPathMap[eventIndex].section))
                                    }
                                }
                            }
                            for eventIndex in modifications {
                                if !deletedSections.contains(oldIndexPathMap[eventIndex].section) && !insertedSections.contains(weakSelf!.indexPathMap[eventIndex].section) {
                                    if weakSelf!.dateDidChange {
                                        if !sectionsToReload.contains(weakSelf!.indexPathMap[eventIndex].section) {
                                            sectionsToReload.append(weakSelf!.indexPathMap[eventIndex].section)
                                        }
                                    }
                                    else {indexPathsToModify.append(oldIndexPathMap[eventIndex])}
                                }
                                else if !deletedSections.contains(oldIndexPathMap[eventIndex].section) && insertedSections.contains(weakSelf!.indexPathMap[eventIndex].section) {
                                    indexPathsToDelete.append(oldIndexPathMap[eventIndex])
                                }
                            }
                        }
                        
                        DispatchQueue.main.async { [weak weakSelf = self] in
                            if weakSelf != nil {
                                
                                if fullDataReload {weakSelf!.tableView.reloadData()}
                                else {
                                    weakSelf!.tableView.beginUpdates()
                                    if !insertedSections.isEmpty {
                                        weakSelf!.tableView.insertSections(IndexSet(insertedSections), with: .fade)
                                    }
                                    if !deletedSections.isEmpty {
                                        weakSelf!.tableView.deleteSections(IndexSet(deletedSections), with: .fade)
                                    }
                                    if !sectionsToReload.isEmpty {
                                        weakSelf!.tableView.reloadSections(IndexSet(sectionsToReload), with: .fade)
                                    }
                                    if !indexPathsToDelete.isEmpty {
                                        weakSelf!.tableView.deleteRows(at: indexPathsToDelete, with: .fade)
                                    }
                                    if !indexPathsToInsert.isEmpty {
                                        weakSelf!.tableView.insertRows(at: indexPathsToInsert, with: .fade)
                                    }
                                    if !indexPathsToModify.isEmpty {
                                        weakSelf!.tableView.reloadRows(at: indexPathsToModify, with: .fade)
                                    }
                                    
                                    weakSelf!.tableView.endUpdates()
                                }
                                weakSelf!.addOrRemoveNewCellPrompt()
                                weakSelf!.dateDidChange = false
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
    
    fileprivate func updateIndexPathMap() {
        indexPathMap = Array(repeating: IndexPath(), count: specialEvents.count)
        for section in 0..<activeCategories.count {
            for (row, event) in items(forSection: section).enumerated() {
                let index = specialEvents.index(of: event)!
                indexPathMap[index] = IndexPath(row: row, section: section)
            }
        }
    }
    
    // Function to add a new event from the events page.
    @objc fileprivate func insertNewObject(_ sender: Any) {performSegue(withIdentifier: "Add New Event Segue", sender: self)}
    
    @objc fileprivate func editTableView(_ sender: UIBarButtonItem) {
        if sender.title == "EDIT" {
            tableView.setEditing(true, animated: true)
            sender.title = "DONE"
        }
        else if sender.title == "DONE" {
            tableView.setEditing(false, animated: true)
            sender.title = "EDIT"
        }
    }
    
    fileprivate func addOrRemoveNewCellPrompt() -> Void {
        // TODO: Make this a soft and comfortable glyph instead of harsh text.
        if activeCategories.isEmpty {
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
    
    fileprivate func indexPaths(forEvents indicies: [Int]) -> [IndexPath] {
        var indexPathsToReturn = [IndexPath]()
        for index in indicies {
            let category = specialEvents[index].category
            let section = activeCategories.index(where: {$0 == category})!
            let items = self.items(forSection: section)
            let row = items.index(where: {$0.category == category})!
            indexPathsToReturn.append(IndexPath(row: row, section: section))
        }
        return indexPathsToReturn
    }
}


