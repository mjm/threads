//
//  CollectionThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class CollectionThreadTableViewCell: UITableViewCell {

    @IBOutlet var colorStackView: UIStackView!
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!

    func populate(_ thread: Thread) {
        backgroundColor = UIColor.systemBackground

        colorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = "DMC \(number)"
        } else {
            numberLabel.text = ""
        }
        labelLabel.text = thread.label ?? ""
        
        numberLabel.textColor = UIColor.label
        labelLabel.textColor = UIColor.label

        statusLabel.isHidden = true
        
        if thread.inCollection {
            if thread.onBobbin {
                statusLabel.isHidden = false
                statusLabel.text = "On Bobbin"
            } else if thread.amountInCollection == 0 {
                statusLabel.isHidden = false
                statusLabel.text = "Out of Stock"
                
                numberLabel.textColor = UIColor.secondaryLabel
                labelLabel.textColor = UIColor.secondaryLabel
                
                backgroundColor = UIColor.secondarySystemBackground
            }
        }
    }
    
    static var nib = UINib(nibName: "CollectionThreadTableViewCell", bundle: nil)
}
