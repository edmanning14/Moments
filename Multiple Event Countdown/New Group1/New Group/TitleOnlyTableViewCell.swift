//
//  TitleOnlyTableViewCell.swift
//  Multiple Event Countdown
//
//  Created by Ed Manning on 7/8/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class TitleOnlyTableViewCell: UITableViewCell {

    var title: String? {didSet {titleLabel.text = title}}
    
    static var cellMargin: CGFloat = 10.0 // Desired Padding
    static let cellHeight: CGFloat = (2 * TitleOnlyTableViewCell.cellMargin) + 19 // Label height
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {super.awakeFromNib()}

}
