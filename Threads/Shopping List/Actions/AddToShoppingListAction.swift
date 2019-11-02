//
//  AddToShoppingListAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct AddToShoppingListAction: SyncUserAction {
    let threads: [Thread]
    let showBanner: Bool

    init(threads: [Thread], showBanner: Bool = false) {
        assert(threads.count > 0)
        self.threads = threads
        self.showBanner = showBanner
    }

    init(thread: Thread, showBanner: Bool = false) {
        self.init(threads: [thread], showBanner: showBanner)
    }

    var undoActionName: String? { Localized.addToShoppingList }

    var canPerform: Bool {
        if threads.count > 1 {
            return true
        } else {
            return !threads[0].inShoppingList
        }
    }

    func perform(_ context: UserActionContext<AddToShoppingListAction>) throws {
        Event.current[.threadCount] = threads.count

        for thread in threads {
            thread.addToShoppingList()
        }

        if showBanner {
            let message = threads.count == 1
                ? String(format: Localized.addToShoppingListBannerNumber, threads[0].number!)
                : String(format: Localized.addToShoppingListBannerCount, threads.count)
            context.present(BannerController(message: message))
        }
    }
}

extension Thread {
    func addToShoppingListAction(showBanner: Bool = false) -> AddToShoppingListAction {
        .init(thread: self, showBanner: showBanner)
    }
}

extension Array where Element == Thread {
    var addToShoppingListAction: AddToShoppingListAction {
        .init(threads: self)
    }
}
