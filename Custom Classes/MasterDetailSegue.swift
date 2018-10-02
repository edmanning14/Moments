//
//  MasterDetailSegue.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 6/13/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class MasterDetailSegue: UIStoryboardSegue {
    
    fileprivate func getCropRect(locationForCellView: CGFloat, imageView: UIImageView) -> CGRect? {
        if let imageFrame = imageView.imageRect {
            let height: CGFloat = 160.0
            let width = self.destination.view.frame.width
            let x = imageFrame.origin.x
            let cropRectYRelativeToImage = (imageFrame.size.height * locationForCellView) - (height / 2)
            let cropRectYRelativeToImageView = cropRectYRelativeToImage + imageFrame.origin.y
            
            return CGRect(x: x, y: cropRectYRelativeToImageView, width: width, height: height)
        }
        else {return nil}
    }
    
    override func perform() {
        
        switch identifier {
            
        case "showDetail":
            let tableViewVC = self.source as! MasterViewController
            let sourceNavVC = tableViewVC.navigationController!
            let destinationNavVC = self.destination as! UINavigationController
            let detailVC = destinationNavVC.viewControllers[0] as! DetailViewController
            
            if let ipForSelectedCell = tableViewVC.tableView.indexPathForSelectedRow {
                if let cell = tableViewVC.tableView.cellForRow(at: ipForSelectedCell) as? EventTableViewCell {
                    if let mainWindow = UIApplication.shared.keyWindow {
                        let cellFrameToContentView = tableViewVC.tableView.rectForRow(at: ipForSelectedCell)
                        let contentOffset = tableViewVC.tableView.contentOffset.y
                        let cellFrameToTableView = CGRect(origin: CGPoint(x: cellFrameToContentView.origin.x, y: cellFrameToContentView.origin.y - contentOffset), size: cellFrameToContentView.size)
                        let navStuffAdjustment = source.view.convert(CGPoint(x: 0.0, y: contentOffset), to: mainWindow).y
                        let movingView = UIView(frame: CGRect(x: 0.0, y: cellFrameToTableView.origin.y + navStuffAdjustment, width: mainWindow.frame.width, height: 160.0))
                        movingView.translatesAutoresizingMaskIntoConstraints = false
                        movingView.layer.cornerRadius = 3.0
                        movingView.layer.masksToBounds = true
                        movingView.backgroundColor = UIColor.black
                        if let homeImage = cell.mainImageView.image {
                            let imageView = UIImageView(image: homeImage)
                            imageView.translatesAutoresizingMaskIntoConstraints = false
                            imageView.frame = movingView.bounds
                            imageView.contentMode = .scaleAspectFit
                            movingView.addSubview(imageView)
                        }
                        else {movingView.backgroundColor = UIColor.clear}
                        
                        let transitionView = UIView(frame: detailVC.view.frame)
                        transitionView.translatesAutoresizingMaskIntoConstraints = false
                        transitionView.layer.cornerRadius = 3.0
                        transitionView.layer.masksToBounds = true
                        
                        
                        let blackRect1 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: navStuffAdjustment, width: movingView.frame.width, height: movingView.frame.origin.y - navStuffAdjustment))
                        let blackRect2 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: movingView.frame.origin.y + movingView.frame.height, width: movingView.frame.width, height: max(detailVC.view.bounds.height - (movingView.frame.origin.y + movingView.frame.height), 0.0)))
                        
                        blackRect1.translatesAutoresizingMaskIntoConstraints = false
                        blackRect2.translatesAutoresizingMaskIntoConstraints = false
                        blackRect1.backgroundColor = UIColor.black
                        blackRect2.backgroundColor = UIColor.black
                        
                        transitionView.addSubview(blackRect1)
                        transitionView.addSubview(blackRect2)
                        transitionView.addSubview(movingView)
                        
                        // Master view belonging to splitViewController is only subview of mainWindow at this time.
                        var row = ipForSelectedCell.row
                        if let welcome = tableViewVC.welcomeCellIndexPath, welcome.section == ipForSelectedCell.section {row -= 1}
                        if let tip = tableViewVC.tipCellIndexPath, tip.section == ipForSelectedCell.section, tip.row < ipForSelectedCell.row {row -= 1}
                        let event = tableViewVC.items(forSection: ipForSelectedCell.section)[row]
                        
                        if let intLocationForCellView = event.locationForCellView.value {
                            let locationForCellView = CGFloat(intLocationForCellView) / 100.0
                            
                            let renderer = UIGraphicsImageRenderer(bounds: mainWindow.frame)
                            let image = renderer.image { (ctx) in mainWindow.layer.render(in: ctx.cgContext)}
                            let fauxImageView = UIImageView(image: image)
                            mainWindow.addSubview(fauxImageView)
                            
                            movingView.layer.opacity = 0.0
                            transitionView.layer.opacity = 0.0
                            mainWindow.addSubview(transitionView)
                            
                            //
                            // Reorder views, add new VC to nav stack
                            var vcs = sourceNavVC.viewControllers
                            vcs.append(self.destination)
                            sourceNavVC.setViewControllers(vcs, animated: false)
                            
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: 0.2,
                                delay: 0.0,
                                options: .curveLinear,
                                animations: {transitionView.layer.opacity = 1.0},
                                completion: nil
                            )
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: 0.2,
                                delay: 0.0,
                                options: .curveLinear,
                                animations: {movingView.layer.opacity = 1.0},
                                completion:  {(poistion) in
                                    fauxImageView.removeFromSuperview()
                                    let imageView = detailVC.detailViewCell!.mainImageView!
                                    if let cropRect = self.getCropRect(locationForCellView: locationForCellView, imageView: imageView) {
                                        
                                        //
                                        // Prep for animations
                                        let newMovingViewOrigin = CGPoint(x: movingView.frame.origin.x, y: navStuffAdjustment + cropRect.origin.y)
                                        let newRect2Origin = CGPoint(x: blackRect2.frame.origin.x, y: newMovingViewOrigin.y + cropRect.size.height)
                                        let newRect2Size = CGSize(width: blackRect2.frame.size.width, height: self.destination.view.frame.height - (newMovingViewOrigin.y + cropRect.size.height))

                                        //
                                        // Animate move of transitionView
                                        UIViewPropertyAnimator.runningPropertyAnimator(
                                            withDuration: 0.3,
                                            delay: 0.0,
                                            options: .curveEaseIn,
                                            animations: {
                                                movingView.frame.origin.y = newMovingViewOrigin.y
                                                blackRect1.frame.size = CGSize(width: blackRect1.frame.width, height: newMovingViewOrigin.y - navStuffAdjustment)
                                                blackRect2.frame = CGRect(origin: newRect2Origin, size: newRect2Size)
                                        },
                                            completion: { (position) in
                                                
                                                //
                                                // Remove transitionView image
                                                let imageView = movingView.subviews[0] as! UIImageView
                                                imageView.image = nil
                                                imageView.backgroundColor = UIColor.clear
                                                movingView.backgroundColor = UIColor.clear
                                                
                                                //
                                                // Animate the expansion of the transitionView to reveal underlying detailVC
                                                UIViewPropertyAnimator.runningPropertyAnimator(
                                                    withDuration: 0.3,
                                                    delay: 0.0,
                                                    options: .curveLinear,
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
                            )
                        }
                        else { // No cell view location, do some normal transition.
                            var vcs = sourceNavVC.viewControllers
                            vcs.append(self.destination)
                            sourceNavVC.setViewControllers(vcs, animated: false)
                        }
                    }
                }
            }
            
        case "Unwind to Master":
            let tableViewVC = self.destination as! MasterViewController
            let destinationNavVC = tableViewVC.navigationController!
            let detailVC = self.source as! DetailViewController
            
            if let ipForSelectedCell = tableViewVC.tableView.indexPathForSelectedRow {
            if let cell = tableViewVC.tableView.cellForRow(at: ipForSelectedCell) as? EventTableViewCell {
            if let mainImage = cell.mainImageView.image {
            if let mainWindow = UIApplication.shared.keyWindow {
                
                var row = ipForSelectedCell.row
                if let welcome = tableViewVC.welcomeCellIndexPath, welcome.section == ipForSelectedCell.section {row -= 1}
                if let tip = tableViewVC.tipCellIndexPath, tip.section == ipForSelectedCell.section, tip.row < ipForSelectedCell.row {row -= 1}
                let event = tableViewVC.items(forSection: ipForSelectedCell.section)[row]
                let detailImageView = detailVC.detailViewCell!.mainImageView!
                
                if let intLocationForCellView = event.locationForCellView.value, let cropRect = self.getCropRect(locationForCellView: CGFloat(intLocationForCellView) / 100.0, imageView: detailImageView) {
                    
                    let cellFrameToContentView = tableViewVC.tableView.rectForRow(at: ipForSelectedCell)
                    let contentOffset = tableViewVC.tableView.contentOffset.y
                    let cellOriginToTableView = CGPoint(x: cellFrameToContentView.origin.x, y: cellFrameToContentView.origin.y - contentOffset)
                    let navStuffAdjustment = destination.view.convert(CGPoint(x: 0.0, y: contentOffset), to: mainWindow).y
                    let destinationOriginForMovingView = CGPoint(x: 0.0, y: cellOriginToTableView.y + navStuffAdjustment)
                    
                    let startOriginForMovingView = CGPoint(x: 0.0, y: cropRect.origin.y + navStuffAdjustment)
                    let movingView = UIView(frame: CGRect(origin: startOriginForMovingView, size: cropRect.size))
                    movingView.translatesAutoresizingMaskIntoConstraints = false
                    movingView.layer.cornerRadius = 3.0
                    movingView.layer.masksToBounds = true
                    movingView.backgroundColor = UIColor.black
                    
                    let imageView = UIImageView(image: mainImage)
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.frame = movingView.bounds
                    imageView.contentMode = .scaleAspectFit
                    movingView.addSubview(imageView)
                    
                    let transitionView = UIView(frame: mainWindow.frame)
                    transitionView.translatesAutoresizingMaskIntoConstraints = false
                    
                    let blackRect1 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: navStuffAdjustment, width: movingView.frame.width, height: 0.0))
                    let blackRect2 = UIView(frame: CGRect(x: movingView.frame.origin.x, y: mainWindow.bounds.height, width: movingView.frame.width, height: mainWindow.bounds.height - (movingView.frame.origin.y + movingView.frame.height)))
                    
                    let newRect2Origin = CGPoint(x: blackRect2.frame.origin.x, y: destinationOriginForMovingView.y + cropRect.size.height)
                    let newRect2Size = CGSize(width: blackRect2.frame.size.width, height: mainWindow.frame.height - (destinationOriginForMovingView.y + cropRect.size.height))
                    
                    blackRect1.translatesAutoresizingMaskIntoConstraints = false
                    blackRect2.translatesAutoresizingMaskIntoConstraints = false
                    blackRect1.backgroundColor = UIColor.black
                    blackRect2.backgroundColor = UIColor.black
                    
                    transitionView.addSubview(blackRect1)
                    transitionView.addSubview(blackRect2)
                    transitionView.addSubview(movingView)
                    
                    mainWindow.addSubview(transitionView)
                    
                    UIViewPropertyAnimator.runningPropertyAnimator(
                        withDuration: 0.3,
                        delay: 0.0,
                        options: .curveLinear,
                        animations: {
                            blackRect1.frame.size = CGSize(width: blackRect1.frame.width, height: movingView.frame.origin.y - navStuffAdjustment)
                            blackRect2.frame.origin.y = movingView.frame.origin.y + movingView.frame.height
                        },
                        completion: {(poistion) in
                            //
                            // Reorder views, add new VC to nav stack
                            destinationNavVC.popViewController(animated: false)
                            
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: 0.3,
                                delay: 0.0,
                                options: .curveEaseIn,
                                animations: {
                                    movingView.frame.origin.y = destinationOriginForMovingView.y
                                    blackRect1.frame.size = CGSize(width: blackRect1.frame.width, height: destinationOriginForMovingView.y - navStuffAdjustment)
                                    blackRect2.frame = CGRect(origin: newRect2Origin, size: newRect2Size)
                                },
                                completion: { (position) in
                                    UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: 0.2,
                                        delay: 0.0,
                                        options: .curveLinear,
                                        animations: {movingView.layer.opacity = 0.0},
                                        completion: nil
                                    )
                                    UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: 0.2,
                                        delay: 0.1,
                                        options: .curveLinear,
                                        animations: {transitionView.layer.opacity = 0.0},
                                        completion: { (position) in transitionView.removeFromSuperview()}
                                    )
                                }
                            )
                        }
                    )
                }
            }}}}
            else { // No cell view location, do some normal transition.
                
            }
        default: break
        }
    }
}
