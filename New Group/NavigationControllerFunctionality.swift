//
//  NavigationBarItems.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/28/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

enum BarSides {case left, right}

protocol NavigationControllerFunctionality where Self: UIViewController {
    var standardFont: UIFont {get}
    var standardColor: UIColor {get}
    
    func configureBarTitleAttributes()
    func addBackButton(action: Selector, title: String?, target: Any?) -> UIBarButtonItem
    func addBarButtonItem(side: BarSides, action: Selector, target: AnyObject?, title: String?, image: UIImage?) -> UIBarButtonItem
}

extension NavigationControllerFunctionality {
    var standardFont: UIFont {return UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)!}
    var standardColor: UIColor {return GlobalColors.orangeDark}
    
    func configureBarTitleAttributes() {
        if let navBar = navigationController?.navigationBar {

            navBar.titleTextAttributes = [
                .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 18.0) as Any,
                .foregroundColor: GlobalColors.orangeRegular
            ]
            
            if #available(iOS 11, *) {
                navigationController?.navigationBar.largeTitleTextAttributes = [
                    .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0) as Any,
                    .foregroundColor: GlobalColors.orangeRegular
                ]
                navBar.isTranslucent = false
            }
        }
    }
    
    func addBackButton(action: Selector, title: String?, target: Any?) -> UIBarButtonItem {
        
        let backButton = UIButton()
        backButton.tintColor = standardColor
        backButton.titleLabel?.font = standardFont
        backButton.setTitleColor(standardColor, for: .normal)
        backButton.imageEdgeInsets.left = -10.0
        backButton.setImage(#imageLiteral(resourceName: "BackButton"), for: .normal)
        backButton.setTitle(title ?? "BACK", for: .normal)
        backButton.addTarget(target, action: action, for: .touchUpInside)
        backButton.sizeToFit()
        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
        return backBarButtonItem
    }
    
    func addBarButtonItem(side: BarSides, action: Selector, target: AnyObject?, title: String?, image: UIImage?) -> UIBarButtonItem {
        
        let barButtonItem = UIBarButtonItem()
        barButtonItem.action = action
        barButtonItem.target = target
        barButtonItem.tintColor = standardColor
        
        if let aImage = image {barButtonItem.image = aImage}
        else {
            barButtonItem.title = title ?? "BUTTON"
            let attributes: [NSAttributedStringKey: Any] = [.font: standardFont as Any]
            barButtonItem.setTitleTextAttributes(attributes, for: .normal)
            barButtonItem.setTitleTextAttributes(attributes, for: .disabled)
        }
        
        switch side {
        case .left: navigationItem.leftBarButtonItem = barButtonItem
        case .right: navigationItem.rightBarButtonItem = barButtonItem
        }
        
        return barButtonItem
    }
}

extension UIViewController: NavigationControllerFunctionality {
    var standardFont: UIFont {return UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)!}
    var standardColor: UIColor {return GlobalColors.orangeDark}
    
    func configureBarTitleAttributes() {
        if let navBar = navigationController?.navigationBar {
            
            navBar.titleTextAttributes = [
                .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 18.0) as Any,
                .foregroundColor: GlobalColors.orangeRegular
            ]
            
            if #available(iOS 11, *) {
                navigationController?.navigationBar.largeTitleTextAttributes = [
                    .font: UIFont(name: GlobalFontNames.ComfortaaLight, size: 30.0) as Any,
                    .foregroundColor: GlobalColors.orangeRegular
                ]
                navBar.isTranslucent = false
            }
        }
    }
    
    func addBackButton(action: Selector, title: String?, target: Any?) -> UIBarButtonItem {
        
        let backButton = UIButton()
        backButton.tintColor = standardColor
        backButton.titleLabel?.font = standardFont
        backButton.setTitleColor(standardColor, for: .normal)
        backButton.imageEdgeInsets.left = -10.0
        backButton.setImage(#imageLiteral(resourceName: "BackButton"), for: .normal)
        backButton.setTitle(title ?? "BACK", for: .normal)
        backButton.addTarget(target, action: action, for: .touchUpInside)
        backButton.sizeToFit()
        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem
        return backBarButtonItem
    }
    
    func addBarButtonItem(side: BarSides, action: Selector, target: AnyObject?, title: String?, image: UIImage?) -> UIBarButtonItem {
        
        let barButtonItem = UIBarButtonItem()
        barButtonItem.action = action
        barButtonItem.target = target
        barButtonItem.tintColor = standardColor
        
        if let aImage = image {barButtonItem.image = aImage}
        else {
            barButtonItem.title = title ?? "BUTTON"
            let attributes: [NSAttributedStringKey: Any] = [.font: standardFont as Any]
            barButtonItem.setTitleTextAttributes(attributes, for: .normal)
            barButtonItem.setTitleTextAttributes(attributes, for: .disabled)
        }
        
        switch side {
        case .left: navigationItem.leftBarButtonItem = barButtonItem
        case .right: navigationItem.rightBarButtonItem = barButtonItem
        }
        
        return barButtonItem
    }
    
    @objc func defaultPop() {if let navigationController = self.navigationController {navigationController.popViewController(animated: true)}}
}
