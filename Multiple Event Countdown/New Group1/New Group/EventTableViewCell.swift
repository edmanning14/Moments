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

class EventTableViewCell: UITableViewCell {
    
    //
    // MARK: - Variables and Constants
    //
    
    fileprivate let computationalQueue = DispatchQueue(label: "computationalQueue", qos: DispatchQoS.userInitiated)
    
    
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
            if eventTagline != nil {taglineLabel.text = eventTagline}
            else {taglineLabel.isHidden = true; taglineLabel.isUserInteractionEnabled = false}
        }
    }
    
    var eventDate: EventDate? {
        didSet {
            if !shadowsInitialized {initializeShadows()}
            if eventDate != nil {update()}
            else {
                agoLabel.isHidden = true
                inLabel.isHidden = false
                weeksLabel.text = "00"
                daysLabel.text = "00"
                hoursLabel.text = "00"
                minutesLabel.text = "00"
                secondsLabel.text = "00"
            }
        }
    }
    
    var abridgedDisplayMode = false {
        didSet {
            if abridgedDisplayMode {
                if abridgedTimerContainerView.isHidden {
                    if !timerContainerView.isHidden {
                        viewTransition(from: [timerContainerView], to: [abridgedTimerContainerView])
                    }
                    else {show(view: abridgedTimerContainerView)}
                }
            }
            else {
                if timerContainerView.isHidden {
                    if !abridgedTimerContainerView.isHidden {
                        viewTransition(from: [abridgedTimerContainerView], to: [timerContainerView])
                    }
                    else {show(view: timerContainerView)}
                }
            }
            update()
        }
    }
    
    var creationDate: Date? {didSet {updateMask()}}
    
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
                    if useMask {updateMask(); addGradientView()}}
                else {removeGradientView()}
            case .detail: break
            }
        }
    }
    
    fileprivate var maskHomeImage: UIImage? {
        didSet {
            switch configuration {
            case .cell:
                if useMask {addMaskImageView()}
                else {removeMaskImageView()}
            case .detail: break
            }
        }
    }
    
    var locationForCellView: CGFloat {return _locationForCellView}
    fileprivate var _locationForCellView: CGFloat = 0.5
    
    //
    // MARK: Types
    
    fileprivate struct Constants {
        static let oneLabelTraverseDistance: CGFloat = 2.5 + 33.0 + 7.5 + 2.5
    }
    
    //
    // MARK: States
    enum Configurations {case cell, detail}
    var configuration: Configurations = .cell
    
    fileprivate enum Stages {
        case weeks, days, hours, minutes, seconds
        
        var interval: TimeInterval {
            switch self {
            case .weeks: return 604800.0
            case .days: return 86400.0
            case .hours: return 3600.0
            case .minutes: return 60.0
            case .seconds: return 0.0
            }
        }
    }
    fileprivate var currentStage = Stages.weeks
    
    //
    // MARK: Mask parameters
    var percentMaskCoverage: CGFloat = 1.0 - 0.025 {
        didSet {
            if 1.0 - percentMaskCoverage < minSizeOfGradientArea {percentMaskCoverage = 1.0 - minSizeOfGradientArea}
            if let _gradientView = gradientView {
                let percentDiff = (_gradientView.percentMaskCoverage - percentMaskCoverage) / _gradientView.percentMaskCoverage
                if percentDiff > minMaskCoveragePercentDifferenceForUIUpdate || percentDiff < 0.0 {
                    _gradientView.percentMaskCoverage = percentMaskCoverage
                    maskImageView?.percentMaskCoverage = percentMaskCoverage
                }
            }
        }
    }
    
    var useMask = false {
        didSet {
            if useMask == true && oldValue == false && mainImageView.image != nil {
                updateMask()
                addGradientView()
                addMaskImageView()
            }
            else if useMask == false && oldValue == true {
                removeGradientView()
                removeMaskImageView()
            }
        }
    }
    
    fileprivate let minMaskCoveragePercentDifferenceForUIUpdate: CGFloat = 0.005
    fileprivate let minSizeOfGradientArea: CGFloat = 0.025
    
    //
    // MARK: Flags
    fileprivate var isPastEvent = false {
        didSet {
            if isPastEvent && oldValue != isPastEvent {
                
                removeGradientView()
                removeMaskImageView()
                
                viewTransition(from: [inLabel], to: [agoLabel])
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.abridgedInLabel.isHidden = true},
                    completion: nil
                )
                transitionText(inLabel: abridgedDaysTextLabel, toText: "Days Ago")
            }
                
            else if !isPastEvent && oldValue != isPastEvent {
                if useMask {updateMask(); addGradientView(); addMaskImageView()}
                
                viewTransition(from: [agoLabel], to: [inLabel])
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.abridgedInLabel.isHidden = false},
                    completion: nil
                )
                transitionText(inLabel: abridgedDaysTextLabel, toText: "Days")
            }
        }
    }
    fileprivate var shadowsInitialized = false
    fileprivate var initialized = false
    
    //
    // MARK: UI Elements
    @IBOutlet weak var viewWithMargins: UIView!
    @IBOutlet weak var mainImageView: UIImageView!
    
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
    @IBOutlet weak var abridgedWeeksLabel: UILabel!
    @IBOutlet weak var abridgedDaysLabel: UILabel!
    @IBOutlet weak var abridgedWeeksTextLabel: UILabel!
    @IBOutlet weak var abridgedDaysTextLabel: UILabel!
    
    /*var titleWaveEffectView: WaveEffectView?
    var taglineWaveEffectView: WaveEffectView?
    var timerWaveEffectView: WaveEffectView?
    var timerLabelsWaveEffectView: WaveEffectView?*/
    
    fileprivate var gradientView: GradientMaskView?
    fileprivate var maskImageView: CountdownMaskImageView?

    
    //
    // MARK: - Cell Lifecycle
    //
    
    override func prepareForReuse() {
        eventImage?.delegate = nil
        clearEventImage()
        maskImageView = nil
        gradientView = nil
    }
    
    //
    // MARK: Delegate Methods
    //
    
    //
    // MARK: - Instance Methods
    //
    
    internal func setSelectedImage(image: UserEventImage, locationForCellView: CGFloat?) {
        
        if let location = locationForCellView {_locationForCellView = location}
        _eventImage = image
        
        if let mainUIImage = image.mainImage?.uiImage {
            mainImageView.contentMode = .scaleAspectFit
            switch configuration {
            case .cell: getHomeImages(nil)
            case .detail: mainImageView.image = mainUIImage
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
        removeMaskImageView()
        removeGradientView()
        mainImageView.image = nil
    }
    
    // Function to update the displayed event times and masks.
    internal func update() {
        
        func fullFormat(label: UILabel, withNumber number: Double) {
            let intNumber = Int(number)
            if intNumber < 10 {label.text = "0" + String(intNumber)}
            else {label.text = String(intNumber)}
        }
        
        func abridgedFormat(label: UILabel, withNumber number: Double) {label.text = String(Int(number))}
        
        let todaysDate = Date()
        var timeInterval = eventDate!.date.timeIntervalSince(todaysDate)
        if timeInterval < 0.0 {
            isPastEvent = true
            timeInterval = todaysDate.timeIntervalSince(eventDate!.date)
        }
        else {isPastEvent = false}
        
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
            let currentCalendar = Calendar.current
            let dayNow = currentCalendar.component(.day, from: todaysDate)
            let eventDay = currentCalendar.component(.day, from: eventDate!.date)
            
            var midnightDateComponents = DateComponents()
            midnightDateComponents.year = currentCalendar.component(.year, from: eventDate!.date)
            midnightDateComponents.month = currentCalendar.component(.month, from: eventDate!.date)
            midnightDateComponents.day = currentCalendar.component(.day, from: eventDate!.date)
            midnightDateComponents.hour = 0
            midnightDateComponents.minute = 0
            midnightDateComponents.second = 0
            let midnightDate = currentCalendar.date(from: midnightDateComponents)!
            
            let abridgedTimeInterval = midnightDate.timeIntervalSince(todaysDate)
            var abridgedModeWeeks = (abridgedTimeInterval/Stages.weeks.interval).rounded(.towardZero)
            let abridgedRemainder = abridgedTimeInterval - (abridgedModeWeeks * Stages.weeks.interval)
            var abridgedModeDays = (abridgedRemainder/Stages.days.interval).rounded(.up)
            abridgedModeWeeks = abs(abridgedModeWeeks)
            abridgedModeDays = abs(abridgedModeDays)
            if abridgedModeDays == 7.0 {abridgedModeDays = 0.0; abridgedModeWeeks += 1.0}
            
            var formatDays = true
            if abridgedModeWeeks == 0.0 {
                if !abridgedWeeksLabel.isHidden {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: [.curveLinear],
                        animations: {self.abridgedWeeksLabel.isHidden = true; self.abridgedWeeksTextLabel.isHidden = true},
                        completion: nil
                    )
                }
                
                if eventDay == dayNow + 1 {
                    if !abridgedTimerStackView.isHidden {
                        tomorrowLabel.text = "Tomorrow!"
                        viewTransition(from: [abridgedTimerStackView], to: [tomorrowLabel])
                    }
                    else if let labelText = tomorrowLabel.text, labelText != "Tomorrow!" {
                        transitionText(inLabel: tomorrowLabel, toText: "Tomorrow!")
                    }
                    formatDays = false
                }
                
                else if eventDay == dayNow {
                    if !abridgedTimerStackView.isHidden {
                        tomorrowLabel.text = "Today!!!"
                        viewTransition(from: [abridgedTimerStackView], to: [tomorrowLabel])
                    }
                    else if let labelText = tomorrowLabel.text, labelText != "Today!!!" {
                        transitionText(inLabel: tomorrowLabel, toText: "Today!!!")
                    }
                    formatDays = false
                }
                
                else if eventDay == dayNow - 1 {
                    if !abridgedTimerStackView.isHidden {
                        tomorrowLabel.text = "Yesterday"
                        viewTransition(from: [abridgedTimerStackView], to: [tomorrowLabel])
                    }
                    else if let labelText = tomorrowLabel.text, labelText != "Yesterday" {
                        transitionText(inLabel: tomorrowLabel, toText: "Yesterday")
                    }
                    formatDays = false
                }
            }
            else {
                abridgedFormat(label: abridgedWeeksLabel, withNumber: abridgedModeWeeks)
                
                if abridgedModeWeeks == 1.0 && abridgedModeDays != 0.0 {abridgedWeeksTextLabel.text = "Week, "}
                else if abridgedModeWeeks == 1.0 && abridgedModeDays == 0.0 {abridgedWeeksTextLabel.text = "Week"}
                else if abridgedModeWeeks > 1.0 && abridgedModeDays != 0.0 {abridgedWeeksTextLabel.text = "Weeks, "}
                else {abridgedWeeksTextLabel.text = "Weeks"}
                
                if abridgedWeeksLabel.isHidden {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: [.curveLinear],
                        animations: {self.abridgedWeeksLabel.isHidden = false; self.abridgedWeeksTextLabel.isHidden = false},
                        completion: nil
                    )
                }
            }
            
            if formatDays {
                if abridgedModeDays == 0 {
                    if !abridgedDaysLabel.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.3,
                            delay: 0.0,
                            options: [.curveLinear],
                            animations: {self.abridgedDaysLabel.isHidden = true; self.abridgedDaysTextLabel.isHidden = true},
                            completion: nil
                        )
                    }
                    if isPastEvent {abridgedWeeksTextLabel.text = abridgedWeeksTextLabel.text! + " ago"}
                }
                else  {
                    abridgedFormat(label: abridgedDaysLabel, withNumber: abridgedModeDays)
                    if !isPastEvent {
                        if abridgedModeDays == 1.0 {abridgedDaysTextLabel.text = "Day"}
                        else {abridgedDaysTextLabel.text = "Days"}
                    }
                    else {
                        if abridgedModeDays == 1.0 {abridgedDaysTextLabel.text = "Day Ago"}
                        else {abridgedDaysTextLabel.text = "Days Ago"}
                    }
                    if abridgedDaysLabel.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.3,
                            delay: 0.0,
                            options: [.curveLinear],
                            animations: {self.abridgedDaysLabel.isHidden = false; self.abridgedDaysTextLabel.isHidden = false},
                            completion: nil
                        )
                    }
                }
                
                if !tomorrowLabel.isHidden {viewTransition(from: [tomorrowLabel], to: [abridgedTimerStackView])}
            }
        }
        
        if weeks == 0 {
            if !weeksLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.weeksLabel.isHidden = true; self.weeksTextLabel.isHidden = true; self.weeksColon.isHidden = true},
                    completion: nil
                )
            }
        }
        else {
            fullFormat(label: weeksLabel, withNumber: weeks)
            if weeksLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.weeksLabel.isHidden = false; self.weeksTextLabel.isHidden = false; self.weeksColon.isHidden = false},
                    completion: nil
                )
            }
        }
        
        if days == 0.0 && weeks == 0.0 {
            if !daysLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.daysLabel.isHidden = true; self.daysTextLabel.isHidden = true; self.daysColon.isHidden = true},
                    completion: nil
                )
            }
        }
        else {
            fullFormat(label: daysLabel, withNumber: days)
            if daysLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.daysLabel.isHidden = false; self.daysTextLabel.isHidden = false; self.daysColon.isHidden = false},
                    completion: nil
                )
            }
        }
        
        if hours == 0.0 && days == 0.0 && weeks == 0.0 {
            if !hoursLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.hoursLabel.isHidden = true; self.hoursTextLabel.isHidden = true; self.hoursColon.isHidden = true},
                    completion: nil
                )
            }
        }
        else {
            fullFormat(label: hoursLabel, withNumber: hours)
            if hoursLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.hoursLabel.isHidden = false; self.hoursTextLabel.isHidden = false; self.hoursColon.isHidden = false},
                    completion: nil
                )
            }
            
        }
        
        if minutes == 0.0 && hours == 0.0 && days == 0.0 && weeks == 0.0 {
            if !minutesLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.minutesLabel.isHidden = true; self.minutesTextLabel.isHidden = true; self.minutesColon.isHidden = true},
                    completion: nil
                )
            }
        }
        else {
            fullFormat(label: minutesLabel, withNumber: minutes)
            if minutesLabel.isHidden {
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {self.minutesLabel.isHidden = false; self.minutesTextLabel.isHidden = false; self.minutesColon.isHidden = false},
                    completion: nil
                )
            }
        }
        
        fullFormat(label: secondsLabel, withNumber: seconds)
        
        updateMask()
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func updateMask() {
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
                case .weeks: return eventDate!.date.timeIntervalSince(creationDate!)
                case .days: return Stages.weeks.interval
                case .hours: return Stages.days.interval
                case .minutes: return Stages.hours.interval
                case .seconds: return Stages.minutes.interval
                }
            }
            
            let timeIntervalNowToEventDate = eventDate!.date.timeIntervalSince(Date())
            
            let timeIntervalUntilNextStage = timeIntervalNowToEventDate - currentStage.interval
            let timeIntervalOfCurrentStage = previousStageTimeInterval - currentStage.interval
            let percentUntilLegComplete = CGFloat(timeIntervalUntilNextStage / timeIntervalOfCurrentStage)
            
            let percentRevealRange = maxPercentCoverage - minPercentCoverage
            let percentOfLegToCover = percentRevealRange * percentUntilLegComplete
            percentMaskCoverage = minPercentCoverage + percentOfLegToCover
        }
    }
    
    fileprivate func initializeGradientView() {
        gradientView = GradientMaskView(frame: self.bounds)
        gradientView!.translatesAutoresizingMaskIntoConstraints = false
        gradientView!.backgroundColor = UIColor.clear
        gradientView!.percentMaskCoverage = percentMaskCoverage
    }
    
    fileprivate func initializeMaskImageView() {
        if let _maskHomeImage = maskHomeImage?.cgImage {
            maskImageView = CountdownMaskImageView(frame: self.bounds, image: _maskHomeImage)
            maskImageView!.translatesAutoresizingMaskIntoConstraints = false
            maskImageView!.backgroundColor = UIColor.clear
            
            maskImageView!.image = _maskHomeImage
            maskImageView!.percentMaskCoverage = percentMaskCoverage
        }
    }
    
    fileprivate func addGradientView() {
        if useMask && !isPastEvent {
            if let _gradientView = gradientView {_gradientView.percentMaskCoverage = percentMaskCoverage}
            else {initializeGradientView()}
            
            if !mainImageView!.subviews.contains(gradientView!) {
                gradientView!.layer.opacity = 0.0
                mainImageView!.addSubview(gradientView!)
                mainImageView!.topAnchor.constraint(equalTo: gradientView!.topAnchor).isActive = true
                mainImageView!.rightAnchor.constraint(equalTo: gradientView!.rightAnchor).isActive = true
                mainImageView!.bottomAnchor.constraint(equalTo: gradientView!.bottomAnchor).isActive = true
                mainImageView!.leftAnchor.constraint(equalTo: gradientView!.leftAnchor).isActive = true
                //if configuration == .newEventsController, configuration == .imagePreviewControllerCell {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.2,
                        delay: 0.0,
                        options: .curveEaseInOut,
                        animations: { [weak self] in self?.gradientView!.layer.opacity = 1.0},
                        completion: nil
                    )
                //}
                //else {gradientView!.layer.opacity = 1.0}
            }
            if maskHomeImage != nil {addMaskImageView()}
        }
    }
    
    fileprivate func addMaskImageView() {
        if let _maskHomeImage = maskHomeImage?.cgImage, let _gradientView = gradientView {
            if let _maskImageView = maskImageView {
                _maskImageView.image = _maskHomeImage
                _maskImageView.percentMaskCoverage = percentMaskCoverage
            }
            else {initializeMaskImageView()}
            
            if !_gradientView.subviews.contains(maskImageView!) {
                maskImageView!.layer.opacity = 0.0
                _gradientView.addSubview(maskImageView!)
                _gradientView.topAnchor.constraint(equalTo: maskImageView!.topAnchor).isActive = true
                _gradientView.rightAnchor.constraint(equalTo: maskImageView!.rightAnchor).isActive = true
                _gradientView.bottomAnchor.constraint(equalTo: maskImageView!.bottomAnchor).isActive = true
                _gradientView.leftAnchor.constraint(equalTo: maskImageView!.leftAnchor).isActive = true
                //if configuration == .newEventsController, configuration == .imagePreviewControllerCell {
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.2,
                        delay: 0.0,
                        options: .curveEaseInOut,
                        animations: { [weak self] in self?.maskImageView!.layer.opacity = 1.0},
                        completion: nil
                    )
                //}
                //else {maskImageView!.layer.opacity = 1.0}
            }
        }
    }
    
    fileprivate func removeGradientView() {
        if let _gradientView = gradientView {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.2,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {_gradientView.layer.opacity = 0.0},
                completion: {(_) in _gradientView.removeFromSuperview()}
            )
        }
    }
    
    fileprivate func removeMaskImageView() {
        if let _maskImageView = maskImageView {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.2,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {_maskImageView.layer.opacity = 0.0},
                completion: {(_) in _maskImageView.removeFromSuperview()}
            )
        }
    }
    
    fileprivate func getHomeImages(_ completion: (() -> Void)?) {
        if let _eventImage = eventImage, _eventImage.mainImage?.uiImage != nil {
            var mainFetchComplete = false
            var maskFetchComplete = false
            if let appImage = _eventImage as? AppEventImage {
                appImage.generateMainHomeImage(
                    size: defaultHomeImageSize,
                    locationForCellView: locationForCellView,
                    userInitiated: true,
                    completion: { [weak self] (image) in
                        if image != nil {
                            mainFetchComplete = true
                            DispatchQueue.main.async { [weak self] in
                                self?.mainHomeImage = image
                                if maskFetchComplete {completion?()}
                            }
                        }
                    }
                )
                appImage.generateMaskHomeImage(
                    size: defaultHomeImageSize,
                    locationForCellView: locationForCellView,
                    userInitiated: true,
                    completion: { [weak self] (maskHomeImage) in
                        maskFetchComplete = true
                        DispatchQueue.main.async { [weak self] in
                            self?.maskHomeImage = maskHomeImage
                            if mainFetchComplete {completion?()}
                        }
                    }
                )
            }
            else {
                maskFetchComplete = true
                _eventImage.generateMainHomeImage(
                    size: defaultHomeImageSize,
                    locationForCellView: locationForCellView,
                    userInitiated: true,
                    completion: { [weak self] (image) in
                        if image != nil {
                            DispatchQueue.main.async { [weak self] in
                                self?.mainHomeImage = image
                                completion?()
                            }
                        }
                    }
                )
            }
        }
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
    
    /*fileprivate func configureView() {
        switch configuration {
            
        case .tableView:
            /*titleWaveEffectView?.removeFromSuperview()
            titleWaveEffectView = nil
            taglineWaveEffectView?.removeFromSuperview()
            taglineWaveEffectView = nil
            timerWaveEffectView?.removeFromSuperview()
            timerWaveEffectView = nil
            timerLabelsWaveEffectView?.removeFromSuperview()
            timerLabelsWaveEffectView = nil*/
            
        case .newEventsController:
            
            //titleLabel.isHidden = true
            //taglineLabel.isHidden = true
            timerContainerView.isHidden = true
            abridgedTimerContainerView.isHidden = true
            
            /*titleWaveEffectView = WaveEffectView()
            taglineWaveEffectView = WaveEffectView()
            timerWaveEffectView = WaveEffectView()
            timerLabelsWaveEffectView = WaveEffectView()
            
            titleWaveEffectView!.translatesAutoresizingMaskIntoConstraints = false
            taglineWaveEffectView!.translatesAutoresizingMaskIntoConstraints = false
            timerWaveEffectView!.translatesAutoresizingMaskIntoConstraints = false
            timerLabelsWaveEffectView!.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(titleWaveEffectView!)
            addSubview(taglineWaveEffectView!)
            addSubview(timerWaveEffectView!)
            addSubview(timerLabelsWaveEffectView!)
            
            titleWaveEffectView!.topAnchor.constraint(equalTo: self.topAnchor, constant: 8.0).isActive = true
            titleWaveEffectView!.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8.0).isActive = true
            titleWaveEffectView!.heightAnchor.constraint(equalToConstant: titleLabel.bounds.height).isActive = true
            titleWaveEffectView!.widthAnchor.constraint(equalToConstant: self.bounds.width * (2.0/5.0)).isActive = true
            
            taglineWaveEffectView!.topAnchor.constraint(equalTo: titleWaveEffectView!.bottomAnchor, constant: 6.0).isActive = true
            taglineWaveEffectView!.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8.0).isActive = true
            taglineWaveEffectView!.heightAnchor.constraint(equalToConstant: taglineLabel.bounds.height).isActive = true
            taglineWaveEffectView!.widthAnchor.constraint(equalToConstant: self.bounds.width * (1.0/3.0)).isActive = true
            
            timerLabelsWaveEffectView!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8.0).isActive = true
            timerLabelsWaveEffectView!.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
            timerLabelsWaveEffectView!.heightAnchor.constraint(equalToConstant: timerLabelsStackView.bounds.height).isActive = true
            timerLabelsWaveEffectView!.widthAnchor.constraint(equalToConstant: timerLabelsStackView.bounds.width).isActive = true
            
            timerWaveEffectView!.bottomAnchor.constraint(equalTo: timerLabelsWaveEffectView!.topAnchor, constant: -6.0).isActive = true
            timerWaveEffectView!.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
            timerWaveEffectView!.heightAnchor.constraint(equalToConstant: timerStackView.bounds.height).isActive = true
            timerWaveEffectView!.widthAnchor.constraint(equalToConstant: timerStackView.bounds.width).isActive = true*/
            
            titleLabel.textColor = UIColor.lightText
            taglineLabel.textColor = UIColor.lightText
            inLabel.textColor = UIColor.lightText
            weeksLabel.textColor = UIColor.lightText
            weeksColon.textColor = UIColor.lightText
            daysLabel.textColor = UIColor.lightText
            daysColon.textColor = UIColor.lightText
            hoursLabel.textColor = UIColor.lightText
            hoursColon.textColor = UIColor.lightText
            minutesLabel.textColor = UIColor.lightText
            minutesColon.textColor = UIColor.lightText
            secondsLabel.textColor = UIColor.lightText
            
        case .imagePreviewControllerCell, .imagePreviewControllerDetail, .detailView:
            titleWaveEffectView?.removeFromSuperview()
            titleWaveEffectView = nil
            taglineWaveEffectView?.removeFromSuperview()
            taglineWaveEffectView = nil
            timerWaveEffectView?.removeFromSuperview()
            timerWaveEffectView = nil
            timerLabelsWaveEffectView?.removeFromSuperview()
            timerLabelsWaveEffectView = nil
            
            if configuration == .imagePreviewControllerCell || configuration == .imagePreviewControllerDetail {
                titleLabel.removeFromSuperview()
                taglineLabel.removeFromSuperview()
                timerContainerView.removeFromSuperview()
                abridgedTimerContainerView.removeFromSuperview()
            }
        }
    }*/
    
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
        mediumLabels = [taglineLabel, abridgedWeeksLabel, abridgedDaysLabel, weeksLabel, daysLabel, hoursLabel, minutesLabel, secondsLabel]
        lowLabels = [abridgedInLabel, abridgedWeeksTextLabel, abridgedDaysTextLabel, inLabel, weeksColon, daysColon, hoursColon, minutesColon, agoLabel, weeksTextLabel!, daysTextLabel!, hoursTextLabel!, minutesTextLabel!, secondsTextLabel!]
        initializeShadows(for: highLabels, withShadowRadius: 3.0)
        initializeShadows(for: mediumLabels, withShadowRadius: 2.0)
        initializeShadows(for: lowLabels, withShadowRadius: 1.0)
        shadowsInitialized = true
    }
    
    fileprivate func hide(view: UIView) {view.isHidden = true; view.isUserInteractionEnabled = false}
    fileprivate func show(view: UIView) {view.isHidden = false; view.isUserInteractionEnabled = true}
    
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
    
    fileprivate func fadeIn(view: UIView) {
        view.isHidden = false
        view.isUserInteractionEnabled = true
        
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.3,
            delay: 0.0,
            options: [.curveLinear],
            animations: {view.layer.opacity = 1.0},
            completion: nil
        )
    }
    
    /*fileprivate func fadeOut(view: UIView) {
        let duration = 0.3
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: duration,
            delay: 0.0,
            options: [.curveLinear],
            animations: {view.layer.opacity = 0.0},
            completion: {(position) in
                switch position {
                case .end:
                    Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                        view.isHidden = true; view.isUserInteractionEnabled = false
                    }
                default: fatalError("...")
                }
            }
        )
    }*/
    
    fileprivate func transitionText(inLabel label: UILabel, toText text: String) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.15,
            delay: 0.0,
            options: [.curveLinear],
            animations: {label.layer.opacity = 0.0},
            completion: { (position) in
                label.text = text
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.15,
                    delay: 0.0,
                    options: [.curveLinear],
                    animations: {label.layer.opacity = 1.0},
                    completion: nil
                )
            }
        )
    }
}
