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
import MessageUI

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsTableViewCellDelegate, MFMailComposeViewControllerDelegate {

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
        //static let resetAllThemes = SettingsTypeDataSource.Option(text: nil) {}
        static let resetNotifsToDefaults = SettingsTypeDataSource.Option(text: nil) {}
        struct dateDisplayMode {
            static let short = SettingsTypeDataSource.Option(text: "Short") {}
            static let long = SettingsTypeDataSource.Option(text: "Long") {}
        }
        struct widgetSort {
            static let random = SettingsTypeDataSource.Option(text: "Random") {}
            static let upcoming = SettingsTypeDataSource.Option(text: "Upcoming") {}
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
        let s1 = dataSource.addSection(title: Text.SectionTitles.general)
        
        let s1r1 = dataSource[s1].addRow(type: .segue, title: Text.RowTitles.organizeCategories)
        
        /*let s1r2 = dataSource[s1].addRow(type: .action, title: Text.RowTitles.resetAllThemes)
        dataSource[s1].rows[s1r2].options.append(Options.resetAllThemes)*/
        
        let s1r3 = dataSource[s1].addRow(type: .selectOption, title: Text.RowTitles.dateDisplayMode)
        dataSource[s1].rows[s1r3].options.append(Options.dateDisplayMode.short)
        dataSource[s1].rows[s1r3].options.append(Options.dateDisplayMode.long)
        
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
    var defaultNotificationsConfig: Results<DefaultNotificationsConfig>!
    
    //
    // MARK: Other Constants
    let headerViewTitles = ["Contact Me!", "Say Hello!", "Have a Question?", "Have Feedback?", "Have an Idea?", "I don't bite!", "How do you like the app?"]
    struct cellReuseIdentifiers {
        static let settingsCell = "Settings Cell"
    }
    
    struct Text {
        struct SectionTitles {
            static let general = "GENERAL"
            static let widgit = "CONFIGURE WIDGET"
            static let notifications = "NOTIFICATIONS"
        }
        struct RowTitles {
            static let organizeCategories = "Organize Categories"
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
    // MARK: Flags
    var composingBugReport = false
    var composingContactMeMessage = false
    
    //
    // MARK: GUI
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var secondaryButtonsStackView: UIStackView!
    @IBOutlet weak var headerViewMeImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewMeImageToButtonsConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var headerViewBottomAnchor: NSLayoutConstraint!
    
    @IBAction func sendMeMail(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            composingContactMeMessage = true
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            
            composeVC.setToRecipients(["indiedeved@gmail.com"])
            composeVC.setSubject("Hello!")
            
            self.present(composeVC, animated: true, completion: nil)
        }
        else {
            guard let mailToURL = URL(string: "mailto:indiedeved@gmail.com") else {
                #if DEBUG
                fatalError("Expected a valid URL here.")
                #endif
                // TODO: Tell user there was a problem sending the mail.
            }
            guard UIApplication.shared.canOpenURL(mailToURL) else {
                // TODO: Tell user they may not be configured to send mail.
                return
            }
            UIApplication.shared.open(mailToURL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func sendFBMessage(_ sender: UIButton) {
        if let fbAppURL = URL(string: "fb://profile/191744958342767") {
            if UIApplication.shared.canOpenURL(fbAppURL) {
                UIApplication.shared.open(fbAppURL, options: [:], completionHandler: nil)
            }
            else {
                if let fbInternetURL = URL(string: "https://www.facebook.com/IndieDevEd") {
                    UIApplication.shared.open(fbInternetURL, options: [:], completionHandler: nil)
                }
                else {
                    // TODO: Log, continue
                    fatalError("URL couldnt be created for some reason...")
                }
            }
        }
        else {
            // TODO: Log, continue
            fatalError("URL couldnt be created for some reason...")
        }
    }
    
    @IBAction func tweetAtMe(_ sender: UIButton) {
        if let twitterAppURL = URL(string: "twitter://user?id=1012615671362928642") {
            if UIApplication.shared.canOpenURL(twitterAppURL) {
                UIApplication.shared.open(twitterAppURL, options: [:], completionHandler: nil)
            }
            else {
                if let twitterInternetURL = URL(string: "https://twitter.com/IndieMakerEd") {
                    UIApplication.shared.open(twitterInternetURL, options: [:], completionHandler: nil)
                }
                else {
                    // TODO: Log, continue
                    fatalError("URL couldnt be created for some reason...")
                }
            }
        }
        else {
            // TODO: Log, continue
            fatalError("URL couldnt be created for some reason...")
        }
    }
    
    @IBAction func sendInstaMessage(_ sender: UIButton) {
        if let instaAppURL = URL(string: "instagram://user?username=indiemakered") {
            if UIApplication.shared.canOpenURL(instaAppURL) {
                UIApplication.shared.open(instaAppURL, options: [:], completionHandler: nil)
            }
            else {
                if let instaInternetURL = URL(string: "https://www.instagram.com/indiemakered/") {
                    UIApplication.shared.open(instaInternetURL, options: [:], completionHandler: nil)
                }
                else {
                    // TODO: Log, continue
                    fatalError("URL couldnt be created for some reason...")
                }
            }
        }
        else {
            // TODO: Log, continue
            fatalError("URL couldnt be created for some reason...")
        }
    }
    
    @IBAction func request(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            composingBugReport = true
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            
            composeVC.setToRecipients(["indiedeved@gmail.com"])
            composeVC.setSubject("I have an idea!")
            composeVC.setMessageBody("Have an idea how this app can be better? Is it missing a feature you desparately want? Does somthing not quite look right? How can I do better?:\n\n", isHTML: false)
            
            self.present(composeVC, animated: true, completion: nil)
        }
        else {
            guard let mailToURL = URL(string: "mailto:indiedeved@gmail.com") else {
                #if DEBUG
                fatalError("Expected a valid URL here.")
                #endif
                // TODO: Tell user there was a problem sending the mail.
            }
            guard UIApplication.shared.canOpenURL(mailToURL) else {
                // TODO: Tell user they may not be configured to send mail.
                return
            }
            UIApplication.shared.open(mailToURL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func reportBug(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            composingBugReport = true
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            
            composeVC.setToRecipients(["indiedeved@gmail.com"])
            composeVC.setSubject("I found a bug!")
            composeVC.setMessageBody("Please describe the bug in detail. e.g. What happened? Did the app fail to perform as expected? Did it fail at a task? Does somthing look funny?:\n\n\n\nPlease describe what you were doing when the bug occured or what was the last thing you did when the bug occured. e.g. Did you tap a button? Were you scrolling through a view?:\n\n", isHTML: false)
            
            self.present(composeVC, animated: true, completion: nil)
        }
        else {
            guard let mailToURL = URL(string: "mailto:indiedeved@gmail.com") else {
                #if DEBUG
                fatalError("Expected a valid URL here.")
                #endif
                // TODO: Tell user there was a problem sending the mail.
            }
            guard UIApplication.shared.canOpenURL(mailToURL) else {
                // TODO: Tell user they may not be configured to send mail.
                return
            }
            UIApplication.shared.open(mailToURL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func rateApp(_ sender: UIButton) {
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1342990841?action=write-review") else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    let maxTopAnchorDimension: CGFloat = 18.0
    let maxBottomAnchorDimension: CGFloat = 12.0
    var minTopAnchorDimension: CGFloat = 0.0
    var minBottomAnchorDimension: CGFloat = 0.0
    var previousScrollOffset: CGFloat = 0.0
    
    //
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = addBackButton(action: #selector(defaultPop), title: "BACK", target: self)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        headerViewTopAnchor.constant = maxTopAnchorDimension
        headerViewBottomAnchor.constant = maxBottomAnchorDimension
        minTopAnchorDimension = -headerViewMeImageConstraint.constant - max((headerViewMeImageToButtonsConstraint.constant - maxTopAnchorDimension), 0.0)
        minBottomAnchorDimension = -secondaryButtonsStackView.bounds.height

        let settingsCellNib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
        tableView.register(settingsCellNib, forCellReuseIdentifier: cellReuseIdentifiers.settingsCell)
        
        try! mainRealm = Realm(configuration: appRealmConfig)
        defaultNotificationsConfig = mainRealm.objects(DefaultNotificationsConfig.self)
        
        if defaultNotificationsConfig.count != 1 {
            // TODO: Log this error, delete the first one maybe for production?
            fatalError("There were multiple notification configs! Should only be one.")
        }
        
        if userDefaults.value(forKey: UserDefaultKeys.dateDisplayMode) as! String == Defaults.DateDisplayMode.short {
            dateDisplayMode = Options.dateDisplayMode.short
        }
        else {dateDisplayMode = Options.dateDisplayMode.long}
        if defaultNotificationsConfig[0].allOn {allNotifications = Options.allNotifications.on}
        else {allNotifications = Options.allNotifications.off}
        if defaultNotificationsConfig[0].dailyNotificationOn {dailyReminders = Options.dailyReminders.on}
        else {dailyReminders = Options.dailyReminders.off}
        if defaultNotificationsConfig[0].individualEventRemindersOn {eventReminders = Options.eventReminders.on}
        else {eventReminders = Options.eventReminders.off}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let randomIndex = Int(arc4random_uniform(UInt32(headerViewTitles.count)))
        headerViewTitle.text = headerViewTitles[randomIndex]
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIP = expandedCellIndexPath, indexPath == selectedIP {return SettingsTableViewCell.expandedHeight}
        else {return SettingsTableViewCell.collapsedHeight}
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {return 30.0}
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        let bgView = UIView()
        bgView.backgroundColor = GlobalColors.lightGrayForFills
        headerView.backgroundView = bgView
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = tableViewDataSource[section].title!
        titleLabel.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 12.0)
        titleLabel.textColor = UIColor.lightGray
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textAlignment = .left
        
        headerView.contentView.addSubview(titleLabel)
        headerView.contentView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor, constant: -4.0).isActive = true
        headerView.contentView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4.0).isActive = true
        headerView.contentView.rightAnchor.constraint(greaterThanOrEqualTo: titleLabel.rightAnchor, constant: 4.0).isActive = true
        
        return headerView
    }
    
    /*func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 10.0)
            headerView.textLabel!.textColor = UIColor.black
        }
    }*/
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowData = tableViewDataSource[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifiers.settingsCell) as! SettingsTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.black
        cell.delegate = self
        cell.rowType = rowData.type
        if cell.onOffSwitch.allTargets.isEmpty {
            cell.onOffSwitch.addTarget(self, action: #selector(cellSwitchFlipped(_:)), for: .valueChanged)
        }
        cell.title = rowData.title
        cell.options = rowData.options
        
        switch rowData.type {
        case .action: break
        case .onOrOff, .segue, .selectOption:
            switch rowData.title {
            case Text.RowTitles.dateDisplayMode: cell.selectedOption = dateDisplayMode
            case Text.RowTitles.widgetSort: cell.selectedOption = widgitSort
            case Text.RowTitles.allNotifications: cell.selectedOption = allNotifications
            case Text.RowTitles.dailyReminders: cell.selectedOption = dailyReminders
            case Text.RowTitles.eventReminders: cell.selectedOption = eventReminders
            case Text.RowTitles.organizeCategories: break
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
            case Text.RowTitles.organizeCategories:
                performSegue(withIdentifier: "Order Categories", sender: self)
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
                    self.defaultNotificationsConfig[0].cascadeDelete()
                    do {
                        try! self.mainRealm.write {
                            self.defaultNotificationsConfig[0].allOn = Defaults.Notifications.allOn
                            self.defaultNotificationsConfig[0].dailyNotificationOn = Defaults.Notifications.dailyNotificationsOn
                            
                            let newScheduleTime = RealmEventNotificationComponents(fromDateComponents: Defaults.Notifications.dailyNotificationsScheduledTime)
                            self.defaultNotificationsConfig[0].dailyNotificationsScheduledTime = newScheduleTime
                            
                            self.defaultNotificationsConfig[0].individualEventRemindersOn = Defaults.Notifications.individualEventRemindersOn
                            
                            let newRealmNotifTimes = List<RealmEventNotification>()
                            for eventNotif in Defaults.Notifications.eventNotifications {
                                newRealmNotifTimes.append(RealmEventNotification(copyingEventNotification: eventNotif))
                            }
                            self.defaultNotificationsConfig[0].eventNotifications.append(objectsIn: newRealmNotifTimes)
                            
                            self.defaultNotificationsConfig[0].categoriesToNotify = Defaults.Notifications.categoriesToNotify
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
                                let resetDefaultsRealm = try! Realm(configuration: appRealmConfig)
                                let resetDefaultsSpecialEvents = resetDefaultsRealm.objects(SpecialEvent.self)
                                
                                //
                                // Reset all events to default, get uuids
                                var uuidsToDeschedule = [String]()
                                
                                for event in resetDefaultsSpecialEvents {
                                    print("Reseting \"\(event.title)\"")
                                    
                                    if event.notificationsConfig != nil { // Old config
                                        for notif in event.notificationsConfig!.eventNotifications {uuidsToDeschedule.append(notif.uuid)}
                                        event.notificationsConfig!.cascadeDelete()
                                        
                                        let newRealmNotifications = List<RealmEventNotification>()
                                        for eventNotif in Defaults.Notifications.eventNotifications {
                                            let realmNotif = RealmEventNotification(copyingEventNotification: eventNotif)
                                            newRealmNotifications.append(realmNotif)
                                        }
                                        
                                        do {
                                            try! resetDefaultsRealm.write {
                                                event.notificationsConfig!.eventNotificationsOn = Defaults.Notifications.individualEventRemindersOn
                                                event.notificationsConfig!.isCustom = false
                                                event.notificationsConfig!.eventNotifications.append(objectsIn: newRealmNotifications)
                                            }
                                        }
                                    }
                                        
                                    else { // New config
                                        var realmEventNotifs = [RealmEventNotification]()
                                        for eventNotif in Defaults.Notifications.eventNotifications {
                                            let realmEventNotif = RealmEventNotification(copyingEventNotification: eventNotif)
                                            realmEventNotifs.append(realmEventNotif)
                                        }
                                        let newConfig = RealmEventNotificationConfig(
                                            eventNotifications: realmEventNotifs,
                                            eventNotificationsOn: true,
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
    // MARK: Scroll view delegate collapsing header functionality!
    
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == tableView {
            let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
            let absoluteTop: CGFloat = 0;
            let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height
            let isScrollingDown = scrollDiff > 0
            
            var newHeight = headerViewTopAnchor.constant
            if isScrollingDown && scrollView.contentOffset.y > absoluteTop {
                let possibleNewValue = headerViewTopAnchor.constant - abs(scrollDiff)
                if minTopAnchorDimension > possibleNewValue {newHeight = minTopAnchorDimension}
                else {
                    newHeight = possibleNewValue
                    scrollView.contentOffset.y = previousScrollOffset
                }
                
            }
            else if scrollView.contentOffset.y < absoluteBottom {
                if scrollView.contentOffset.y <= 0.0 {
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
                userDefaults.set(Defaults.DateDisplayMode.short, forKey: UserDefaultKeys.dateDisplayMode)
                masterViewController?.tableView.reloadData()
            case Options.dateDisplayMode.long:
                userDefaults.set(Defaults.DateDisplayMode.long, forKey: UserDefaultKeys.dateDisplayMode)
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
    // MARK: mailComposeDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if let _error = error {
            #if DEBUG
            print(_error.localizedDescription)
            fatalError("^ Check Error")
            #endif
            // TODO: Tell user there was an error sending the message.
        }
        self.dismiss(animated: true) {
            switch result {
            case .sent:
                if self.composingBugReport {
                    let thanksController = UIAlertController(title: "Report Submitted!", message: "\nThank you for getting in touch with me and helping to make this app better! I may return your e-mail to get more information about the bug or issue you are having.\n\nEnjoy each moment!", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
                        self.dismiss(animated: true, completion: nil)
                        self.composingBugReport = false
                    }
                    
                    thanksController.addAction(dismissAction)
                    self.present(thanksController, animated: true, completion: nil)
                }
                
                if self.composingContactMeMessage {
                    let thanksController = UIAlertController(title: "Thanks!", message: "\nI value bringing humanity into software, so your contact is appreciated! I look forward to reading your e-mail and helping you in any way.\n\nEnjoy each moment!", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
                        self.dismiss(animated: true, completion: nil)
                        self.composingContactMeMessage = false
                    }
                    
                    thanksController.addAction(dismissAction)
                    self.present(thanksController, animated: true, completion: nil)
                }
            case .failed:
                let failedController = UIAlertController(title: "There Was a Problem", message: "\nSorry, but the mail app told me there was a problem sending your message. You can try again later, or we can try sending from your default mail app.", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: "I'll try later.", style: .cancel) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                let mailtoAction = UIAlertAction(title: "Try default mail app", style: .default) { (Action) in
                    guard let mailToURL = URL(string: "mailto:indiedeved@gmail.com") else {
                        #if DEBUG
                        fatalError("Expected a valid URL here.")
                        #endif
                        // TODO: Tell user there was a problem sending the mail.
                    }
                    guard UIApplication.shared.canOpenURL(mailToURL) else {
                        // TODO: Tell user they may not be configured to send mail.
                        return
                    }
                    UIApplication.shared.open(mailToURL, options: [:], completionHandler: nil)
                }
                
                failedController.addAction(dismissAction)
                failedController.addAction(mailtoAction)
                self.present(failedController, animated: true, completion: nil)
            default: break
            }
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
            do {try! mainRealm.write {defaultNotificationsConfig[0].allOn = sender.isOn}}
            if sender.isOn {
                allNotifications = Options.allNotifications.on
                updateDailyNotifications(async: true, updatePending: false)
                let allEvents = mainRealm.objects(SpecialEvent.self)
                var eventsToSchedule = [String]()
                for event in allEvents {eventsToSchedule.append(event.title)}
                scheduleNewEvents(titled: eventsToSchedule)
                
                tableView.beginUpdates()
                tableView.insertRows(at: ipsToModify, with: .fade)
                tableView.endUpdates()
            }
            else {
                allNotifications = Options.allNotifications.off
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                
                tableView.beginUpdates()
                tableView.deleteRows(at: ipsToModify, with: .fade)
                tableView.endUpdates()
            }
        default:
            // TODO: log and break
            fatalError("Need to add a case?")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "Configure Notifications":
            let destination = segue.destination as! ConfigureNotificationsTableViewController
            destination.segueFrom = .settings
            destination.configuring = configuring
            switch configuring {
            case .dailyReminders: destination.globalToggleOn = defaultNotificationsConfig[0].dailyNotificationOn
            case .eventReminders: destination.globalToggleOn = defaultNotificationsConfig[0].individualEventRemindersOn
            }
            destination.useCustomNotifications = false
        case "Order Categories": break
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
    
    @IBAction func unwindFromEditCategories(segue: UIStoryboardSegue) {
        masterViewController?.updateActiveCategories()
        masterViewController?.updateIndexPathMap()
        masterViewController?.tableView.reloadData()
    }
}
