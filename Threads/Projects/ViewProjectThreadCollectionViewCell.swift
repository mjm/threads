//
//  ProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class ViewProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    @IBOutlet var separatorLeadingConstraint: NSLayoutConstraint!

    func bind(_ projectThread: ProjectThread, isLastItem: Bool = false) {
        super.bind(projectThread)

        separatorLeadingConstraint.constant = isLastItem ? 0 : 15
    }
}
