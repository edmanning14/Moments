//
//  AppDelegate.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift
import Foundation

//
// MARK: Global Constants

// MARK: Colors
struct GlobalColors {
    static let orangeRegular = UIColor(red: 1.0, green: 152/255, blue: 0.0, alpha: 1.0)
    static let orangeDark = UIColor(red: 230/255, green: 81/255, blue: 0.0, alpha: 1.0)
    static let cyanRegular = UIColor(red: 100/255, green: 1.0, blue: 218/255, alpha: 1.0)
    //static let cyanLight = UIColor(red: 167/255, green: 1.0, blue: 235/255, alpha: 1.0)
    static let lightGrayForFills = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1.0)
    static let darkPurpleForFills = UIColor(red: 66/255, green: 23/255, blue: 66/255, alpha: 1.0)
    static let taskCompleteColor = UIColor.green
    static let optionalTaskIncompleteColor = UIColor.darkGray
    static let inactiveColor = UIColor.lightText
    static let unselectedButtonColor = UIColor.lightGray
    static let shareButtonColor = UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha: 1.0) //Facebook Blue
}

// MARK: Fonts
struct GlobalFontNames {
    static let ComfortaaLight = "Comfortaa-Light" // Headings
    static let ralewayRegular = "Raleway-Regular" // Text
    static let ralewayMedium = "Raleway-Medium" // Cell Title
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        // Perform initial app setup.
        var localPersistentStore: Realm!
        try! localPersistentStore = Realm(configuration: realmConfig)
        let eventImages = localPersistentStore.objects(EventImageInfo.self)
        
        if eventImages.count == 0 {
            
            // Add image info for images on the disk to the persistent store
            for imageInfo in AppEventImage.bundleMainImageInfo {
                let fileRootName = imageInfo.title.convertToFileName()
                if let _ = Bundle.main.path(forResource: fileRootName, ofType: ".jpg") {
                    if imageInfo.hasMask {
                        if let _ = Bundle.main.path(forResource: fileRootName + "Mask", ofType: ".png") {
                            do {
                                try! localPersistentStore.write {
                                    localPersistentStore.add(imageInfo)
                                }
                            }
                        }
                        else {
                            let imageInfoToAdd = EventImageInfo(
                                imageTitle: imageInfo.title,
                                imageCategory: imageInfo.category,
                                isAppImage: imageInfo.isAppImage,
                                recordName: nil,
                                hasMask: imageInfo.hasMask,
                                recommendedLocationForCellView: imageInfo.recommendedLocationForCellView.value
                            )
                            do {
                                try! localPersistentStore.write {
                                    localPersistentStore.add(imageInfoToAdd)
                                }
                            }
                        }
                    }
                    else {
                        do {
                            try! localPersistentStore.write {
                                localPersistentStore.add(imageInfo)
                            }
                        }
                    }
                }
            }
            
            // Create the default event.
            struct DefaultEvent {
                static let category = "Holidays"
                static let title = "New Years!"
                static let tagline = "Party like it's 1989"
                static var date: EventDate = {
                    let calender = Calendar.current
                    var dateComponents = DateComponents()
                    dateComponents.second = 0
                    dateComponents.minute = 0
                    dateComponents.hour = 0
                    dateComponents.day = 1
                    dateComponents.month = 1
                    dateComponents.year = calender.component(.year, from: Date()) + 1
                    let newYearsDay = calender.date(from: dateComponents)!
                    return EventDate(date: newYearsDay, dateOnly: true)
                }()
                static let imageTitle = "Desert Dunes"
                static let useMask: Bool = true
            }
            
            if let i = eventImages.index(where: {$0.title == DefaultEvent.imageTitle}) {
                let defaultImageInfo = eventImages[i]
                var locationForCellView: CGFloat?
                if let intRecommendedLocationForCellView = defaultImageInfo.recommendedLocationForCellView.value {
                    locationForCellView = CGFloat(intRecommendedLocationForCellView) / 100.0
                }
                let defaultEvent = SpecialEvent(
                    category: DefaultEvent.category,
                    title: DefaultEvent.title,
                    tagline: DefaultEvent.tagline,
                    date: DefaultEvent.date,
                    abridgedDisplayMode: false,
                    useMask: DefaultEvent.useMask,
                    image: defaultImageInfo,
                    locationForCellView: locationForCellView
                )
                try! localPersistentStore.write {localPersistentStore.add(defaultEvent)}
            }
            else {
                // TODO: error handling
                fatalError("Default Image for the default event was not on the disk!")
            }
        }
        
        // Setup split view controller.
        let splitViewController = window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    //
    // MARK: - Split view
    //

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.specialEvent == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

