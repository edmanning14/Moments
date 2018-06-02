//
//  DetailViewController.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 10/22/17.
//  Copyright © 2017 Ed Manning. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    //
    // MARK: - GUI
    //
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    
    //
    // MARK: - Data Model
    //
    
    var detailItem: SpecialEvent? {didSet {configureView()}}
    
    
    //
    // MARK: - View Controller Lifecycle
    //

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {super.didReceiveMemoryWarning()}
    
    
    //
    // MARK: - View Cofiguration
    //
    
    func configureView() {
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.title
            }
        }
    }
    
    
    //
    // MARK: - Action Methods
    //
    
    @objc fileprivate func handleNavButtonClick(_ sender: Any?) {
        /*if let button = sender as? UIBarButtonItem {
            
        }*/
    }

}

