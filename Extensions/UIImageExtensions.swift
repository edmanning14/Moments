//
//  UIImageExtensions.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 6/13/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    var imageRect: CGRect? {
        guard self.contentMode == .scaleAspectFit else {return nil}
        
        let imageViewSize = self.frame.size
        let imgSize = self.image?.size
        
        guard let imageSize = imgSize else {return nil}
        
        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)
        
        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2
        
        // Add imageView offset
        imageRect.origin.x += self.frame.origin.x
        imageRect.origin.y += self.frame.origin.y
        
        return imageRect
    }
}
