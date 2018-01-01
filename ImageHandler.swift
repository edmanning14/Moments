//
//  ImageHandler.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 11/23/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import CloudKit

open class ImageHandler {
    
    enum FetchErrors: Error {
        case querryError(message: String)
    }
    
    enum saveErrors: Error {
        case invalidImageTitle(message: String), groupFileDirectoryInaccessable(message: String), fileNotSaved(message: String, error: Error)
    }
    
    //
    // MARK: - Parameters
    //
    
    // Public Data Model
    //
    
    var delegate: NewEventViewController? /*{
        didSet {
            switch job {
            case .newEventControllerImageRetrieval:
                fetchOriginalsFromCloud()
            case .activeEventsImageCaching:
                break
            }
        }
    }*/
    
    //enum ImageHandlerJob {case newEventControllerImageRetrieval, activeEventsImageCaching}
    
    open var eventImages: [EventImage] {
        var arrayToReturn = [EventImage]()
        for element in images {arrayToReturn.append(element.0)}
        return arrayToReturn
    }
    
    // Private Data Model
    //
    
    //fileprivate let job: ImageHandlerJob
    fileprivate var images = [(EventImage, CKRecordID, CKReference?)]()
    lazy fileprivate var publicCloudDatabase = CKContainer.default().publicCloudDatabase
    lazy fileprivate var originalImagesPredicate = NSPredicate(format: "isTraceImage = %@", "No")
    lazy fileprivate var originalImagesQuerry = CKQuery(recordType: "EventImage", predicate: originalImagesPredicate)
    lazy fileprivate var defaultFileManager = FileManager.default
    lazy fileprivate var groupFileDirectory = defaultFileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ed_Manning.Multiple_Event_Countdown")
    
    //
    // MARK: - Initializers
    //
    
    init() {}
    
    /*convenience init(forJob job: ImageHandlerJob) {
        self.init()
        switch job {
        case .newEventControllerImageRetrieval:
            fetchOriginalsFromCloud()
        case .activeEventsImageCaching:
            fetchImagesFromFiles()
        }
    }*/
    
    //
    // MARK: - Instance Methods
    //
    
    open func fetchImagesFromFiles() -> Void {
        
    }
    
    open func fetchOriginalsFromCloud() -> Void {
        publicCloudDatabase.perform(originalImagesQuerry, inZoneWith: nil) { [weak weakSelf = self] (records, error) in
            guard error != nil else {
                print("There was an error fetching shit from the cloud: \(error.debugDescription)")
                switch error {
                default:
                    DispatchQueue.main.async { [weak weakSelf = self] in
                        weakSelf?.delegate?.cloudLoadFailed = true
                    }
                    return
                }
            }
            if let returnedRecords = records {
                var arrayToReturn = [(EventImage, CKRecordID, CKReference?)]()
                for record in returnedRecords {
                    let imageTitle = record.object(forKey: "Title") as! String
                    let imageCategory = record.object(forKey: "Category") as! String
                    let isTraceImage = record.object(forKey: "isTraceImage") as! String
                    let image = record.object(forKey: "Image") as! CKAsset
                    let associatedTraceImage = record.object(forKey: "AssociatedTraceImage") as? CKReference
                    let recordID = record.recordID
                    
                    var boolIsTraceImage: Bool {if isTraceImage == "Yes" {return true} else {return false}}
                    
                    do {
                        let imageData = try Data(contentsOf: image.fileURL)
                        let uiImage  = UIImage(data: imageData)!
                        
                        let newImage = EventImage(title: imageTitle, image: uiImage, category: imageCategory, associatedTraceImage: nil, isTraceImage: boolIsTraceImage)
                        arrayToReturn.append((newImage, recordID, associatedTraceImage))
                    }
                    catch {
                        print("Error converting asset to data: \(error.localizedDescription)")
                    }
                }
                weakSelf?.images = arrayToReturn
            }
            else {print("No records were returned, no error.")}
        }
    }
    
    open func fetchOverlay(forImage image: UIImage) -> UIImage {
        
    }
    
    open func saveLocal(imageTitled title: String) throws -> Bool {
        let imageExists = images.contains {$0.0.title == title}
        guard imageExists else {throw saveErrors.invalidImageTitle(message: "Image title was not found in my data model.  Please check image name.")}
        
        guard groupFileDirectory != nil else {throw saveErrors.groupFileDirectoryInaccessable(message: "The shared application container is inaccessable, check app permisions.")}
        do {
            let sharedContainerContents = try defaultFileManager.contentsOfDirectory(at: groupFileDirectory!, includingPropertiesForKeys: nil, options: [])
            let imagesDirectory = groupFileDirectory!.appendingPathComponent("EventImages")
            if !sharedContainerContents.contains(imagesDirectory) {
                do {
                    try defaultFileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: false, attributes: nil)
                }
                catch {throw saveErrors.fileNotSaved(message: "unable to create the images directory", error: error)}
            }
            let imageURL = imagesDirectory.appendingPathComponent(title)
            let arrayIndex = images.index {$0.0.title == title}!
            let imageToSave = images[arrayIndex].0.uiImage
            if let imageData = UIImagePNGRepresentation(imageToSave) {
                defaultFileManager.createFile(atPath: imageURL.absoluteString, contents: imageData, attributes: nil)
            }
            else {print("Conversion to PNG image data failed."); return false}
        }
        catch {throw saveErrors.fileNotSaved(message: "There was an error checking the contents of the shared app directory.  Check file permisions", error: error)}
        return true
    }
    
    open func hasAvailableOverlayImage(mainImage image: EventImage) -> Bool {
        if let arrayIndex = images.index(where: {$0.0.title == image.title}) {
            if images[arrayIndex].2 != nil {return true}
        }
        return false
    }
    
    //
    // MARK: - Helper functions
    //
}
