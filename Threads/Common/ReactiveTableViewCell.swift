//
//  ReactiveTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ReactiveTableViewCell: UITableViewCell {
    @Published var _selected: Bool = false
    @Published var _highlighted: Bool = false

    var cancellables = Set<AnyCancellable>()

    var selectedOrHighlighted: AnyPublisher<Bool, Never> {
        $_selected.combineLatest($_highlighted) { selected, highlighted in
            selected || highlighted
        }.eraseToAnyPublisher()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        _selected = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        _highlighted = highlighted
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}
