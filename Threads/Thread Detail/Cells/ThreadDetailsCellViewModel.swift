//
//  ThreadDetailsCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ThreadDetailCellViewModel {
    let thread: Thread

    init(thread: Thread) {
        self.thread = thread
    }

    var label: AnyPublisher<String?, Never> { publish(\.label) }
    var color: AnyPublisher<UIColor?, Never> { publish(\.color) }

    var onBobbin: AnyPublisher<Bool, Never> { publish(\.onBobbin) }
    var outOfStock: AnyPublisher<Bool, Never> {
        publish(\.amountInCollection).map { $0 == 0 }.eraseToAnyPublisher()
    }

    var hasStatus: AnyPublisher<Bool, Never> {
        onBobbin.combineLatest(outOfStock) { $0 || $1 }.eraseToAnyPublisher()
    }

    // This is used to animate height changes in the details cell
    var onUpdate: AnyPublisher<Void, Never> {
        onBobbin.combineLatest(outOfStock) { _, _ in }.eraseToAnyPublisher()
    }

    private func publish<T>(_ keyPath: KeyPath<Thread, T>) -> AnyPublisher<T, Never> {
        thread.publisher(for: keyPath).eraseToAnyPublisher()
    }
}

extension ThreadDetailCellViewModel: Hashable {
    static func == (lhs: ThreadDetailCellViewModel, rhs: ThreadDetailCellViewModel) -> Bool {
        lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }
}
