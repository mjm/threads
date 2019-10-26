//
//  EditProjectThreadCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/11/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Combine

class EditProjectThreadCollectionViewCell: ProjectThreadCollectionViewCell {
    enum Action {
        case increment
        case decrement
    }
    
    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    private let onAction = PassthroughSubject<Action, Never>()

    override func populate(_ projectThread: ProjectThread) {
        super.populate(projectThread)

        decreaseButton.setImage(UIImage(systemName: projectThread.amount == 1 ? "trash" : "minus.square"), for: .normal)
    }
    
    func actionPublisher() -> AnyPublisher<Action, Never> {
        onAction.eraseToAnyPublisher()
    }

    @IBAction func increaseQuantity() {
        onAction.send(.increment)
    }

    @IBAction func decreaseQuantity() {
        onAction.send(.decrement)
    }
}
