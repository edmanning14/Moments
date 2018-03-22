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
            for imageInfo in EventImage.bundleMainImageInfo {
                if let _ = Bundle.main.path(forResource: imageInfo.fileRootName, ofType: ".jpg") {
                    if imageInfo.hasMask {
                        if let _ = Bundle.main.path(forResource: imageInfo.fileRootName + "Mask", ofType: ".png") {
                            do {
                                try! localPersistentStore.write {
                                    localPersistentStore.add(imageInfo)
                                }
                            }
                        }
                        else {
                            let imageInfoToAdd = EventImageInfo(
                                imageTitle: imageInfo.title,
                                fileRootName: imageInfo.fileRootName,
                                imageCategory: imageInfo.category,
                                isAppImage: imageInfo.isAppImage,
                                hasMask: imageInfo.hasMask
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
            }
            
            if let i = eventImages.index(where: {$0.title == DefaultEvent.imageTitle}) {
                let defaultImageInfo = eventImages[i]
                let defaultEvent = SpecialEvent(
                    category: DefaultEvent.category,
                    title: DefaultEvent.title,
                    tagline: DefaultEvent.tagline,
                    date: DefaultEvent.date,
                    image: defaultImageInfo
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
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

