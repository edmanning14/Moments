//
//  EventDate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/21/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

open struct EventDate {
    
    var date: Date
    var dateOnly: Bool
    
    init() {date = Date(); dateOnly = true}
    init(date aDate: Date, dateOnly aDateOnly: Bool) {date = aDate; dateOnly = aDateOnly}
}

open class EventImage {
    let title: String
    let uiImage: UIImage
    lazy var cgImage: cgImage? {return uiImage.cgImage}
    let category: String
    var associatedTraceImage: EventImage?
    let isTraceImage: Bool
    
    init(title aTitle: String, image aImage: UIImage, category aCategory: String, associatedTraceImage: EventImage?, isTraceImage: Bool) {
        self.title = aTitle
        self.uiImage = aImage
        self.category = aCategory
        self.associatedTraceImage = associatedTraceImage
        self.isTraceImage = isTraceImage
    }
    
    convenience init(title aTitle: String, image aImage: CGImage, category aCategory: String, associatedTraceImage: EventImage?, isTraceImage: Bool) {
        self.title = aTitle
        self.uiImage = UIImage(cgImage: aImage)
        self.category = aCategory
        self.associatedTraceImage = associatedTraceImage
        self.isTraceImage = isTraceImage
    }
    
    convenience init(title aTitle: String, image aImage: UIImage, category aCategory: String) {
        self.title = aTitle
        self.uiImage = aImage
        self.category = aCategory
        self.associatedTraceImage = nil
        self.isTraceImage = true
    }
}

/*struct EventImageSet {
    
    var originalImage: EventImage
    var traceImage: EventImage?
    
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
}*/
