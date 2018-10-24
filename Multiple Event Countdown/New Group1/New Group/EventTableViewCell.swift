//
//  EventTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/23/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import CoreGraphics
import Foundation
import os

class EventTableViewCell: UITableViewCell {
    
    //
    // MARK: - Variables and Constants
    //
    
    fileprivate let computationalQueue = DispatchQueue(label: "computationalQueue", qos: DispatchQoS.userInitiated)
    weak var delegate: EventTableViewCellDelegate?
    
    // Data Model
    var eventTitle: String? {
        didSet {
            if !shadowsInitialized {initializeShadows()}
            titleLabel.text = eventTitle
        }
    }
    
    var eventTagline: String? {
        didSet{
            if !shadowsInitialized {initializeShadows()}
            if infoDisplayed == .tagline {
                if eventTagline != nil {taglineLabel.text = eventTagline}
                else {taglineLabel.isHidden = true; taglineLabel.isUserInteractionEnabled = false}
            }
        }
    }
    
    var eventDate: EventDate? {
        didSet {
            if !shadowsInitialized {initializeShadows()}
            if let _eventDate = eventDate {
                update()
                if infoDisplayed == .date {
                    taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                    if _eventDate.dateOnly {infoDateFormatter.timeStyle = .none}
                    else {infoDateFormatter.timeStyle = .short}
                    taglineLabel.text = infoDateFormatter.string(from: _eventDate.date)
                }
            }
            else {
                agoLabel.isHidden = true
                inLabel.isHidden = false
                weeksLabel.text = "00"
                daysLabel.text = "00"
                hoursLabel.text = "00"
                minutesLabel.text = "00"
                secondsLabel.text = "00"
                if infoDisplayed == .date {
                    taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                    taglineLabel.text = "Set a date"
                }
            }
        }
    }
    
    var abridgedDisplayMode = false {
        didSet {
            if eventDate != nil {
                if abridgedDisplayMode {
                    if abridgedTimerContainerView.isHidden {
                        if !timerContainerView.isHidden {
                            viewTransition(from: [timerContainerView], to: [abridgedTimerContainerView])
                        }
                        else {show(views: [abridgedTimerContainerView], animated: true)}
                    }
                }
                else {
                    if timerContainerView.isHidden {
                        if !abridgedTimerContainerView.isHidden {
                            viewTransition(from: [abridgedTimerContainerView], to: [timerContainerView])
                        }
                        else {show(views: [timerContainerView], animated: true)}
                    }
                }
                update()
            }
        }
    }
    
    var infoDisplayed = DisplayInfoOptions.tagline {
        didSet {
            if infoDisplayed != oldValue {
                taglineLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                switch infoDisplayed {
                case .none:
                    taglineLabel.isHidden = true
                    taglineLabel.isUserInteractionEnabled = false
                case .tagline, .date:
                    if infoDisplayed == .tagline {taglineLabel.text = eventTagline}
                    else {
                        if let _eventDate = eventDate {taglineLabel.text = infoDateFormatter.string(from: _eventDate.date)}
                        else {taglineLabel.text = "Set a date"}
                    }
                    if taglineLabel.isHidden {
                        taglineLabel.isHidden = false
                        taglineLabel.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }
    
    var repeats = RepeatingOptions.never {didSet {if eventDate != nil {update()}}}
    
    var creationDate: Date? {didSet {updateMaskCoverageValues()}}
    
    fileprivate let defaultHomeImageSize = CGSize(width: UIScreen.main.bounds.width, height: 160.0)
    
    var eventImage: UserEventImage? {return _eventImage}
    fileprivate var _eventImage: UserEventImage?
    
    fileprivate var mainHomeImage: UIImage? {
        didSet {
            switch configuration {
            case .cell:
                if mainHomeImage != nil {
                    mainImageView.layer.opacity = 0.0
                    mainImageView.image = mainHomeImage
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.2,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {self.mainImageView.layer.opacity = 1.0},
                        completion: nil
                    )
                    if useMask {
                        updateMask()
                        showMaskView()
                    }
                }
                else {
                    mainImageView.image = nil
                    hideMaskView()
                }
            case .detail: break
            }
        }
    }
    
    fileprivate var maskHomeImage: UIImage? {
        didSet {
            switch configuration {
            case .cell:
                maskImageView.image = maskHomeImage
                if useMask {
                    updateMask()
                    showMaskView()
                }
            case .detail: break
            }
        }
    }
    
    var locationForCellView: CGFloat {return _locationForCellView}
    fileprivate var _locationForCellView: CGFloat = 0.5
    
    fileprivate var infoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        let dateDisplayMode = userDefaults.value(forKey: UserDefaultKeys.dateDisplayMode) as! String
        switch dateDisplayMode {
        case Defaults.DateDisplayMode.short:
            formatter.dateStyle = .short
            if eventDate?.dateOnly ?? true {formatter.timeStyle = .none}
            else {formatter.timeStyle = .short}
        case Defaults.DateDisplayMode.long:
            formatter.dateStyle = .long
            if eventDate?.dateOnly ?? true {formatter.timeStyle = .none}
            else {formatter.timeStyle = .short}
        default: os_log("Unexpected date display mode encoutnered!", log: .default, type: .error)
        }
        return formatter
    }
    
    //
    // MARK: Types
    
    fileprivate struct Constants {
        static let oneLabelTraverseDistance: CGFloat = 2.5 + 33.0 + 7.5 + 2.5
    }
    
    //
    // MARK: States
    enum Configurations {case cell, detail}
    var configuration: Configurations = .cell
    
    fileprivate enum Stages: Comparable {
        
        case seconds, minutes, hours, days, weeks, months, years
        
        static func < (lhs: EventTableViewCell.Stages, rhs: EventTableViewCell.Stages) -> Bool {
            if lhs.interval < rhs.interval {return true}
            else {return false}
        }
        
        static func == (lhs: EventTableViewCell.Stages, rhs: EventTableViewCell.Stages) -> Bool {
            if lhs.interval == rhs.interval {return true}
            else {return false}
        }
        
        var interval: TimeInterval {
            switch self {
            case .years: return 31104000 // 12 months to a year
            case .months: return 2592000.0 // Arbitrary 30 days to a month
            case .weeks: return 604800.0
            case .days: return 86400.0
            case .hours: return 3600.0
            case .minutes: return 60.0
            case .seconds: return 1.0
            }
        }
    }
    fileprivate var currentStage = Stages.months
    fileprivate var precision = Stages.months
    
    //
    // MARK: Mask parameters
    var percentMaskCoverage: CGFloat = 1.0 - 0.025 {
        didSet {
            if 1.0 - percentMaskCoverage < minSizeOfGradientArea {percentMaskCoverage = 1.0 - minSizeOfGradientArea}
            if useMask {updateMask()}
        }
    }
    
    var useMask = false {
        didSet {
            if useMask == true && oldValue == false && mainImageView.image != nil {
                switch configuration {
                case .cell:
                    if maskHomeImage != nil {
                        updateMask()
                        showMaskView()
                    }
                case .detail: break
                }
            }
            else if useMask == false && oldValue == true {hideMaskView()}
        }
    }
    
    fileprivate let minMaskCoveragePercentDifferenceForUIUpdate: CGFloat = 0.005
    fileprivate let minSizeOfGradientArea: CGFloat = 0.025
    
    //
    // MARK: Flags
    fileprivate var isPastEvent = false {
        didSet {
            if isPastEvent && oldValue != isPastEvent {
                
                //removeGradientView()
                //removeMaskImageView()
                
                viewTransition(from: [inLabel], to: [agoLabel])
                viewTransition(from: [abridgedInLabel], to: [abridgedAgoLabel])
            }
                
            else if !isPastEvent && oldValue != isPastEvent {
                if useMask {updateMaskCoverageValues()}
                
                viewTransition(from: [agoLabel], to: [inLabel])
                viewTransition(from: [abridgedAgoLabel], to: [abridgedInLabel])
            }
        }
    }
    fileprivate var shadowsInitialized = false
    fileprivate var initialized = false
    
    //
    // MARK: GUI
    @IBOutlet weak var viewWithMargins: UIView!
    @IBOutlet weak var spacingAdjustmentConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var maskImageView: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var taglineLabel: UILabel!
    @IBOutlet weak var tomorrowLabel: UILabel!
    
    @IBOutlet weak var timerContainerView: UIView!
    @IBOutlet weak var timerStackView: UIStackView!
    @IBOutlet weak var inLabel: UILabel!
    @IBOutlet weak var weeksLabel: UILabel!
    @IBOutlet weak var daysLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    @IBOutlet weak var agoLabel: UILabel!
    @IBOutlet weak var timerLabelsStackView: UIStackView!
    @IBOutlet weak var weeksColon: UILabel!
    @IBOutlet weak var daysColon: UILabel!
    @IBOutlet weak var hoursColon: UILabel!
    @IBOutlet weak var minutesColon: UILabel!
    @IBOutlet weak var weeksTextLabel: UILabel!
    @IBOutlet weak var daysTextLabel: UILabel!
    @IBOutlet weak var hoursTextLabel: UILabel!
    @IBOutlet weak var minutesTextLabel: UILabel!
    @IBOutlet weak var secondsTextLabel: UILabel!
    
    @IBOutlet weak var abridgedTimerContainerView: UIView!
    @IBOutlet weak var abridgedTimerStackView: UIStackView!
    @IBOutlet weak var abridgedInLabel: UILabel!
    @IBOutlet weak var abridgedAgoLabel: UILabel!
    @IBOutlet weak var abridgedYearsStackView: UIStackView!
    @IBOutlet weak var abridgedMonthsStackView: UIStackView!
    @IBOutlet weak var abridgedDaysStackView: UIStackView!
    @IBOutlet weak var abridgedYearsLabel: UILabel!
    @IBOutlet weak var abridgedMonthsLabel: UILabel!
    @IBOutlet weak var abridgedDaysLabel: UILabel!
    @IBOutlet weak var abridgedYearsTextLabel: UILabel!
    @IBOutlet weak var abridgedMonthsTextLabel: UILabel!
    @IBOutlet weak var abridgedDaysTextLabel: UILabel!

    
    //
    // MARK: - Cell Lifecycle
    //
    
    override func prepareForReuse() {clearEventImage()}
    
    //
    // MARK: Delegate Methods
    //
    
    //
    // MARK: - Instance Methods
    //
    
    internal func setSelectedImage(image: UserEventImage, locationForCellView: CGFloat?) {
        
        if let location = locationForCellView {_locationForCellView = location}
        _eventImage = image
        mainImageView.contentMode = .scaleAspectFit
        
        switch configuration {
        case .cell:
            image.requestMainHomeImage(size: defaultHomeImageSize, locationForCellView: _locationForCellView) { (image) in
                DispatchQueue.main.async { [weak self] in
                    self?.mainHomeImage = image
                }
            }
            if useMask {
                image.requestMaskHomeImage(size: defaultHomeImageSize, locationForCellView: _locationForCellView) {  (image) in
                    DispatchQueue.main.async { [weak self] in
                        self?.maskHomeImage = image
                    }
                }
            }
        case .detail:
            image.requestMainImage { (image) in
                DispatchQueue.main.async { [weak self] in
                    self?.mainImageView.image = image?.uiImage
                }
            }
        }
    }
    
    internal func setHomeImages(mainHomeImage: UIImage?, maskHomeImage: UIImage?) {
        if let main = mainHomeImage {self.mainHomeImage = main}
        if let mask = maskHomeImage {self.maskHomeImage = mask}
    }
    
    internal func clearEventImage() {
        _eventImage = nil
        mainHomeImage = nil
        maskHomeImage = nil
        backgroundColor = UIColor.black
    }
    
    // Function to update the displayed event times and masks.
    internal func update() {
        
        func checkIfPastEvent(intervalToCheck timeInterval: inout Double) {
            if timeInterval < 0.0 {
                if repeats == .never {
                    isPastEvent = true
                    timeInterval = -timeInterval
                }
                else {
                    isPastEvent = false
                    let currentCalendar = Calendar.current
                    var timeInterval = 0.0
                    let todaysDate = Date()
                    
                    func failSafe() {
                        os_log("Error creating next date for repeating date event: %@", log: .default, type: .error, self.eventTitle ?? "Nil")
                        let tomorrow = currentCalendar.date(bySetting: .day, value: 1, of: Date()) ?? Date()
                        delegate?.eventDateRepeatTriggered(cell: self, newDate: EventDate(date: tomorrow, dateOnly: eventDate!.dateOnly))
                    }
                    
                    switch repeats {
                    case .never: break
                    case .monthly:
                        guard var nextMonth = currentCalendar.date(byAdding: .month, value: 1, to: eventDate!.date, wrappingComponents: false) else {
                            failSafe(); return
                        }
                        timeInterval = nextMonth.timeIntervalSince(todaysDate)
                        while timeInterval < 0.0 {
                            guard let newDate = currentCalendar.date(byAdding: .month, value: 1, to: nextMonth, wrappingComponents: false) else {
                                failSafe(); return
                            }
                            nextMonth = newDate
                            timeInterval = nextMonth.timeIntervalSince(todaysDate)
                        }
                        delegate?.eventDateRepeatTriggered(cell: self, newDate: EventDate(date: nextMonth, dateOnly: eventDate!.dateOnly))
                    case .yearly:
                        guard var nextYear = currentCalendar.date(byAdding: .year, value: 1, to: eventDate!.date, wrappingComponents: false) else {
                            failSafe(); return
                        }
                        timeInterval = nextYear.timeIntervalSince(todaysDate)
                        while timeInterval < 0.0 {
                            guard let newDate = currentCalendar.date(byAdding: .month, value: 1, to: nextYear, wrappingComponents: false) else {
                                failSafe(); return
                            }
                            nextYear = newDate
                            timeInterval = nextYear.timeIntervalSince(todaysDate)
                        }
                        delegate?.eventDateRepeatTriggered(cell: self, newDate: EventDate(date: nextYear, dateOnly: eventDate!.dateOnly))
                    }
                }
            }
            else {isPastEvent = false}
        }
        
        let todaysDate = Date()
        var timeInterval = eventDate!.date.timeIntervalSince(todaysDate)
        checkIfPastEvent(intervalToCheck: &timeInterval)
        currentStage = .weeks
        
        let weeks = (timeInterval/Stages.weeks.interval).rounded(.towardZero)
        if weeks == 0 {currentStage = .days}
        
        var remainder = timeInterval - (weeks * Stages.weeks.interval)
        let days = (remainder/Stages.days.interval).rounded(.towardZero)
        if days == 0.0 && weeks == 0.0 {currentStage = .hours}
        
        remainder -= days * Stages.days.interval
        let hours = (remainder/Stages.hours.interval).rounded(.towardZero)
        if hours == 0.0 && days == 0.0 && weeks == 0.0 {currentStage = .minutes}
        
        remainder -= hours * Stages.hours.interval
        let minutes = (remainder/Stages.minutes.interval).rounded(.towardZero)
        if minutes == 0.0 && hours == 0.0 && days == 0.0 && weeks == 0.0 {currentStage = .seconds}
        
        remainder -= minutes * Stages.minutes.interval
        let seconds = remainder.rounded(.towardZero)
        
        if abridgedDisplayMode {
            
            func abridgedFormat(label: UILabel, withNumber number: Double) {label.text = String(Int(number))}
            
            let currentCalendar = Calendar.current
            let calendarComponents: Set<Calendar.Component> = [.year, .month, .day]
            let todaysDateComponents = currentCalendar.dateComponents(calendarComponents, from: Date())
            let eventDateComponents = currentCalendar.dateComponents(calendarComponents, from: eventDate!.date)
            
            var years = 0.0
            var months = 0.0
            var abridgedDays = 0.0
            
            if isPastEvent {
                abridgedDays = Double(todaysDateComponents.day! - eventDateComponents.day!)
                if abridgedDays < 0.0 {
                    months -= 1.0
                    let todaysDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: todaysDate)!
                    let daysInTodaysDatePreviousMonth = currentCalendar.range(of: .day, in: .month, for: todaysDatePreviousMonth)!.count
                    let daysLeftInTodaysDatePreviousMonth = daysInTodaysDatePreviousMonth - eventDateComponents.day!
                    abridgedDays = Double(daysLeftInTodaysDatePreviousMonth + todaysDateComponents.day!)
                }
            }
            else {
                abridgedDays = Double(eventDateComponents.day! - todaysDateComponents.day!)
                if abridgedDays < 0.0 {
                    months -= 1.0
                    let eventDatePreviousMonth = currentCalendar.date(byAdding: .month, value: -1, to: eventDate!.date)!
                    let daysInEventDatePreviousMonth = currentCalendar.range(of: .day, in: .month, for: eventDatePreviousMonth)!.count
                    let daysLeftInEventDatePreviousMonth = daysInEventDatePreviousMonth - todaysDateComponents.day!
                    abridgedDays = Double(daysLeftInEventDatePreviousMonth + eventDateComponents.day!)
                }
            }
            
            if isPastEvent {months += Double(todaysDateComponents.month! - eventDateComponents.month!)}
            else {months += Double(eventDateComponents.month! - todaysDateComponents.month!)}
            if months < 0.0 {
                years -= 1.0
                months = 12 + months
            }
            
            if isPastEvent {years += Double(todaysDateComponents.year! - eventDateComponents.year!)}
            else {years += Double(eventDateComponents.year! - todaysDateComponents.year!)}
            
            if years == 0 && months == 0 && (abridgedDays == 1 || abridgedDays == 0) { // Within one day
                if tomorrowLabel.isHidden {
                    if eventDateComponents.day! == todaysDateComponents.day! + 1 {tomorrowLabel.text = "Tomorrow!"}
                    else if eventDateComponents.day! == todaysDateComponents.day! {tomorrowLabel.text = "Today!!!"}
                    else if eventDateComponents.day! == todaysDateComponents.day! - 1 {tomorrowLabel.text = "Yesterday"}
                    
                    if !abridgedTimerStackView.isHidden {viewTransition(from: [abridgedTimerStackView], to: [tomorrowLabel])}
                    else if !timerContainerView.isHidden {
                        abridgedTimerStackView.isHidden = true
                        tomorrowLabel.isHidden = false
                        viewTransition(from: [timerContainerView], to: [abridgedTimerContainerView])
                    }
                }
                else {
                    if eventDateComponents.day! == todaysDateComponents.day! + 1 && tomorrowLabel.text != "Tomorrow!" {
                        tomorrowLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                        tomorrowLabel.text = "Tomorrow!"
                    }
                    else if eventDateComponents.day! == todaysDateComponents.day! && tomorrowLabel.text != "Today!!!" {
                        tomorrowLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                        tomorrowLabel.text = "Today!!!"
                    }
                    else if eventDateComponents.day! == todaysDateComponents.day! - 1 && tomorrowLabel.text != "Yesterday" {
                        tomorrowLabel.layer.add(GlobalAnimations.labelTransition, forKey: nil)
                        tomorrowLabel.text = "Yesterday"
                    }
                }
            }
                
            else { // Not within one day
                if !abridgedTimerStackView.isHidden {
                    if years == 0 {hide(views: [abridgedYearsStackView], animated: true)}
                    else {
                        abridgedFormat(label: abridgedYearsLabel, withNumber: years)
                        show(views: [abridgedYearsStackView], animated: true)
                        if years > 1.0 {
                            if months != 0.0 || abridgedDays != 0.0 {abridgedYearsTextLabel.text = "Years,"}
                            else {abridgedYearsTextLabel.text = "Years"}
                        }
                        else {
                            if months != 0.0 || abridgedDays != 0.0 {abridgedYearsTextLabel.text = "Year,"}
                            else {abridgedYearsTextLabel.text = "Year"}
                        }
                    }
                    
                    if months == 0 {hide(views: [abridgedMonthsStackView], animated: true)}
                    else {
                        abridgedFormat(label: abridgedMonthsLabel, withNumber: months)
                        show(views: [abridgedMonthsStackView], animated: true)
                        if months > 1.0 {
                            if abridgedDays != 0.0 {abridgedMonthsTextLabel.text = "Months,"}
                            else {abridgedMonthsTextLabel.text = "Months"}
                        }
                        else {
                            if abridgedDays != 0.0 {abridgedMonthsTextLabel.text = "Month,"}
                            else {abridgedMonthsTextLabel.text = "Month"}
                        }
                    }
                    
                    if abridgedDays == 0 {hide(views: [abridgedDaysStackView], animated: true)}
                    else {
                        abridgedFormat(label: abridgedDaysLabel, withNumber: abridgedDays)
                        show(views: [abridgedDaysStackView], animated: true)
                        if abridgedDays > 1.0 {abridgedDaysTextLabel.text = "Days"}
                        else {abridgedDaysTextLabel.text = "Day"}
                    }
                }
                else {
                    if years == 0 {hide(views: [abridgedYearsStackView], animated: false)}
                    else {
                        abridgedFormat(label: abridgedYearsLabel, withNumber: years)
                        show(views: [abridgedYearsStackView], animated: false)
                        if years > 1.0 {
                            if months != 0.0 || days != 0.0 {abridgedYearsTextLabel.text = "Years,"}
                            else {abridgedYearsTextLabel.text = "Years"}
                        }
                        else {
                            if months != 0.0 || days != 0.0 {abridgedYearsTextLabel.text = "Year,"}
                            else {abridgedYearsTextLabel.text = "Year"}
                        }
                    }
                    
                    if months == 0 {hide(views: [abridgedMonthsStackView], animated: false)}
                    else {
                        abridgedFormat(label: abridgedMonthsLabel, withNumber: months)
                        show(views: [abridgedMonthsStackView], animated: false)
                        if months > 1.0 {
                            if days != 0.0 {abridgedMonthsTextLabel.text = "Months,"}
                            else {abridgedMonthsTextLabel.text = "Months"}
                        }
                        else {
                            if days != 0.0 {abridgedMonthsTextLabel.text = "Month,"}
                            else {abridgedMonthsTextLabel.text = "Month"}
                        }
                    }
                    
                    if abridgedDays == 0 {hide(views: [abridgedDaysStackView], animated: false)}
                    else {
                        abridgedFormat(label: abridgedDaysLabel, withNumber: days)
                        show(views: [abridgedDaysStackView], animated: false)
                        if days > 1.0 {abridgedDaysTextLabel.text = "Days"}
                        else {abridgedDaysTextLabel.text = "Day"}
                    }
                    
                    if !tomorrowLabel.isHidden {viewTransition(from: [tomorrowLabel], to: [abridgedTimerStackView])}
                    else if !timerContainerView.isHidden {
                        abridgedTimerStackView.isHidden = false
                        tomorrowLabel.isHidden = true
                        viewTransition(from: [timerContainerView], to: [abridgedTimerContainerView])
                    }
                }
            }
        }
            
        else { // Not abridged display mode
            
            func fullFormat(label: UILabel, withNumber number: Double) {
                let intNumber = Int(number)
                if intNumber < 10 {label.text = "0" + String(intNumber)}
                else {label.text = String(intNumber)}
            }
            
            if timerContainerView.isHidden {viewTransition(from: [abridgedTimerContainerView], to: [timerContainerView])}
            
            if weeks == 0.0 {hide(views: [weeksLabel, weeksColon, weeksTextLabel], animated: true)}
            else {
                fullFormat(label: weeksLabel, withNumber: weeks)
                show(views: [weeksLabel, weeksColon, weeksTextLabel], animated: true)
            }
            if weeks == 0.0 && days == 0.0 {hide(views: [daysLabel, daysColon, daysTextLabel], animated: true)}
            else {
                fullFormat(label: daysLabel, withNumber: days)
                show(views: [daysLabel, daysColon, daysTextLabel], animated: true)
            }
            if weeks == 0.0 && days == 0.0 && hours == 0.0 {hide(views: [hoursLabel, hoursColon, hoursTextLabel], animated: true)}
            else {
                fullFormat(label: hoursLabel, withNumber: hours)
                show(views: [hoursLabel, hoursColon, hoursTextLabel], animated: true)
            }
            if weeks == 0.0 && days == 0.0 && hours == 0.0 && minutes == 0.0 {hide(views: [minutesLabel, minutesColon, minutesTextLabel], animated: true)}
            else {
                fullFormat(label: minutesLabel, withNumber: minutes)
                show(views: [minutesLabel, minutesColon, minutesTextLabel], animated: true)
            }
            fullFormat(label: secondsLabel, withNumber: seconds)
        }
        
        updateMaskCoverageValues()
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func updateMaskCoverageValues() {
        if useMask && !isPastEvent && creationDate != nil && eventDate != nil {
            
            let timerCoverage = timerContainerView.frame.width + 8.0
            let minPercentCoverage = timerCoverage / self.bounds.width
            var maxPercentCoverage: CGFloat {
                switch currentStage {
                case .weeks: return 1.0
                default: return (timerCoverage + Constants.oneLabelTraverseDistance) / self.bounds.width
                }
            }
            
            var previousStageTimeInterval: TimeInterval {
                switch currentStage {
                case .days: return Stages.weeks.interval
                case .hours: return Stages.days.interval
                case .minutes: return Stages.hours.interval
                case .seconds: return Stages.minutes.interval
                default: return eventDate!.date.timeIntervalSince(creationDate!)
                }
            }
            
            let timeIntervalNowToEventDate = eventDate!.date.timeIntervalSince(Date())
            
            let timeIntervalUntilNextStage = timeIntervalNowToEventDate - currentStage.interval
            let timeIntervalOfCurrentStage = previousStageTimeInterval - currentStage.interval
            let percentUntilLegComplete = CGFloat(timeIntervalUntilNextStage / timeIntervalOfCurrentStage)
            
            let percentRevealRange = maxPercentCoverage - minPercentCoverage
            let percentOfLegToCover = percentRevealRange * percentUntilLegComplete
            let newPercentMaskCoverage = minPercentCoverage + percentOfLegToCover
            
            let percentDiff = (percentMaskCoverage - newPercentMaskCoverage) / percentMaskCoverage
            if percentDiff > minMaskCoveragePercentDifferenceForUIUpdate || percentDiff < 0.0 {
                percentMaskCoverage = newPercentMaskCoverage
            }
        }
    }
    
    fileprivate func updateMask() {
        let sizeOfGradientArea: CGFloat = 0.15
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = maskImageView.bounds
        gradientLayer.colors = [
            UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor,
            UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor]
        
        let location2: CGFloat = 1.0 - percentMaskCoverage
        var location1: CGFloat {
            let location = location2 - sizeOfGradientArea
            if location < 0.0 {return 0.0} else {return location}
        }
        gradientLayer.startPoint = CGPoint(x: location1, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: location2, y: 0.5)
        
        maskImageView.layer.mask = gradientLayer;
    }
    
    //
    // MARK: Init helpers
    
    func configure() {
        if !initialized {
            self.backgroundColor = UIColor.clear
            viewWithMargins.layer.cornerRadius = 3.0
            viewWithMargins.layer.masksToBounds = true
            
            let backgroundView = UIView()
            backgroundView.backgroundColor = UIColor.black
            self.selectedBackgroundView = backgroundView
            
            initialized = true
        }
    }
    
    fileprivate func initializeShadows() {
        func initializeShadows(for views: [UIView], withShadowRadius shadowRadius: CGFloat) {
            for view in views {
                view.backgroundColor = .clear
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
                view.layer.shadowRadius = shadowRadius
                view.layer.shadowOpacity = 1.0
            }
        }
        var highLabels: [UILabel]
        var mediumLabels: [UILabel]
        var lowLabels: [UILabel]
        highLabels = [tomorrowLabel, titleLabel]
        mediumLabels = [taglineLabel, abridgedYearsLabel, abridgedMonthsLabel, abridgedDaysLabel, weeksLabel, daysLabel, hoursLabel, minutesLabel, secondsLabel]
        lowLabels = [abridgedInLabel, abridgedYearsTextLabel, abridgedMonthsTextLabel, abridgedDaysTextLabel, abridgedAgoLabel, inLabel, weeksColon, daysColon, hoursColon, minutesColon, agoLabel, weeksTextLabel!, daysTextLabel!, hoursTextLabel!, minutesTextLabel!, secondsTextLabel!]
        initializeShadows(for: highLabels, withShadowRadius: 3.0)
        initializeShadows(for: mediumLabels, withShadowRadius: 2.0)
        initializeShadows(for: lowLabels, withShadowRadius: 1.0)
        shadowsInitialized = true
    }
    
    fileprivate func hide(views: [UIView], animated: Bool) {
        var viewsToHide = [UIView]()
        for view in views {if !view.isHidden {viewsToHide.append(view)}}
        if !viewsToHide.isEmpty {
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {for view in viewsToHide {view.isHidden = true; view.isUserInteractionEnabled = false}},
                    completion: nil
                )
            }
            else {for view in viewsToHide {view.isHidden = true; view.isUserInteractionEnabled = false}}
        }
    }
    
    fileprivate func show(views: [UIView], animated: Bool) {
        var viewsToShow = [UIView]()
        for view in views {if view.isHidden {viewsToShow.append(view)}}
        if !viewsToShow.isEmpty {
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {for view in viewsToShow {view.isHidden = false; view.isUserInteractionEnabled = true}},
                    completion: nil
                )
            }
            else {for view in viewsToShow {view.isHidden = false; view.isUserInteractionEnabled = true}}
        }
    }
    
    //
    // MARK: Animation helpers
    
    func viewTransition(from startViews: [UIView], to endViews: [UIView]) {
        let transition = CATransition()
        transition.type = kCATransitionFade
        transition.duration = 0.3
        
        for view in startViews {view.layer.add(transition, forKey: "transition")}
        for view in endViews {view.layer.add(transition, forKey: "transition")}
        
        for view in startViews {view.isHidden = true; view.isUserInteractionEnabled = false}
        for view in endViews {view.isHidden = false; view.isUserInteractionEnabled = true}
    }
    
    fileprivate func showMaskView() {
        if mainHomeImage != nil && maskHomeImage != nil && maskImageView.isHidden {
            maskImageView.layer.opacity = 0.0
            maskImageView.isHidden = false
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.2,
                delay: 0.0,
                options: .curveLinear,
                animations: {self.maskImageView.layer.opacity = 1.0},
                completion: nil
            )
        }
    }
    
    fileprivate func hideMaskView() {
        if !maskImageView.isHidden {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.2,
                delay: 0.0,
                options: .curveLinear,
                animations: {self.maskImageView.layer.opacity = 0.0},
                completion: {[weak self] (position) in self?.maskImageView.isHidden = true}
            )
        }
    }
}
