//
//  MarkInStockAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct MarkInStockAction: SyncUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.markInStock }
    var shortDisplayName: String? { Localized.inStock }

    func perform(_ context: UserActionContext<MarkInStockAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.amountInCollection = 1
    }
}

extension Thread {
    var markInStockAction: MarkInStockAction { .init(thread: self) }
}
