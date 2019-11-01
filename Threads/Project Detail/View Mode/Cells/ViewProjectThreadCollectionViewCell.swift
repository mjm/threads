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

    func bind(_ model: ViewProjectThreadCellViewModel) {
        bindCommonProperties(model)

        model.$isLastItem.map { $0 ? 0 : 15 }
            .assign(to: \.constant, on: separatorLeadingConstraint)
            .store(in: &cancellables)
    }
}
