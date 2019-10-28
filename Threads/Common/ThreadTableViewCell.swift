//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ThreadTableViewCell: UITableViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!

    @Published var _selected: Bool = false
    @Published var _highlighted: Bool = false

    var cancellables = Set<AnyCancellable>()

    // allow these to be replaced in subclasses
    var labelColorSubscription: AnyCancellable?

    var numberColorSubscription: AnyCancellable?

    var selectedOrHighlighted: AnyPublisher<Bool, Never> {
        $_selected.combineLatest($_highlighted) { selected, highlighted in
            selected || highlighted
        }.eraseToAnyPublisher()
    }

    func bind(_ thread: Thread) {
        backgroundColor = .systemBackground

        thread.publisher(for: \.color)
            .replaceNil(with: .systemBackground)
            .assign(to: \.color, on: colorView)
            .store(in: &cancellables)

        thread.publisher(for: \.number).map { number -> String? in
            number.flatMap { String(format: Localized.dmcNumber, $0) } ?? Localized.dmcNumberUnknown
        }.assign(to: \.text, on: numberLabel).store(in: &cancellables)

        thread.publisher(for: \.label)
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

        cancellables.removeAll()
        numberColorSubscription = nil
        labelColorSubscription = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        _selected = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        _highlighted = highlighted
    }
}
