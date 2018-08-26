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
import Photos

internal enum RepeatingOptions {
    case never, monthly, yearly
    
    var displayText: String {
        switch self {
        case .never: return "Never"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

internal enum DisplayInfoOptions {
    case none, tagline, date
    
    var displayText: String {
        switch self {
        case .none: return "None"
        case .tagline: return "Tagline"
        case .date: return "Date"
        }
    }
}

internal enum NotificationsOptions {
    case custom, _default, off
    
    var displayText: String {
        switch self {
        case ._default: return "Default"
        case .custom: return "Custom"
        case .off: return "Off"
        }
    }
}

internal class CountdownImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let imageType: ImageType
    let fileRootName: String
    fileprivate let fileName: String
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
    
    init?(imageType: ImageType, fileRootName: String, fileExtension: String) {
        
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
        
        self.fileRootName = fileRootName
        self.fileName = _fileName
        self.imageType = imageType
        self.fileExtension = fileExtension
        
        let path = sharedImageLocationURL.appendingPathComponent(_fileName + fileExtension).relativePath
        if FileManager.default.fileExists(atPath: path) {filePath = path; return}
        
        return nil
    }
    
    init(imageType: ImageType, fileRootName: String, fileExtension: String, imageData: Data) {
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
        
        self.fileRootName = fileRootName
        self.fileName = _fileName
        self.imageType = imageType
        self.fileExtension = fileExtension
        self.imageData = imageData
    }
    
    init(imageType: ImageType, fileRootName: String, fileExtension: String, image: UIImage) {
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
        
        self.fileRootName = fileRootName
        self.fileName = _fileName
        self.imageType = imageType
        self.fileExtension = fileExtension
        self._uiImage = image
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
        if !isSavedToDisk {
            var data = Data()
            if let _imageData = imageData {data = _imageData}
            else if let image = _uiImage {
                if let _imageData = UIImageJPEGRepresentation(image, 1.0) {data = _imageData}
                else {return false}
            }
            else {return false}
            
            let saveDest = sharedImageLocationURL.appendingPathComponent(fileName + fileExtension, isDirectory: false)
            do {try data.write(to: saveDest, options: []); return true}
            catch {print(error.localizedDescription); return false}
        }
        return true
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
        else if let image = _uiImage {_cgImage = image.cgImage}
    }
}

internal class UserEventImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let title: String
    var photoAsset: PHAsset?
    var delegate: CountdownImageDelegate?
    
    var mainImage: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .main}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.main], alertDelegate: true)}
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
        let fileRootName = info.title.convertToFileName()
        if let image = CountdownImage(imageType: .main, fileRootName: fileRootName, fileExtension: ".jpg") {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .main, fileRootName: fileRootName, fileExtension: ".png") {
            images.append(image)
        }
        
        if let image = CountdownImage(imageType: .thumbnail, fileRootName: fileRootName, fileExtension: ".jpg") {
            images.append(image)
        }
        if let image = CountdownImage(imageType: .thumbnail, fileRootName: fileRootName, fileExtension: ".png") {
            images.append(image)
        }
        
        if images.isEmpty {return nil}
    }
    
    init(fromPhotosAsset asset: PHAsset) {
        title = asset.localIdentifier
        photoAsset = asset
    }
    
    init?(title: String, images: [CountdownImage]) {
        guard !images.isEmpty else {return nil}
        let _fileRootName = images[0].fileRootName
        for i in 1..<images.count {
            if images[i].fileRootName != _fileRootName {return nil}
        }
        self.title = title
        self.images = images
    }
    
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
        
        func fetchMainImage() {
            let imageName = photoAsset!.localIdentifier
            let fileRootName = imageName.convertToFileName()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            let id = PHImageManager.default().requestImage(for: photoAsset!, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFit, options: options) { (_image, _info) in
                if let info = _info {
                    if let error = info[PHImageErrorKey] as? NSError {
                        // TODO: Handle errors gracefully
                        print(error.debugDescription)
                        fatalError()
                    }
                }
                if let image = _image {
                    let fileExtension = ".jpg"
                    let wrappedImage = CountdownImage(imageType: .main, fileRootName: fileRootName, fileExtension: fileExtension, image: image)
                    DispatchQueue.main.async { [weak self] in
                        self?.images.append(wrappedImage)
                        for imageType in imageTypes {
                            if let i = self?.fetching.index(where:{$0 == imageType}) {self?.fetching.remove(at: i)}
                        }
                        self?.imageRequests.removeAll()
                        if alertDelegate {self?.delegate?.fetchComplete(forImageTypes: [CountdownImage.ImageType.main], success: [true])}
                    }
                }
                else {
                    // TODO: Error handling
                    fatalError("DataUTI and/or ImageData are nil! Incorrect user image asset fetched maybe?")
                }
            }
            imageRequests.append(id)
        }
        
        guard photoAsset != nil && imageTypes.contains(.main) else {
            delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
            return
        }
        
        if imageTypes.contains(.main) && !fetching.contains(.main) {fetching.append(.main); fetchMainImage()}
    }
    
    func generateMainHomeImage(size: CGSize, locationForCellView: CGFloat, userInitiated: Bool, completion: ((UIImage?) -> Void)?) {
        guard let image = mainImage?.cgImage else {completion?(nil); return}
        
        _generateHomeImage(
            from: image,
            imageType: "Main Home",
            isUserImage: true,
            size: size,
            locationForCellView: locationForCellView,
            userInitiated: userInitiated,
            completion: { (mainHomeImage) in completion?(mainHomeImage)}
        )
    }
    
    func cancelNetworkFetches() {
        for request in imageRequests {PHImageManager.default().cancelImageRequest(request)}
        if let i = fetching.index(of: .main) {fetching.remove(at: i)}
    }
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var images = [CountdownImage]()
    fileprivate var imageRequests = [PHImageRequestID]()
    fileprivate var serialImageCreationQueue: DispatchQueue?
    
    //
    // Flags
    
    fileprivate var fetching = [CountdownImage.ImageType]()
    
    //
    // Methods
    
    fileprivate func _generateHomeImage(from image: CGImage, imageType: String, isUserImage: Bool, size: CGSize, locationForCellView: CGFloat, userInitiated: Bool, completion: ((UIImage?) -> Void)?) {
        var qos: DispatchQoS
        if userInitiated {qos = .userInitiated} else {qos = .utility}
        serialImageCreationQueue = DispatchQueue(label: "serialImageCreationQueue", qos: qos)
        
        serialImageCreationQueue!.async {
            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
            let imageCTX = UIGraphicsGetCurrentContext()!
            
            var imageWidth: Int!
            var imageHeight: Int!
            if imageType == "Main Home" && isUserImage || imageType == "Mask Home" {
                if imageType == "Main Home" && isUserImage { // ULO, Positive y up, positive x right
                    imageWidth = image.width
                    imageHeight = image.height
                    imageCTX.scaleBy(x: 1.0, y: -1.0)
                    imageCTX.translateBy(x: 0.0, y: -size.height)
                }
                else { // Normal coords
                    imageWidth = image.width
                    imageHeight = image.height
                }
                
                let contextAR = size.aspectRatio
                let croppingRectHeight = Int(CGFloat(imageWidth) / contextAR)
                let croppingRectSize = CGSize(width: imageWidth, height: croppingRectHeight)
                
                let croppingRectY = (CGFloat(imageHeight) * locationForCellView) - (croppingRectSize.height / 2)
                let croppingRectOrigin = CGPoint(x: 0.0, y: croppingRectY)
                
                let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                guard let croppedImage = image.cropping(to: croppingRect) else {
                    UIGraphicsEndImageContext()
                    completion?(nil)
                    return
                }
                
                imageCTX.draw(croppedImage, in: CGRect(origin: CGPoint.zero, size: size))
                guard let homeUIImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    UIGraphicsEndImageContext()
                    completion?(nil)
                    return
                }
                
                UIGraphicsEndImageContext()
                completion?(homeUIImage)
            }
            else { // is mainHome AppImage
                imageWidth = image.height  // URO, Positive y down, positive x left
                imageHeight = image.width
                imageCTX.scaleBy(x: -1.0, y: 1.0)
                imageCTX.translateBy(x: -size.width, y: 0.0)
                imageCTX.rotate(by: CGFloat.pi / 2)
                imageCTX.translateBy(x: 0.0, y: -size.width)
                
                let contextAR = size.aspectRatio
                
                let croppingRectWidth = Int(CGFloat(imageHeight) / contextAR)
                let croppingRectSize = CGSize(width: croppingRectWidth, height: imageHeight)
                
                let croppingRectX = (CGFloat(imageWidth) * locationForCellView) - (croppingRectSize.width / 2)
                let croppingRectOrigin = CGPoint(x: croppingRectX, y: 0.0)
                
                let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
                guard let croppedImage = image.cropping(to: croppingRect) else {
                    UIGraphicsEndImageContext()
                    completion?(nil)
                    return
                }
                
                imageCTX.draw(croppedImage, in: CGRect(origin: CGPoint.zero, size: CGSize(width: size.height, height: size.width)))
                guard let homeUIImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    UIGraphicsEndImageContext()
                    completion?(nil)
                    return
                }
                
                UIGraphicsEndImageContext()
                completion?(homeUIImage)
            }
        }
    }
}

internal class AppEventImage: UserEventImage {
    
    //
    // MARK: - Public
    //
    
    //
    // Paramters
    
    let category: String
    var recommendedLocationForCellView: CGFloat?
    var recordName: String?
    
    var maskImage: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .mask}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.mask], alertDelegate: true)}
        }
        return nil
    }
    
    var maskHomeImage: UIImage? {return _maskHomeImage}
    
    var thumbnail: CountdownImage? {
        if let i = images.index(where: {$0.imageType == .thumbnail}) {return images[i]}
        else {
            if delegate != nil {fetch(imageTypes: [CountdownImage.ImageType.thumbnail], alertDelegate: true)}
        }
        return nil
    }
    
    //
    // init
    
    override init?(fromEventImageInfo info: EventImageInfo) {
        
        let isAppImage = info.isAppImage
        print(isAppImage)
        guard isAppImage else {return nil}
        
        category = info.category!
        recordName = info.recordName
        if let _recommendedLocationForCellView = info.recommendedLocationForCellView.value {
            self.recommendedLocationForCellView = CGFloat(_recommendedLocationForCellView) / 100.0
        }
        super.init(fromEventImageInfo: info)
        
        let fileRootName = info.title.convertToFileName()
        if let image = CountdownImage(imageType: .mask, fileRootName: fileRootName, fileExtension: ".jpg") {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .mask, fileRootName: fileRootName, fileExtension: ".png") {
            images.append(image)
        }
        
        if images.isEmpty {return nil}
    }
    
    init?(category: String, title: String, recordName: String, recommendedLocationForCellView: CGFloat, images: [CountdownImage]) {
        self.category = category
        self.recordName = recordName
        self.recommendedLocationForCellView = recommendedLocationForCellView
        super.init(title: title, images: images)
    }
    
    //
    // Constants
    
    static let bundleMainImageInfo = [
        EventImageInfo(
            imageTitle: "Desert Dunes",
            imageCategory: "Travel",
            isAppImage: true,
            recordName: nil,
            hasMask: true,
            recommendedLocationForCellView: 45
        )
    ]
    
    //
    // Methods
    
    override func fetch(imageTypes: [CountdownImage.ImageType], alertDelegate: Bool) {
        
        guard recordName != nil && imageTypes.count > 0 else {
            delegate?.fetchComplete(forImageTypes: imageTypes, success: Array(repeating: false, count: imageTypes.count))
            return
        }
        
        var needToFetch = [CountdownImage.ImageType]()
        for imageType in imageTypes {
            if !fetching.contains(imageType) {
                fetching.append(imageType)
                needToFetch.append(imageType)
            }
        }
        if needToFetch.isEmpty {return}
        
        let recordID = CKRecordID(recordName: recordName!)
        fetchOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        var desiredKeys = [String]()
        for imageType in needToFetch {
            desiredKeys.append(contentsOf: [CloudKitKeys.EventImageKeys.fileRootName, imageType.recordKey, imageType.extensionRecordKey])
        }
        fetchOperation!.desiredKeys = desiredKeys
        
        fetchOperation!.fetchRecordsCompletionBlock = { [weak weakSelf = self] (_records, error) in
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
                        let imageFileRootName = record.value[CloudKitKeys.EventImageKeys.fileRootName] as! String
                        let imageFileExtension = record.value[imageType.extensionRecordKey] as! String
                        
                        do {
                            let imageData = try Data(contentsOf: imageAsset.fileURL)
                            let newImage = CountdownImage(imageType: imageType, fileRootName: imageFileRootName, fileExtension: imageFileExtension, imageData: imageData)
                            images.append(newImage)
                            success.append(true)
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
        CKContainer.default().publicCloudDatabase.add(fetchOperation!)
    }
    
    override func generateMainHomeImage(size: CGSize, locationForCellView: CGFloat, userInitiated: Bool, completion: ((UIImage?) -> Void)?) {
        guard let image = mainImage?.cgImage else {completion?(nil); return}
        
        _generateHomeImage(
            from: image,
            imageType: "Main Home",
            isUserImage: false,
            size: size,
            locationForCellView: locationForCellView,
            userInitiated: userInitiated,
            completion: { (mainHomeImage) in completion?(mainHomeImage)}
        )
    }
    
    func generateMaskHomeImage(size: CGSize, locationForCellView: CGFloat, userInitiated: Bool, completion: ((UIImage?) -> Void)?) {
        
        guard let maskImage = maskImage?.cgImage else {completion?(nil); return}
        
        _generateHomeImage(
            from: maskImage,
            imageType: "Mask Home",
            isUserImage: false,
            size: size,
            locationForCellView: locationForCellView,
            userInitiated: userInitiated,
            completion: { [weak self] (maskHomeImage) in
                completion?(maskHomeImage)
                self?._maskHomeImage = maskHomeImage
            }
        )
    }
    
    override func cancelNetworkFetches() {
        fetchOperation?.cancel()
        fetchOperation = nil
    }
    
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var fetchOperation: CKFetchRecordsOperation?
    fileprivate var _maskHomeImage: UIImage?
    
    //
    // Types
    
    fileprivate enum CloudErrors: Error {case imageCreationFailure, assetCreationFailure, noRecords, imageNotFound}
    
    //
    // Persistence
    
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
