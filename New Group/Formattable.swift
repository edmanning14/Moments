//
//  Formatable.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 9/3/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

protocol Formattable {
    func largeHeadingFormat()
    func regularHeadingFormat()
    func offFormat()
    func onFormat()
    func regularFormat()
    func emphasisedFormat()
}

extension UILabel: Formattable {
    func largeHeadingFormat() {
        self.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0)
        self.textColor = GlobalColors.orangeRegular
    }
    func regularHeadingFormat() {
        self.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
        self.textColor = GlobalColors.orangeRegular
    }
    func offFormat() {
        self.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        self.textColor = GlobalColors.gray
    }
    func onFormat() {
        self.font = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
        self.textColor = GlobalColors.orangeRegular
    }
    func regularFormat() {
        self.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        self.textColor = GlobalColors.orangeRegular
    }
    func emphasisedFormat() {
        self.font = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
        self.textColor = GlobalColors.orangeDark
    }
}

extension UIButton: Formattable {
    func commonFormatting() {
        self.directionalLayoutMargins = standardDirectionalLayoutMargins
        self.contentEdgeInsets = UIEdgeInsets(top: standardDirectionalLayoutMargins.top, left: standardDirectionalLayoutMargins.leading, bottom: standardDirectionalLayoutMargins.bottom, right: standardDirectionalLayoutMargins.trailing)
        self.layer.cornerRadius = GlobalCornerRadii.material
        self.layer.borderWidth = 1.0
    }
    func largeHeadingFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0)
        self.setTitleColor(GlobalColors.orangeRegular, for: .normal)
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
    }
    func regularHeadingFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ComfortaaLight, size: 20.0)
        self.setTitleColor(GlobalColors.orangeRegular, for: .normal)
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
    }
    func offFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        self.setTitleColor(GlobalColors.orangeRegular, for: .normal)
        self.layer.borderColor = GlobalColors.gray.cgColor
    }
    func onFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
        self.setTitleColor(GlobalColors.orangeRegular, for: .normal)
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
    }
    func regularFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ralewayRegular, size: 16.0)
        self.setTitleColor(GlobalColors.orangeRegular, for: .normal)
        self.layer.borderColor = GlobalColors.orangeRegular.cgColor
    }
    func emphasisedFormat() {
        commonFormatting()
        self.titleLabel?.font = UIFont(name: GlobalFontNames.ralewaySemiBold, size: 16.0)
        self.setTitleColor(GlobalColors.orangeDark, for: .normal)
        self.layer.borderColor = GlobalColors.orangeDark.cgColor
    }
}
