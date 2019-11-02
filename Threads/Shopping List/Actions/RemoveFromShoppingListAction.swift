//
//  RemoveFromShoppingListAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct RemoveFromShoppingListAction: SimpleUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.removeFromShoppingList }

    func perform() throws {
        Event.current[.threadNumber] = thread.number
        thread.removeFromShoppingList()
    }
}

extension Thread {
    var removeFromShoppingListAction: RemoveFromShoppingListAction { .init(thread: self) }
}
