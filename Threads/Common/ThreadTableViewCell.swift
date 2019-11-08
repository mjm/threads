//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import UIKit

class ThreadTableViewCell<ViewModel: ThreadCellViewModel>: CombinableTableViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!

    // allow these to be replaced in subclasses
    var labelColorSubscription: AnyCancellable?

    var numberColorSubscription: AnyCancellable?

    func bind(_ model: ViewModel) {
        bindCommonProperties(model)
    }

    func bindCommonProperties(_ model: ThreadCellViewModel) {
        backgroundColor = .systemBackground

        model.color
            .replaceNil(with: .systemBackground)
            .assign(to: \.color, on: colorView)
            .store(in: &cancellables)

        model.number.map { number -> String? in
            number.flatMap { String(format: Localized.dmcNumber, $0) } ?? Localized.dmcNumberUnknown
        }.assign(to: \.text, on: numberLabel).store(in: &cancellables)

        model.label
            .assign(to: \.text, on: labelLabel)
            .store(in: &cancellables)

        let labelColor = selectedOrHighlighted.map { selected -> UIColor in
            selected ? .lightText : .label
        }
        numberColorSubscription = labelColor.assign(to: \.textColor, on: numberLabel)
        labelColorSubscription = labelColor.assign(to: \.textColor, on: labelLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        numberColorSubscription = nil
        labelColorSubscription = nil
    }
}

protocol ThreadCellViewModel {
    var thread: Thread { get }

    var number: AnyPublisher<String?, Never> { get }
    var label: AnyPublisher<String?, Never> { get }
    var color: AnyPublisher<UIColor?, Never> { get }
}

extension ThreadCellViewModel {
    var number: AnyPublisher<String?, Never> { publish(\.number) }
    var label: AnyPublisher<String?, Never> { publish(\.label) }
    var color: AnyPublisher<UIColor?, Never> { publish(\.color) }

    func publish<T>(_ keyPath: KeyPath<Thread, T>) -> AnyPublisher<T, Never> {
        thread.publisher(for: keyPath).eraseToAnyPublisher()
    }
}
