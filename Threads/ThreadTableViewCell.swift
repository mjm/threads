//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    
    @IBOutlet var colorView: UIView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorView.layer.cornerRadius = 10
        colorView.layer.shadowColor = UIColor.systemGray.cgColor
        colorView.layer.shadowOffset = CGSize(width: 0, height: 0)
        colorView.layer.shadowRadius = 2
        colorView.layer.shadowOpacity = 0.7
    }

    func populate(_ thread: Thread) {
        backgroundColor = UIColor.systemBackground
        
        colorView.backgroundColor = thread.color
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
    
    static var nib = UINib(nibName: "ThreadTableViewCell", bundle: nil)
}
