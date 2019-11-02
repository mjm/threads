//
//  TogglePurchasedAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct TogglePurchasedAction: SimpleUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.changePurchased }

    func perform() throws {
        Event.current[.threadNumber] = thread.number
        thread.togglePurchased()
    }
}

extension Thread {
    var togglePurchasedAction: TogglePurchasedAction { .init(thread: self) }
}
