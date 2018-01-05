//
//  NewEventInputsControl.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 1/4/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class NewEventInputsControl: UIControl {

    //
    // MARK: - Parameters
    //
    
    //
    // Public Data Model

    
    //
    // Private Data Model
    
    
    //
    // References and UI Elements
    
    
    //
    // MARK: - Control Lifecycle
    //
    
    required init?(coder aDecoder: NSCoder) {super.init(coder: aDecoder)}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    //
    // MARK: - Public Methods
    //
    
    
    //
    // MARK: - Private Methods
    //
    
    fileprivate func initializeView() -> Void {
        layer.backgroundColor = UIColor.white.cgColor
    }
    
}
