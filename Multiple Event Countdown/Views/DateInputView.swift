//
//  DateInputView.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/21/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class DateInputView: UIView {

    
    //
    // MARK: - Parameters
    //
    
    // Data Model
    var eventDate: EventDate {
        var eventDateToReturn = EventDate()
        switch mutableDatePicker.datePickerMode {
        case .date:
            if timeHolder == nil {
                eventDateToReturn.date = mutableDatePicker.date
                eventDateToReturn.dateOnly = true
                return eventDateToReturn
            }
            
            let selectedTime = timeHolder!.timeIntervalSinceReferenceDate
            let days = (selectedTime/86400.0).rounded(.down)
            let timeIntervalFromMidnight = selectedTime - (days * 86400.0)
            
            var selectedDate = mutableDatePicker.date.timeIntervalSinceReferenceDate
            let days2 = (selectedDate/86400.0).rounded(.down)
            let timeIntervalFromMidnight2 = selectedDate - (days2 * 86400.0)
            selectedDate -= timeIntervalFromMidnight2
            
            let newDate = Date(timeIntervalSinceReferenceDate: timeIntervalFromMidnight + selectedDate)
            
            eventDateToReturn.date = newDate
            eventDateToReturn.dateOnly = false
            
            return eventDateToReturn
            
        case .time:
            let selectedTime = mutableDatePicker.date.timeIntervalSinceReferenceDate
            let days = (selectedTime/86400.0).rounded(.down)
            let timeIntervalFromMidnight = selectedTime - (days * 86400.0)
            
            var selectedDate = calendarDayHolder!.timeIntervalSinceReferenceDate
            let days2 = (selectedDate/86400.0).rounded(.down)
            let timeIntervalFromMidnight2 = selectedDate - (days2 * 86400.0)
            selectedDate -= timeIntervalFromMidnight2
            
            let newDate = Date(timeIntervalSinceReferenceDate: timeIntervalFromMidnight + selectedDate)
            
            eventDateToReturn.date = newDate
            eventDateToReturn.dateOnly = false
            
            return eventDateToReturn
        default: // Should never happen
            return eventDateToReturn
        }
    }
    
    var calendarDayHolder: Date?
    var timeHolder: Date?
    
    // Other
    var delegate: Any?
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    
    // UI Items
    @IBOutlet weak var aStackView: UIStackView!
    @IBOutlet weak var selectDateButton: UIButton!
    @IBOutlet weak var mutableDatePicker: UIDatePicker!
    var cancelSetTimeButton: UIButton?
    
    
    //
    // MARK: - View Lifecycle
    //
    
    override func awakeFromNib() {
        self.sizeToFit()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        selectDateButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
    }
    
    
    //
    // MARK: - Target-Action Functions
    //
    
    @objc fileprivate func buttonPressed(_ sender: UIButton?) -> Void {
        if let button = sender {
            if button == selectDateButton {
                switch mutableDatePicker.datePickerMode {
                case .date:
                    calendarDayHolder = mutableDatePicker.date
                    button.isSelected = true
                    button.setTitle(dateFormatter.string(from: calendarDayHolder!), for: UIControlState.selected)
                    mutableDatePicker.datePickerMode = .time
                    mutableDatePicker.date = timeHolder ?? Date()
                    if cancelSetTimeButton == nil {initializeCancelSetTimeButton()}
                    if !cancelSetTimeButton!.isDescendant(of: aStackView) {
                        aStackView.addArrangedSubview(cancelSetTimeButton!)
                        aStackView.sizeToFit()
                    }
                case .time:
                    timeHolder = mutableDatePicker.date
                    button.setTitle(timeFormatter.string(from: timeHolder!), for: UIControlState.selected)
                    mutableDatePicker.datePickerMode = .date
                    mutableDatePicker.date = calendarDayHolder ?? Date()
                default: // Should never happen
                    mutableDatePicker.datePickerMode = .date
                }
            }
            else if button == cancelSetTimeButton {
                timeHolder = nil
                selectDateButton.isSelected = false
                if mutableDatePicker.datePickerMode != .date {
                    mutableDatePicker.datePickerMode = .date
                    mutableDatePicker.date = calendarDayHolder ?? Date()
                }
                cancelSetTimeButton!.removeFromSuperview()
                aStackView.sizeToFit()
            }
        }
    }
    
    
    //
    // MARK: - Helper Functions
    //
    
    fileprivate func initializeCancelSetTimeButton() -> Void {
        cancelSetTimeButton = UIButton(type: .system)
        cancelSetTimeButton!.setTitle("Clear Time", for: UIControlState.normal)
        cancelSetTimeButton!.sizeToFit()
        cancelSetTimeButton!.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        cancelSetTimeButton!.titleLabel!.font = UIFont(name: "FiraSans-Light", size: 18.0)
        cancelSetTimeButton?.titleLabel!.textColor = UIColor.black
    }
}
