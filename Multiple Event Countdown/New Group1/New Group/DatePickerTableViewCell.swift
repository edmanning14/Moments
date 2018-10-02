//
//  DatePickerTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/6/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import os

class DatePickerTableViewCell: UITableViewCell {
    
    var title: String? {didSet {titleLabel.text = title}}
    
    var eventNotification: EventNotification? {
        didSet {
            if let notif = eventNotification {
                typeButton.setTitle(notif.type.stringEquivalent, for: .normal)
                switch notif.type {
                case .afterEvent, .beforeEvent:
                    if notif.components?.month == nil && notif.components?.day == nil && notif.components?.hour == nil && notif.components?.minute == nil && notif.components?.second == nil {
                        os_log("dateComponents was nil for cell %@", log: .default, type: .error, title ?? "Nil")
                        digitButton.setTitle("1", for: .normal)
                        precisionButton.setTitle("Day", for: .normal)
                    }
                    else if let months = notif.components?.month {
                        digitButton.setTitle(String(months), for: .normal)
                        if months == 1 {precisionButton.setTitle("Month", for: .normal)}
                        else {precisionButton.setTitle("Months", for: .normal)}
                    }
                    if let days = notif.components?.day {
                        digitButton.setTitle(String(days), for: .normal)
                        if days == 1 {precisionButton.setTitle("Day", for: .normal)}
                        else {precisionButton.setTitle("Days", for: .normal)}
                    }
                    if let hours = notif.components?.hour {
                        digitButton.setTitle(String(hours), for: .normal)
                        if hours == 1 {precisionButton.setTitle("Hour", for: .normal)}
                        else {precisionButton.setTitle("Hours", for: .normal)}
                    }
                    if let minutes = notif.components?.minute {
                        digitButton.setTitle(String(minutes), for: .normal)
                        if minutes == 1 {precisionButton.setTitle("Minute", for: .normal)}
                        else {precisionButton.setTitle("Minutes", for: .normal)}
                    }
                    if let seconds = notif.components?.second {
                        digitButton.setTitle(String(seconds), for: .normal)
                        if seconds == 1 {precisionButton.setTitle("Second", for: .normal)}
                        else {precisionButton.setTitle("Seconds", for: .normal)}
                    }
                    
                    if digitButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.digitButton.isHidden = false},
                            completion: nil
                        )
                    }
                    if precisionButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.precisionButton.isHidden = false},
                            completion: nil
                        )
                    }
                    
                case .dayOfEvent:
                    if notif.components?.hour == nil {
                        os_log("Hour dateComponents was nil for cell %@", log: .default, type: .error, title ?? "Nil")
                        eventNotification?.components?.hour = 9
                        if notif.components?.minute == nil {
                            os_log("minute dateComponents was nil for cell %@", log: .default, type: .error, title ?? "Nil")
                            eventNotification?.components?.minute = 0
                        }
                    }
                    
                    eventNotification?.components?.second = 0
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .none
                    dateFormatter.timeStyle = .short
                    
                    let dateComponentsOfInterest: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
                    var todaysDateComponents = Calendar.current.dateComponents(dateComponentsOfInterest, from: Date())
                    todaysDateComponents.hour = eventNotification?.components?.hour
                    todaysDateComponents.minute = eventNotification?.components?.minute
                    
                    let stringDate = dateFormatter.string(from: Calendar.current.date(from: todaysDateComponents)!)
                    digitButton.setTitle(stringDate, for: .normal)
                    
                    if digitButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.digitButton.isHidden = false},
                            completion: nil
                        )
                    }
                    if !precisionButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.precisionButton.isHidden = true},
                            completion: nil
                        )
                    }
                    
                case .timeOfEvent:
                    if !digitButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.digitButton.isHidden = true},
                            completion: nil
                        )
                    }
                    if !precisionButton.isHidden {
                        UIViewPropertyAnimator.runningPropertyAnimator(
                            withDuration: 0.15,
                            delay: 0.0,
                            options: .curveEaseOut,
                            animations: {self.precisionButton.isHidden = true},
                            completion: nil
                        )
                    }
                }
            }
        }
    }
    
    static var collapsedHeight: CGFloat = 44 // Labelheight + top margin + bottom margin + 8
    static var expandedHeight: CGFloat = DatePickerTableViewCell.collapsedHeight + 88 // + PickerView Height + corner radius for some reason.
    
    // MARK: GUI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var digitButton: UIButton!
    @IBOutlet weak var precisionButton: UIButton!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func awakeFromNib() {super.awakeFromNib()}

}
