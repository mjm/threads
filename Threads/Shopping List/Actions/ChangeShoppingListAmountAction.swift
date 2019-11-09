//
//  ChangeShoppingListAmountAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct ChangeShoppingListAmountAction: SimpleUserAction {
    enum Change {
        case increment
        case decrement
    }

    let thread: Thread
    let change: Change

    var isRemoval: Bool {
        change == .decrement && thread.amountInShoppingList == 1
    }

    var undoActionName: String? {
        isRemoval ? Localized.removeFromShoppingList : Localized.changeQuantity
    }

    var displayName: String? {
        switch change {
        case .increment:
            return Localized.increaseQuantity
        case .decrement:
            return isRemoval ? Localized.removeFromShoppingList : Localized.decreaseQuantity
        }
    }

    func perform() throws {
        Event.current[.threadNumber] = thread.number
        Event.current[.oldAmount] = thread.amountInShoppingList

        switch change {
        case .increment:
            thread.amountInShoppingList += 1
        case .decrement:
            if thread.amountInShoppingList == 1 {
                Event.current[.removed] = true
                thread.removeFromShoppingList()
            } else {
                thread.amountInShoppingList -= 1
            }
        }

        Event.current[.newAmount] = thread.amountInShoppingList
    }
}

extension Thread {
    var incrementShoppingListAmountAction: ChangeShoppingListAmountAction {
        .init(thread: self, change: .increment)
    }

    var decrementShoppingListAmountAction: ChangeShoppingListAmountAction {
        .init(thread: self, change: .decrement)
    }
}
