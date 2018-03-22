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
            
            let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let saveDest = documentsURL.appendingPathComponent(fileName + fileExtension)
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
    var recordID: CKRecordID?
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
    
    init?(title: String, fileRootName: String, category: String, recordID: CKRecordID, images: [CountdownImage]) {
        guard !images.isEmpty else {return nil}
        self.title = title
        self.fileRootName = fileRootName
        self.category = category
        self.recordID = recordID
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
        
        guard recordID != nil else {
            delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
            return
        }
        guard imageTypes.count > 0 else {
            delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
            return
        }
        if fetching.contains(where: {imageTypes.contains($0)}) {return}
        else {fetching.append(contentsOf: imageTypes)}
        
        let fetchOperation = CKFetchRecordsOperation(recordIDs: [recordID!])
        
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
    
    //
    // Methods
    
    /*fileprivate func fetch(imageTypes: [CountdownImage.ImageType]) {
        for imageType in imageTypes {
            if let image = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: ".jpg", imageData: nil) {images.append(image); return}
            if let image = CountdownImage(imageType: imageType, fileRootName: fileRootName, fileExtension: ".png", imageData: nil) {images.append(image); return}
            
            if let id = recordID {
                let fetchOperation = CKFetchRecordsOperation(recordIDs: [id])
                
                var desiredKeys = [String]()
                for imageType in imageTypes {
                    desiredKeys.append(contentsOf: [imageType.recordKey, imageType.extensionRecordKey])
                }
                fetchOperation.desiredKeys = desiredKeys
                
                fetchOperation.fetchRecordsCompletionBlock = { [weak weakSelf = self] (_records, error) in
                    if let records = _records {
                        for record in records {
                            for imageType in imageTypes {
                                let imageAsset = record.value[imageType.recordKey] as! CKAsset
                                let imageFileExtension = record.value[imageType.extensionRecordKey] as! String
                                
                                do {
                                    let imageData = try Data(contentsOf: imageAsset.fileURL)
                                    
                                    if let livingSelf = weakSelf {
                                        if let newImage = CountdownImage(imageType: imageType, fileRootName: livingSelf.fileRootName, fileExtension: imageFileExtension, imageData: imageData) {
                                            livingSelf.completion(newImage, nil)
                                        }
                                    }
                                }
                                catch {weakSelf?.completion(nil, .imageCreationFailure)}
                            }
                        }
                    }
                    else {weakSelf?.completion(nil, .noRecords)}
                }
                
                publicCloudDatabase.add(fetchOperation)
            }
            else {completion(nil, .imageNotFound)}
        }
    }
    
    fileprivate func completion(_ image: CountdownImage?, _ error: CloudErrors?) {
        if image != nil && error == nil {
            DispatchQueue.main.async { [weak weakSelf = self] in
                weakSelf?.images.append(image!)
                if let livingSelf = weakSelf, livingSelf.tellDelegate {
                    livingSelf.delegate?.imageLoadComplete(forImage: livingSelf, imageTypeLoaded: image!.imageType)
                    livingSelf.tellDelegate = false
                }
            }
        }
        else {
            // TODO: - Error handling
            fatalError("There was an error fetching images from the cloud")
        }
    }*/
}

/*internal class AppImage { // Abstract superclass
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let fileName: String
    var uiImage: UIImage? {
        if imageData == nil && !isSavedToDisk {return nil}
        else if _uiImage != nil {return _uiImage}
        else {loadUIImage(); return _uiImage}
    }
    var cgImage: CGImage? {
        if imageData == nil && !isSavedToDisk {return nil}
        if _cgImage != nil {return _cgImage}
        else {loadCGImage(); return _cgImage}
    }
    var isSavedToDisk: Bool {
        switch imageSavedTo {
        case .bundle: return true
        case .documents: return true
        case .nowhere: return false
        }
    }
    
    //
    // Initialization
    
    fileprivate init?(fileName name: String) {
        fileName = name
        
        if let path1 = Bundle.main.path(forResource: name, ofType: ".jpg") {
            imageFilePath = path1
            imageSavedTo = .bundle
            fileExtension = ".jpg"
            return
        }
        if let path2 = Bundle.main.path(forResource: name, ofType: ".png") {
            imageFilePath = path2
            imageSavedTo = .bundle
            fileExtension = ".png"
            return
        }
        
        
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let path3 = documentsURL.appendingPathComponent(name + ".jpg").relativePath
        if FileManager.default.fileExists(atPath: path3) {
            imageFilePath = path3
            imageSavedTo = .documents
            fileExtension = ".jpg"
            return
        }
        let path4 = documentsURL.appendingPathComponent(name + ".png").relativePath
        if FileManager.default.fileExists(atPath: path4) {
            imageFilePath = path4
            imageSavedTo = .documents
            fileExtension = ".png"
            return
        }
        
        return nil
    }
    
    fileprivate init(fileName name: String, fileExtension ext: String, image: Data) {
        fileName = name
        fileExtension = ext
        imageData = image
        imageSavedTo = .nowhere
    }
    
    //
    // Methods
    
    func saveDataToDisk() -> Bool {
        
        guard imageData != nil else {return false}
        
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let saveDest = documentsURL.appendingPathComponent(fileName)
        
        do {try imageData!.write(to: saveDest, options: .atomic)}
        catch {print(error.localizedDescription); return false}
        
        imageSavedTo = .documents
        return true
    }
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate let fileExtension: String
    fileprivate var imageFilePath: String? {didSet {if imageFilePath != nil {imageURL = URL(fileURLWithPath: imageFilePath!)}}}
    fileprivate var imageURL: URL?
    fileprivate var _uiImage: UIImage?
    fileprivate var _cgImage: CGImage?
    fileprivate var imageData: Data?
    
    fileprivate enum saveStates {case bundle, documents, nowhere}
    fileprivate var imageSavedTo: saveStates
    
    //
    // Methods
    
    fileprivate func loadUIImage() {
        switch imageSavedTo {
        case .bundle:
            if let image = UIImage(contentsOfFile: imageFilePath!) {_uiImage = image}
        case .documents:
            _uiImage = UIImage(contentsOfFile: imageFilePath!)
        case .nowhere:
            if let image = UIImage(data: imageData!) {_uiImage = image}
        }
    }
    
    fileprivate func loadCGImage() {
        switch imageSavedTo {
        case .bundle:
            if let dataProvider = CGDataProvider(url: imageURL! as CFURL) {
                _cgImage = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
            }
        case .documents:
            if let dataProvider = CGDataProvider(url: imageURL! as CFURL) {
                _cgImage = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
            }
        case .nowhere:
            if let dataProvider = CGDataProvider(data: imageData! as CFData) {
                _cgImage = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
            }
        }
    }
}

internal class Thumbnail: AppImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let ownerFileName: String
    
    //
    // Initialization
    
    init?(ownerFileName: String) {
        
        self.ownerFileName = ownerFileName
        
        let floatScale = UIScreen.main.scale
        var scale = ""
        switch floatScale {
        case 1.0: scale = "@1x"
        case 2.0: scale = "@2x"
        case 3.0: scale = "@3x"
        default: scale = "@3x"
        }
        
        let thumbnailFileName = ownerFileName + "Thumbnail" + scale
        super.init(fileName: thumbnailFileName)
    }
    
    init(ownerFileName: String, fileExtension ext: String, image: Data) {
        
        self.ownerFileName = ownerFileName
        
        let floatScale = UIScreen.main.scale
        var scale = ""
        switch floatScale {
        case 1.0: scale = "@1x"
        case 2.0: scale = "@2x"
        case 3.0: scale = "@3x"
        default: scale = "@3x"
        }
        
        let thumbnailFileName = ownerFileName + "Thumbnail" + scale
        super.init(fileName: thumbnailFileName, fileExtension: ".jpg", image: image)
    }
}

internal class MaskEventImage: AppImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let ownerFileName: String
    
    //
    // Initialization
    
    init?(ownerFileName name: String) {
        self.ownerFileName = name
        let maskFileName = name + "Mask"
        super.init(fileName: maskFileName)
    }
    init(ownerFileName name: String, fileExtension ext: String, image: Data) {
        self.ownerFileName = name
        let maskFileName = name + "Mask"
        super.init(fileName: maskFileName, fileExtension: ext, image: image)
    }
}


class MainEventImage: AppImage {

    //
    // MARK: - Public
    //
    
    //
    // Parameters
    
    let title: String
    let category: String
    let isAppImage: Bool
    var mask: MaskEventImage?
    var isUnlocked: Bool
    
    static let bundleMainImageInfo = [
        EventImageInfo(
            imageTitle: "Desert Dunes",
            fileName: "DesertDunes",
            fileExtension: ".jpg",
            imageCategory: "Travel",
            isAppImage: true,
            hasMask: true
        )
    ]
    
    //
    // Initialization
    
    init?(from info: EventImageInfo) {
        title = info.title
        category = info.category
        isAppImage = info.isAppImage
        if info.hasMask {
            if let imageMask = MaskEventImage(ownerFileName: info.fileName) {mask = imageMask}
            else {return nil}
        }
        isUnlocked = true
        super.init(fileName: info.fileName)
    }
    
    init(fileName: String, fileExtension: String, title: String, category: String, isAppImage: Bool, mask: MaskEventImage?, isUnlocked: Bool, image: Data) {
        self.title = title
        self.category = category
        self.isAppImage = isAppImage
        self.mask = mask
        self.isUnlocked = isUnlocked
        super.init(fileName: fileName, fileExtension: fileExtension, image: image)
    }
}*/
