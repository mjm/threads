//
//  ShoppingListActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/16/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

struct AddToShoppingListAction: SyncUserAction {
    let threads: [Thread]
    init(threads: [Thread]) {
        assert(threads.count > 0)
        self.threads = threads
    }

    init(thread: Thread) {
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

    func perform(_ context: UserActionContext<AddToShoppingListAction>) throws {
        for thread in threads {
            thread.addToShoppingList()
        }
    }
}

struct AddPurchasedToCollectionAction: SyncUserAction {
    let undoActionName: String? = Localized.addToCollection

    func perform(_ context: UserActionContext<AddPurchasedToCollectionAction>) throws {
        let request = Thread.purchasedFetchRequest()
        let threads = try context.managedObjectContext.fetch(request)

        for thread in threads {
            thread.removeFromShoppingList()
            thread.addToCollection()
        }
    }
}

struct TogglePurchasedAction: SyncUserAction {
    let thread: Thread

    let undoActionName: String? = Localized.changePurchased

    func perform(_ context: UserActionContext<TogglePurchasedAction>) throws {
        thread.togglePurchased()
    }
}

struct ChangeShoppingListAmountAction: SyncUserAction {
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

    func perform(_ context: UserActionContext<ChangeShoppingListAmountAction>) throws {
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
