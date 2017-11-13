//
//  EventTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/23/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {

    //
    // MARK: - Variables and Constants
    //
    
    // Data Model
    var eventTitle: String? {didSet {testLabel.text = eventTitle ?? "New Event"}}
    var eventDate: Date? {
        didSet {
            if eventDate == nil {
                timeRemainingGradientLayer = nil
                let blackMask = CALayer()
                blackMask.frame = backgroundImageView.bounds
                blackMask.backgroundColor = UIColor.black.cgColor
                backgroundImageView.layer.addSublayer(blackMask)
            }
            else {
                if timeRemainingGradientLayer == nil {
                    timeRemainingGradientLayer = CAGradientLayer()
                    timeRemainingGradientLayer!.frame = backgroundImageView.bounds
                    timeRemainingGradientLayer!.startPoint = CGPoint(x: 0.0, y: 0.5)
                    timeRemainingGradientLayer!.endPoint = CGPoint(x: 1.0, y: 0.5)
                    timeRemainingGradientLayer!.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
                    timeRemainingGradientLayer!.locations = [NSNumber(value: 0.0),NSNumber(value: 0.0)]
                    backgroundImageView.layer.addSublayer(timeRemainingGradientLayer!)
                }
                else {
                    timeRemainingGradientLayer!.frame = backgroundImageView.bounds
                    timeRemainingGradientLayer!.startPoint = CGPoint(x: 0.0, y: 0.5)
                    timeRemainingGradientLayer!.endPoint = CGPoint(x: 1.0, y: 0.5)
                    timeRemainingGradientLayer!.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.cgColor]
                    timeRemainingGradientLayer!.locations = [NSNumber(value: 0.0),NSNumber(value: 0.0)]
                }
            }
        }
    }
    
    // References and Outlets
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var testLabel: UILabel!
    var timeRemainingGradientLayer: CAGradientLayer?
    
    
    //
    // MARK: - Cell Lifecylce
    //
    
    override func awakeFromNib() {super.awakeFromNib()}
    override func setSelected(_ selected: Bool, animated: Bool) {super.setSelected(selected, animated: animated)}
    
    
    //
    // MARK: - Instance Methods
    //
    
    internal func Update() {
        let currentDate = Date()
        if let timeInterval = eventDate?.timeIntervalSince(currentDate){
            if timeInterval > 0.0 {
                let formattedTimeInterval = FormatInterval(interval: timeInterval)
            }
        }
    }

}
