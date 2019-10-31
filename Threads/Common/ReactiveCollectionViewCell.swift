//
//  ReactiveCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class ReactiveCollectionViewCell: UICollectionViewCell {
    var cancellables = Set<AnyCancellable>()

    override func prepareForReuse() {
        super.prepareForReuse()

        cancellables.removeAll()
    }
}

