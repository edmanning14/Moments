//
//  CellExpandSegue.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 6/13/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class CellExpandSegue: UIStoryboardSegue {
    
    fileprivate func getCropRect(locationForCellView: CGFloat, imageView: UIImageView) -> CGRect? {
        if let imageFrame = imageView.imageRect {
            print(imageFrame)
            let height: CGFloat = 160.0
            let width = self.destination.view.frame.width
            let x = imageFrame.origin.x
            let y = (imageFrame.origin.y + (imageFrame.height * locationForCellView)) - (height / 2)
            return CGRect(x: x, y: y, width: width, height: height)
        }
        else {return nil}
    }
    
    override func perform() {
        let tableViewVC = self.source as! MasterViewController
        let sourceNavVC = tableViewVC.navigationController!
        let destinationNavVC = self.destination as! UINavigationController
        let detailVC = destinationNavVC.viewControllers[0] as! DetailViewController
        
        if let ipForSelectedCell = tableViewVC.tableView.indexPathForSelectedRow {
            if let cell = tableViewVC.tableView.cellForRow(at: ipForSelectedCell) as? EventTableViewCell {
                if let mainWindow = UIApplication.shared.keyWindow {
                    let cellFrame = tableViewVC.tableView.rectForRow(at: ipForSelectedCell)
                    let cellOffsetFromTopOfTableViewContentView = cellFrame.origin.y - tableViewVC.tableView.contentOffset.y
                    let sourceNavBarHeight = sourceNavVC.navigationBar.frame.height
                    let statusBarHeight = UIApplication.shared.statusBarFrame.height
                    let movingView = UIView(frame: CGRect(x: 0.0, y: cellOffsetFromTopOfTableViewContentView + sourceNavBarHeight + statusBarHeight, width: mainWindow.frame.width, height: 160.0))
                    movingView.translatesAutoresizingMaskIntoConstraints = false
                    if let homeImage = cell.mainImageView.image {
                        let imageView = UIImageView(image: homeImage)
                        imageView.translatesAutoresizingMaskIntoConstraints = false
                        imageView.frame = movingView.bounds
                        imageView.contentMode = .scaleAspectFit
                        movingView.addSubview(imageView)
                        print(imageView.frame)
                    }
                    else {movingView.backgroundColor = UIColor.clear}
                    
                    let transitionView = UIView(frame: detailVC.view.frame)
                    transitionView.translatesAutoresizingMaskIntoConstraints = false
                    
                    let blackRect1 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: 0.0, width: movingView.frame.width, height: movingView.frame.origin.y))
                    let blackRect2 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: movingView.frame.origin.y + movingView.frame.height, width: movingView.frame.width, height: detailVC.view.bounds.height - (movingView.frame.origin.y + movingView.frame.height)))
                    
                    blackRect1.translatesAutoresizingMaskIntoConstraints = false
                    blackRect2.translatesAutoresizingMaskIntoConstraints = false
                    blackRect1.backgroundColor = UIColor.black
                    blackRect2.backgroundColor = UIColor.black
                    
                    transitionView.addSubview(blackRect1)
                    transitionView.addSubview(blackRect2)
                    transitionView.addSubview(movingView)
                    
                    mainWindow.addSubview(transitionView)
                    
                    print(movingView.frame)
                    print(blackRect1.frame)
                    print(blackRect2.frame)
                    
                    let event = tableViewVC.items(forSection: ipForSelectedCell.section)[ipForSelectedCell.row]
                    if let intLocationForCellView = event.locationForCellView.value {
                        let locationForCellView = CGFloat(intLocationForCellView) / 100.0
                        detailVC.loadViewIfNeeded()
                        print(detailVC.view.frame)
                        let imageView = detailVC.detailViewCell!.mainImageView!
                        if let cropRect = getCropRect(locationForCellView: locationForCellView, imageView: imageView) {
                            print(cropRect)
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: 0.3,
                                delay: 0.0,
                                options: .curveLinear,
                                animations: {sourceNavVC.view.layer.opacity = 0.0},
                                completion: nil
                            )
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: 0.3,
                                delay: 0.0,
                                options: .curveEaseInOut,
                                animations: {
                                    let destNavBarHeight = destinationNavVC.navigationBar.frame.height
                                    print(destNavBarHeight)
                                    print(detailVC.detailViewCell.mainImageView.frame.origin.y)
                                    print(detailVC.view.safeAreaInsets.top)
                                    let shitToAdd = destNavBarHeight + statusBarHeight + detailVC.detailViewCell.mainImageView.frame.origin.y + detailVC.view.safeAreaInsets.top
                                    movingView.frame.origin.y = cropRect.origin.y + shitToAdd
                                    blackRect1.frame.size = CGSize(width: blackRect1.frame.width, height: cropRect.origin.y + shitToAdd)
                                    let newRect2Origin = CGPoint(x: blackRect2.frame.origin.x, y: cropRect.origin.y + cropRect.size.height + shitToAdd)
                                    let newRect2Size = CGSize(width: blackRect2.frame.size.width, height: detailVC.view.frame.height - (cropRect.origin.y + cropRect.size.height + shitToAdd))
                                    blackRect2.frame = CGRect(origin: newRect2Origin, size: newRect2Size)
                            },
                                completion: { (position) in
                                    mainWindow.sendSubview(toBack: sourceNavVC.view)
                                    sourceNavVC.view.layer.opacity = 1.0
                                    var vcs = sourceNavVC.viewControllers
                                    vcs.append(destinationNavVC)
                                    sourceNavVC.setViewControllers(vcs, animated: false)
                                    
                                    let imageView = movingView.subviews[0] as! UIImageView
                                    imageView.image = nil
                                    imageView.backgroundColor = UIColor.clear
                                    movingView.backgroundColor = UIColor.clear
                                    
                                    UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: 0.3,
                                        delay: 0.0,
                                        options: .curveEaseInOut,
                                        animations: {
                                            blackRect1.frame.size = CGSize(width: blackRect1.frame.width, height: 0.0)
                                            blackRect2.frame.origin.y = detailVC.view.frame.height
                                            movingView.frame = detailVC.view.frame
                                    },
                                        completion: { (position) in
                                            transitionView.removeFromSuperview()
                                    }
                                    )
                            }
                            )
                        }
                    }
                }
            }
        }
    }
}
