//
//  ThreadProjectTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import UIKit

class ThreadProjectTableViewCell: CombinableTableViewCell {
    func bind(_ model: ThreadProjectCellViewModel) {
        model.projectName.assign(to: \.text, on: textLabel!).store(in: &cancellables)
    }
}
