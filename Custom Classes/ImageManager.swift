//
//  ImageManager.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 3/14/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

/*import Foundation
import UIKit
import RealmSwift
import CloudKit

class ImageManager {
    
    //
    // MARK: - Public
    //
    
    //
    // MARK: - Accessors
    func shared() -> ImageManager {return .sharedImageManager}
    
    //
    // MARK: - Types
    enum ImageType {
        case thumbnail
        case mask
        case main
        
        var fileNameSuffixAndExtension: String {
            switch self {
            case .thumbnail:
                let floatScale = UIScreen.main.scale
                var scale = ""
                switch floatScale {
                case 1.0: scale = "@1x"
                case 2.0: scale = "@2x"
                case 3.0: scale = "@3x"
                default: scale = "@3x"
                }
                return "Thumbnail" + scale + ".jpg"
            case .mask: return "Mask.png"
            case .main: return ".jpg"
            }
        }
        
        var recordKey: String {
            switch self {
            case .thumbnail:
                let floatScale = UIScreen.main.scale
                var scale = ""
                switch floatScale {
                case 1.0: scale = "1x"
                case 2.0: scale = "2x"
                case 3.0: scale = "3x"
                default: scale = "3x"
                }
                return "thumbnail" + scale
            case .mask: return "mask"
            case .main: return "image"
            }
        }
        
        var extensionRecordKey: String {
            switch self {
            case .thumbnail: return "thumbnailFileExtension"
            case .mask: return "maskFileExtension"
            case .main: return "mainFileExtension"
            }
        }
    }
    
    //
    // MARK: - Methods
    func getEventImages(named imageNames: [String], imageTypes: [ImageType], returnImmediate: Bool = false, completionHandler returnImages: @escaping ([EventImage], [String]?) -> Void) {
        
        func process(results: [(String, EventImage?, ImageFetchErrors?)]) {
            
            guard !results.isEmpty else {return}
            
            var imagesToReturn = [EventImage]()
            var imagesNotFound = [String]()
            
            for result in results {
                if let image = result.1 {
                    if let error = result.2 {
                        // TODO: handle errors where an image was returned but an error occured.
                        print(error.localizedDescription)
                        fatalError("Incomplete error handling, image found but error occured,")
                    }
                    imagesToReturn.append(image)
                }
                else {
                    if result.2 == .localFileNotFound || result.2 == .cloudFileNotFound {
                        imagesNotFound.append(result.0); break
                    }
                    // TODO: Error handling
                    fatalError("There was an error fetching the image!")
                }
            }
            
            if !imagesNotFound.isEmpty {self.returnQueue.async {returnImages(imagesToReturn, imagesNotFound)}}
            else {self.returnQueue.async {returnImages(imagesToReturn, nil)}}
        }
        
        getImageFunctionQueue.async {
            var resultsToProcess = [(String, EventImage?, ImageFetchErrors?)]()
            var imagesForCloudFetch = [String]()
            
            for name in imageNames {
                
                if let i = self.images.index(where: {$0.title == name}) {
                    let result: (String, EventImage?, ImageFetchErrors?) = (name, self.images[i], nil)
                    if returnImmediate {process(results: [result])}
                    else {resultsToProcess.append(result)}
                    break
                }
                
                let localResult = self.fetchLocalEventImage(named: name, withImageTypes: imageTypes)
                if localResult.2 == .localFileNotFound {imagesForCloudFetch.append(localResult.0); break}
                else {
                    if returnImmediate {process(results: [localResult])}
                    else {resultsToProcess.append(localResult)}
                }
                
            }
            
            let cloudResults = self.fetchCloudEventImages(named: imagesForCloudFetch, withImageTypes: imageTypes)
            process(results: cloudResults)
        }
    }
    
    
    //
    // MARK: - Private
    //
    
    //
    // MARK: - Paramters
    fileprivate static var sharedImageManager: ImageManager = {
        let imageManager = ImageManager()
        imageManager.localPersistentStore = try! Realm(configuration: realmConfig)
        imageManager.localImageInfo = imageManager.localPersistentStore.objects(EventImageInfo.self)
        return imageManager
    }()
    
    fileprivate var images = [EventImage]()
    
    //
    // MARK: - Types
    fileprivate enum ImageFetchErrors: Error {case localFileNotFound, cloudFileNotFound}
    
    //
    // MARK: - Persistence
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    fileprivate var localPersistentStore: Realm!
    fileprivate var localImageInfo: Results<EventImageInfo>!
    
    //
    // MARK: - Threading
    fileprivate let getImageFunctionQueue = DispatchQueue(label: "getImageQueue", qos: .userInitiated)
    fileprivate let returnQueue = DispatchQueue(label: "returnQueue", qos: .userInitiated)
    fileprivate let synchronousQueue = DispatchQueue(label: "synchronousQueue", qos: .userInitiated)
    
    
    //
    // MARK: - Initialization
    //
    
    //
    // MARK: - Methods
    //
    
    fileprivate func fetchLocalEventImage(named name: String, withImageTypes types: [ImageType]) -> (String, EventImage?, ImageFetchErrors?) {
        if let i = localImageInfo.index(where: {$0.title == name}) {
            for type in types {
                let fileURL = localImageInfo[i].fileRootName + type.fileNameSuffixAndExtension
                
            }
        }
        return (name, nil, .localFileNotFound)
    }
    
    fileprivate func fetchCloudEventImages(named name: [String], withImageTypes: [ImageType]) -> [(String, EventImage?, ImageFetchErrors?)] {
        
    }
}*/
