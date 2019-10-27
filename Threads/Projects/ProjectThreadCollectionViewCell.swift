//
//  ThreadTableViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Combine

class ProjectThreadCollectionViewCell: UICollectionViewCell {
    @IBOutlet var colorView: SwatchView!
    @IBOutlet var labelLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    
    var cancellables = Set<AnyCancellable>()

    func bind(_ projectThread: ProjectThread) {
        backgroundColor = .systemBackground
        
        projectThread.publisher(for: \.thread?.color)
            .replaceNil(with: .systemBackground)
            .assign(to: \.color, on: colorView)
            .store(in: &cancellables)

        projectThread.publisher(for: \.thread?.number).map { number -> String? in
            number.flatMap { String(format: Localized.dmcNumber, $0) } ?? Localized.dmcNumberUnknown
        }.assign(to: \.text, on: numberLabel).store(in: &cancellables)

        projectThread.publisher(for: \.thread?.label)
            .assign(to: \.text, on: labelLabel)
            .store(in: &cancellables)
        
        projectThread.publisher(for: \.amount)
            .map { "\($0)" }
            .assign(to: \.text, on: quantityLabel)
            .store(in: &cancellables)

        numberLabel.textColor = .label
        labelLabel.textColor = .label
        quantityLabel.textColor = .label
    }
}
