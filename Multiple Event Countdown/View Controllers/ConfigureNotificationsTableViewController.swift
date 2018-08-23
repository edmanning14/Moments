//
//  ConfigureNotificationsTableViewController.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/6/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift

class ConfigureNotificationsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: Data Model
    enum DepartureSegues {case settings, individualEvent}
    enum NotificationTypes {case dailyReminders, eventReminders}
    
    var segueFrom: DepartureSegues = .settings
    var configuring: NotificationTypes = .dailyReminders
    var globalToggleOn = true
    var useCustomNotifications = false
    fileprivate var dailyNotificationsScheduledTime = DateComponents()
    
    var modifiedEventNotifications: [EventNotification] {
        get {
            if let notifs = _modifiedEventNotifications {return notifs}
            else {
                var newNotifs = [EventNotification]()
                for realmNotif in defaultNotificationsConfig[0].eventNotifications {
                    if let newNotif = EventNotification(fromRealmEventNotification: realmNotif) {
                        newNotifs.append(newNotif)
                    }
                }
                _modifiedEventNotifications = newNotifs
                return newNotifs
            }
        }
        set {
            _modifiedEventNotifications = newValue
        }
    }
    fileprivate var _modifiedEventNotifications: [EventNotification]?
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    fileprivate var selectedCellIndexPath: IndexPath? {
        didSet {
            if selectedCellIndexPath != oldValue {
                tableView.beginUpdates(); tableView.endUpdates()
            }
            if selectedCellIndexPath == nil {currentlyEditing = nil}
        }
    }
    fileprivate enum Editables {case digit, precision, type}
    fileprivate var currentlyEditing: Editables? {
        didSet {
            if let selectedCellIP = selectedCellIndexPath, let editing = currentlyEditing {
                let cell = tableView.cellForRow(at: selectedCellIP) as! DatePickerTableViewCell
                switch editing {
                case .digit:
                    switch configuring {
                    case .dailyReminders:
                        cell.pickerView.isHidden = true
                        cell.datePicker.isHidden = false
                    case .eventReminders:
                        switch cell.eventNotification!.type {
                        case .afterEvent, .beforeEvent:
                            cell.pickerView.isHidden = false
                            cell.datePicker.isHidden = true
                            cell.pickerView.reloadAllComponents()
                        case .dayOfEvent, .timeOfEvent:
                            cell.pickerView.isHidden = true
                            cell.datePicker.isHidden = false
                        }
                    }
                case .precision, .type:
                    cell.pickerView.isHidden = false
                    cell.datePicker.isHidden = true
                    cell.pickerView.reloadAllComponents()
                }
            }
        }
    }
    
    // MARK: Data Source
    enum PrecisionOptions {
        case months, days, hours, minutes, seconds
        
        var string: String {
            switch self {
            case .months: return "Months"
            case .days: return "Days"
            case .hours: return "Hours"
            case .minutes: return "Minutes"
            case .seconds: return "Seconds"
            }
        }
        
        init?(fromString: String) {
            switch fromString {
            case PrecisionOptions.months.string, "Month": self = PrecisionOptions.months
            case PrecisionOptions.days.string, "Day": self = PrecisionOptions.days
            case PrecisionOptions.hours.string, "Hour": self = PrecisionOptions.hours
            case PrecisionOptions.minutes.string, "Minute": self = PrecisionOptions.minutes
            case PrecisionOptions.seconds.string, "Second": self = PrecisionOptions.seconds
            default: return nil
            }
        }
    }
    var currentPrecision: PrecisionOptions?
    
    let dateComponentsOfInterest: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let typeOptions = [EventNotification.Types.afterEvent.stringEquivalent, EventNotification.Types.beforeEvent.stringEquivalent, EventNotification.Types.dayOfEvent.stringEquivalent, EventNotification.Types.timeOfEvent.stringEquivalent]
    let precisionOptionsTitles = [PrecisionOptions.months.string, PrecisionOptions.days.string, PrecisionOptions.hours.string, PrecisionOptions.minutes.string, PrecisionOptions.seconds.string]
    let oneThrough59 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"]
    var digitOptions: [String]? {
        if let _currentPrecision = currentPrecision {
            switch _currentPrecision {
            case .months: return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
            case .days: return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30"]
            case .hours: return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"]
            case .minutes: return oneThrough59
            case .seconds: return oneThrough59
            }
        }
        else {return nil}
    }
    
    // MARK: Realm
    var mainRealm: Realm!
    var defaultNotificationsConfig: Results<DefaultNotificationsConfig>!
    
    //
    // MARK: Other Constants
    struct CellReuseIdentifiers {
        static let settingsCell = "Settings Cell"
        static let datePickerCell = "Date Picker Cell"
    }
    
    
    //
    // MARK: View controller lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsCellNib = UINib(nibName: "SettingsTableViewCell", bundle: nil)
        tableView.register(settingsCellNib, forCellReuseIdentifier: CellReuseIdentifiers.settingsCell)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header View")
        
        try! mainRealm = Realm(configuration: realmConfig)
        defaultNotificationsConfig = mainRealm.objects(DefaultNotificationsConfig.self)
        
        dailyNotificationsScheduledTime.hour = defaultNotificationsConfig[0].dailyNotificationsScheduledTime?.hour.value
        dailyNotificationsScheduledTime.minute = defaultNotificationsConfig[0].dailyNotificationsScheduledTime?.minute.value
        
        let confirmButton = UIBarButtonItem()
        confirmButton.target = self
        confirmButton.action = #selector(confirmAndExit)
        confirmButton.tintColor = GlobalColors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
        confirmButton.setTitleTextAttributes(attributes, for: .normal)
        confirmButton.setTitleTextAttributes(attributes, for: .disabled)
        confirmButton.title = "CONFIRM"
        
        navigationItem.rightBarButtonItem = confirmButton
        
        switch configuring {
        case .dailyReminders: navigationItem.title = "Daily Reminders"
        case .eventReminders: navigationItem.title = "Event Reminders"
        }
        
        tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}

    //
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if globalToggleOn {
            switch segueFrom {
            case .individualEvent: if useCustomNotifications {return 2} else {return 1}
            case .settings: return 2
            }
        }
        else {return 1}
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if segueFrom == .individualEvent && globalToggleOn {return 2}
            else {return 1}
        case 1:
            switch configuring {
            case .dailyReminders: return 1
            case .eventReminders: return modifiedEventNotifications.count
            }
        default:
            // TODO: log and break.
            fatalError("Need to add a case??")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseIdentifiers.settingsCell) as! SettingsTableViewCell
            
            cell.selectionStyle = .none
            cell.rowType = .onOrOff
            if cell.onOffSwitch.allTargets.isEmpty {
                cell.onOffSwitch.addTarget(self, action: #selector(cellSwitchFlipped(_:)), for: .valueChanged)
            }
            cell.titleLabel.font = UIFont(name: GlobalFontNames.ralewayMedium, size: 18.0)
            
            switch indexPath.row {
            case 0:
                cell.title = "Turn on or off"
                cell.onOffSwitch.isOn = globalToggleOn
            case 1:
                cell.title = "Use custom notifications"
                cell.onOffSwitch.isOn = useCustomNotifications
            default:
                // TODO: log and break.
                fatalError("Need to add a case??")
            }
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseIdentifiers.datePickerCell) as! DatePickerTableViewCell
            
            cell.pickerView.delegate = self
            cell.pickerView.dataSource = self
            
            cell.digitButton.layer.cornerRadius = GlobalCornerRadii.material
            cell.precisionButton.layer.cornerRadius = GlobalCornerRadii.material
            cell.typeButton.layer.cornerRadius = GlobalCornerRadii.material
            
            if cell.datePicker.allTargets.isEmpty {
                cell.datePicker.addTarget(self, action: #selector(datePickerDateDidChange(_:)), for: .valueChanged)
                cell.datePicker.backgroundColor = UIColor.clear
                cell.datePicker.setValue(GlobalColors.cyanRegular, forKey: "textColor")
                //cell.datePicker.setValue(UIFont(name: GlobalFontNames.ralewayLight, size: 14.0), forKey: "textFont")
            }
            
            if cell.typeButton.allTargets.isEmpty {
                cell.typeButton.addTarget(self, action: #selector(handleCellButtonsTap(_:)), for: .touchUpInside)
                cell.precisionButton.addTarget(self, action: #selector(handleCellButtonsTap(_:)), for: .touchUpInside)
                cell.digitButton.addTarget(self, action: #selector(handleCellButtonsTap(_:)), for: .touchUpInside)
            }
            
            switch configuring {
            case .dailyReminders:
                cell.title = "Time of notification"
                
                cell.typeButton.isHidden = true
                cell.precisionButton.isHidden = true
                cell.digitButton.isHidden = false
                
                var todaysDateComponents = Calendar.current.dateComponents(dateComponentsOfInterest, from: Date())
                todaysDateComponents.hour = dailyNotificationsScheduledTime.hour
                todaysDateComponents.minute = dailyNotificationsScheduledTime.minute
                
                let stringDate = dateFormatter.string(from: Calendar.current.date(from: todaysDateComponents)!)
                cell.digitButton.setTitle(stringDate, for: .normal)
            case .eventReminders:
                cell.title = String(indexPath.row + 1)
                cell.eventNotification = modifiedEventNotifications[indexPath.row]
            }
            return cell
        default:
            // TODO: return an empty cell?
            fatalError("Need to add a section??")
            
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch configuring {
        case .dailyReminders: let view = UIView(); view.backgroundColor = UIColor.clear; return view
        case .eventReminders:
            switch section {
            case 0: let view = UIView(); view.backgroundColor = UIColor.black; return view
            case 1:
                let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header View")!
                let bgView = UIView()
                bgView.translatesAutoresizingMaskIntoConstraints = false
                bgView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
                headerView.backgroundView = bgView
                
                headerView.contentView.backgroundColor = UIColor.clear
                //view.translatesAutoresizingMaskIntoConstraints = false
                
                let addButton = UIButton()
                addButton.translatesAutoresizingMaskIntoConstraints = false
                addButton.setTitle("ADD", for: .normal)
                addButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
                addButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayMedium, size: 18.0)
                addButton.addTarget(self, action: #selector(handleEventConfigButtonsTap(_:)), for: .touchUpInside)
                
                let editButton = UIButton()
                editButton.translatesAutoresizingMaskIntoConstraints = false
                editButton.setTitle("EDIT", for: .normal)
                editButton.setTitleColor(GlobalColors.orangeDark, for: .normal)
                editButton.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayMedium, size: 18.0)
                editButton.addTarget(self, action: #selector(handleEventConfigButtonsTap(_:)), for: .touchUpInside)
                
                headerView.contentView.addSubview(addButton)
                headerView.contentView.addSubview(editButton)
                let margin: CGFloat = 12.0
                headerView.contentView.bottomAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 8.0).isActive = true
                headerView.contentView.bottomAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 8.0).isActive = true
                headerView.contentView.leftAnchor.constraint(equalTo: editButton.leftAnchor, constant: -margin).isActive = true
                headerView.contentView.rightAnchor.constraint(equalTo: addButton.rightAnchor, constant: margin).isActive = true
                
                return headerView
            default:
                // TODO: Log and break
                fatalError("Need to add a case??")
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let selectedIP = selectedCellIndexPath, indexPath == selectedIP {
            if let cell = tableView.cellForRow(at: indexPath) as? DatePickerTableViewCell {
                if !cell.pickerView.isHidden {return cell.pickerView.bounds.height + DatePickerTableViewCell.collapsedHeight}
                else {return cell.datePicker.bounds.height + DatePickerTableViewCell.collapsedHeight}
            }
            else {return DatePickerTableViewCell.expandedHeight}
        }
        else {return DatePickerTableViewCell.collapsedHeight}
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel!.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 14.0)
            headerView.textLabel!.textColor = GlobalColors.orangeRegular
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 50
        case 1:
            switch configuring {
            case .dailyReminders: return 50
            case .eventReminders: return 100
            }
        default:
            // TODO: Log and break
            fatalError("Need to add a section??")
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0: return false
        case 1:
            switch configuring {
            case .dailyReminders: return false
            case .eventReminders: return true
            }
        default:
            // TODO: Log and break
            fatalError("Need to add a case??")
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            modifiedEventNotifications.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
    //
    // MARK: - Picker View Delegate and Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let editing = currentlyEditing {
            switch editing {
            case .digit: return digitOptions?.count ?? 0
            case .precision: return precisionOptionsTitles.count
            case .type: return typeOptions.count
            }
        }
        else {return 0}
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var _viewToReturn = view as? UILabel
        if _viewToReturn == nil {
            _viewToReturn = UILabel()
            _viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 18.0)
            _viewToReturn!.textColor = GlobalColors.cyanRegular
            _viewToReturn!.textAlignment = .center
        }
        let viewToReturn = _viewToReturn!
        
        if let editing = currentlyEditing {
            switch editing {
            case .digit: viewToReturn.text = digitOptions![row]
            case .precision: viewToReturn.text = precisionOptionsTitles[row]
            case .type: viewToReturn.text = typeOptions[row]
            }
        }
        
        return viewToReturn
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let editing = currentlyEditing {
            let cell = tableView.cellForRow(at: selectedCellIndexPath!) as! DatePickerTableViewCell
            switch editing {
            case .digit:
                let value = Int(digitOptions![row])!
                if let _currentPrecision = currentPrecision {
                    switch _currentPrecision {
                    case .months: modifiedEventNotifications[selectedCellIndexPath!.row].components?.month = value
                    case .days: modifiedEventNotifications[selectedCellIndexPath!.row].components?.day = value
                    case .hours: modifiedEventNotifications[selectedCellIndexPath!.row].components?.hour = value
                    case .minutes: modifiedEventNotifications[selectedCellIndexPath!.row].components?.minute = value
                    case .seconds: modifiedEventNotifications[selectedCellIndexPath!.row].components?.second = value
                    }
                }
                else {
                    // TODO: Log, return from function probably
                    fatalError("currentPrecision was nil!")
                }
                cell.eventNotification = modifiedEventNotifications[selectedCellIndexPath!.row]
            case .precision:
                if let digit = cell.digitButton.currentTitle {
                    
                    if let _currentPrecision = currentPrecision {
                        switch _currentPrecision {
                        case .months:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.month = nil
                        case .days:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.day = nil
                        case .hours:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.hour = nil
                        case .minutes:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.minute = nil
                        case .seconds:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.second = nil
                        }
                    }
                    else {
                        // TODO: Log, return from function probably
                        fatalError("currentPrecision was nil!")
                    }
                    
                    currentPrecision = PrecisionOptions(fromString: precisionOptionsTitles[row])!
                    var currentValue = Int(digit)!
                    if !digitOptions!.contains(digit) {currentValue = Int(digitOptions!.last!)!}
                    
                    if let _currentPrecision = currentPrecision {
                        switch _currentPrecision {
                        case .months:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.month = currentValue
                        case .days:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.day = currentValue
                        case .hours:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.hour = currentValue
                        case .minutes:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.minute = currentValue
                        case .seconds:
                            modifiedEventNotifications[selectedCellIndexPath!.row].components?.second = currentValue
                        }
                    }
                    else {
                        // TODO: Log, return from function probably
                        fatalError("currentPrecision was nil!")
                    }

                    cell.eventNotification = modifiedEventNotifications[selectedCellIndexPath!.row]
                }
                else {
                    // TODO: fail this gracefully
                    fatalError("There was no title on the digit button for some reason...")
                }
            case .type:
                let newType = EventNotification.Types(string: typeOptions[row])!
                switch newType {
                case .afterEvent, .beforeEvent:
                    if modifiedEventNotifications[selectedCellIndexPath!.row].type != .afterEvent && modifiedEventNotifications[selectedCellIndexPath!.row].type != .beforeEvent {
                        modifiedEventNotifications[selectedCellIndexPath!.row].components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: 1, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                    }
                case .dayOfEvent:
                    modifiedEventNotifications[selectedCellIndexPath!.row].components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: 9, minute: 0, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                case .timeOfEvent:
                    modifiedEventNotifications[selectedCellIndexPath!.row].components = nil
                }
                modifiedEventNotifications[selectedCellIndexPath!.row].type = newType
                cell.eventNotification = modifiedEventNotifications[selectedCellIndexPath!.row]
            }
        }
        else {
            // TODO: log and error and continue.
            fatalError("Shouldn't have happened.")
        }
    }
    
    //
    // MARK: Date Picker Actions
    @objc fileprivate func datePickerDateDidChange(_ sender: UIDatePicker) {
        let date = sender.date
        let cell = tableView.cellForRow(at: selectedCellIndexPath!) as! DatePickerTableViewCell
        switch configuring {
        case .dailyReminders:
            let components = Calendar.current.dateComponents(dateComponentsOfInterest, from: date)
            dailyNotificationsScheduledTime.hour = components.hour
            dailyNotificationsScheduledTime.minute = components.minute
            cell.digitButton.setTitle(dateFormatter.string(from: date), for: .normal)
        case .eventReminders:
            let desiredTimeComponents: Set<Calendar.Component> = [.hour, .minute]
            let timeComponents = Calendar.current.dateComponents(desiredTimeComponents, from: date)
            modifiedEventNotifications[selectedCellIndexPath!.row].components?.hour = timeComponents.hour!
            modifiedEventNotifications[selectedCellIndexPath!.row].components?.minute = timeComponents.minute!
            cell.eventNotification = modifiedEventNotifications[selectedCellIndexPath!.row]
        }
    }
    
    //
    // MARK: Cell buttons action methods
    @objc fileprivate func cellSwitchFlipped(_ sender: UISwitch) {
        let cell = sender.superview as! SettingsTableViewCell
        var section = IndexSet()
        section.insert(1)
        let customNotifRowSection = tableView.indexPath(for: cell)!.section
        let customNotifRow = [IndexPath(row: 1, section: customNotifRowSection)]
        
        switch cell.title {
        case "Turn on or off":
            globalToggleOn = sender.isOn
            switch configuring {
            case .dailyReminders:
                if globalToggleOn {
                    tableView.beginUpdates()
                    tableView.insertSections(section, with: .fade)
                    tableView.endUpdates()
                }
                else {
                    tableView.beginUpdates()
                    tableView.deleteSections(section, with: .fade)
                    tableView.endUpdates()
                }
            case .eventReminders:
                switch segueFrom {
                case .individualEvent:
                    if globalToggleOn {
                        tableView.beginUpdates()
                        tableView.insertRows(at: customNotifRow, with: .fade)
                        if useCustomNotifications {tableView.insertSections(section, with: .fade)}
                        tableView.endUpdates()
                    }
                    else {
                        tableView.beginUpdates()
                        tableView.deleteRows(at: customNotifRow, with: .fade)
                        if useCustomNotifications {tableView.deleteSections(section, with: .fade)}
                        tableView.endUpdates()
                    }
                case .settings:
                    if globalToggleOn {
                        tableView.beginUpdates()
                        tableView.insertSections(section, with: .fade)
                        tableView.endUpdates()
                    }
                    else {
                        tableView.beginUpdates()
                        tableView.deleteSections(section, with: .fade)
                        tableView.endUpdates()
                    }
                }
            }
        case "Use custom notifications":
            useCustomNotifications = sender.isOn
            if useCustomNotifications {
                tableView.beginUpdates()
                tableView.insertSections(section, with: .fade)
                tableView.endUpdates()
            }
            else {
                tableView.beginUpdates()
                tableView.deleteSections(section, with: .fade)
                tableView.endUpdates()
            }
        default:
            // TODO: log and break
            fatalError("Need to add a case?")
        }
        tableView.reloadData()
    }
    
    @objc fileprivate func handleCellButtonsTap(_ sender: UIButton) {
        if let buttonTitle = sender.currentTitle {
            let cell = sender.superview!.superview!.superview as! DatePickerTableViewCell
            let newSelectedCellIP = tableView.indexPath(for: cell)!
            
            let otherPrecisionButtonTitles = ["Month", "Day", "Hour", "Minute", "Second"]
            var newEditable: Editables?
            
            if let _currentPrecision = PrecisionOptions(fromString: cell.precisionButton.currentTitle!) {
                currentPrecision = _currentPrecision
            }
            else {
                // TODO: Log, probably should alert user and break out of function.
                fatalError("Couldn't get current precision, probably a title issue")
            }
            
            let typei = typeOptions.index(of: buttonTitle)
            let precisioni: Int? = {
                if let i = precisionOptionsTitles.index(of: buttonTitle) {return i}
                else if let i = otherPrecisionButtonTitles.index(of: buttonTitle) {return i}
                else {return nil}
            }()
            let digiti = digitOptions?.index(of: buttonTitle)
            var newDate: Date?
            
            if typei != nil {newEditable = .type}
            else if precisioni != nil {newEditable = .precision}
            else if digiti != nil {newEditable = .digit}
            else {
                if let date = dateFormatter.date(from: buttonTitle) {
                    newDate = date
                    newEditable = .digit
                }
                else {
                    // TODO: Handle this gracefully
                    fatalError("Couldn't determing button title!")
                }
            }
            
            if newSelectedCellIP == selectedCellIndexPath && newEditable == currentlyEditing {
                selectedCellIndexPath = nil
                currentPrecision = nil
                currentlyEditing =  nil
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: .curveEaseOut,
                    animations: {sender.backgroundColor = GlobalColors.lightGrayForFills},
                    completion: nil
                )
            }
            else {
                if let editing = currentlyEditing {
                    let oldCell = tableView.cellForRow(at: selectedCellIndexPath!) as! DatePickerTableViewCell
                    switch editing {
                    case .digit:
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.3,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {oldCell.digitButton.backgroundColor = GlobalColors.lightGrayForFills},
                            completion: nil
                        )
                    case .precision:
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.3,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {oldCell.precisionButton.backgroundColor = GlobalColors.lightGrayForFills},
                            completion: nil
                        )
                    case .type:
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.3,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {oldCell.typeButton.backgroundColor = GlobalColors.lightGrayForFills},
                            completion: nil
                        )
                    }
                }
                selectedCellIndexPath = newSelectedCellIP
                currentlyEditing = newEditable
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: .curveEaseOut,
                    animations: {sender.backgroundColor = GlobalColors.darkPurpleForFills},
                    completion: nil
                )
                
                if let i = typei {cell.pickerView.selectRow(i, inComponent: 0, animated: false)}
                else if let i = precisioni {cell.pickerView.selectRow(i, inComponent: 0, animated: false)}
                else if let i = digiti {cell.pickerView.selectRow(i, inComponent: 0, animated: false)}
                else if let _newDate = newDate {cell.datePicker.date = _newDate}
                else {
                    // TODO: Do nothing, I'm pretty sure this is quite literally impossible.
                    fatalError("How the fuck did this happen?")
                }
            }
        }
        else {
            // TODO: Do nothing I think...
            fatalError("No button title!?")
        }
    }
    
    @objc fileprivate func handleEventConfigButtonsTap(_ sender: UIButton) {
        if let title = sender.currentTitle {
            switch title {
            case "ADD":
                let components = DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: 1, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
                let ipToInsertAt = IndexPath(row: modifiedEventNotifications.endIndex, section: 1)
                modifiedEventNotifications.append(EventNotification(type: .beforeEvent, components: components))
                tableView.beginUpdates()
                tableView.insertRows(at: [ipToInsertAt], with: .fade)
                tableView.endUpdates()
            case "EDIT":
                tableView.setEditing(true, animated: true)
                sender.setTitle("DONE", for: .normal)
            case "DONE":
                tableView.setEditing(false, animated: true)
                sender.setTitle("EDIT", for: .normal)
            default:
                // TODO: Log and break
                fatalError("Need to add a case??")
            }
        }
    }
    
    @objc fileprivate func confirmAndExit() {
        switch configuring {
        case .dailyReminders:
            do {
                try! mainRealm.write {
                    defaultNotificationsConfig[0].dailyNotificationOn = globalToggleOn
                    defaultNotificationsConfig[0].dailyNotificationsScheduledTime?.hour.value = dailyNotificationsScheduledTime.hour
                    defaultNotificationsConfig[0].dailyNotificationsScheduledTime?.minute.value = dailyNotificationsScheduledTime.minute
                }
            }
            updateDailyNotifications(async: true)
            performSegue(withIdentifier: "Unwind to Settings", sender: self)
        case .eventReminders:
            switch segueFrom {
            case .individualEvent: performSegue(withIdentifier: "Unwind to Event", sender: self)
            case .settings:
                for notif in defaultNotificationsConfig[0].eventNotifications {notif.cascadeDelete()}
                do {
                    try! mainRealm.write {
                        defaultNotificationsConfig[0].individualEventRemindersOn = globalToggleOn
                        mainRealm.delete(defaultNotificationsConfig[0].eventNotifications)
                        let newRealmEventNotifications = List<RealmEventNotification>()
                        for notif in modifiedEventNotifications {
                            newRealmEventNotifications.append(RealmEventNotification(fromEventNotification: notif))
                        }
                        defaultNotificationsConfig[0].eventNotifications.append(objectsIn: newRealmEventNotifications)
                    }
                }
                // TODO: Ask user if they would like to reset all current events to these settings or just future ones
                performSegue(withIdentifier: "Unwind to Settings", sender: self)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
