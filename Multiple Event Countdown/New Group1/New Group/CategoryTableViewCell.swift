//
//  CategoryTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/21/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var undoButton: UIButton!
    
    override func awakeFromNib() {super.awakeFromNib()}

    override func setSelected(_ selected: Bool, animated: Bool) {super.setSelected(selected, animated: animated)}

}
