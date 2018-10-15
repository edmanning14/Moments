//
//  EMContentExpandableMaterialDelegate.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 9/3/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation

protocol EMContentExpandableMaterialDelegate: class {
    func colapseButtonTapped(forMaterial material: EMContentExpandableMaterial)
    func contentViewChanged(forMaterial material: EMContentExpandableMaterial)
}
