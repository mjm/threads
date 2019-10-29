//
//  ShoppingListViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData

class AddThreadsToShoppingListMode: AddThreadMode {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addThreadChoices() throws -> [Thread] {
        let request = Thread.notInShoppingListFetchRequest()
        return try context.fetch(request)
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToShoppingListAction(threads: threads))
    }
}
