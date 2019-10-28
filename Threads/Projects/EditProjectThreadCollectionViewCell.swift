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
    enum Action {
        case increment
        case decrement
    }

    @IBOutlet var decreaseButton: UIButton!
    @IBOutlet var increaseButton: UIButton!

    private let onAction = PassthroughSubject<Action, Never>()

    override func bind(_ projectThread: ProjectThread) {
        super.bind(projectThread)

        projectThread.publisher(for: \.amount)
            .map { $0 == 1 ? "trash" : "minus.square" }
            .map { UIImage(systemName: $0) }
            .sink { [decreaseButton] image in
                decreaseButton?.setImage(image, for: .normal)
            }.store(in: &cancellables)
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
