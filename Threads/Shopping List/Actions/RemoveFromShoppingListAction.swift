//
//  RemoveFromShoppingListAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct RemoveFromShoppingListAction: SyncUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.removeFromShoppingList }

    func perform(_ context: UserActionContext<RemoveFromShoppingListAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.removeFromShoppingList()
    }
}

extension Thread {
    var removeFromShoppingListAction: RemoveFromShoppingListAction { .init(thread: self) }
}
