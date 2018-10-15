//
//  CountdownImageDelegate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/28/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

protocol CountdownImageDelegate: class {
    func fetchComplete(forImageTypes: [CountdownImage.ImageType], success: [Bool])
}
