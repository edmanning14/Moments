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
        case invalidAssetName, cgImageConversionError
    }
    
    enum saveErrors: Error {
        case invalidImageTitle(message: String), groupFileDirectoryInaccessable(message: String), fileNotSaved(message: String, error: Error)
    }
    
    //
    // MARK: - Parameters
    //
    
    // Public Data Model
    //
    
    enum ImageHandlerJob {case newEventControllerImageRetrieval, activeEventsImageCaching}
    
    open var eventImages: [EventImage] {return images}
    
    // Private Data Model
    //
    
    fileprivate var images = [EventImage]()
    lazy fileprivate var publicCloudDatabase = CKContainer.default().publicCloudDatabase
    lazy fileprivate var originalImagesPredicate = NSPredicate(format: "isTraceImage = %@", "No")
    lazy fileprivate var originalImagesQuerry = CKQuery(recordType: "EventImage", predicate: originalImagesPredicate)
    lazy fileprivate var defaultFileManager = FileManager.default
    lazy fileprivate var groupFileDirectory = defaultFileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Ed_Manning.Multiple_Event_Countdown")
    
    //
    // MARK: - Initializers
    //
    
    init() {}
    
    convenience init(forJob job: ImageHandlerJob) {
        self.init()
        switch job {
        case .newEventControllerImageRetrieval:
            fetchOriginalsFromCloud()
        case .activeEventsImageCaching:
            fetchImagesFromFiles()
        }
    }
    
    //
    // MARK: - Instance Methods
    //
    
    open func fetchImagesFromFiles() -> Void {
        
    }
    
    open func fetchOriginalsFromCloud() -> Void {
        
        func createReferences(inArray array: [(EventImage, CKReference, CKReference?)]) -> [EventImage] {
            var arrayToReturn = [EventImage]()
            for element in array {
                if element.2 != nil {
                    if let referenceRecordIndex = array.index(where: {$0.1 == element.2}) {
                        let newImage = EventImage(
                            title: element.0.title,
                            image: element.0.uiImage,
                            category: element.0.category,
                            associatedTraceImage: array[referenceRecordIndex].0,
                            isTraceImage: element.0.isTraceImage
                        )
                        arrayToReturn.append(newImage)
                    }
                    else {arrayToReturn.append(element.0)}
                }
                else{arrayToReturn.append(element.0)}
            }
            return arrayToReturn
        }
        
        publicCloudDatabase.perform(originalImagesQuerry, inZoneWith: nil) { [weak weakSelf = self] (records, error) in
            guard error == nil else {print("There was an error fetching shit from the cloud: \(error.debugDescription)")}
            if let returnedRecords = records {
                var imageArrayWithoutReferences = [(EventImage, CKReference, CKReference?)]()
                for record in returnedRecords {
                    let imageTitle = record.object(forKey: "Title") as! String
                    let imageCategory = record.object(forKey: "Category") as! String
                    let isTraceImage = record.object(forKey: "isTraceImage") as! String
                    let image = record.object(forKey: "Image") as! CKAsset
                    let associatedTraceImage = record.object(forKey: "AssociatedTraceImage") as? CKReference
                    let recordReference = record.object(forKey: "recordName") as! CKReference
                    
                    var boolIsTraceImage: Bool {if isTraceImage == "Yes" {return true} else {return false}}
                    
                    do {
                        let imageData = try Data(contentsOf: image.fileURL)
                        let uiImage  = UIImage(data: imageData)!
                        
                        let newImage = EventImage(title: imageTitle, image: uiImage, category: imageCategory, associatedTraceImage: nil, isTraceImage: boolIsTraceImage)
                        imageArrayWithoutReferences.append((newImage, recordReference, associatedTraceImage))
                    }
                    catch {
                        print("Error converting asset to data: \(error.localizedDescription)")
                    }
                }
                weakSelf?.images = createReferences(inArray: imageArrayWithoutReferences)
            }
            else {print("No records were returned, no error.")}
        }
    }
    
    open func saveLocal(imageTitled title: String) throws -> Bool {
        let imageExists = images.contains {$0.title == title}
        guard imageExists else {throw saveErrors.invalidImageTitle(message: "Image title was not found in my data model.  Please check image name.")}
        
        guard groupFileDirectory != nil else {throw saveErrors.groupFileDirectoryInaccessable(message: "The shared application container is inaccessable, check app permisions.")}
        do {
            let sharedContainerContents = try defaultFileManager.contentsOfDirectory(at: groupFileDirectory!, includingPropertiesForKeys: nil, options: [])
            let imagesDirectory = groupFileDirectory!.appendingPathComponent("EventImages")
            if !sharedContainerContents.contains(imagesDirectory) {
                do {
                    try defaultFileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: false, attributes: nil)
                }
                catch {print("unable to create the images directory \(error.localizedDescription)")}
            }
            let imageURL = imagesDirectory.appendingPathComponent(title)
            let arrayIndex = images.index {$0.title == title}!
            let imageToSave = images[arrayIndex].uiImage
            if let imageData = UIImagePNGRepresentation(imageToSave) {
                defaultFileManager.createFile(atPath: imageURL.absoluteString, contents: imageData, attributes: nil)
            }
            else {print("Conversion to PNG image data failed.")}
        }
        catch {throw saveErrors.fileNotSaved(message: "There was an error checking the contents of the shared app directory.  Check file permisions", error: error)}
    }
    
    
    //
    // MARK: - Helper functions
    //
}
