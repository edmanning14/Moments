//
//  ImageHandlerDelegate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/25/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import Foundation

@objc protocol ImageHandlerDelegate {
    @objc optional func cloudLoadBegan() -> Void
    @objc optional func cloudLoadEnded(imagesLoaded: Bool, error: Error?) -> Void
}
