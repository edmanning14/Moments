//
//  ImageClasses.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/6/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import CloudKit

internal class CountdownImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let imageType: ImageType
    let fileName: String
    let fileExtension: String
    
    var uiImage: UIImage? {
        if _uiImage != nil {return _uiImage!}
        else {loadUIImage(); return _uiImage}
    }
    
    var cgImage: CGImage? {
        if _cgImage != nil {return _cgImage}
        else {loadCGImage(); return _cgImage}
    }
    
    var isSavedToDisk: Bool {
        if filePath == nil {return false}
        else {return true}
    }
    
    //
    // init
    
    init?(imageType: ImageType, fileRootName: String, fileExtension: String, imageData: Data?) {
        
        var _fileName = ""
        
        switch imageType {
        case .main: _fileName = fileRootName
        case .mask: _fileName = fileRootName + "Mask"
        case .thumbnail:
            let floatScale = UIScreen.main.scale
            var scale = ""
            switch floatScale {
            case 1.0: scale = "@1x"
            case 2.0: scale = "@2x"
            case 3.0: scale = "@3x"
            default: scale = "@3x"
            }
            _fileName = fileRootName + "Thumbnail" + scale
        }
        
        self.fileName = _fileName
        self.imageType = imageType
        self.fileExtension = fileExtension
        
        if imageData == nil {
            if let path1 = Bundle.main.path(forResource: _fileName, ofType: fileExtension) {filePath = path1; return}
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path2 = documentsURL.appendingPathComponent(_fileName + fileExtension).relativePath
            if FileManager.default.fileExists(atPath: path2) {filePath = path2; return}
        }
        else {self.imageData = imageData!; return}
        
        return nil
    }
    
    //
    // Types
    
    enum ImageType {
        case thumbnail
        case mask
        case main
        
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
    // Methods
    
    //
    // Methods
    
    func saveToDisk() -> Bool {
        guard imageData != nil else {return false}
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let saveDest = documentsURL.appendingPathComponent(fileName + fileExtension, isDirectory: false)
        do {try imageData!.write(to: saveDest, options: .atomic); return true}
        catch {print(error.localizedDescription); return false}
    }
    
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var _uiImage: UIImage?
    fileprivate var _cgImage: CGImage?
    fileprivate var imageData: Data?
    
    fileprivate var filePath: String?
    
    //
    // Flags

    
    //
    // Methods
    
    fileprivate func loadUIImage() {
        
        if let path = filePath {
            if let image = UIImage(contentsOfFile: path) {_uiImage = image}
            // TODO: Error Handling
            else {fatalError("There was an error loading the image from the path provided.")}
        }
        else if let data = imageData {
            if let image = UIImage(data: data, scale: UIScreen.main.scale) {_uiImage = image}
            // TODO: Error Handling
            else {fatalError("There was an creating the image from the provided image data.")}
        }
    }
    
    fileprivate func loadCGImage() {
        if let path = filePath {
            let url = URL(fileURLWithPath: path)
            if let dataProvider = CGDataProvider(url: url as CFURL) {
                switch fileExtension {
                case ".png":
                    if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                    // TODO: Error Handling
                    else {fatalError("There was an error creating the png image from the data provider provided.")}
                case ".jpg":
                    if let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                    // TODO: Error Handling
                    else {fatalError("There was an error loading the jpg image from the data provider provided.")}
                default: fatalError("Recieved an unrecognized file extension.") // TODO: Error handling
                }
            }
            // TODO: Error Handling
            else {fatalError("There was an error creating the data provider from the path provided.")}
        }
        else if let data = imageData {
            if let dataProvider = CGDataProvider(data: data as CFData) {
                switch fileExtension {
                case ".png":
                    if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                        // TODO: Error Handling
                    else {fatalError("There was an error loading the image from the path provided.")}
                case ".jpg":
                    if let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                        // TODO: Error Handling
                    else {fatalError("There was an error loading the jpg image from the data provider provided.")}
                default: fatalError("Recieved an unrecognized file extension.") // TODO: Error handling
                }
            }
            // TODO: Error Handling
            else {fatalError("There was an creating the image from the provided image data.")}
        }
    }
}

internal class EventImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let title: String
    let category: String
    let fileRootName: String
    let isAppImage: Bool
    let locationForCellView: CGFloat
    var recordName: String?
    var delegate: CountdownImageDelegate?
    
    var mainImage: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .main}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.main], alertDelegate: true)}
        }
        return nil
    }
    
    var maskImage: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .mask}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.mask], alertDelegate: true)}
        }
        return nil
    }
    
    var thumbnail: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .thumbnail}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.thumbnail], alertDelegate: true)}
        }
        return nil
    }
    
    var imagesAreSavedToDisk: Bool {
        for image in images {if !image.isSavedToDisk {return false}}
        return true
    }
    
    //
    // init
    
    init?(fromEventImageInfo info: EventImageInfo) {
        title = info.title
        category = info.category
        fileRootName = info.fileRootName
        isAppImage = info.isAppImage
        recordName = info.recordName
        locationForCellView = CGFloat(info.locationForCellView) / 100.0
        
        if let image = CountdownImage(imageType: .main, fileRootName: info.fileRootName, fileExtension: ".jpg", imageData: nil) {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .main, fileRootName: info.fileRootName, fileExtension: ".png", imageData: nil) {
            images.append(image)
        }
        
        if let image = CountdownImage(imageType: .mask, fileRootName: info.fileRootName, fileExtension: ".jpg", imageData: nil) {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .mask, fileRootName: info.fileRootName, fileExtension: ".png", imageData: nil) {
            images.append(image)
        }
        
        if let image = CountdownImage(imageType: .thumbnail, fileRootName: info.fileRootName, fileExtension: ".jpg", imageData: nil) {
            images.append(image)
        }
        if let image = CountdownImage(imageType: .thumbnail, fileRootName: info.fileRootName, fileExtension: ".png", imageData: nil) {
            images.append(image)
        }
        
        if images.isEmpty {return nil}
    }
    
    init?(title: String, fileRootName: String, category: String, isAppImage: Bool, locationForCellView: Int, recordName: String, images: [CountdownImage]) {
        guard !images.isEmpty else {return nil}
        self.title = title
        self.fileRootName = fileRootName
        self.category = category
        self.isAppImage = isAppImage
        self.locationForCellView = CGFloat(locationForCellView) / 100.0
        self.recordName = recordName
        self.images = images
    }
    
    //
    // Constants
    
    static let bundleMainImageInfo = [
        EventImageInfo(
            imageTitle: "Desert Dunes",
            fileRootName: "DesertDunes",
            imageCategory: "Travel",
            isAppImage: true,
            recordName: nil,
            locationForCellView: 50,
            hasMask: true
        )
    ]
    
    //
    // Flags
    
    fileprivate var fetching = [CountdownImage.ImageType]()
    
    //
    // Methods
    
    func saveToDisk(imageTypes: [CountdownImage.ImageType]) -> [Bool] {
        
        var arrayToReturn = [Bool]()
        for imageType in imageTypes {
            if let i = images.index(where: {$0.imageType == imageType}) {arrayToReturn.append(images[i].saveToDisk())}
        }
        
        return arrayToReturn
    }
    
    func fetch(imageTypes: [CountdownImage.ImageType], alertDelegate: Bool) {
        
        guard recordName != nil && imageTypes.count > 0 else {
            delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
            return
        }
        
        if fetching.contains(where: {imageTypes.contains($0)}) {return}
        else {fetching.append(contentsOf: imageTypes)}
        
        let recordID = CKRecordID(recordName: recordName!)
        let fetchOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        var desiredKeys = [String]()
        for imageType in imageTypes {
            desiredKeys.append(contentsOf: [imageType.recordKey, imageType.extensionRecordKey])
        }
        fetchOperation.desiredKeys = desiredKeys
        
        fetchOperation.fetchRecordsCompletionBlock = { [weak weakSelf = self] (_records, error) in
            if let records = _records {
                guard !records.isEmpty else {
                    DispatchQueue.main.async { [weak weakSelf = self] in
                        for imageType in imageTypes {
                            if let i = weakSelf?.fetching.index(where:{$0 == imageType}) {weakSelf?.fetching.remove(at: i)}
                        }
                        weakSelf?.delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
                    }
                    return
                }
                for record in records {
                    
                    var images = [CountdownImage]()
                    var success = [Bool]()
                    for imageType in imageTypes {
                        
                        let imageAsset = record.value[imageType.recordKey] as! CKAsset
                        let imageFileExtension = record.value[imageType.extensionRecordKey] as! String
                        
                        do {
                            let imageData = try Data(contentsOf: imageAsset.fileURL)
                            if let livingSelf = weakSelf, let newImage = CountdownImage(imageType: imageType, fileRootName: livingSelf.fileRootName, fileExtension: imageFileExtension, imageData: imageData) {
                                images.append(newImage)
                                success.append(true)
                            }
                        } catch {success.append(false)}
                    }
                    
                    weakSelf?.images.append(contentsOf: images)
                    DispatchQueue.main.async { [weak weakSelf = self] in
                        for imageType in imageTypes {
                            if let i = weakSelf?.fetching.index(where:{$0 == imageType}) {weakSelf?.fetching.remove(at: i)}
                        }
                        weakSelf?.delegate?.fetchComplete(forImageTypes: imageTypes, success: success)
                    }
                }
            }
            else {
                DispatchQueue.main.async { [weak weakSelf = self] in
                    for imageType in imageTypes {
                        if let i = weakSelf?.fetching.index(where:{$0 == imageType}) {weakSelf?.fetching.remove(at: i)}
                    }
                    weakSelf?.delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
                }
            }
        }
        publicCloudDatabase.add(fetchOperation)
    }

    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var images = [CountdownImage]()
    
    //
    // Types
    
    fileprivate enum CloudErrors: Error {case imageCreationFailure, assetCreationFailure, noRecords, imageNotFound}
    
    //
    // Persistence
    
    fileprivate let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    //
    // Flags
    
    //
    // Constants
    
    struct CloudKitKeys {
        static let EventImage = "EventImage"
        static let Product = "Product"
        struct EventImageKeys {
            static let title = "title"
            static let fileRootName = "fileRootName"
            static let locationForCellView = "locationForCellView"
            static let mainFileExtension = "mainFileExtension"
            static let maskFileExtension = "maskFileExtension"
            static let thumbnailFileExtension = "thumbnailFileExtension"
            static let category = "category"
            static let image = "image"
            static let mask = "mask"
            static var thumbnail: String {
                let floatScale = UIScreen.main.scale
                var scale = ""
                switch floatScale {
                case 1.0: scale = "1x"
                case 2.0: scale = "2x"
                case 3.0: scale = "3x"
                default: scale = "3x"
                }
                return "thumbnail" + scale
            }
        }
        struct ProductKeys {
            static let productIdentifier = "productIdentifier"
            static let containedRecords = "containedRecords"
        }
    }
}
