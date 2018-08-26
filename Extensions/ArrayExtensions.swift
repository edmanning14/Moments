//
//  ArrayExtensions.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/23/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

extension Array {
    mutating func removeAfter(index: Array.Index) -> [Element] {
        guard index < self.count - 1 else {return [Element]()}
        var elementsToReturn = [Element]()
        var lastEntryIndex = self.endIndex - 1
        while lastEntryIndex != index {
            elementsToReturn.append(self.removeLast())
            lastEntryIndex = self.endIndex - 1
        }
        return elementsToReturn
    }
    
    func removedAfter(index: Array.Index) -> [Element] {
        guard index < self.count - 1 else {return self}
        var elementsToReturn = [Element]()
        var currentIndex = 0
        while currentIndex <= index {
            elementsToReturn.append(self[currentIndex])
            currentIndex += 1
        }
        return elementsToReturn
    }
}
