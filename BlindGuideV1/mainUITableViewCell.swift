//
//  mainUITableViewCell.swift
//  BlindGuideV1
//
//  Created by Ding Xu on 11/24/14.
//  Copyright (c) 2014 Ding Xu. All rights reserved.
//

import UIKit

class mainUITableViewCell: UITableViewCell {
    
    @IBOutlet var cellCoverImage: UIImageView!
    @IBOutlet var cellTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}