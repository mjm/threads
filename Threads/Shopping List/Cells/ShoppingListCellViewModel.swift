//
//  ShoppingListCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ShoppingListCellViewModel: ThreadCellViewModel {
    enum Action {
        case togglePurchased
        case increment
        case decrement
    }

    let thread: Thread

    init(thread: Thread) {
        self.thread = thread
    }

    var cancellables = Set<AnyCancellable>()
    private let onAction = PassthroughSubject<Action, Never>()

    var isPurchased: AnyPublisher<Bool, Never> { publish(\.purchased) }
    var amount: AnyPublisher<Int64, Never> { publish(\.amountInShoppingList) }

    var amountText: AnyPublisher<String?, Never> {
        amount.map { String(describing: $0) }.eraseToAnyPublisher()
    }

    var willRemoveOnDecrement: AnyPublisher<Bool, Never> {
        amount.map { $0 == 1 }.eraseToAnyPublisher()
    }

    var actions: AnyPublisher<Action, Never> {
        onAction.eraseToAnyPublisher()
    }

    func togglePurchased() {
        onAction.send(.togglePurchased)
    }

    func increaseQuantity() {
        onAction.send(.increment)
    }

    func decreaseQuantity() {
        onAction.send(.decrement)
    }
}

extension ShoppingListCellViewModel: Hashable {
    static func == (lhs: ShoppingListCellViewModel, rhs: ShoppingListCellViewModel) -> Bool {
        lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }
}
