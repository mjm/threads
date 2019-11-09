//
//  MarkOnBobbinAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct MarkOnBobbinAction: SimpleUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.markOnBobbin }
    var shortDisplayName: String? { Localized.onBobbin }

    func perform() throws {
        Event.current[.threadNumber] = thread.number
        thread.onBobbin = true
    }
}

extension Thread {
    var markOnBobbinAction: MarkOnBobbinAction { .init(thread: self) }
}
