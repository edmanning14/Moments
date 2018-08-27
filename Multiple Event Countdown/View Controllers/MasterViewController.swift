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

class MasterViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    
    //
    // MARK: - Properties
    //
    
    //
    // MARK: Data Management
    fileprivate var currentFilter = EventFilters.all {
        didSet {
            userDefaults.set(currentFilter.string, forKey: UserDefaultKeys.DataManagement.currentFilter)
            navItemTitle.setTitle(currentFilter.string, for: .normal)
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
            userDefaults.set(currentSort.string, forKey: UserDefaultKeys.DataManagement.currentSort)
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
    // MARK: References and Outlets
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
        [EventFilters.all.string, EventFilters.upcoming.string, EventFilters.past.string],
        [SortMethods.chronologically.string, SortMethods.byCategory.string],
        ["Yes", "No"]
    ]
    struct headerColumnTitles {
        static let filter = "Show"
        static let sort = "Organized"
        static let order = "Ascending?"
    }
    
    //
    // MARK: - Design
    
    //
    // MARK: Flags
    var firstRun = false
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
        
        currentFilter = EventFilters.type(from: userDefaults.string(forKey: UserDefaultKeys.DataManagement.currentFilter)!)!
        currentSort = SortMethods.type(from: userDefaults.string(forKey: UserDefaultKeys.DataManagement.currentSort)!)!
        futureToPast = userDefaults.bool(forKey: UserDefaultKeys.DataManagement.futureToPast)
        
        setupDataModel()
        
        let specialEventNib = UINib(nibName: "SpecialEventCell", bundle: nil)
        tableView.register(specialEventNib, forCellReuseIdentifier: "Event")
        
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 18.0) as Any,
            .foregroundColor: GlobalColors.orangeRegular
        ]
        tableView.backgroundColor = UIColor.black
        navigationController?.view.backgroundColor = UIColor.black
        if #available(iOS 11, *) {
            navigationController?.navigationBar.largeTitleTextAttributes = [
                .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0) as Any,
                .foregroundColor: GlobalColors.orangeRegular
            ]
        }
        
        //let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: Fonts.contentSecondaryFontName, size: 16.0)! as Any]
        
        let addEventImage = #imageLiteral(resourceName: "AddEventImage")
        let addButton = UIBarButtonItem(image: addEventImage, style: .plain, target: self, action: #selector(insertNewObject(_:)))
        addButton.tintColor = GlobalColors.orangeDark
        navigationItem.rightBarButtonItem = addButton
        
        let settingsImage = #imageLiteral(resourceName: "SettingsButtonImage")
        let settingsButton = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(handleSettingsButtonTap))
        settingsButton.tintColor = GlobalColors.orangeDark
        navigationItem.leftBarButtonItem = settingsButton
        
        navItemTitle = createHeaderDropdownButton()
        navItemTitle.setTitle(currentFilter.string, for: .normal)
        navItemTitle.addTarget(self, action: #selector(handleNavTitleTap(_:)), for: .touchUpInside)
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
        
        let allnotifConfigs = mainRealm.objects(RealmEventNotificationConfig.self)
        let allEventNotifs = mainRealm.objects(RealmEventNotification.self)
        let allNotifComponents = mainRealm.objects(RealmEventNotificationComponents.self)
        let allEventDates = mainRealm.objects(EventDate.self)
        
        print("Notification Configs: \(allnotifConfigs.count)")
        print("Event Notifications: \(allEventNotifs.count)")
        print("All Notification Components: \(allNotifComponents.count)")
        print("All Event Dates: \(allEventDates.count)")
        
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Setup notifications
        if firstRun {
            firstRun = false
            let notifcationPermissionsPopUp = UIAlertController(title: "Enable Notifications", message: "Moments would like to send you notifications to remind you when your special moments will or have occured. Click enable on the next prompt to allow these kinds of notifications. When you have time, click the gear in the upper left of the main screen to see how you can customize these notifications.", preferredStyle: .alert)
            let okayButton = UIAlertAction(title: "Okay!", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .badge, .sound])
                { (granted, error) in
                    if let _error = error {
                        // TODO: Log and break
                        print(_error.localizedDescription)
                        fatalError("^ Check error")
                    }
                    
                    autoreleasepool {
                        let authorizationRealm = try! Realm(configuration: appRealmConfig)
                        if granted {
                            updateDailyNotifications(async: false)
                        
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
        switch segue.identifier! {
            
        case SegueIdentifiers.showDetail:
            if let indexPath = tableView.indexPathForSelectedRow {
                let eventToDetail = items(forSection: indexPath.section)[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.specialEvent = eventToDetail
                
                let backButton = UIBarButtonItem()
                backButton.tintColor = GlobalColors.orangeDark
                let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
                backButton.setTitleTextAttributes(attributes, for: .normal)
                backButton.title = "BACK"
                navigationItem.backBarButtonItem = backButton
            }
            
        case SegueIdentifiers.addNewEventSegue:
            let cancelButton = UIBarButtonItem()
            cancelButton.tintColor = GlobalColors.orangeDark
            let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
            cancelButton.setTitleTextAttributes(attributes, for: .normal)
            cancelButton.title = "CANCEL"
            
            if let cell = sender as? EventTableViewCell {
                let ip = tableView.indexPath(for: cell)!
                let event = items(forSection: ip.section)[ip.row]
                let dest = segue.destination as! NewEventViewController
                dest.specialEvent = event
                dest.editingEvent = true
            }
            
            let newEventController = segue.destination as! NewEventViewController
            newEventController.masterViewController = self
            
            navigationItem.backBarButtonItem = cancelButton
            
        case SegueIdentifiers.showSettings:
            let backButton = UIBarButtonItem()
            backButton.tintColor = GlobalColors.orangeDark
            let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
            backButton.setTitleTextAttributes(attributes, for: .normal)
            backButton.title = "BACK"
            navigationItem.backBarButtonItem = backButton
            
            let settingsController = segue.destination as! SettingsViewController
            settingsController.masterViewController = self
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
        if indexPath.row == items(forSection: indexPath.section).count - 1 {return 160}
        return 170
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let event = items(forSection: indexPath.section)[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as! EventTableViewCell
        cell.configuration = .cell
        cell.configure()
        
        if indexPath.row == items(forSection: indexPath.section).count - 1 {cell.spacingAdjustmentConstraint.constant = 0.0}
        else {cell.spacingAdjustmentConstraint.constant = globalCellSpacing}
        
        cell.eventTitle = event.title
        cell.eventTagline = event.tagline
        switch event.infoDisplayed {
        case DisplayInfoOptions.none.displayText: cell.infoDisplayed = DisplayInfoOptions.none
        case DisplayInfoOptions.tagline.displayText: cell.infoDisplayed = DisplayInfoOptions.tagline
        case DisplayInfoOptions.date.displayText: cell.infoDisplayed = DisplayInfoOptions.date
        default:
            // TODO: Log and set a default info display
            fatalError("Unexpected display info option encoutered, do you need to add a new one?")
        }
        cell.eventDate = event.date
        switch event.repeats {
        case RepeatingOptions.never.displayText: cell.repeats = RepeatingOptions.never
        case RepeatingOptions.monthly.displayText: cell.repeats = RepeatingOptions.monthly
        case RepeatingOptions.yearly.displayText: cell.repeats = RepeatingOptions.yearly
        default:
            // TODO: Log and set a default repeating option
            fatalError("Unexpected repeating option encoutered, do you need to add a new one?")
        }
        cell.abridgedDisplayMode = event.abridgedDisplayMode
        cell.creationDate = event.creationDate
        cell.useMask =  event.useMask
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
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let livingSelf = self else {completion(false); return}
            
            let deletedItem = livingSelf.items(forSection: indexPath.section)[indexPath.row]
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
            
            tableView.beginUpdates()
            switch livingSelf.currentSort {
            case .byCategory:
                if !livingSelf.activeCategories.contains(deletedItemCategory) {
                    tableView.deleteSections(IndexSet([indexPath.section]), with: .fade)
                }
                else {tableView.deleteRows(at: [indexPath], with: .fade)}
            case .chronologically:
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            tableView.endUpdates()
            
            shouldUpdateDailyNotifications = true
            updatePendingNotifcationsBadges(forDate: deletedItemDate)
            
            completion(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        performSegue(withIdentifier: SegueIdentifiers.showDetail, sender: cell)
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
        if let filterChange = EventFilters.type(from: newValue) {currentFilter = filterChange}
        else if let sortChange = SortMethods.type(from: newValue) {currentSort = sortChange}
        else if newValue == filterPickerViewData[component][0] {futureToPast = true}
        else if newValue == filterPickerViewData[component][1] {futureToPast = false}
    }
    
    //func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {return 12.0}
    
    
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
        mainRealm.beginWrite()
        items(forSection: indexPath.section)[indexPath.row].abridgedDisplayMode = !items(forSection: indexPath.section)[indexPath.row].abridgedDisplayMode
        try! mainRealm.commitWrite() //withoutNotifying: [specialEventsOnMainRealmNotificationToken]
    }
    
    @objc fileprivate func handleChangeInfoDisplayModeTap(_ sender: UITapGestureRecognizer) {
        let cell = sender.view!.superview!.superview! as! EventTableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        switch cell.infoDisplayed {
        case .tagline:
            cell.infoDisplayed = .date
            mainRealm.beginWrite()
            items(forSection: indexPath.section)[indexPath.row].infoDisplayed = DisplayInfoOptions.date.displayText
            try! mainRealm.commitWrite() //withoutNotifying: [specialEventsOnMainRealmNotificationToken]
        case .date:
            cell.infoDisplayed = .tagline
            mainRealm.beginWrite()
            items(forSection: indexPath.section)[indexPath.row].infoDisplayed = DisplayInfoOptions.tagline.displayText
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
        
        let filterToSelect = filterPickerViewData[0].index(where: {$0 == currentFilter.string})!
        let sortToSelect = filterPickerViewData[1].index(where: {$0 == currentSort.string})!
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
            firstRun = true
            let _allCategories = defaultCategories + immutableCategories
            userDefaults.set(_allCategories, forKey: "Categories")
        }
        
        mainRealmSpecialEvents = mainRealm!.objects(SpecialEvent.self)
        defaultNotificationsConfig = mainRealm!.objects(DefaultNotificationsConfig.self)[0]
        
        updateActiveCategories()
        updateIndexPathMap()
        tableView.reloadData()
        addOrRemoveNewCellPrompt()
        
        // Setup notification token for database changes
        /*specialEventsOnMainRealmNotificationToken = mainRealmSpecialEvents._observe { [weak weakSelf = self] (changes: RealmCollectionChange) in
            if !weakSelf!.isUserChange {
                switch changes {
                case .error(let error):
                    // TODO: Log and break
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
                    
                    shouldUpdateDailyNotifications = true
                    
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
        }*/
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
}


