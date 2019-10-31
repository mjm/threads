//
//  AddThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension CollectionThreadTableViewCell {
    // A little hacky to add another supported model here
    func bind(_ model: AddThreadCellViewModel) {
        bindCommonProperties(model)

        // hide status label always in this case
        statusLabel.isHidden = true
    }
}
