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
            if configuration != .newEventsController {updateShadow(for: titleLabel)}
            if eventTitle != nil {
                if titleLabel.isHidden {
                    show(view: titleLabel)
                    if titleWaveEffectView != nil {hide(view: titleWaveEffectView!)}
                }
                titleLabel.text = eventTitle
            }
            else {
                if !titleLabel.isHidden {
                    hide(view: titleLabel)
                    if titleWaveEffectView != nil {show(view: titleWaveEffectView!)}
                }
            }
        }
    }
    
    var eventTagline: String? {
        didSet{
            if !shadowsInitialized {initializeShadows()}
            if configuration != .newEventsController {updateShadow(for: taglineLabel)}
            if eventTagline != nil {
                if taglineLabel.isHidden {
                    show(view: taglineLabel)
                    if taglineWaveEffectView != nil {hide(view: taglineWaveEffectView!)}
                }
                taglineLabel.text = eventTagline
            }
            else {
                if !taglineLabel.isHidden {
                    hide(view: taglineLabel)
                    if taglineWaveEffectView != nil {show(view: taglineWaveEffectView!)}
                }
            }
        }
    }
    
    var eventDate: EventDate? {
        didSet {
            if !shadowsInitialized {initializeShadows()}
            if eventDate != nil {
                if eventDate!.dateOnly {
                    if abridgedTimerContainerView.isHidden {
                        show(view: abridgedTimerContainerView)
                        if !timerContainerView.isHidden {hide(view: timerContainerView)}
                        if timerWaveEffectView != nil {hide(view: timerWaveEffectView!)}
                        if timerLabelsWaveEffectView != nil {hide(view: timerLabelsWaveEffectView!)}
                    }
                    updateShadow(for: abridgedTimerContainerView)
                }
                else {
                    if timerContainerView.isHidden {
                        show(view: timerContainerView)
                        if !abridgedTimerContainerView.isHidden {hide(view: abridgedTimerContainerView)}
                        if timerWaveEffectView != nil {hide(view: timerWaveEffectView!)}
                        if timerLabelsWaveEffectView != nil {hide(view: timerLabelsWaveEffectView!)}
                    }
                    updateShadow(for: timerContainerView)
                }
                update()
            }
            else {
                if !timerContainerView.isHidden {hide(view: timerContainerView)}
                if !abridgedTimerContainerView.isHidden {hide(view: abridgedTimerContainerView)}
                if timerWaveEffectView != nil {show(view: timerWaveEffectView!)}
                if timerLabelsWaveEffectView != nil {show(view: timerLabelsWaveEffectView!)}
            }
        }
    }
    
    var creationDate: Date? {didSet {updateMask()}}
    
    var eventImage: EventImage? {
        didSet {
            if eventImage == nil {
                backgroundColor = UIColor.black
                maskImageView = nil
                mainImageView = nil
            }
            else {
                if eventImage?.mainImage?.cgImage != nil {
                    if mainImageView == nil {
                        switch configuration {
                        case .imagePreviewControllerCell, .newEventsController, .tableView:
                            mainImageView = CountdownMainImageView(frame: self.bounds, image: eventImage!.mainImage!.cgImage!, locationForCellView: eventImage!.locationForCellView, displayMode: .cell)
                        case .imagePreviewControllerDetail, .detailView:
                            mainImageView = CountdownMainImageView(frame: self.bounds, image: eventImage!.mainImage!.cgImage!, locationForCellView: eventImage!.locationForCellView, displayMode: .detail)
                        }
                    }
                    else {
                        mainImageView!.image = eventImage!.mainImage!.cgImage!
                        mainImageView!.locationForCellView = eventImage!.locationForCellView
                    }
                    mainImageView!.translatesAutoresizingMaskIntoConstraints = false
                    insertSubview(mainImageView!, at: 0)
                    topAnchor.constraint(equalTo: mainImageView!.topAnchor).isActive = true
                    rightAnchor.constraint(equalTo: mainImageView!.rightAnchor).isActive = true
                    bottomAnchor.constraint(equalTo: mainImageView!.bottomAnchor).isActive = true
                    leftAnchor.constraint(equalTo: mainImageView!.leftAnchor).isActive = true
                    
                    if eventImage?.maskImage?.cgImage != nil && useGradient {
                        if gradientView == nil {
                            gradientView = GradientMaskView(frame: self.bounds)
                            gradientView!.translatesAutoresizingMaskIntoConstraints = false
                            mainImageView!.addSubview(gradientView!)
                            gradientView!.backgroundColor = UIColor.clear
                            mainImageView!.topAnchor.constraint(equalTo: gradientView!.topAnchor).isActive = true
                            mainImageView!.rightAnchor.constraint(equalTo: gradientView!.rightAnchor).isActive = true
                            mainImageView!.bottomAnchor.constraint(equalTo: gradientView!.bottomAnchor).isActive = true
                            mainImageView!.leftAnchor.constraint(equalTo: gradientView!.leftAnchor).isActive = true
                        }
                        
                        if maskImageView == nil {
                            maskImageView = CountdownMaskImageView(frame: self.bounds, image: eventImage!.maskImage!.cgImage!, locationForCellView: eventImage!.locationForCellView)
                            maskImageView!.translatesAutoresizingMaskIntoConstraints = false
                            gradientView!.addSubview(maskImageView!)
                            maskImageView!.backgroundColor = UIColor.clear
                            gradientView!.topAnchor.constraint(equalTo: maskImageView!.topAnchor).isActive = true
                            gradientView!.rightAnchor.constraint(equalTo: maskImageView!.rightAnchor).isActive = true
                            gradientView!.bottomAnchor.constraint(equalTo: maskImageView!.bottomAnchor).isActive = true
                            gradientView!.leftAnchor.constraint(equalTo: maskImageView!.leftAnchor).isActive = true
                        }
                        else {
                            maskImageView!.image = eventImage!.maskImage!.cgImage!
                            maskImageView!.locationForCellView = eventImage!.locationForCellView
                        }
                    }
                    else {gradientView = nil; maskImageView = nil}
                }
            }
        }
    }
    
    //
    // MARK: States
    enum Configurations {case tableView, detailView, newEventsController, imagePreviewControllerCell, imagePreviewControllerDetail}
    //enum TimerStates: Int {case weeks = 0, days, hours, minutes, seconds}
    /*func label(forState state: TimerStates) -> UILabel {
        switch state {
        case .weeks: return weeksLabel
        case .days: return daysLabel
        case .hours: return hoursLabel
        case .minutes: return minutesLabel
        case .seconds: return secondsLabel
        }
    }*/
    
    var configuration: Configurations = .tableView {didSet {if configuration != oldValue {configureView()}}}
    /*var currentTimerState: TimerStates = .weeks {
        didSet {
            if currentTimerState != oldValue { // Remove subviews
                if currentTimerState.rawValue > oldValue.rawValue {
                    for i in oldValue.rawValue..<currentTimerState.rawValue {
                        timerStackView.removeArrangedSubview(label(forState: TimerStates(rawValue: i)!))
                    }
                }
                else { // Add subviews
                    for i in currentTimerState.rawValue...oldValue.rawValue {
                        timerStackView.addArrangedSubview(label(forState: TimerStates(rawValue: i)!))
                    }
                }
            }
        }
    }*/
    
    var oldPercentCompletion = 0
    
    
    //
    // MARK: Flags
    var useGradient = true
    fileprivate var isPastEvent = false {
        didSet {
            if isPastEvent && oldValue == !isPastEvent {
                hide(view: inLabel); show(view: agoLabel)
                hide(view: abridgedInLabel); abridgedDaysTextLabel.text = "Days Ago"
            }
            else if !isPastEvent && oldValue == isPastEvent {
                show(view: inLabel); hide(view: agoLabel)
                show(view: abridgedInLabel); abridgedDaysTextLabel.text = "Days"
            }
        }
    }
    fileprivate var shadowsInitialized = false
    
    //
    // MARK: Constants
    fileprivate let sizeOfGradientArea: CGFloat = 0.15
    
    
    // MARK: UI Elements
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
    
    @IBOutlet weak var abridgedTimerContainerView: UIView!
    @IBOutlet weak var abridgedTimerStackView: UIStackView!
    @IBOutlet weak var abridgedInLabel: UILabel!
    @IBOutlet weak var abridgedWeeksLabel: UILabel!
    @IBOutlet weak var abridgedDaysLabel: UILabel!
    @IBOutlet weak var abridgedWeeksTextLabel: UILabel!
    @IBOutlet weak var abridgedDaysTextLabel: UILabel!
    
    var titleWaveEffectView: WaveEffectView?
    var taglineWaveEffectView: WaveEffectView?
    var timerWaveEffectView: WaveEffectView?
    var timerLabelsWaveEffectView: WaveEffectView?
    
    fileprivate var mainImageView: CountdownMainImageView?
    fileprivate var gradientView: GradientMaskView?
    fileprivate var maskImageView: CountdownMaskImageView?
    
    
    //
    // MARK: - Cell Lifecycle
    //
    
    override func draw(_ rect: CGRect) {
        switch configuration {
        case .imagePreviewControllerDetail, .imagePreviewControllerCell: break
        default:
            if !shadowsInitialized {initializeShadows()}
            if !titleLabel.isEnabled {updateShadow(for: titleLabel)}
            if !taglineLabel.isHidden {updateShadow(for: taglineLabel)}
            if !timerContainerView.isHidden {updateShadow(for: timerContainerView)}
            if !abridgedTimerContainerView.isHidden {updateShadow(for: abridgedTimerContainerView)}
        }
    }
    
    
    //
    // MARK: - Instance Methods
    //
    
    // Function to update the displayed event times and masks.
    internal func update() {
        
        let now = Date()
        var timeInterval = eventDate!.date.timeIntervalSince(now)
        if timeInterval < 0.0 {
            isPastEvent = true
            timeInterval = now.timeIntervalSince(eventDate!.date)
        }
        else {isPastEvent = false}
        
        func format(label: UILabel, withNumber number: Double) {
            let intNumber = Int(number)
            if intNumber < 10 {label.text = "0" + String(intNumber)}
            else {label.text = String(intNumber)}
        }
        
        if eventDate!.dateOnly {
            let weeks = (timeInterval/604800.0).rounded(.down)
            if weeks == 0 {
                abridgedWeeksLabel.isHidden = true
                abridgedWeeksTextLabel.isHidden = true
            }
            else {
                abridgedWeeksLabel.isHidden = false
                abridgedWeeksTextLabel.isHidden = false
                format(label: abridgedWeeksLabel, withNumber: weeks)
            }
            
            let remainder = timeInterval - (weeks * 604800.0)
            var days = 0.0
            if !isPastEvent {days = (remainder/86400.0).rounded(.down)}
            else {days = (remainder/86400.0).rounded(.up)}
            if !isPastEvent && days == 1.0 && weeks == 0.0 {
                hide(view: abridgedTimerStackView)
                show(view: tomorrowLabel)
                tomorrowLabel.text = "Tomorrow!!!"
            }
            else if !isPastEvent && days == 0.0 && weeks == 0.0 {
                hide(view: abridgedTimerStackView)
                show(view: tomorrowLabel)
                tomorrowLabel.text = "Today!!!"
            }
            else if isPastEvent && days == 1.0 && weeks == 0.0 {
                hide(view: abridgedTimerStackView)
                show(view: tomorrowLabel)
                tomorrowLabel.text = "Yesterday"
            }
            else {
                hide(view: tomorrowLabel)
                show(view: abridgedTimerStackView)
                format(label: abridgedDaysLabel, withNumber: days)
            }
        }
        else {
            let weeks = (timeInterval/604800.0).rounded(.down)
            if weeks == 0 {
                weeksLabel.isHidden = true
                weeksTextLabel.isHidden = true
                weeksColon.isHidden = true
            }
            else {
                weeksLabel.isHidden = false
                weeksTextLabel.isHidden = false
                weeksColon.isHidden = false
                format(label: weeksLabel, withNumber: weeks)
            }
            
            var remainder = timeInterval - (weeks * 604800.0)
            let days = (remainder/86400.0).rounded(.down)
            if days == 0.0 && weeks == 0.0 {
                daysLabel.isHidden = true
                daysTextLabel.isHidden = true
                daysColon.isHidden = true
            }
            else {
                daysLabel.isHidden = false
                daysTextLabel.isHidden = false
                daysColon.isHidden = false
                format(label: daysLabel, withNumber: days)
            }
            
            remainder -= days * 86400.0
            let hours = (remainder/3600.0).rounded(.down)
            if hours == 0.0 && days == 0.0 && weeks == 0.0 {
                hoursLabel.isHidden = true
                hoursTextLabel.isHidden = true
                hoursColon.isHidden = true
            }
            else {
                hoursLabel.isHidden = false
                hoursTextLabel.isHidden = false
                hoursColon.isHidden = false
                format(label: hoursLabel, withNumber: hours)
            }
            
            remainder -= hours * 3600.0
            let minutes = (remainder/60.0).rounded(.down)
            if minutes == 0.0 && hours == 0.0 && days == 0.0 && weeks == 0.0 {
                minutesLabel.isHidden = true
                minutesTextLabel.isHidden = true
                minutesColon.isHidden = true
            }
            else {
                minutesLabel.isHidden = false
                minutesTextLabel.isHidden = false
                minutesColon.isHidden = false
                format(label: minutesLabel, withNumber: minutes)
            }
            
            remainder -= minutes * 60.0
            let seconds = remainder.rounded(.down)
            format(label: secondsLabel, withNumber: seconds)
        }
        
        updateMask()
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func updateMask() {
        if creationDate != nil {
            let percentCompletion = CGFloat(Date().timeIntervalSince(creationDate!) / eventDate!.date.timeIntervalSince(creationDate!))
            if Int(percentCompletion) != oldPercentCompletion {
                gradientView?.percentMaskCoverage = 1 / percentCompletion
                maskImageView?.percentMaskCoverage = 1 / percentCompletion
                oldPercentCompletion = Int(percentCompletion)
            }
        }
    }
    
    fileprivate func configureView() {
        switch configuration {
            
        case .tableView:
            titleWaveEffectView?.removeFromSuperview()
            titleWaveEffectView = nil
            taglineWaveEffectView?.removeFromSuperview()
            taglineWaveEffectView = nil
            timerWaveEffectView?.removeFromSuperview()
            timerWaveEffectView = nil
            timerLabelsWaveEffectView?.removeFromSuperview()
            timerLabelsWaveEffectView = nil
            
        case .detailView: fatalError("Add detail view implemetation!") // TODO: Add implementation.
            
        case .newEventsController:
            titleWaveEffectView = WaveEffectView()
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
            titleWaveEffectView!.widthAnchor.constraint(equalToConstant: titleLabel.frame.width / 3).isActive = true
            
            taglineWaveEffectView!.topAnchor.constraint(equalTo: titleWaveEffectView!.bottomAnchor, constant: 6.0).isActive = true
            taglineWaveEffectView!.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8.0).isActive = true
            taglineWaveEffectView!.heightAnchor.constraint(equalToConstant: taglineLabel.bounds.height).isActive = true
            taglineWaveEffectView!.widthAnchor.constraint(equalToConstant: taglineLabel.frame.width / 2).isActive = true
            
            timerLabelsWaveEffectView!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8.0).isActive = true
            timerLabelsWaveEffectView!.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
            timerLabelsWaveEffectView!.heightAnchor.constraint(equalToConstant: timerLabelsStackView.bounds.height).isActive = true
            timerLabelsWaveEffectView!.widthAnchor.constraint(equalToConstant: timerLabelsStackView.bounds.width).isActive = true
            
            timerWaveEffectView!.bottomAnchor.constraint(equalTo: timerLabelsWaveEffectView!.topAnchor, constant: -6.0).isActive = true
            timerWaveEffectView!.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
            timerWaveEffectView!.heightAnchor.constraint(equalToConstant: timerStackView.bounds.height).isActive = true
            timerWaveEffectView!.widthAnchor.constraint(equalToConstant: timerStackView.bounds.width).isActive = true
            
            if eventTitle != nil {hide(view: titleWaveEffectView!)} else {hide(view: titleLabel)}
            if eventTagline != nil {hide(view: taglineWaveEffectView!)} else {hide(view: taglineLabel)}
            if eventDate != nil {hide(view: timerWaveEffectView!); hide(view: timerLabelsWaveEffectView!)}
            else {hide(view: timerContainerView)}
            
        case .imagePreviewControllerCell, .imagePreviewControllerDetail:
            titleWaveEffectView?.removeFromSuperview()
            titleWaveEffectView = nil
            taglineWaveEffectView?.removeFromSuperview()
            taglineWaveEffectView = nil
            timerWaveEffectView?.removeFromSuperview()
            timerWaveEffectView = nil
            timerLabelsWaveEffectView?.removeFromSuperview()
            timerLabelsWaveEffectView = nil
            
            titleLabel.removeFromSuperview()
            taglineLabel.removeFromSuperview()
            timerContainerView.removeFromSuperview()
            abridgedTimerContainerView.removeFromSuperview()
        }
    }
    
    fileprivate func initializeShadows() {
        func initializeShadow(for view: UIView) {
            view.backgroundColor = .clear
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
            view.layer.shadowRadius = 3.0
            view.layer.shadowOpacity = 0.50
        }
        initializeShadow(for: titleLabel)
        initializeShadow(for: taglineLabel)
        initializeShadow(for: timerContainerView)
        initializeShadow(for: abridgedTimerContainerView)
        shadowsInitialized = true
    }
    
    func updateShadow(for view: UIView) {
        if !view.isHidden {
            view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: 3.0).cgPath
        }
    }
    
    fileprivate func hide(view: UIView) {view.isHidden = true; view.isUserInteractionEnabled = false}
    fileprivate func show(view: UIView) {view.isHidden = false; view.isUserInteractionEnabled = true}
}
