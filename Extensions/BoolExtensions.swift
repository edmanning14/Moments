//
//  BoolExtensions.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/13/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

extension Bool {
    var rawValue: Int {if self {return 1}; return 0}
}
