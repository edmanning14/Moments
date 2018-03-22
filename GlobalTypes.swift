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

/*public struct EventDate {
    
    var date: Date
    var dateOnly: Bool
    
    init() {date = Date(); dateOnly = true}
    init(date aDate: Date, dateOnly aDateOnly: Bool) {date = aDate; dateOnly = aDateOnly}
}*/

/* open class EventImage {
    let title: String
    let uiImage: UIImage
    var cgImage: CGImage? {return uiImage.cgImage}
    let category: String
    var usingOverlayImage: EventImage?
    let isTraceImage: Bool
    
    init(title aTitle: String, image aImage: UIImage, category aCategory: String, associatedTraceImage: EventImage?, isTraceImage: Bool) {
        self.title = aTitle
        self.uiImage = aImage
        self.category = aCategory
        self.usingOverlayImage = associatedTraceImage
        self.isTraceImage = isTraceImage
    }
    
    convenience init(title aTitle: String, image aImage: CGImage, category aCategory: String, associatedTraceImage: EventImage?, isTraceImage: Bool) {
        
        let uiImage = UIImage(cgImage: aImage)
        self.init(
            title: aTitle,
            image: uiImage,
            category: aCategory,
            associatedTraceImage: associatedTraceImage,
            isTraceImage: isTraceImage
        )
    }
    
    convenience init(title aTitle: String, image aImage: UIImage, category aCategory: String) {
        self.init(
            title: aTitle,
            image: aImage,
            category: aCategory,
            associatedTraceImage: nil,
            isTraceImage: true
        )
    }
    
    convenience init(title aTitle: String, image aImage: CGImage, category aCategory: String) {
        self.init(
            title: aTitle,
            image: aImage,
            category: aCategory,
            associatedTraceImage: nil,
            isTraceImage: true)
    }
} */
