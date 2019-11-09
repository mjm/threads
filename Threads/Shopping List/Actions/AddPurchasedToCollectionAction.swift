//
//  AddPurchasedToCollectionAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events
import UserActions

struct AddPurchasedToCollectionAction: SyncUserAction {
    var undoActionName: String? { Localized.addToCollection }

    func perform(_ context: UserActions.Context<AddPurchasedToCollectionAction>) throws {
        let request = Thread.purchasedFetchRequest()
        let threads = try context.managedObjectContext.fetch(request)

        Event.current[.threadCount] = threads.count

        for thread in threads {
            thread.removeFromShoppingList()
            thread.addToCollection()
        }
    }
}
