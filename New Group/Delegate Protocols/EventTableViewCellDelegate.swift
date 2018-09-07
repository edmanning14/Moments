//
//  EventTableViewCellDelegate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 7/15/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

protocol EventTableViewCellDelegate {
    func eventDateRepeatTriggered(cell: EventTableViewCell, newDate: EventDate)
}
