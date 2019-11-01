//
//  EditProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class EditProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    private var model: EditProjectThreadCellViewModel?

    func bind(_ model: EditProjectThreadCellViewModel) {
        bindCommonProperties(model)
        self.model = model

        model.willRemoveOnDecrement
            .map { $0 ? "trash" : "minus.square" }
            .map { UIImage(systemName: $0) }
            .sink { [decreaseButton] image in
                decreaseButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)
    }

    @IBAction func increaseQuantity() {
        model?.increaseQuantity()
    }

    @IBAction func decreaseQuantity() {
        model?.decreaseQuantity()
    }
}
