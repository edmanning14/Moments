//
//  EMContentExpandableMaterialDelegate.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/29/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

@objc protocol EMContentExpandableMaterialManagerDelegate: class {
    @objc optional func shouldSelectMaterial(_ material: EMContentExpandableMaterial) -> Bool
    @objc optional func shouldColapseMaterial(_ material: EMContentExpandableMaterial) -> Bool
}
