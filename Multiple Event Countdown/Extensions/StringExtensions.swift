//
//  StringExtensions.swift
//  
//
//  Created by Ed Manning on 1/12/18.
//

import Foundation

extension String {
    func removeCharsFromEnd(numberToRemove num: Int) -> String {
        if num == 0 {return self}
        else if num == 1 {
            var stringToReturn = ""
            stringToReturn = self
            stringToReturn.removeLast()
            return stringToReturn
        }
        else {return removeCharsFromEnd(numberToRemove: num - 1)}
    }
    
    func index(_ i: String.Index, insetBy num: Int) -> String.Index {
        if num == 0 {return i}
        else if num == 1 {return self.index(before: i)}
        else {return index(_: i, insetBy: num - 1)}
    }
}
