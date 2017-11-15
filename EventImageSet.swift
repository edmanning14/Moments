//
//  EventImageSet.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/14/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import Foundation
import UIKit

struct EventImageSet {
    
    var originalImage: CGImage?
    var traceImage: CGImage?
    
    var containedImages: packageContents {
        if originalImage == nil && traceImage == nil {return .none}
        else if originalImage != nil && traceImage == nil {return .originalOnly}
        else if originalImage == nil && traceImage != nil {return .traceOnly}
        else {return .originalAndTrace}
    }
    
    enum packageContents {
        case none
        case originalOnly
        case traceOnly
        case originalAndTrace
    }
    
    init() {originalImage = nil; traceImage = nil}
    
    init(originalImage aOriginalImage: CGImage?, traceImage aTraceImage: CGImage?) {
        originalImage = aOriginalImage
        traceImage = aTraceImage
    }
}
