//
//  CGSizeExtensions.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/20/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGSize: Comparable {
    public static func <(lhs: CGSize, rhs: CGSize) -> Bool {
        if lhs.width < rhs.width || lhs.height < rhs.height {return true}
        else {return false}
    }
    
    public static func ==(lhs: CGSize, rhs: CGSize) -> Bool {
        if lhs.width == rhs.width && rhs.height == lhs.height {return true}
        else {return false}
    }
}
