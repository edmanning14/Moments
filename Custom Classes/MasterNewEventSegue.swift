//
//  MasterNewEventSegue.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/28/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class MasterNewEventSegue: UIStoryboardSegue {
    
    override func perform() {
        switch identifier {
        case "Add New Event Segue":
            let sourceVC = source as! MasterViewController
            let sourceNavVC = sourceVC.navigationController!
            let destinationVC = destination as! NewEventViewController
            
            destinationVC.loadViewIfNeeded()
            
            if destinationVC.isEditing {
                
            }
            
            else {
                let fadeDurations = 0.2
                let waitForNavAnimation = 0.3
                let cascadeDelay = 0.2
                let sourceFadeOut = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {sourceVC.view.layer.opacity = 0.0}
                sourceFadeOut.addCompletion { (position) in
                    
                    destinationVC.categoryLabel.layer.opacity = 0.0
                    destinationVC.specialEventViewContainer.layer.opacity = 0.0
                    destinationVC.optionsTableView.layer.opacity = 0.0
                    destinationVC.finishButton.layer.opacity = 0.0
                    
                    var vcs = sourceNavVC.viewControllers
                    vcs.append(self.destination)
                    sourceNavVC.setViewControllers(vcs, animated: true)
                    
                    let cellFadeIn = UIViewPropertyAnimator(duration: fadeDurations, curve: .linear) {
                        destinationVC.categoryLabel.layer.opacity = 1.0
                        destinationVC.specialEventViewContainer.layer.opacity = 1.0
                    }
                    let inputViewFadeIn = UIViewPropertyAnimator(duration: fadeDurations, curve: .linear) {destinationVC.optionsTableView.layer.opacity = 1.0}
                    let finishButtonFadeIn = UIViewPropertyAnimator(duration: fadeDurations, curve: .linear) {destinationVC.finishButton.layer.opacity = 1.0}
                    finishButtonFadeIn.addCompletion { (position) in sourceVC.view.layer.opacity = 1.0}
                    
                    cellFadeIn.startAnimation(afterDelay: waitForNavAnimation)
                    inputViewFadeIn.startAnimation(afterDelay: waitForNavAnimation + cascadeDelay)
                    finishButtonFadeIn.startAnimation(afterDelay: waitForNavAnimation + cascadeDelay + cascadeDelay)
                }
                sourceFadeOut.startAnimation()
            }
        case "": break
            
        default: break
        }
    }
}
