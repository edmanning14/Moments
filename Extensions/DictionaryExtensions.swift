//
//  DictionaryExtensions.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/22/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

extension Dictionary where Value: Equatable {
    func firstKey(forValue value: Value) -> Key? {
        return first(where: { $1 == value })?.key
    }
}
