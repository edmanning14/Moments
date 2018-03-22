//
//  ImageFileManager.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 2/5/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class ImageFileManager {
    
    let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let bundleImageFileNames = ["DesertDunes", "DesertDunesMask", "SwissAlps", "SwissAlpsMask"]
    
    func saveImage(_ image: Data, named name: String) -> URL {
        let newPathComponent = name + ".png"
        let writeURL = documentsURL.appendingPathComponent(newPathComponent)
        
        do {try image.write(to: writeURL, options: .atomic)}
        catch {
            // TODO: Error handling
            print(error.localizedDescription)
            fatalError("Failed to write \(name) image to disk!")
        }
        
        return writeURL
    }
    
    func returnUIImage(named fileName: String) -> UIImage? {
        
        if bundleImageFileNames.contains(fileName) {
            if let path = Bundle.main.path(forResource: fileName, ofType: ".png") {
                if let image = UIImage(contentsOfFile: path) {return image}
            }
        }
        else {
            let pathComponent = fileName + ".png"
            let fileURL = documentsURL.appendingPathComponent(pathComponent)
            if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                return UIImage(contentsOfFile: fileURL.relativePath)
            }
        }
        return nil
    }
    
    func returnCGImage(named fileName: String) -> CGImage? {
        
        if bundleImageFileNames.contains(fileName) {
            if let path = Bundle.main.path(forResource: fileName, ofType: ".png") {
                let url = URL(fileURLWithPath: path)
                if let dataProvider = CGDataProvider(url: url as CFURL) {
                    return CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
                }
            }
        }
        else {
            let pathComponent = fileName + ".png"
            let fileURL = documentsURL.appendingPathComponent(pathComponent)
            if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                if let dataProvider = CGDataProvider(url: fileURL as CFURL) {
                    return CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .perceptual)
                }
            }
        }
        return nil
    }
    
    func getBundleUIImages() -> [UIImage] {
        var arrayToReturn = [UIImage]()
        for fileName in bundleImageFileNames {
            if let image = returnUIImage(named: fileName) {arrayToReturn.append(image)}
        }
        return arrayToReturn
    }
    
    func loadUIImages(named fileNames: [String]) -> [UIImage] {
        var arrayToReturn = [UIImage]()
        for fileName in fileNames {
            
        }
        return arrayToReturn
    }
}
