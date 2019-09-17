//
//  ProjectActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/16/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

struct CreateProjectAction: SyncUserAction {
    typealias ResultType = Project

    let undoActionName: String? = Localized.newProject

    func perform(_ context: UserActionContext<CreateProjectAction>) throws -> Project {
        return Project(context: context.managedObjectContext)
    }
}

struct AddToProjectAction: SyncUserAction {
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

    var canPerform: Bool {
        if threads.count > 1 {
            return true
        } else {
            let projectThreads = threads[0].projects as? Set<ProjectThread> ?? []
            return projectThreads.allSatisfy { $0.project != project }
        }
    }

    func perform(_ context: UserActionContext<AddToProjectAction>) throws {
        for thread in threads {
            thread.add(to: project)
        }
    }
}

struct AddProjectToShoppingListAction: SyncUserAction {
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

struct ShareProjectAction: SyncUserAction {
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

struct DeleteProjectImageAction: SyncUserAction {
    let image: ProjectImage

    let undoActionName: String? = Localized.deleteImage

    func perform(_ context: UserActionContext<DeleteProjectImageAction>) throws {
        image.delete()
    }
}
