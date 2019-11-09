//
//  MarkOutOfStockAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct MarkOutOfStockAction: SimpleUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.markOutOfStock }
    var shortDisplayName: String? { Localized.outOfStock }

    func perform() throws {
        Event.current[.threadNumber] = thread.number
        thread.amountInCollection = 0
        thread.onBobbin = false
    }
}

extension Thread {
    var markOutOfStockAction: MarkOutOfStockAction { .init(thread: self) }
}
