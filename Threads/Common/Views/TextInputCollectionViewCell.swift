//
//  TextInputCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import UIKit

class TextInputCollectionViewCell: CombinableCollectionViewCell {
    enum Action {
        case `return`
    }

    @IBOutlet var textField: UITextField!

    private let onChange = PassthroughSubject<String?, Never>()
    private let onAction = PassthroughSubject<Action, Never>()

    func bind<Root: NSObject>(to path: ReferenceWritableKeyPath<Root, String?>, on root: Root) {
        root.publisher(for: path).assign(to: \.text, on: textField).store(in: &cancellables)
        onChange.assign(to: path, on: root).store(in: &cancellables)
    }

    @IBAction func textChanged() {
        onChange.send(textField.text)
    }

    func actionPublisher() -> AnyPublisher<Action, Never> {
        onAction.eraseToAnyPublisher()
    }
}

extension TextInputCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onAction.send(.return)
        return true
    }
}
