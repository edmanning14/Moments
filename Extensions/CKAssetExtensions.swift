//
//  CKAssetExtensions.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/26/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

extension CKAsset {
    var uiImage: UIImage? {
        do {
            let data = try Data(contentsOf: self.fileURL)
            if let image = UIImage(data: data) {return image} else {return nil}
        }
        catch {return nil}
    }
}
