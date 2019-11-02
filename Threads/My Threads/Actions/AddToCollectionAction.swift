//
//  AddToCollectionAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct AddToCollectionAction: SyncUserAction {
    let threads: [Thread]

    var undoActionName: String? { Localized.addToCollection }

    func perform(_ context: UserActionContext<AddToCollectionAction>) throws {
        Event.current[.threadCount] = threads.count
        for thread in threads {
            thread.addToCollection()
        }
    }
}

extension Array where Element == Thread {
    var addToCollectionAction: AddToCollectionAction { .init(threads: self) }
}
