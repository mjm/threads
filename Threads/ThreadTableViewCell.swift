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

    func populate(_ thread: Thread) {
        colorView.backgroundColor = thread.color
        labelLabel.text = thread.label ?? ""
        if let number = thread.number {
            // TODO show the onBobbin somewhere else
            numberLabel.text = "DMC \(number)\(thread.onBobbin ? " (On Bobbin)" : "")"
        } else {
            numberLabel.text = ""
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    static var nib = UINib(nibName: "ThreadTableViewCell", bundle: nil)
}
