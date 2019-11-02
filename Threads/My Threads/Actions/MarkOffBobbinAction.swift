//
//  MarkOffBobbinAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct MarkOffBobbinAction: SyncUserAction {
    let thread: Thread

    var undoActionName: String? { Localized.markOffBobbin }
    var shortDisplayName: String? { Localized.offBobbin }

    func perform(_ context: UserActionContext<MarkOffBobbinAction>) throws {
        Event.current[.threadNumber] = thread.number
        thread.onBobbin = false
    }
}

extension Thread {
    var markOffBobbinAction: MarkOffBobbinAction { .init(thread: self) }
}
