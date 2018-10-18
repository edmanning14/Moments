//
//  MasterViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications
import os

class MasterViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    //
    // MARK: - Properties
    //
    
    //
    // MARK: Data Management
    fileprivate var currentFilter = EventFilters.all {
        didSet {
            userDefaults.set(currentFilter.rawValue, forKey: UserDefaultKeys.DataManagement.currentFilter)
            navItemTitle.setTitle(currentFilter.rawValue, for: .normal)
            if isUserChange {
                updateActiveCategories()
                updateIndexPathMap()
                tableView.reloadData()
                isUserChange = false
            }
        }
    }
    fileprivate var currentSort = SortMethods.chronologically {
        didSet {
            userDefaults.set(currentSort.rawValue, forKey: UserDefaultKeys.DataManagement.currentSort)
            if isUserChange {
                updateActiveCategories()
                updateIndexPathMap()
                tableView.reloadData()
                isUserChange = false
            }
        }
    }
    fileprivate var futureToPast = true {
        didSet {
            userDefaults.set(futureToPast, forKey: UserDefaultKeys.DataManagement.futureToPast)
            if isUserChange {
                updateActiveCategories()
                updateIndexPathMap()
                tableView.reloadData()
                isUserChange = false
            }
        }
    }
    
    //
    // MARK: Data Model
    var mainRealmSpecialEvents: Results<SpecialEvent>!
    var defaultNotificationsConfig: DefaultNotificationsConfig!
    var activeCategories = [String]()
    var indexPathMap = [IndexPath]()
    var allCategories: [String] {return userDefaults.value(forKey: "Categories") as! [String]}
    var lastIndexPath = IndexPath(row: 0, section: 0)

    //
    // MARK: Persistence
    var mainRealm: Realm!
    //var specialEventsOnMainRealmNotificationToken: NotificationToken!
    
    //
    // MARK: GUI
    var detailViewController: DetailViewController? = nil
    var navItemTitle = UIButton()
    
    //
    // MARK: Constants
    fileprivate struct SegueIdentifiers {
        static let showDetail = "showDetail"
        static let addNewEventSegue = "Add New Event Segue"
        static let showSettings = "Show Settings"
    }
    
    //
    // MARK: Expanding Header Parameters
    lazy var headerExpansion: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.black
        return contentView
    }()
    lazy var separator: UIView = {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white
        line.layer.opacity = 0.2
        return line
    }()
    lazy var expandedHeaderContents: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.clear
        
        let material1 = UIView()
        let material2 = UIView()
        let material3 = UIView()
        material1.backgroundColor = GlobalColors.lightGrayForFills
        material2.backgroundColor = GlobalColors.lightGrayForFills
        material3.backgroundColor = GlobalColors.lightGrayForFills
        material1.layer.cornerRadius = GlobalCornerRadii.material
        material2.layer.cornerRadius = GlobalCornerRadii.material
        material3.layer.cornerRadius = GlobalCornerRadii.material
        
        let materialStackView = UIStackView()
        let spacing: CGFloat = 2.0
        materialStackView.translatesAutoresizingMaskIntoConstraints = false
        materialStackView.backgroundColor = UIColor.clear
        materialStackView.spacing = spacing
        materialStackView.axis = .horizontal
        materialStackView.distribution = .fillEqually
        materialStackView.addArrangedSubview(material1)
        materialStackView.addArrangedSubview(material2)
        materialStackView.addArrangedSubview(material3)
        containerView.addSubview(materialStackView)
        
        let headingsStackView = UIStackView()
        headingsStackView.translatesAutoresizingMaskIntoConstraints = false
        headingsStackView.backgroundColor = UIColor.clear
        headingsStackView.axis = .horizontal
        headingsStackView.distribution = .fillEqually
        
        let filterTitleLabel = UILabel()
        let sortTitleLabel = UILabel()
        let orderTitleLabel = UILabel()
        filterTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        sortTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        orderTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        filterTitleLabel.textColor = GlobalColors.orangeRegular
        sortTitleLabel.textColor = GlobalColors.orangeRegular
        orderTitleLabel.textColor = GlobalColors.orangeRegular
        filterTitleLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        sortTitleLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        orderTitleLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        filterTitleLabel.textAlignment = .center
        sortTitleLabel.textAlignment = .center
        orderTitleLabel.textAlignment = .center
        filterTitleLabel.text = headerColumnTitles.filter
        sortTitleLabel.text = headerColumnTitles.sort
        orderTitleLabel.text = headerColumnTitles.order
        headingsStackView.addArrangedSubview(filterTitleLabel)
        headingsStackView.addArrangedSubview(sortTitleLabel)
        headingsStackView.addArrangedSubview(orderTitleLabel)
        containerView.addSubview(headingsStackView)
        
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.backgroundColor = UIColor.clear
        pickerView.dataSource = self
        pickerView.delegate = self
        containerView.addSubview(pickerView)
        
        containerView.topAnchor.constraint(equalTo: headingsStackView.topAnchor, constant: -8.0).isActive = true
        containerView.leftAnchor.constraint(equalTo: headingsStackView.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: headingsStackView.rightAnchor).isActive = true
        containerView.leftAnchor.constraint(equalTo: pickerView.leftAnchor).isActive = true
        containerView.rightAnchor.constraint(equalTo: pickerView.rightAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 8.0).isActive = true
        headingsStackView.bottomAnchor.constraint(equalTo: pickerView.topAnchor).isActive = true
    
        containerView.leftAnchor.constraint(equalTo: materialStackView.leftAnchor, constant: -spacing).isActive = true
        containerView.rightAnchor.constraint(equalTo: materialStackView.rightAnchor, constant: spacing).isActive = true
        containerView.topAnchor.constraint(equalTo: materialStackView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: materialStackView.bottomAnchor, constant: 8.0).isActive = true

        return containerView
    }()
    var headerIsExpanded = false
    let filterPickerViewData = [
        [EventFilters.all.rawValue, EventFilters.upcoming.rawValue, EventFilters.past.rawValue],
        [SortMethods.chronologically.rawValue, SortMethods.byCategory.rawValue],
        ["Yes", "No"]
    ]
    struct headerColumnTitles {
        static let filter = "Show"
        static let sort = "Organized"
        static let order = "Ascending?"
    }
    
    //
    // MARK: Flags
    var isUserChange = false
    var categoryDidChange = false
    
    //
    // MARK: Timers
    var eventTimer: Timer?
    
    //
    // MARK: Other
    var tipCellIndexPath: IndexPath?
    var welcomeCellIndexPath: IndexPath?
    var reviewCellIndexPath: IndexPath?
    
    
    //
    // MARK: - View Controller Lifecycle
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentFilter = EventFilters(rawValue: userDefaults.string(forKey: UserDefaultKeys.DataManagement.currentFilter)!)!
        currentSort = SortMethods(rawValue: userDefaults.string(forKey: UserDefaultKeys.DataManagement.currentSort)!)!
        futureToPast = userDefaults.bool(forKey: UserDefaultKeys.DataManagement.futureToPast)
        
        setupDataModel()
        
        let specialEventNib = UINib(nibName: "SpecialEventCell", bundle: nil)
        tableView.register(specialEventNib, forCellReuseIdentifier: "Event")
        
        tableView.backgroundColor = UIColor.black
        tableView.estimatedRowHeight = 300.0
        navigationController?.view.backgroundColor = UIColor.black
        
        configureBarTitleAttributes()
        
        //let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: Fonts.contentSecondaryFontName, size: 16.0)! as Any]
        
        
        _ = addBarButtonItem(side: .right, action:  #selector(insertNewObject(_:)), target: self, title: nil, image: #imageLiteral(resourceName: "AddEventImage"))
        _ = addBarButtonItem(side: .left, action: #selector(handleSettingsButtonTap), target: self, title: nil, image: #imageLiteral(resourceName: "SettingsButtonImage"))
        
        navItemTitle = createHeaderDropdownButton()
        navItemTitle.setTitle(EventFilters.all.rawValue, for: .normal)
        navItemTitle.addTarget(self, action: #selector(handleNavTitleTap(_:)), for: .touchUpInside)
        navItemTitle.titleLabel?.adjustsFontSizeToFitWidth = true
        navItemTitle.titleLabel?.minimumScaleFactor = 0.5
        navigationItem.titleView = navItemTitle
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Reference to detail view controller
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !mainRealmSpecialEvents.isEmpty && eventTimer == nil {
            eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
        }
        
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    var numTimesViewDidAppear = 0
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        func displayTipCell() {
            var section = 0
            var row = 0
            var cellCounter = 0
            for _section in 0..<activeCategories.count {
                let count = items(forSection: section).count
                if count >= 3 - cellCounter {row = 2 - cellCounter; section = _section; break}
                else {cellCounter += count; row = count; section = _section}
            }
            
            if section != 0 || row != 0 {
                tipCellIndexPath = IndexPath(row: row, section: section)
                if welcomeCellIndexPath == nil {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
                        DispatchQueue.main.async { [weak self] in
                            self?.tableView.beginUpdates()
                            self?.tableView.insertRows(at: [self!.tipCellIndexPath!], with: .fade)
                            self?.tableView.endUpdates()
                            userDefaults.set(true, forKey: UserDefaultKeys.tipShown)
                        }
                    }
                }
            }
        }
        
        numTimesViewDidAppear += 1
        let numLaunches = userDefaults.integer(forKey: UserDefaultKeys.numberOfLaunches)
        if numLaunches == 1 {if !userDefaults.bool(forKey: UserDefaultKeys.tipShown) && numTimesViewDidAppear > 1 {displayTipCell()}}
        else if !userDefaults.bool(forKey: UserDefaultKeys.tipShown) {displayTipCell()}
        
        if numLaunches > 2 && !userDefaults.bool(forKey: UserDefaultKeys.reviewPromptShown) && userDefaults.bool(forKey: UserDefaultKeys.tipShown) {
            var section = 0
            var row = 0
            var cellCounter = 0
            for _section in 0..<activeCategories.count {
                let count = items(forSection: section).count
                if count >= 3 - cellCounter {row = 2 - cellCounter; section = _section; break}
                else {cellCounter += count; row = count; section = _section}
            }
            
            if section != 0 || row != 0 {
                reviewCellIndexPath = IndexPath(row: row, section: section)
                if welcomeCellIndexPath == nil && tipCellIndexPath == nil {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
                        DispatchQueue.main.async { [weak self] in
                            self?.tableView.beginUpdates()
                            self?.tableView.insertRows(at: [self!.reviewCellIndexPath!], with: .fade)
                            self?.tableView.endUpdates()
                            userDefaults.set(true, forKey: UserDefaultKeys.reviewPromptShown)
                        }
                    }
                }
            }
        }
        
        navItemTitle.setTitle(currentFilter.rawValue, for: .normal)
        
        // Setup notifications
        if numLaunches == 1 && numTimesViewDidAppear == 1 {
            let notifcationPermissionsPopUp = UIAlertController(title: "Notifications", message: "Moments would like to send you notifications to remind you when your special moments will or have occurred. Tap 'Allow' in the next prompt to allow these kinds of notifications. When you have a free moment, click the gear in the upper left of the main screen to see how you can customize these notifications.", preferredStyle: .alert)
            let okayButton = UIAlertAction(title: "Okay!", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .badge, .sound])
                { (granted, error) in
                    if let _error = error {
                        os_log("Error requesting notification authorization: %@", log: .default, type: .error, _error.localizedDescription)
                        let errorPopup = UIAlertController(title: "Oops", message: "There was an error getting authorization to send notifications. If you could file a bug report on this by navigting to the 'Settings' view that would be much appreciated!", preferredStyle: .alert)
                        let okayButton2 = UIAlertAction(title: "Okay", style: .default) { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }
                        errorPopup.addAction(okayButton2)
                        self.present(errorPopup, animated: true, completion: nil)
                    }
                    else {
                        autoreleasepool {
                            let authorizationRealm = try! Realm(configuration: appRealmConfig)
                            if granted {
                                updateDailyNotifications(async: false, updatePending: false)
                                
                                let authorizationSpecialEvents = authorizationRealm.objects(SpecialEvent.self)
                                var titles = [String]()
                                for event in authorizationSpecialEvents {titles.append(event.title)}
                                scheduleNewEvents(titled: titles)
                                
                            }
                            else {
                                let authorizationDefaultNotificationsConfig = authorizationRealm.objects(DefaultNotificationsConfig.self)
                                authorizationDefaultNotificationsConfig[0].allOn = false
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer) in
                            DispatchQueue.main.async { [weak self] in
                                self?.welcomeCellIndexPath = IndexPath(row: 0, section: 0)
                                self?.tableView.beginUpdates()
                                self?.tableView.insertRows(at: [self!.welcomeCellIndexPath!], with: .fade)
                                self?.tableView.endUpdates()
                            }
                        }
                    }
                }
            }
            notifcationPermissionsPopUp.addAction(okayButton)
            self.present(notifcationPermissionsPopUp, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func applicationDidBecomeActive(notification: NSNotification) {
        if !mainRealmSpecialEvents.isEmpty && eventTimer == nil {
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
    
    override func viewDidDisappear(_ animated: Bool) {
        if welcomeCellIndexPath != nil {
            welcomeCellIndexPath = nil
            var newSelectedRow: IndexPath?
            if let currentSelectedRow = tableView.indexPathForSelectedRow {
                newSelectedRow = IndexPath(row: currentSelectedRow.row - 1, section: currentSelectedRow.section)
            }
            tableView.reloadData()
            tableView.selectRow(at: newSelectedRow, animated: false, scrollPosition: .none)
        }
    }
    
    override func didReceiveMemoryWarning() {
        if UIApplication.shared.applicationState == .background {
            eventTimer?.invalidate()
            eventTimer = nil
        }
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        //specialEventsOnMainRealmNotificationToken?.invalidate()
        eventTimer?.invalidate()
        eventTimer = nil
    }
    
    
    //
    // MARK: - Segues
    //
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if headerIsExpanded {collapseHeader(animated: false)}
        
        switch segue.identifier! {
            
        case SegueIdentifiers.showDetail:
            if let indexPath = tableView.indexPathForSelectedRow {
                var row = indexPath.row
                if let welcome = welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
                if let tip = tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
                if let review = reviewCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
                let eventToDetail = items(forSection: indexPath.section)[row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.specialEvent = eventToDetail
            }
            
        case SegueIdentifiers.addNewEventSegue:
            if let cell = sender as? EventTableViewCell {
                let indexPath = tableView.indexPath(for: cell)!
                var row = indexPath.row
                if let welcome = welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
                if let tip = tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
                if let review = reviewCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
                let event = items(forSection: indexPath.section)[row]
                let dest = segue.destination as! NewEventViewController
                dest.specialEvent = event
                dest.editingEvent = true
            }
            
            let newEventController = segue.destination as! NewEventViewController
            newEventController.masterViewController = self
                        
        case SegueIdentifiers.showSettings:
            let settingsController = segue.destination as! SettingsViewController
            settingsController.masterViewController = self
        default: break
        }
    }
    
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue) {}
    
    @IBAction func unwindFromNewEventController(segue: UIStoryboardSegue) {
        updateActiveCategories()
        updateIndexPathMap()
        tableView.reloadData()
    }
    
    //
    // MARK: - Table View Functions
    //
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if activeCategories.count > 0 {removeTableViewBackground(); return activeCategories.count}
        else if welcomeCellIndexPath != nil || tipCellIndexPath != nil || reviewCellIndexPath != nil {removeTableViewBackground(); return 1}
        else {
            if mainRealmSpecialEvents.count == 0 {addTableViewBackground(withMessage: TableViewBackgroundViewMessages.noEvents)}
            else {addTableViewBackground(withMessage: TableViewBackgroundViewMessages.noEventsInThisFilter)}
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let ipForWelcomCell = welcomeCellIndexPath, ipForWelcomCell.section == section {return items(forSection: section).count + 1}
        if let ipForTipCell = tipCellIndexPath, ipForTipCell.section == section {return items(forSection: section).count + 1}
        if let ipForReviewCell = reviewCellIndexPath, ipForReviewCell.section == section {return items(forSection: section).count + 1}
        return items(forSection: section).count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch currentSort {
        case .byCategory: return titleOnlyHeaderView(title: activeCategories[section])
        case .chronologically: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0)
            headerView.textLabel!.textColor = GlobalColors.orangeRegular
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch currentSort {
        case .byCategory: return 60.0
        case .chronologically: return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == welcomeCellIndexPath || indexPath == tipCellIndexPath || indexPath == reviewCellIndexPath {return UITableViewAutomaticDimension}
        if indexPath.row == items(forSection: indexPath.section).count - 1 {return 160}
        return 160 + globalCellSpacing
    }
    
    @objc fileprivate func reviewApp() {
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1342990841?action=write-review") else {
            os_log("App Store URL could not be initialized.", log: .default, type: .error); return
        }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
        dismissReviewCell()
    }
    
    @objc fileprivate func dismissReviewCell() {
        if let deletedIP = reviewCellIndexPath {
            reviewCellIndexPath = nil
            tableView.beginUpdates()
            if activeCategories.count == 0 {tableView.deleteSections(IndexSet([deletedIP.section]), with: .fade)}
            else {tableView.deleteRows(at: [deletedIP], with: .fade)}
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath == welcomeCellIndexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Welcome Cell", for: indexPath)
            return cell
        }
        else if indexPath == tipCellIndexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Cell", for: indexPath)
            return cell
        }
        else if indexPath == reviewCellIndexPath {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "Review Cell", for: indexPath) as? ReviewTableViewCell {
                cell.sureButton.emphasisedFormat()
                cell.laterButton.regularFormat()
                cell.sureButton.addTarget(self, action: #selector(reviewApp), for: .touchUpInside)
                cell.laterButton.addTarget(self, action: #selector(dismissReviewCell), for: .touchUpInside)
                return cell
            }
            else {
                os_log("Could not downcast to reviewTableViewCell.", log: .default, type: .error)
                return UITableViewCell()
            }
        }
        else {
            let event: SpecialEvent = {
                var row = indexPath.row
                if let welcome = welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
                if let tip = tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
                if let review = reviewCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
                return items(forSection: indexPath.section)[row]
            }()
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
            cell.configuration = .cell
            cell.configure()
            
            if indexPath.row == items(forSection: indexPath.section).count - 1 {cell.spacingAdjustmentConstraint.constant = 0.0}
            else {cell.spacingAdjustmentConstraint.constant = globalCellSpacing}
            
            let title = event.title
            cell.eventTitle = title
            
            if let tagline = event.tagline {cell.eventTagline = tagline} else {cell.eventTagline = nil}
            
            let infoDisplayed = event.infoDisplayed
            cell.infoDisplayed = DisplayInfoOptions(rawValue: infoDisplayed)!
            
            if let eventDate = event.date {cell.eventDate = event.date} else {cell.eventDate = nil}
            
            let repeats = event.repeats
            cell.repeats = RepeatingOptions(rawValue: repeats)!
            
            let abridgedDisplayMode = event.abridgedDisplayMode
            cell.abridgedDisplayMode = abridgedDisplayMode
            
            let creationDate = event.creationDate
            cell.creationDate = creationDate
            
            let useMask = event.useMask
            cell.useMask =  useMask
            
            if let imageInfo = event.image {
                var locationForCellView: CGFloat?
                if let intLocationForCellView = event.locationForCellView.value {
                    locationForCellView = CGFloat(intLocationForCellView) / 100.0
                }
                if imageInfo.isAppImage {
                    if let appImage = AppEventImage(fromEventImageInfo: imageInfo) {
                        cell.setSelectedImage(image: appImage, locationForCellView: locationForCellView)
                    }
                }
                else {
                    if let userImage = UserEventImage(fromEventImageInfo: imageInfo) {
                        cell.setSelectedImage(image: userImage, locationForCellView: locationForCellView)
                    }
                }
            }
            
            func addGestures() {
                let changeDateDisplayModeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleChangeDisplayModeTap(_:)))
                let changeDateDisplayModeTapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(handleChangeDisplayModeTap(_:)))
                let changeInfoDisplayModeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleChangeInfoDisplayModeTap(_:)))
                cell.timerContainerView.addGestureRecognizer(changeDateDisplayModeTapGestureRecognizer)
                cell.abridgedTimerContainerView.addGestureRecognizer(changeDateDisplayModeTapGestureRecognizer2)
                cell.taglineLabel.addGestureRecognizer(changeInfoDisplayModeTapGestureRecognizer)
            }
            
            if cell.timerContainerView.gestureRecognizers == nil {addGestures()}
            else if let gestures = cell.timerContainerView.gestureRecognizers, gestures.isEmpty {addGestures()}
            
            if indexPath == lastIndexPath, eventTimer == nil {
                eventTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerBlock(timerFireMethod:)), userInfo: nil, repeats: true)
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath != welcomeCellIndexPath || indexPath != tipCellIndexPath || indexPath != reviewCellIndexPath {
            let editAction = UIContextualAction(style: .normal, title:"Edit") { [weak self] (_, _, completion) in
                if let cell = self?.tableView.cellForRow(at: indexPath) {
                    self?.performSegue(withIdentifier: SegueIdentifiers.addNewEventSegue, sender: cell)
                    completion(true)
                }
                else {completion(false)}
            }
            
            let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] (_, _, completion) in
                if let cell = self?.tableView.cellForRow(at: indexPath) as? EventTableViewCell {
                    let viewWithMargins = cell.viewWithMargins!
                    let currentCornerRadius = viewWithMargins.layer.cornerRadius
                    viewWithMargins.layer.cornerRadius = 0.0
                    let imageToShare = viewWithMargins.asJPEGImage()
                    viewWithMargins.layer.cornerRadius = currentCornerRadius
                    let activityController = UIActivityViewController(activityItems: [imageToShare], applicationActivities: nil)
                    activityController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.assignToContact, UIActivityType.openInIBooks]
                    self?.present(activityController, animated: true, completion: nil)
                    completion(true)
                }
                completion(false)
            }
            
            editAction.backgroundColor = GlobalColors.orangeDark
            shareAction.backgroundColor = GlobalColors.shareButtonColor
            let configuration = UISwipeActionsConfiguration(actions: [shareAction, editAction])
            configuration.performsFirstActionWithFullSwipe = true
            return configuration
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let livingSelf = self else {completion(false); return}
            
            if self?.welcomeCellIndexPath != nil, self!.welcomeCellIndexPath! == indexPath {
                self?.welcomeCellIndexPath = nil
                tableView.beginUpdates()
                if livingSelf.activeCategories.count == 0 {tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)}
                else {tableView.deleteRows(at: [indexPath], with: .fade)}
                tableView.endUpdates()
            }
            else if self?.tipCellIndexPath != nil, self!.tipCellIndexPath! == indexPath {
                self?.tipCellIndexPath = nil
                tableView.beginUpdates()
                if livingSelf.activeCategories.count == 0 {tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)}
                else {tableView.deleteRows(at: [indexPath], with: .fade)}
                tableView.endUpdates()
            }
            else if self?.reviewCellIndexPath != nil, self!.reviewCellIndexPath! == indexPath {
                self?.reviewCellIndexPath = nil
                tableView.beginUpdates()
                if livingSelf.activeCategories.count == 0 {tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)}
                else {tableView.deleteRows(at: [indexPath], with: .fade)}
                tableView.endUpdates()
            }
            else {
                let deletedItem: SpecialEvent = {
                    var row = indexPath.row
                    if let welcome = livingSelf.welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
                    if let tip = livingSelf.tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
                    if let review = livingSelf.tipCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
                    return livingSelf.items(forSection: indexPath.section)[row]
                }()
                let deletedItemCategory = deletedItem.category
                let deletedItemDate = deletedItem.date!.date
                
                if let config = deletedItem.notificationsConfig {
                    var uuidsToDeschedule = [String]()
                    for notif in config.eventNotifications {uuidsToDeschedule.append(notif.uuid)}
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: uuidsToDeschedule)
                }
                
                deletedItem.cascadeDelete()
                livingSelf.mainRealm.beginWrite()
                livingSelf.mainRealm.delete(deletedItem)
                try! livingSelf.mainRealm.commitWrite() //withoutNotifying: [livingSelf.specialEventsOnMainRealmNotificationToken]
                
                livingSelf.updateActiveCategories()
                livingSelf.updateIndexPathMap()
                
                if livingSelf.tipCellIndexPath != nil && livingSelf.tipCellIndexPath!.section == indexPath.section && livingSelf.tipCellIndexPath!.row > indexPath.row {
                    livingSelf.tipCellIndexPath = IndexPath(row: livingSelf.tipCellIndexPath!.row - 1, section: livingSelf.tipCellIndexPath!.section)
                }
                if livingSelf.reviewCellIndexPath != nil && livingSelf.reviewCellIndexPath!.section == indexPath.section && livingSelf.reviewCellIndexPath!.row > indexPath.row {
                    livingSelf.reviewCellIndexPath = IndexPath(row: livingSelf.reviewCellIndexPath!.row - 1, section: livingSelf.reviewCellIndexPath!.section)
                }
                
                tableView.beginUpdates()
                switch livingSelf.currentSort {
                case .byCategory:
                    if !livingSelf.activeCategories.contains(deletedItemCategory) && livingSelf.welcomeCellIndexPath == nil {
                        tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)
                    }
                    else {tableView.deleteRows(at: [indexPath], with: .fade)}
                case .chronologically:
                    if livingSelf.items(forSection: 0).count == 0 && livingSelf.welcomeCellIndexPath == nil && livingSelf.tipCellIndexPath == nil && livingSelf.reviewCellIndexPath == nil {
                        tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)
                    }
                    else {tableView.deleteRows(at: [indexPath], with: .fade)}
                }
                tableView.endUpdates()
                
                shouldUpdateDailyNotifications = true
                updatePendingNotifcationsBadges(forDate: deletedItemDate)
            }
            
            
            if let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row - 1, section: indexPath.section)) as? EventTableViewCell {
                if indexPath.row == livingSelf.items(forSection: indexPath.section).count {
                    cell.spacingAdjustmentConstraint.constant = 0.0
                }
            }
            
            completion(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let cellsNotToSelect = ["Welcome Cell", "Tip Cell"]
        if !cellsNotToSelect.contains(cell.reuseIdentifier!) {performSegue(withIdentifier: SegueIdentifiers.showDetail, sender: cell)}
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let _tableView = scrollView as? UITableView {
            if _tableView == tableView {
                if headerIsExpanded {collapseHeader(animated: true)}
            }
        }
    }
    
    
    //
    // MARK: - Picker View Delegate/Data Source
    //
    //
    // Picker View Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return filterPickerViewData.count}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filterPickerViewData[component].count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var _viewToReturn = view as? UILabel
        if _viewToReturn == nil {
            _viewToReturn = UILabel()
            _viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayLight, size: 14.0)
            _viewToReturn!.textColor = GlobalColors.cyanRegular
            _viewToReturn!.textAlignment = .center
        }
        let viewToReturn = _viewToReturn!
        viewToReturn.text = filterPickerViewData[component][row]
        return viewToReturn
    }
    
    //
    // Picker View Delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        isUserChange = true
        let newValue = filterPickerViewData[component][row]
        if let filterChange = EventFilters(rawValue: newValue) {currentFilter = filterChange}
        else if let sortChange = SortMethods(rawValue: newValue) {currentSort = sortChange}
        else if newValue == filterPickerViewData[component][0] {futureToPast = true}
        else if newValue == filterPickerViewData[component][1] {futureToPast = false}
    }
    
    
    //
    // MARK: - Private Methods
    //
    
    //
    // MARK: Target-action methods
    @objc fileprivate func timerBlock(timerFireMethod: Timer) {
        print(tableView.visibleCells.count)
        for cell in tableView.visibleCells {
            if let eventCell = cell as? EventTableViewCell {print(eventCell.eventTitle ?? "None"); eventCell.update()}
        }
    }
    
    @objc fileprivate func handleChangeDisplayModeTap(_ sender: UITapGestureRecognizer) {
        let cell = sender.view!.superview!.superview! as! EventTableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        cell.abridgedDisplayMode = !cell.abridgedDisplayMode
        
        var row = indexPath.row
        if let welcome = welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
        if let tip = tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
        if let review = reviewCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
        mainRealm.beginWrite()
        items(forSection: indexPath.section)[row].abridgedDisplayMode = !items(forSection: indexPath.section)[row].abridgedDisplayMode
        try! mainRealm.commitWrite() //withoutNotifying: [specialEventsOnMainRealmNotificationToken]
    }
    
    @objc fileprivate func handleChangeInfoDisplayModeTap(_ sender: UITapGestureRecognizer) {
        let cell = sender.view!.superview!.superview! as! EventTableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        var row = indexPath.row
        if let welcome = welcomeCellIndexPath, welcome.section == indexPath.section {row -= 1}
        if let tip = tipCellIndexPath, tip.section == indexPath.section, tip.row < indexPath.row {row -= 1}
        if let review = reviewCellIndexPath, review.section == indexPath.section, review.row < indexPath.row {row -= 1}
        switch cell.infoDisplayed {
        case .tagline:
            cell.infoDisplayed = .date
            mainRealm.beginWrite()
            items(forSection: indexPath.section)[row].infoDisplayed = DisplayInfoOptions.date.rawValue
            try! mainRealm.commitWrite() //withoutNotifying: [specialEventsOnMainRealmNotificationToken]
        case .date:
            cell.infoDisplayed = .tagline
            mainRealm.beginWrite()
            items(forSection: indexPath.section)[row].infoDisplayed = DisplayInfoOptions.tagline.rawValue
            try! mainRealm.commitWrite() //withoutNotifying: [specialEventsOnMainRealmNotificationToken]
        case .none: break
        }
    }
    
    @objc fileprivate func cancel() {self.dismiss(animated: true, completion: nil)}
    
    @objc fileprivate func handleSettingsButtonTap() {
        performSegue(withIdentifier: SegueIdentifiers.showSettings, sender: self)
    }
    
    @objc fileprivate func handleNavTitleTap(_ sender: UIButton) {
        if headerIsExpanded {collapseHeader(animated: true)}
        else {expandHeader(animated: true)}
    }
    
    fileprivate func collapseHeader(animated: Bool) {
        navItemTitle.setImage(#imageLiteral(resourceName: "ExpandSelectionImage"), for: .normal)
        headerIsExpanded = false
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.15,
                delay: 0.0,
                options: .curveLinear,
                animations: {
                    self.expandedHeaderContents.layer.opacity = 0.0
                },
                completion: {[weak self] (position) in
                    self?.expandedHeaderContents.removeFromSuperview()
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.15,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {
                            self?.headerExpansion.frame = CGRect(
                                origin: self!.headerExpansion.frame.origin,
                                size: CGSize(width: self!.headerExpansion.bounds.width, height: 1.0)
                            )
                            self?.separator.frame = CGRect(
                                origin: self!.headerExpansion.frame.origin,
                                size: self!.separator.frame.size
                            )
                        },
                        completion: {(position) in
                            self!.headerExpansion.removeFromSuperview()
                            self!.separator.removeFromSuperview()
                        }
                    )
                }
            )
        }
        else {
            expandedHeaderContents.removeFromSuperview()
            headerExpansion.removeFromSuperview()
            separator.removeFromSuperview()
        }
    }
    
    fileprivate func expandHeader(animated: Bool) {
        navItemTitle.setImage(#imageLiteral(resourceName: "ColapseSelectionImage"), for: .normal)
        headerIsExpanded = true
        let endHeight: CGFloat = 150.0
        navigationController!.view.addSubview(headerExpansion)
        navigationController!.view.addSubview(separator)
        headerExpansion.frame = CGRect(
            origin: tableView.frame.origin,
            size: CGSize(width: navigationController!.view.bounds.width, height: 1.0)
        )
        separator.frame = CGRect(
            origin: tableView.frame.origin,
            size: CGSize(width: navigationController!.view.bounds.width, height: 1.0)
        )
        
        let pickerViewIndex = expandedHeaderContents.subviews.index(where: {(view) in if let _ = view as? UIPickerView {return true} else {return false}})!
        let pickerView = expandedHeaderContents.subviews[pickerViewIndex] as! UIPickerView
        
        let filterToSelect = filterPickerViewData[0].index(where: {$0 == currentFilter.rawValue})!
        let sortToSelect = filterPickerViewData[1].index(where: {$0 == currentSort.rawValue})!
        var orderToSelect: Int
        if futureToPast {orderToSelect = filterPickerViewData[2].index(where: {$0 == "Yes"})!}
        else {orderToSelect = filterPickerViewData[2].index(where: {$0 == "No"})!}
        
        pickerView.selectRow(filterToSelect, inComponent: 0, animated: false)
        pickerView.selectRow(sortToSelect, inComponent: 1, animated: false)
        pickerView.selectRow(orderToSelect, inComponent: 2, animated: false)

        if animated {
            expandedHeaderContents.layer.opacity = 0.0
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.15,
                delay: 0.0,
                options: .curveLinear,
                animations: {
                    self.headerExpansion.frame = CGRect(
                        origin: self.headerExpansion.frame.origin,
                        size: CGSize(width: self.headerExpansion.bounds.width, height: endHeight + 1)
                    )
                    self.separator.frame = CGRect(
                        origin: CGPoint(x: self.headerExpansion.frame.origin.x, y: self.headerExpansion.frame.origin.y + endHeight),
                        size: self.separator.frame.size
                    )
                },
                completion: {[weak self] (position) in
                    self?.navigationController!.view.addSubview(self!.expandedHeaderContents)
                    self?.navigationController!.view.topAnchor.constraint(equalTo: self!.expandedHeaderContents.topAnchor, constant: -self!.navigationController!.navigationBar.bounds.height - UIApplication.shared.statusBarFrame.height).isActive = true
                    self?.navigationController!.view.leftAnchor.constraint(equalTo: self!.expandedHeaderContents.leftAnchor).isActive = true
                    self?.navigationController!.view.rightAnchor.constraint(equalTo: self!.expandedHeaderContents.rightAnchor).isActive = true
                    self?.expandedHeaderContents.heightAnchor.constraint(equalToConstant: endHeight).isActive = true
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.15,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {self?.expandedHeaderContents.layer.opacity = 1.0},
                        completion: nil
                    )
                }
            )
        }
        else {
            headerExpansion.frame = CGRect(
                origin: headerExpansion.frame.origin,
                size: CGSize(width: headerExpansion.bounds.width, height: endHeight + 1)
            )
            separator.frame = CGRect(
                origin: CGPoint(x: headerExpansion.frame.origin.x, y: self.headerExpansion.frame.origin.y + endHeight),
                size: separator.frame.size
            )
        }
    }
    
    // Function to setup data model on startup.
    fileprivate func setupDataModel() -> Void {
        
        do {try! mainRealm = Realm(configuration: appRealmConfig)}
        
        if userDefaults.value(forKey: "Categories") as? [String] == nil { // Perform initial app load setup
            let _allCategories = defaultCategories + immutableCategories
            userDefaults.set(_allCategories, forKey: "Categories")
        }
        
        mainRealmSpecialEvents = mainRealm!.objects(SpecialEvent.self)
        defaultNotificationsConfig = mainRealm!.objects(DefaultNotificationsConfig.self)[0]
        
        updateActiveCategories()
        updateIndexPathMap()
        tableView.reloadData()
    }
    
    // Function to update the active categories when changes to the data model occur.
    func updateActiveCategories() {
        
        activeCategories.removeAll()
        var filteredEvents = mainRealmSpecialEvents!
        
        let todaysDate = Date()
        switch currentFilter {
        case .all: break
        case .upcoming: filteredEvents = filteredEvents.filter("date.date > %@", todaysDate)
        case .past: filteredEvents = filteredEvents.filter("date.date < %@", todaysDate)
        }
        
        switch currentSort {
        case .chronologically: if filteredEvents.count != 0 {activeCategories.append("All")}
        case .byCategory:
            for event in filteredEvents {
                if !activeCategories.contains(event.category) {activeCategories.append(event.category)}
            }
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
    
    func updateIndexPathMap() {
        indexPathMap = Array(repeating: IndexPath(), count: mainRealmSpecialEvents.count)
        for section in 0..<activeCategories.count {
            for (row, event) in items(forSection: section).enumerated() {
                let index = mainRealmSpecialEvents.index(of: event)!
                indexPathMap[index] = IndexPath(row: row, section: section)
            }
        }
    }
    
    // Function to add a new event from the events page.
    @objc fileprivate func insertNewObject(_ sender: Any) {performSegue(withIdentifier: "Add New Event Segue", sender: self)}
    
    func items(forSection section: Int) -> Results<SpecialEvent> {
        var eventsToReturn = mainRealmSpecialEvents!
        
        let todaysDate = Date()
        switch currentFilter {
        case .all: break
        case .upcoming: eventsToReturn = eventsToReturn.filter("date.date > %@", todaysDate)
        case .past: eventsToReturn = eventsToReturn.filter("date.date < %@", todaysDate)
        }
        
        switch currentSort {
        case .byCategory: eventsToReturn = eventsToReturn.filter("category = %@", activeCategories[section])
        case .chronologically: break
        }
        
        if futureToPast {eventsToReturn = eventsToReturn.sorted(byKeyPath: "date.date", ascending: true)}
        else {eventsToReturn = eventsToReturn.sorted(byKeyPath: "date.date", ascending: false)}
        
        return eventsToReturn
    }
    
    fileprivate func indexPaths(forEvents indicies: [Int]) -> [IndexPath] {
        var indexPathsToReturn = [IndexPath]()
        for index in indicies {
            let category = mainRealmSpecialEvents[index].category
            let section = activeCategories.index(where: {$0 == category})!
            let items = self.items(forSection: section)
            let row = items.index(where: {$0.category == category})!
            indexPathsToReturn.append(IndexPath(row: row, section: section))
        }
        return indexPathsToReturn
    }
    
    fileprivate var tableViewBackgroundView: UIView?
    fileprivate var tableViewBackgroundViewTitleMessageLabel: UILabel?
    fileprivate var tableViewBackgroundViewDetailMessageLabel: UILabel?
    
    fileprivate enum TableViewBackgroundViewMessages {
        case noEvents, noEventsInThisFilter
        
        var titleText: String {
            switch self {
            case .noEvents: return "So much empty."
            case .noEventsInThisFilter: return "Nothing to see here."
            }
        }
        
        var detailText: String {
            switch self {
            case .noEvents: return "Looks like you have no events! Tap the '+' in the upper right corner to create a new one!"
            case .noEventsInThisFilter: return "Try changing the filter by tapping the drop down menu at the top of the screen."
            }
        }
    }
    
    fileprivate func addTableViewBackground(withMessage message: TableViewBackgroundViewMessages) {
        if tableViewBackgroundView == nil {
            tableViewBackgroundView = UIView()
            tableViewBackgroundView?.backgroundColor = UIColor.black
            
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            tableViewBackgroundView?.addSubview(containerView)
            
            containerView.centerYAnchor.constraint(equalTo: tableViewBackgroundView!.centerYAnchor).isActive = true
            containerView.leftAnchor.constraint(equalTo: tableViewBackgroundView!.leftAnchor, constant: 12.0).isActive = true
            containerView.rightAnchor.constraint(equalTo: tableViewBackgroundView!.rightAnchor, constant: -12.0).isActive = true
            
            tableViewBackgroundViewTitleMessageLabel = UILabel()
            tableViewBackgroundViewTitleMessageLabel?.translatesAutoresizingMaskIntoConstraints = false
            tableViewBackgroundViewTitleMessageLabel?.font = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 20.0)
            tableViewBackgroundViewTitleMessageLabel?.textColor = GlobalColors.gray
            tableViewBackgroundViewTitleMessageLabel?.textAlignment = .center
            tableViewBackgroundViewTitleMessageLabel?.numberOfLines = 0
            
            tableViewBackgroundViewDetailMessageLabel = UILabel()
            tableViewBackgroundViewDetailMessageLabel?.translatesAutoresizingMaskIntoConstraints = false
            tableViewBackgroundViewDetailMessageLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
            tableViewBackgroundViewDetailMessageLabel?.textColor = GlobalColors.gray
            tableViewBackgroundViewDetailMessageLabel?.textAlignment = .center
            tableViewBackgroundViewDetailMessageLabel?.numberOfLines = 0
            
            containerView.addSubview(tableViewBackgroundViewTitleMessageLabel!)
            containerView.addSubview(tableViewBackgroundViewDetailMessageLabel!)
            
            tableViewBackgroundViewTitleMessageLabel?.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            tableViewBackgroundViewTitleMessageLabel?.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            tableViewBackgroundViewTitleMessageLabel?.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            tableViewBackgroundViewTitleMessageLabel?.bottomAnchor.constraint(equalTo: tableViewBackgroundViewDetailMessageLabel!.topAnchor, constant: -15.0).isActive = true
            
            tableViewBackgroundViewDetailMessageLabel?.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
            tableViewBackgroundViewDetailMessageLabel?.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
            tableViewBackgroundViewTitleMessageLabel?.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        }
        
        tableViewBackgroundViewTitleMessageLabel?.text = message.titleText
        tableViewBackgroundViewDetailMessageLabel?.text = message.detailText
        tableView.backgroundView = tableViewBackgroundView
    }
    
    fileprivate func removeTableViewBackground() {tableView.backgroundView = nil}
}


