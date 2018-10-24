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
import os
import CoreML

internal enum WidgetConfigurations: String {
    case nextEvent = "Next Event"
    case lastEvent = "Last Event"
    case randomUpcoming = "Random Upcoming Event"
    case randomPast = "Random Past Event"
    case random = "Random Event"
}

internal enum RepeatingOptions: String {
    case never = "Never"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

internal enum DisplayInfoOptions: String {
    case none = "None"
    case tagline = "Tagline"
    case date = "Date"
}

internal enum ToggleMaskOptions: String {
    case on = "On"
    case off = "Off"
}

internal enum NotificationsOptions: String {
    case custom = "Custom"
    case _default = "Default"
    case off = "Off"
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
            catch {
                os_log("Error saving %@ to disk.", log: .default, type: .error, self.fileName)
                return false
            }
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
            else {os_log("There was an error loading \"%@\" from the provided file path.", log: .default, type: .error, self.fileRootName)}
        }
        else if let data = imageData {
            if let image = UIImage(data: data, scale: UIScreen.main.scale) {_uiImage = image}
            else {os_log("There was an error creating \"%@\" from the provided image data.", log: .default, type: .error, self.fileRootName)}
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
                    else {os_log("There was an error creating \"%@\" from the provided png data provider.", log: .default, type: .error, self.fileRootName)}
                case ".jpg":
                    if let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                    else {os_log("There was an error creating \"%@\" from the provided jpg data provider.", log: .default, type: .error, self.fileRootName)}
                default: os_log("Unrecognized file extension for \"%@\".", log: .default, type: .error, self.fileRootName)
                }
            }
            else {os_log("There was an error creating the data provider for \"%@\" from the provided file path.", log: .default, type: .error, self.fileRootName)}
        }
        else if let data = imageData {
            if let dataProvider = CGDataProvider(data: data as CFData) {
                switch fileExtension {
                case ".png":
                    if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                    else {os_log("There was an error loading \"%@\" from the data provider provided.", log: .default, type: .error, self.fileRootName)}
                case ".jpg":
                    if let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .perceptual) {
                        _cgImage = image
                    }
                    else {os_log("There was an error loading \"%@\" from the data provider provided.", log: .default, type: .error, self.fileRootName)}
                default: os_log("Unrecognized file extension for \"%@\".", log: .default, type: .error, self.fileRootName)
                }
            }
            else {os_log("There was an error creating the data provider for \"%@\" from the provided file path.", log: .default, type: .error, self.fileRootName)}
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
    
    /**
     Returns false if any of the images are not saved to disk.
     */
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
        
        if let image = CountdownImage(imageType: .mask, fileRootName: fileRootName, fileExtension: ".jpg") {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .mask, fileRootName: fileRootName, fileExtension: ".png") {
            images.append(image)
        }
        
        if let image = CountdownImage(imageType: .thumbnail, fileRootName: fileRootName, fileExtension: ".jpg") {
            images.append(image)
        }
        else if let image = CountdownImage(imageType: .thumbnail, fileRootName: fileRootName, fileExtension: ".png") {
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
    
    /**
     Use to request full sized main image. May execute asyncronously to fetch image from photos album. Image is cached. Dispatch back to main with each call to make UI changes.
     */
    func requestMainImage(_ completion: @escaping (CountdownImage?) -> Void) {
        if let i = images.index(where: {$0.imageType == .main}) {completion(images[i]); return}
        else {
            if mainImageFetchOperationQueue == nil {
                guard let asset = photoAsset else {completion(nil); return}
                
                mainImageFetchOperationQueue = OperationQueue()
                mainImageFetchOperationQueue!.isSuspended = true
                mainImageFetchOperationQueue!.qualityOfService = .userInitiated
                
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let imageName = asset.localIdentifier
                    let fileRootName = imageName.convertToFileName()
                    let options = PHImageRequestOptions()
                    options.version = .original
                    options.deliveryMode = .highQualityFormat
                    options.isNetworkAccessAllowed = true
                    let id = PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { [weak self] (_image, _info) in
                        if let info = _info, let error = info[PHImageErrorKey] as? NSError {
                            os_log("PHImageError: %@", log: .default, type: .error, error.debugDescription)
                            completion(nil); self?.mainImageFetchOperationQueue = nil; return
                        }
                        if let image = _image {
                            let fileExtension = ".jpg"
                            let wrappedImage = CountdownImage(imageType: .main, fileRootName: fileRootName, fileExtension: fileExtension, image: image)
                            self?.images.append(wrappedImage)
                            self?.imageRequest = nil
                            completion(wrappedImage)
                            self?.mainImageFetchOperationQueue?.isSuspended = false
                        }
                        else {
                            os_log("DataUTI and/or ImageData are nil! Incorrect user image asset fetched maybe?", log: .default, type: .error)
                            self?.mainImageFetchOperationQueue = nil
                            completion(nil)
                        }
                    }
                    self?.imageRequest = id
                }
            }
            else {
                mainImageFetchOperationQueue?.addOperation { [weak self] in
                    if let i = self?.images.index(where: {$0.imageType == .main}) {
                        completion(self!.images[i]); return
                    }
                }
            }
        }
    }
    
    /**
     Use to request full sized mask image. May execute asyncronously to generate image using coreML. Image is cached. Dispatch back to main with each call to make UI changes.
     */
    func requestMaskImage(_ completion: @escaping (CountdownImage?) -> Void) {
        if let i = images.index(where: {$0.imageType == .mask}) {completion(images[i]); return}
        else if imagesAreSavedToDisk {
            
        }
        else {
            if maskImageFetchOperationQueue == nil {
                guard let i = images.index(where: {$0.imageType == .main}) else {completion(nil); return}
                let mainImage = images[i]
                guard let inputImage = mainImage.uiImage else {completion(nil); return}
                
                maskImageFetchOperationQueue = OperationQueue()
                maskImageFetchOperationQueue!.isSuspended = true
                maskImageFetchOperationQueue!.qualityOfService = .userInitiated
                
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let hedSO3 = HED_so3()
                    let outputLayerName = "upscore-dsn3"
                    
                    // Remember the time when we started
                    let startDate = Date()
                    
                    // Convert our image to proper input format
                    // In this case we need to feed pixel buffer which is 500x500 sized.
                    let inputW = 500
                    let inputH = 500
                    let originalWidth = Int(inputImage.size.width * inputImage.scale)
                    let originalHeight = Int(inputImage.size.height * inputImage.scale)
                    guard let inputPixelBuffer = inputImage.resized(width: inputW, height: inputH).pixelBuffer(width: inputW, height: inputH) else {
                        fatalError("Couldn't create pixel buffer.")
                    }
                    
                    // Use different models based on what output we need
                    let featureProvider: MLFeatureProvider
                    featureProvider = try! hedSO3.prediction(data: inputPixelBuffer)
                    
                    // Retrieve results
                    guard let outputFeatures = featureProvider.featureValue(for: outputLayerName)?.multiArrayValue else {
                        fatalError("Couldn't retrieve features")
                    }
                    
                    // Calculate total buffer size by multiplying shape tensor's dimensions
                    let bufferSize = outputFeatures.shape.lazy.map { $0.intValue }.reduce(1, { $0 * $1 })
                    
                    // Get data pointer to the buffer
                    let dataPointer = UnsafeMutableBufferPointer(start: outputFeatures.dataPointer.assumingMemoryBound(to: Double.self),
                                                                 count: bufferSize)
                    
                    // Prepare buffer for single-channel image result
                    var imgData = [UInt8](repeating: 0, count: bufferSize)
                    
                    // Normalize result features by applying sigmoid to every pixel and convert to UInt8
                    for i in 0..<inputW {
                        for j in 0..<inputH {
                            let idx = i * inputW + j
                            let value = dataPointer[idx]
                            
                            let sigmoid = { (input: Double) -> Double in
                                return 1 / (1 + exp(-input))
                            }
                            
                            let result = sigmoid(value)
                            imgData[idx] = UInt8(result * 255)
                        }
                    }
                    
                    // Create single chanel gray-scale image out of our freshly-created buffer
                    let cfbuffer = CFDataCreate(nil, &imgData, bufferSize)!
                    let dataProvider = CGDataProvider(data: cfbuffer)!
                    let colorSpace = CGColorSpaceCreateDeviceGray()
                    let cgImage = CGImage(width: inputW, height: inputH, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: inputW, space: colorSpace, bitmapInfo: [], provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    let resultUIImage = UIImage(cgImage: cgImage!)
                    let finalUIImage = resultUIImage.resized(width: originalWidth, height: originalHeight)
                    
                    guard let title = self?.title else {completion(nil); return}
                    let resultImage = CountdownImage(imageType: .mask, fileRootName: title + "Mask", fileExtension: ".jpg", image: finalUIImage)
                    
                    // Calculate the time of inference
                    let endDate = Date()
                    
                    print("Inference is finished in \(endDate.timeIntervalSince(startDate))")
                    self?.images.append(resultImage)
                    self?.maskImageFetchOperationQueue?.isSuspended = false
                    completion(resultImage)
                }
            }
            else {
                maskImageFetchOperationQueue?.addOperation { [weak self] in
                    if let i = self?.images.index(where: {$0.imageType == .mask}) {
                        completion(self!.images[i]); return
                    }
                }
            }
        }
    }
    
    /**
     Use to request main home image. Executes asyncronously to generate image each time, does not cache image. Dispatch back to main with each call to make UI changes.
     */
    func requestMainHomeImage(size: CGSize, locationForCellView: CGFloat, completion: @escaping (UIImage?) -> Void) {
        guard let i = images.index(where: {$0.imageType == .main}) else {completion(nil); return}
        guard let mainImage = images[i].uiImage else {completion(nil); return}
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let image = self?._generateHomeImage(from: mainImage, size: size, locationForCellView: locationForCellView)
            completion(image)
        }
    }
    
    /**
     Use to request mask home image. Executes asyncronously to generate image each time, does not cache image. Will attempt to request mask image if it is not cached. Dispatch back to main with each call to make UI changes.
    */
    func requestMaskHomeImage(size: CGSize, locationForCellView: CGFloat, completion: @escaping (UIImage?) -> Void) {
        if let i = images.index(where: {$0.imageType == .mask}) {
            guard let maskImage = images[i].uiImage else {completion(nil); return}
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                let image = self?._generateHomeImage(from: maskImage, size: size, locationForCellView: locationForCellView)
                completion(image)
            }
        }
        else {
            requestMaskImage { (countdownImage) in
                guard let maskImage = countdownImage?.uiImage else {completion(nil); return}
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let image = self?._generateHomeImage(from: maskImage, size: size, locationForCellView: locationForCellView)
                    completion(image)
                }
            }
        }
    }
    
    func cancelNetworkFetches() {
        if let request = imageRequest {
            PHImageManager.default().cancelImageRequest(request)
            imageRequest = nil
        }
    }
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var images = [CountdownImage]()
    fileprivate var imageRequest: PHImageRequestID?
    
    fileprivate var mainImageFetchOperationQueue: OperationQueue?
    fileprivate var maskImageFetchOperationQueue: OperationQueue?
    
    //
    // Methods
    
    fileprivate func _generateHomeImage(from image: UIImage, size: CGSize, locationForCellView: CGFloat) -> UIImage {
        let croppingRectWidth = image.size.width
        let croppingRectAR = size.aspectRatio
        let croppingRectHeight = croppingRectWidth / croppingRectAR
        let croppingRectSize = CGSize(width: croppingRectWidth, height: croppingRectHeight)
        
        let croppingRectY = (image.size.height * locationForCellView) - (croppingRectSize.height / 2)
        let croppingRectOrigin = CGPoint(x: 0.0, y: croppingRectY)
        
        let croppingRect = CGRect(origin: croppingRectOrigin, size: croppingRectSize)
        return image.croppedImage(inRect: croppingRect)
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
    
    //
    // init
    
    override init?(fromEventImageInfo info: EventImageInfo) {
        
        let isAppImage = info.isAppImage
        guard isAppImage else {return nil}
        
        category = info.category!
        recordName = info.recordName
        if let _recommendedLocationForCellView = info.recommendedLocationForCellView.value {
            self.recommendedLocationForCellView = CGFloat(_recommendedLocationForCellView) / 100.0
        }
        super.init(fromEventImageInfo: info)
        
        if images.isEmpty {return nil}
    }
    
    init?(category: String, title: String, recordName: String, recommendedLocationForCellView: CGFloat?, images: [CountdownImage]) {
        self.category = category
        self.recordName = recordName
        self.recommendedLocationForCellView = recommendedLocationForCellView
        super.init(title: title, images: images)
    }
    
    //
    // Constants
    
    static let bundleMainImageInfo = [
        EventImageInfo(
            imageTitle: "Sparkler Art",
            imageCategory: "Holidays",
            isAppImage: true,
            recordName: nil,
            hasMask: false,
            recommendedLocationForCellView: 50
        )
    ]
    
    //
    // Methods
    
    /**
     Use to request full sized main image. May execute asyncronously to fetch image from iCloud. Function is NOT thread safe. Image is cached. Dispatch back to main with each call to make UI changes.
     */
    override func requestMainImage(_ completion: @escaping (CountdownImage?) -> Void) {
        if let i = images.index(where: {$0.imageType == .main}) {completion(images[i]); return}
        else {
            if mainImageFetchOperationQueue == nil {
                guard let record = recordName else {completion(nil); return}
                
                mainImageFetchOperationQueue = OperationQueue()
                mainImageFetchOperationQueue!.isSuspended = true
                mainImageFetchOperationQueue!.qualityOfService = .userInitiated
    
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let recordID = CKRecordID(recordName: record)
                    self?.mainImageFetchOperation = CKFetchRecordsOperation(recordIDs: [recordID])
                    
                    let fileRootName = CloudKitKeys.EventImageKeys.fileRootName
                    let recordKey = CountdownImage.ImageType.main.recordKey
                    let extensionRecordKey = CountdownImage.ImageType.main.extensionRecordKey
                    let desiredKeys = [fileRootName, recordKey, extensionRecordKey]
                    self?.mainImageFetchOperation?.desiredKeys = desiredKeys
                    
                    self?.mainImageFetchOperation?.fetchRecordsCompletionBlock = { [weak self] (_records, _error) in
                        if let error = _error {
                            os_log("Error fetching records from the cloud: %@", log: .default, type: .error, error.localizedDescription)
                            completion(nil); self?.mainImageFetchOperationQueue = nil; return
                        }
                        
                        guard let records = _records, !records.isEmpty else {
                            os_log("Record %@ could not be fetched from the cloud.", log: .default, type: .error, recordID)
                            completion(nil); self?.mainImageFetchOperationQueue = nil; return
                        }
                        
                        for record in records {
                            guard let imageAsset = record.value[recordKey] as? CKAsset else {
                                os_log("Error getting imageAsset", log: .default, type: .error)
                                completion(nil); self?.mainImageFetchOperationQueue = nil; return
                            }
                            guard let imageFileRootName = record.value[fileRootName] as? String else {
                                os_log("Error getting imageFileRootName", log: .default, type: .error)
                                completion(nil); self?.mainImageFetchOperationQueue = nil; return
                            }
                            guard let imageFileExtension = record.value[extensionRecordKey] as? String else {
                                os_log("Error getting extensionRecordKey", log: .default, type: .error)
                                completion(nil); self?.mainImageFetchOperationQueue = nil; return
                            }
                            
                            do {
                                let imageData = try Data(contentsOf: imageAsset.fileURL)
                                let newImage = CountdownImage(imageType: .main, fileRootName: imageFileRootName, fileExtension: imageFileExtension, imageData: imageData)
                                self?.images.append(newImage)
                                completion(newImage)
                                self?.mainImageFetchOperationQueue?.isSuspended = false
                            }
                            catch {
                                os_log("Image data creation failed for %@", log: .default, type: .error, fileRootName)
                                completion(nil); self?.mainImageFetchOperationQueue = nil; return
                            }
                        }
                    }
                    self?.mainImageFetchOperation?.database = CKContainer.default().publicCloudDatabase
                    self?.mainImageFetchOperation?.start()
                    //CKContainer.default().publicCloudDatabase.add(self!.mainImageFetchOperation!)
                }
            }
            else {
                mainImageFetchOperationQueue?.addOperation { [weak self] in
                    if let i = self?.images.index(where: {$0.imageType == .main}) {
                        completion(self!.images[i]); return
                    }
                }
            }
        }
    }
    
    /**
     Use to request thumbnail of main image. May execute asyncronously to fetch image from iCloud. Image is cached. Dispatch back to main with each call to make UI changes.
     */
    func requestThumbnailImage(_ completion: @escaping (CountdownImage?) -> Void) {
        if let i = images.index(where: {$0.imageType == .thumbnail}) {completion(images[i]); return}
        else {
            // Create a queue that will suspend until results processing is done
            if thumbnailFetchOperationQueue == nil {
                guard let record = recordName else {completion(nil); return}
                
                thumbnailFetchOperationQueue = OperationQueue()
                thumbnailFetchOperationQueue!.isSuspended = true
                thumbnailFetchOperationQueue!.qualityOfService = .userInitiated
                
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    let recordID = CKRecordID(recordName: record)
                    self?.thumbnailFetchOperation = CKFetchRecordsOperation(recordIDs: [recordID])
                    
                    let fileRootName = CloudKitKeys.EventImageKeys.fileRootName
                    let recordKey = CountdownImage.ImageType.thumbnail.recordKey
                    let extensionRecordKey = CountdownImage.ImageType.thumbnail.extensionRecordKey
                    let desiredKeys = [fileRootName, recordKey, extensionRecordKey]
                    self?.thumbnailFetchOperation?.desiredKeys = desiredKeys
                    
                    self?.thumbnailFetchOperation?.fetchRecordsCompletionBlock = { [weak self] (_records, _error) in
                        if let error = _error {
                            os_log("Error fetching records from the cloud: %@", log: .default, type: .error, error.localizedDescription)
                            completion(nil); return
                        }
                        
                        guard let records = _records, !records.isEmpty else {
                            os_log("Record %@ could not be fetched from the cloud.", log: .default, type: .error, recordID)
                            completion(nil); return
                        }
                        
                        for record in records {
                            guard let imageAsset = record.value[recordKey] as? CKAsset else {
                                os_log("Error getting imageAsset", log: .default, type: .error)
                                completion(nil); return
                            }
                            guard let imageFileRootName = record.value[fileRootName] as? String else {
                                os_log("Error getting imageFileRootName", log: .default, type: .error)
                                completion(nil); return
                            }
                            guard let imageFileExtension = record.value[extensionRecordKey] as? String else {
                                os_log("Error getting extensionRecordKey", log: .default, type: .error)
                                completion(nil); return
                            }
                            
                            do {
                                let imageData = try Data(contentsOf: imageAsset.fileURL)
                                let newImage = CountdownImage(imageType: .thumbnail, fileRootName: imageFileRootName, fileExtension: imageFileExtension, imageData: imageData)
                                self?.images.append(newImage)
                                completion(newImage)
                                self?.thumbnailFetchOperationQueue?.isSuspended = false
                            }
                            catch {
                                os_log("Image data creation failed for %@", log: .default, type: .error, fileRootName)
                                completion(nil); return
                            }
                        }
                    }
                    self?.thumbnailFetchOperation?.database = CKContainer.default().publicCloudDatabase
                    self?.thumbnailFetchOperation?.start()
                    //CKContainer.default().publicCloudDatabase.add(thumbnailFetchOperation!)
                }
            }
            // Add to the opperations queue if it exists, will suspend until results processing.
            else {
                thumbnailFetchOperationQueue?.addOperation { [weak self] in
                    if let i = self?.images.index(where: {$0.imageType == .thumbnail}) {
                        completion(self!.images[i]); return
                    }
                }
            }
        }
    }
    
    override func cancelNetworkFetches() {
        mainImageFetchOperation?.cancel()
        mainImageFetchOperation = nil
        thumbnailFetchOperation?.cancel()
        thumbnailFetchOperation = nil
        mainImageFetchOperationQueue?.cancelAllOperations()
        mainImageFetchOperationQueue = nil
        thumbnailFetchOperationQueue?.cancelAllOperations()
        thumbnailFetchOperationQueue = nil
    }
    
    
    //
    // MARK: - Private
    //
    
    //
    // Parameters
    
    fileprivate var thumbnailFetchOperationQueue: OperationQueue?
    fileprivate var mainImageFetchOperation: CKFetchRecordsOperation?
    fileprivate var thumbnailFetchOperation: CKFetchRecordsOperation?
    
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
