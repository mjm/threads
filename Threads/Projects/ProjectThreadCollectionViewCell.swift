//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ProjectThreadCollectionViewCell: UICollectionViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!

    func populate(_ projectThread: ProjectThread) {
        guard let thread = projectThread.thread else { return }

        colorView.color = thread.color ?? .systemBackground

        if let number = thread.number {
            numberLabel.text = String(format: Localized.dmcNumber, number)
        } else {
            numberLabel.text = Localized.dmcNumberUnknown
        }
        labelLabel.text = thread.label ?? ""
        quantityLabel.text = "\(projectThread.amount)"

        numberLabel.textColor = .label
        labelLabel.textColor = .label
        quantityLabel.textColor = .label
    }
}
