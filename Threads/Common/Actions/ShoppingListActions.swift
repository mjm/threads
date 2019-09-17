//
//  ShoppingListActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/16/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

class AddToShoppingListAction: UserAction {
    let threads: [Thread]
    init(threads: [Thread]) {
        assert(threads.count > 0)
        self.threads = threads
    }

    convenience init(thread: Thread) {
        self.init(threads: [thread])
    }

    let undoActionName: String? = Localized.addToShoppingList

    var canPerform: Bool {
        if threads.count > 1 {
            return true
        } else {
            return !threads[0].inShoppingList
        }
    }

    func perform(_ context: UserActionContext) throws {
        for thread in threads {
            thread.addToShoppingList()
        }
    }
}

class AddPurchasedToCollectionAction: UserAction {
    let undoActionName: String? = Localized.addToCollection

    func perform(_ context: UserActionContext) throws {
        let request = Thread.purchasedFetchRequest()
        let threads = try context.managedObjectContext.fetch(request)

        for thread in threads {
            thread.removeFromShoppingList()
            thread.addToCollection()
        }
    }
}

class TogglePurchasedAction: ThreadAction, UserAction {
    let undoActionName: String? = Localized.changePurchased

    func perform(_ context: UserActionContext) throws {
        thread.togglePurchased()
    }
}

class ChangeShoppingListAmountAction: ThreadAction, UserAction {
    enum Change {
        case increment
        case decrement
    }

    let change: Change
    init(thread: Thread, change: Change) {
        self.change = change
        super.init(thread: thread)
    }

    var isRemoval: Bool {
        change == .decrement && thread.amountInShoppingList == 1
    }

    var undoActionName: String? {
        isRemoval ? Localized.removeFromShoppingList : Localized.changeQuantity
    }

    func perform(_ context: UserActionContext) throws {
        switch change {
        case .increment:
            thread.amountInShoppingList += 1
        case .decrement:
            if thread.amountInShoppingList == 1 {
                thread.removeFromShoppingList()
            } else {
                thread.amountInShoppingList -= 1
            }
        }
    }
}
