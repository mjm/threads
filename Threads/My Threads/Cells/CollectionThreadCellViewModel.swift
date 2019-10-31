//
//  CollectionThreadCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class CollectionThreadCellViewModel: ThreadCellViewModel {
    enum Status {
        case onBobbin
        case outOfStock
    }

    let thread: Thread

    init(thread: Thread) {
        self.thread = thread
    }

    var isOutOfStock: AnyPublisher<Bool, Never> {
        let inCollection = publish(\.inCollection)
        let amountInCollection = publish(\.amountInCollection)
        return inCollection.combineLatest(amountInCollection) { inCollection, amount in
            inCollection && amount == 0
        }.eraseToAnyPublisher()
    }

    var status: AnyPublisher<Status?, Never> {
        let isOnBobbin = publish(\.onBobbin)
        return isOutOfStock.combineLatest(isOnBobbin) { outOfStock, onBobbin in
            if onBobbin {
                return .onBobbin
            } else if outOfStock {
                return .outOfStock
            } else {
                return nil
            }
        }.eraseToAnyPublisher()
    }
}

extension CollectionThreadCellViewModel: Hashable {
    static func == (lhs: CollectionThreadCellViewModel, rhs: CollectionThreadCellViewModel) -> Bool
    {
        lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }
}
