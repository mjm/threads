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
        case togglePurchased(immediate: Bool)
        case increment
        case decrement
    }

    let thread: Thread
    let actionRunner: UserActionRunner

    init(thread: Thread, actionRunner: UserActionRunner) {
        self.thread = thread
        self.actionRunner = actionRunner
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

    func togglePurchasedAction(immediate: Bool = false) -> BoundUserAction<Void> {
        thread.togglePurchasedAction
            .bind(to: actionRunner)
            .onWillPerform {
                self.onAction.send(.togglePurchased(immediate: immediate))
            }
    }

    var increaseQuantityAction: BoundUserAction<Void> {
        thread.incrementShoppingListAmountAction
            .bind(to: actionRunner)
            .onWillPerform {
                self.onAction.send(.increment)
            }
    }

    var decreaseQuantityAction: BoundUserAction<Void> {
        thread.decrementShoppingListAmountAction
            .bind(to: actionRunner)
            .onWillPerform {
                self.onAction.send(.decrement)
            }
    }

    var removeAction: BoundUserAction<Void> {
        thread.removeFromShoppingListAction.bind(to: actionRunner)
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
