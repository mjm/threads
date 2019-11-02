//
//  AddProjectToShoppingListAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct AddProjectToShoppingListAction: SyncUserAction {
    let project: Project

    var undoActionName: String? { Localized.addToShoppingList }

    func perform(_ context: UserActionContext<AddProjectToShoppingListAction>) throws {
        Event.current[.projectName] = project.name
        project.addToShoppingList()

        let threads = (project.threads as! Set<ProjectThread>).compactMap { $0.thread }
        Event.current[.threadCount] = threads.count

        let message = threads.count == 1
            ? String(format: Localized.addToShoppingListBannerNumber, threads[0].number!)
            : String(format: Localized.addToShoppingListBannerCount, threads.count)
        context.present(BannerController(message: message))
    }
}

extension Project {
    var addToShoppingListAction: AddProjectToShoppingListAction { .init(project: self) }
}
