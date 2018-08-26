//
//  WidgetEventTableViewCell.swift
//  Multiple Event Countdown Widget
//
//  Created by Edward Manning on 8/25/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class WidgetEventTableViewCell: UITableViewCell {
    
    var title: String? {didSet {titleLabel.text = title}}
    var tagline: String? {didSet {taglineLabel.text = tagline}}
    var mainEventImage: UIImage? {didSet {mainImageView.image = mainEventImage}}
    
    @IBOutlet fileprivate weak var mainImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var taglineLabel: UILabel!
    @IBOutlet weak var spacingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
