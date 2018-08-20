//
//  SettingsViewController.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsTableViewCellDelegate {

    //
    // MARK: Paramters
    //
    //
    // MARK: Current selected options
    var dateDisplayMode = Options.dateDisplayMode.short
    var widgitSort = Options.widgetSort.random
    var allNotifications = Options.allNotifications.on
    var dailyReminders = Options.dailyReminders.on
    var eventReminders = Options.eventReminders.on
    var masterViewController: MasterViewController?
    
    // For segue
    var configuring = ConfigureNotificationsTableViewController.NotificationTypes.dailyReminders
    
    //
    // MARK: Table View Static Data Source
    
    struct Options {
        static let resetAllThemes = SettingsTypeDataSource.Option(text: nil) {}
        static let resetNotifsToDefaults = SettingsTypeDataSource.Option(text: nil) {}
        struct dateDisplayMode {
            static let short = SettingsTypeDataSource.Option(text: "Short") {
                
            }
            static let long = SettingsTypeDataSource.Option(text: "Long") {
                
            }
        }
        struct widgetSort {
            static let random = SettingsTypeDataSource.Option(text: "Random") {
                
            }
            static let upcoming = SettingsTypeDataSource.Option(text: "Upcoming") {
                
            }
        }
        struct allNotifications {
            static let on = SettingsTypeDataSource.Option(text: "On") {}
            static let off = SettingsTypeDataSource.Option(text: "Off") {}
        }
        struct dailyReminders {
            static let on = SettingsTypeDataSource.Option(text: "On") {}
            static let off = SettingsTypeDataSource.Option(text: "Off") {}
        }
        struct eventReminders {
            static let on = SettingsTypeDataSource.Option(text: "On") {}
            static let off = SettingsTypeDataSource.Option(text: "Off") {}
        }
    }
    
    lazy var tableViewDataSource: SettingsTypeDataSource = {
        let dataSource = SettingsTypeDataSource()
        
        // Section 1
        let s1 = dataSource.addSection(title: "Appearence")
        
        let s1r1 = dataSource[s1].addRow(type: .action, title: Text.RowTitles.resetAllThemes)
        dataSource[s1].rows[s1r1].options.append(Options.resetAllThemes)
        
        let s1r2 = dataSource[s1].addRow(type: .selectOption, title: Text.RowTitles.dateDisplayMode)
        dataSource[s1].rows[s1r2].options.append(Options.dateDisplayMode.short)
        dataSource[s1].rows[s1r2].options.append(Options.dateDisplayMode.long)
        
        // Section 2
        let s2 = dataSource.addSection(title: Text.SectionTitles.widgit)
        
        let s2r1 = dataSource[s2].addRow(type: .selectOption, title: Text.RowTitles.widgetSort)
        dataSource[s2].rows[s2r1].options.append(Options.widgetSort.random)
        dataSource[s2].rows[s2r1].options.append(Options.widgetSort.upcoming)
        
        // Section 3
        let s3 = dataSource.addSection(title: Text.SectionTitles.notifications)
        
        let s3r1 = dataSource[s3].addRow(type: .onOrOff, title: Text.RowTitles.allNotifications)
        dataSource[s3].rows[s3r1].options.append(Options.allNotifications.on)
        dataSource[s3].rows[s3r1].options.append(Options.allNotifications.off)
        
        let s3r2 = dataSource[s3].addRow(type: .segue, title: Text.RowTitles.dailyReminders)
        dataSource[s3].rows[s3r2].options.append(Options.dailyReminders.on)
        dataSource[s3].rows[s3r2].options.append(Options.dailyReminders.off)
        
        let s3r4 = dataSource[s3].addRow(type: .segue, title: Text.RowTitles.eventReminders)
        dataSource[s3].rows[s3r4].options.append(Options.eventReminders.on)
        dataSource[s3].rows[s3r4].options.append(Options.eventReminders.off)
        
        let s3r5 = dataSource[s3].addRow(type: .action, title: Text.RowTitles.resetToDefaults)
        dataSource[s3].rows[s3r5].options.append(Options.resetNotifsToDefaults)
        
        return dataSource
    }()
    
    var expandedCellIndexPath: IndexPath? {
        didSet {
            if expandedCellIndexPath != oldValue {
                if let _oldValue = oldValue, let oldCell = tableView.cellForRow(at: _oldValue) as? SettingsTableViewCell {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {oldCell.optionsPickerView.layer.opacity = 0.0},
                        completion: {(position) in
                            oldCell.optionsPickerView.isHidden = true; oldCell.optionsPickerView.layer.opacity = 1.0
                    }
                    )
                }
                if let newValue = expandedCellIndexPath, let newCell = tableView.cellForRow(at: newValue) as? SettingsTableViewCell {
                    newCell.optionsPickerView.layer.opacity = 0.0
                    newCell.optionsPickerView.isHidden = false
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {newCell.optionsPickerView.layer.opacity = 1.0},
                        completion: nil
                    )
                }
                tableView.beginUpdates(); tableView.endUpdates()
            }
        }
    }
    
    //
    // MARK: Realm
    var mainRealm: Realm!
    var notificationsConfig: Results<DefaultNotificationsConfig>!
    
    //
    // MARK: Other Constants
    struct cellReuseIdentifiers {
        static let settingsCell = "Settings Cell"
    }
    
    struct Text {
        struct SectionTitles {
            static let apperence = "Appearence"
            static let widgit = "Configure Widget"
            static let notifications = "Notifications"
        }
        struct RowTitles {
            static let resetAllThemes = "Reset All Themes"
            static let dateDisplayMode = "Date Display Mode"
            static let widgetSort = "Sort"
            static let allNotifications = "Turn all on/off"
            static let dailyReminders = "Daily Reminders"
            static let eventReminders = "Event Reminders"
            static let resetToDefaults = "Reset To Defaults"
        }
    }
    
    //
    // MARK: GUI
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerViewMeImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopAnchor: NSLayoutConstraint!
    let maxTopAnchorDimension: CGFloat = 12.0
    var minTopAnchorDimension: CGFloat = 0.0
    var previousScrollOffset: CGFloat = 0.0
    
    //
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        minTopAnchorDimension = -headerViewMeImageConstraint.constant

        let settingsCellNib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
        tableView.register(settingsCellNib, forCellReuseIdentifier: cellReuseIdentifiers.settingsCell)
        
        try! mainRealm = Realm(configuration: realmConfig)
        notificationsConfig = mainRealm.objects(DefaultNotificationsConfig.self)
        
        if notificationsConfig.count != 1 {
            // TODO: Log this error, delete the first one maybe for production?
            fatalError("There were multiple notification configs! Should only be one.")
        }
        
        if UserDefaults.standard.value(forKey: UserDefaultKeys.dateDisplayMode) as! String == Defaults.DateDisplayMode.short {
            dateDisplayMode = Options.dateDisplayMode.short
        }
        else {dateDisplayMode = Options.dateDisplayMode.long}
        if notificationsConfig[0].allOn {allNotifications = Options.allNotifications.on}
        else {allNotifications = Options.allNotifications.off}
        if notificationsConfig[0].dailyNotificationOn {dailyReminders = Options.dailyReminders.on}
        else {dailyReminders = Options.dailyReminders.off}
        if notificationsConfig[0].individualEventRemindersOn {eventReminders = Options.eventReminders.on}
        else {eventReminders = Options.eventReminders.off}
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    //
    // MARK: Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {return tableViewDataSource.count}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableViewDataSource[section].title {
        case Text.SectionTitles.notifications: if allNotifications == Options.allNotifications.off {return 1}
        default: return tableViewDataSource[section].rows.count
        }
        return tableViewDataSource[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return titleOnlyHeaderView(title: tableViewDataSource[section].title!)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
            headerView.textLabel!.textColor = GlobalColors.orangeRegular
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowData = tableViewDataSource[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifiers.settingsCell) as! SettingsTableViewCell
        cell.selectionStyle = .none
        cell.delegate = self
        cell.rowType = rowData.type
        if cell.onOffSwitch.allTargets.isEmpty {
            cell.onOffSwitch.addTarget(self, action: #selector(cellSwitchFlipped(_:)), for: .valueChanged)
        }
        cell.title = rowData.title
        cell.options = tableViewDataSource[indexPath.section].rows[indexPath.row].options
        
        switch rowData.type {
        case .action: break
        case .onOrOff, .segue, .selectOption:
            switch rowData.title {
            case Text.RowTitles.dateDisplayMode: cell.selectedOption = dateDisplayMode
            case Text.RowTitles.widgetSort: cell.selectedOption = widgitSort
            case Text.RowTitles.allNotifications: cell.selectedOption = allNotifications
            case Text.RowTitles.dailyReminders: cell.selectedOption = dailyReminders
            case Text.RowTitles.eventReminders: cell.selectedOption = eventReminders
            default:
                // TODO: break
                fatalError("Need to add a row title?")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableViewDataSource[indexPath.section].rows[indexPath.row].type == .onOrOff {return nil}
        else {return indexPath}
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowData = tableViewDataSource[indexPath.section].rows[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! SettingsTableViewCell
        switch rowData.type {
        case .action, .segue:
            switch rowData.title {
            case Text.RowTitles.dailyReminders:
                configuring = .dailyReminders
                performSegue(withIdentifier: "Configure Notifications", sender: self)
            case Text.RowTitles.eventReminders:
                configuring = .eventReminders
                performSegue(withIdentifier: "Configure Notifications", sender: self)
            case Text.RowTitles.resetToDefaults:
                let alert = UIAlertController(title: "Are You Sure?", message: "Are you sure you want to reset all notifications to default settings?", preferredStyle: .alert)
                let yes = UIAlertAction(title: "Yes please", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                    do {
                        try! self.mainRealm.write {
                            self.notificationsConfig[0].allOn = Defaults.Notifications.allOn
                            self.notificationsConfig[0].dailyNotificationOn = Defaults.Notifications.dailyNotificationsOn
                            
                            let newScheduleTime = RealmEventNotificationComponents(fromDateComponents: Defaults.Notifications.dailyNotificationsScheduledTime)
                            if let oldScheduleTime = self.notificationsConfig[0].dailyNotificationsScheduledTime {
                                self.mainRealm.delete(oldScheduleTime)
                            }
                            self.notificationsConfig[0].dailyNotificationsScheduledTime = newScheduleTime
                            
                            self.notificationsConfig[0].individualEventRemindersOn = Defaults.Notifications.individualEventRemindersOn
                            
                            let newRealmNotifTimes = List<RealmEventNotification>()
                            for eventNotif in Defaults.Notifications.eventNotifications {
                                newRealmNotifTimes.append(RealmEventNotification(fromEventNotification: eventNotif))
                            }
                            self.mainRealm.delete(self.notificationsConfig[0].eventNotifications)
                            self.notificationsConfig[0].eventNotifications.append(objectsIn: newRealmNotifTimes)
                            
                            self.notificationsConfig[0].categoriesToNotify = Defaults.Notifications.categoriesToNotify
                        }
                    }
                    
                    print("Notifications stored after reset to defaults:")
                    let allEventNotifications = self.mainRealm.objects(RealmEventNotification.self)
                    for (i, realmNotif) in allEventNotifications.enumerated() {
                        print("\(i + 1): \(realmNotif.uuid)")
                    }
                    
                    updateDailyNotifications(async: true)
                    let alert2 = UIAlertController(title: "Reset Current Events?", message: "Would you like to reset all current event notifications to these new default settings?", preferredStyle: .alert)
                    let yes2 = UIAlertAction(title: "Yes please", style: .default) {(action) in
                        self.dismiss(animated: true, completion: nil)
                        
                        DispatchQueue.global(qos: .background).async {
                            autoreleasepool {
                                let resetDefaultsRealm = try! Realm(configuration: realmConfig)
                                let resetDefaultsSpecialEvents = resetDefaultsRealm.objects(SpecialEvent.self)
                                
                                //
                                // Reset all events to default, get uuids
                                var uuidsToDeschedule = [String]()
                                for event in resetDefaultsSpecialEvents {
                                    print(event.title)
                                    if event.notificationsConfig != nil { // Old config
                                        do {
                                            try! resetDefaultsRealm.write {
                                                for notif in event.notificationsConfig!.eventNotifications {
                                                    print("Old notif: \(notif.uuid)")
                                                    uuidsToDeschedule.append(notif.uuid)
                                                    resetDefaultsRealm.delete(notif)
                                                }
                                                event.notificationsConfig!.eventNotificationsOn = Defaults.Notifications.individualEventRemindersOn
                                                event.notificationsConfig!.isCustom = false
                                                
                                                let newRealmNotifications = List<RealmEventNotification>()
                                                for eventNotif in Defaults.Notifications.eventNotifications {
                                                    let realmNotif = RealmEventNotification(copyingEventNotification: eventNotif)
                                                    print("New notif: \(realmNotif.uuid)")
                                                    newRealmNotifications.append(realmNotif)
                                                }
                                                event.notificationsConfig!.eventNotifications.append(objectsIn: newRealmNotifications)
                                            }
                                        }
                                    }
                                        
                                    else { // New config
                                        var realmEventNotifs = [RealmEventNotification]()
                                        for eventNotif in Defaults.Notifications.eventNotifications {
                                            let realmEventNotif = RealmEventNotification(fromEventNotification: eventNotif)
                                            realmEventNotifs.append(realmEventNotif)
                                        }
                                        let newConfig = RealmEventNotificationConfig(
                                            eventNotifications: realmEventNotifs,
                                            eventNotificationsOn: Defaults.Notifications.individualEventRemindersOn,
                                            isCustom: false)
                                        
                                        do {try! resetDefaultsRealm.write {event.notificationsConfig = newConfig}}
                                    }
                                    
                                }
                                
                                print("Notifications stored after adding new notifs:")
                                let allEventNotifications = resetDefaultsRealm.objects(RealmEventNotification.self)
                                for (i, realmNotif) in allEventNotifications.enumerated() {
                                    print("\(i + 1): \(realmNotif.uuid)")
                                }
                                
                                //
                                // Cancel all pending event notification requests
                                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: uuidsToDeschedule)
                                
                                //
                                // Schedule new notifications
                                var titles = [String]()
                                for event in resetDefaultsSpecialEvents {titles.append(event.title)}
                                scheduleNewEvents(titled: titles)
                                
                            }
                        }
                    }
                    let no2 = UIAlertAction(title: "No thanks", style: .cancel) { (action) in
                        self.dismiss(animated: true, completion: nil)
                    }
                    alert2.addAction(yes2)
                    alert2.addAction(no2)
                    self.present(alert2, animated: true, completion: nil)
                }
                let no = UIAlertAction(title: "Oops! No thanks", style: .cancel) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                alert.addAction(yes)
                alert.addAction(no)
                self.present(alert, animated: true, completion: nil)
            default:
                // TODO: log and break
                fatalError("Need to add a case?")
            }
            
        case .onOrOff: break
        case .selectOption:
            if rowData.options.count > 2 {
                if expandedCellIndexPath != indexPath {
                    expandedCellIndexPath = indexPath
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                }
                else {expandedCellIndexPath = nil}
            }
            else {expandedCellIndexPath = nil; cell.selectNextOption()}
        }
    }
    
    //
    // MARK: Scroll view delegate
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
            let isScrollingDown = scrollDiff > 0
            
            var newHeight = headerViewTopAnchor.constant
            if isScrollingDown {
                newHeight = max(minTopAnchorDimension, headerViewTopAnchor.constant - abs(scrollDiff))
            }
            else {
                if scrollView.contentOffset.y == 0.0 {
                    newHeight = min(maxTopAnchorDimension, headerViewTopAnchor.constant + abs(scrollDiff))
                }
            }
            
            if newHeight != headerViewTopAnchor.constant {headerViewTopAnchor.constant = newHeight}
            previousScrollOffset = scrollView.contentOffset.y
        }
    }*/
    
    //
    // MARK: SettingsTableViewCellDelegate
    func selectedOptionDidUpdate(cell: SettingsTableViewCell) {
        switch cell.title {
        case Text.RowTitles.allNotifications: allNotifications = cell.selectedOption!; allNotifications.runAction()
        case Text.RowTitles.dailyReminders: dailyReminders = cell.selectedOption!; dailyReminders.runAction()
        case Text.RowTitles.eventReminders: eventReminders = cell.selectedOption!; eventReminders.runAction()
        case Text.RowTitles.widgetSort: widgitSort = cell.selectedOption!; widgitSort.runAction()
        case Text.RowTitles.dateDisplayMode:
            dateDisplayMode = cell.selectedOption!
            switch dateDisplayMode {
            case Options.dateDisplayMode.short:
                UserDefaults.standard.set(Defaults.DateDisplayMode.short, forKey: UserDefaultKeys.dateDisplayMode)
                masterViewController?.tableView.reloadData()
            case Options.dateDisplayMode.long:
                UserDefaults.standard.set(Defaults.DateDisplayMode.long, forKey: UserDefaultKeys.dateDisplayMode)
                masterViewController?.tableView.reloadData()
            default:
                // TODO: Log and break
                fatalError("Do you need to add a case??")
            }
        default:
            // TODO: break
            fatalError("Need to add a case?")
        }
    }
    
    //
    // MARK: Cell buttons action methods
    @objc fileprivate func cellSwitchFlipped(_ sender: UISwitch) {
        let cell = sender.superview as! SettingsTableViewCell
        
        switch cell.title {
        case Text.RowTitles.allNotifications:
            let section = tableView.indexPath(for: cell)!.section
            let ipsToModify = [IndexPath(row: 1, section: section), IndexPath(row: 2, section: section), IndexPath(row: 3, section: section)]
            if sender.isOn {
                allNotifications = Options.allNotifications.on
                // TODO: turn all notifications back on
                tableView.beginUpdates()
                tableView.insertRows(at: ipsToModify, with: .fade)
                tableView.endUpdates()
            }
            else {
                allNotifications = Options.allNotifications.off
                // TODO: turn all notifications off
                tableView.beginUpdates()
                tableView.deleteRows(at: ipsToModify, with: .fade)
                tableView.endUpdates()
            }
            do {try! mainRealm.write {notificationsConfig[0].allOn = sender.isOn}}
        default:
            // TODO: log and break
            fatalError("Need to add a case?")
        }
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cancelButton = UIBarButtonItem()
        cancelButton.tintColor = GlobalColors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
        cancelButton.setTitleTextAttributes(attributes, for: .normal)
        cancelButton.title = "CANCEL"
        navigationItem.backBarButtonItem = cancelButton
        
        switch segue.identifier {
        case "Configure Notifications":
            let destination = segue.destination as! ConfigureNotificationsTableViewController
            destination.segueFrom = .settings
            destination.configuring = configuring
            switch configuring {
            case .dailyReminders: destination.globalToggleOn = notificationsConfig[0].dailyNotificationOn
            case .eventReminders: destination.globalToggleOn = notificationsConfig[0].individualEventRemindersOn
            }
            destination.useCustomNotifications = false
        default:
            // TODO: log and break
            fatalError("Need to add a case?")
        }
    }
    
    @IBAction func unwindFromNotificationsConfig(segue: UIStoryboardSegue) {
        if let notificationsController = segue.source as? ConfigureNotificationsTableViewController {
            
            let section = tableViewDataSource.index(where: {$0.title == Text.SectionTitles.notifications})!
            switch notificationsController.configuring {
            case .dailyReminders:
                let row = tableViewDataSource[section].rows.index(where: {$0.title == Text.RowTitles.dailyReminders})!
                let cellToModify = tableView.cellForRow(at: IndexPath(row: row, section: section)) as! SettingsTableViewCell
                if notificationsController.globalToggleOn {cellToModify.selectedOption = Options.dailyReminders.on}
                else {cellToModify.selectedOption = Options.dailyReminders.off}
            case .eventReminders:
                let row = tableViewDataSource[section].rows.index(where: {$0.title == Text.RowTitles.eventReminders})!
                let cellToModify = tableView.cellForRow(at: IndexPath(row: row, section: section)) as! SettingsTableViewCell
                if notificationsController.globalToggleOn {cellToModify.selectedOption = Options.eventReminders.on}
                else {cellToModify.selectedOption = Options.eventReminders.off}
            }
        }
    }
}
