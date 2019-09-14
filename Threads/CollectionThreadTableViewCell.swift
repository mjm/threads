//
//  CollectionThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class CollectionThreadTableViewCell: ThreadTableViewCell {

    @IBOutlet var statusLabel: UILabel!

    override func populate(_ thread: Thread) {
        super.populate(thread)
        
        backgroundColor = UIColor.systemBackground

        statusLabel.isHidden = true
        
        if thread.inCollection {
            if thread.onBobbin {
                statusLabel.isHidden = false
                statusLabel.text = Localized.onBobbin
            } else if thread.amountInCollection == 0 {
                statusLabel.isHidden = false
                statusLabel.text = Localized.outOfStock
                
                numberLabel.textColor = UIColor.secondaryLabel
                labelLabel.textColor = UIColor.secondaryLabel
                
                backgroundColor = UIColor.secondarySystemBackground
            }
        }
    }
    
    static var nib = UINib(nibName: "CollectionThreadTableViewCell", bundle: nil)
}
