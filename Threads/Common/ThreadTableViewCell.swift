//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ThreadTableViewCell: UITableViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!

    func populate(_ thread: Thread) {
        colorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = String(format: Localized.dmcNumber, number)
        } else {
            numberLabel.text = Localized.dmcNumberUnknown
        }
        labelLabel.text = thread.label ?? ""

        numberLabel.textColor = UIColor.label
        labelLabel.textColor = UIColor.label
    }
}
