//
//  ProjectActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/16/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

struct AddToProjectAction: UserAction {
    let threads: [Thread]
    let project: Project
    init(threads: [Thread], project: Project) {
        assert(threads.count > 0)

        self.threads = threads
        self.project = project
    }

    init(thread: Thread, project: Project) {
        self.init(threads: [thread], project: project)
    }

    let undoActionName: String? = Localized.addToProject

    lazy var canPerform: Bool = {
        if threads.count > 1 {
            return true
        } else {
            let projectThreads = threads[0].projects as? Set<ProjectThread> ?? []
            return projectThreads.allSatisfy { $0.project != project }
        }
    }()

    func perform(_ context: UserActionContext<AddToProjectAction>) throws {
        for thread in threads {
            thread.add(to: project)
        }
    }
}

struct AddProjectToShoppingListAction: UserAction {
    let project: Project

    let undoActionName: String? = Localized.addToShoppingList

    func perform(_ context: UserActionContext<AddProjectToShoppingListAction>) throws {
        project.addToShoppingList()
    }
}

struct DeleteProjectAction: DestructiveUserAction {
    let project: Project

    let undoActionName: String? = Localized.deleteProject

    let confirmationTitle: String = Localized.deleteProject
    let confirmationMessage: String = Localized.deleteProjectPrompt
    let confirmationButtonTitle: String = Localized.delete

    func performAsync(_ context: UserActionContext<DeleteProjectAction>) {
        UserActivity.showProject(project).delete {
            context.managedObjectContext.delete(self.project)
            context.complete()
        }
    }
}

struct ShareProjectAction: UserAction {
    let project: Project

    // There's not really anything you can do to undo a share, since it leaves the
    // context of the app.
    let undoActionName: String? = nil

    func perform(_ context: UserActionContext<ShareProjectAction>) throws {
        let activityController = UIActivityViewController(activityItems: [project],
                                                          applicationActivities: nil)
        context.present(activityController)
    }
}
