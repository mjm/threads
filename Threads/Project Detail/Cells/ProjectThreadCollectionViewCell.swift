//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ProjectThreadCollectionViewCell: ReactiveCollectionViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!

    func bindCommonProperties(_ model: ProjectThreadCellViewModel) {
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

        model.amount
            .map { String(describing: $0) }
            .assign(to: \.text, on: quantityLabel)
            .store(in: &cancellables)

        numberLabel.textColor = .label
        labelLabel.textColor = .label
        quantityLabel.textColor = .label
    }
}

protocol ProjectThreadCellViewModel {
    var projectThread: ProjectThread { get }

    var number: AnyPublisher<String?, Never> { get }
    var label: AnyPublisher<String?, Never> { get }
    var color: AnyPublisher<UIColor?, Never> { get }
    var amount: AnyPublisher<Int64, Never> { get }
}

extension ProjectThreadCellViewModel {
    var number: AnyPublisher<String?, Never> { publish(\.thread?.number) }
    var label: AnyPublisher<String?, Never> { publish(\.thread?.label) }
    var color: AnyPublisher<UIColor?, Never> { publish(\.thread?.color) }
    var amount: AnyPublisher<Int64, Never> { publish(\.amount) }

    func publish<T>(_ keyPath: KeyPath<ProjectThread, T>) -> AnyPublisher<T, Never> {
        projectThread.publisher(for: keyPath).eraseToAnyPublisher()
    }
}
