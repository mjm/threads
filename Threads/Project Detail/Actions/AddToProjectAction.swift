//
//  AddToProjectAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Events

struct AddToProjectAction: SyncUserAction {
    let threads: [Thread]
    let project: Project
    let showBanner: Bool

    init(threads: [Thread], project: Project, showBanner: Bool = false) {
        assert(threads.count > 0)

        self.threads = threads
        self.project = project
        self.showBanner = showBanner
    }

    init(thread: Thread, project: Project, showBanner: Bool = false) {
        self.init(threads: [thread], project: project, showBanner: showBanner)
    }

    var undoActionName: String? { Localized.addToProject }

    var canPerform: Bool {
        if threads.count > 1 {
            return true
        } else {
            let projectThreads = threads[0].projects as? Set<ProjectThread> ?? []
            return projectThreads.allSatisfy { $0.project != project }
        }
    }

    func perform(_ context: UserActionContext<AddToProjectAction>) throws {
        Event.current[.threadCount] = threads.count
        Event.current[.projectName] = project.name

        for thread in threads {
            thread.add(to: project)
        }

        if showBanner {
            let projectName = project.name ?? Localized.unnamedProject
            let message = threads.count == 1
                ? String(
                    format: Localized.addToProjectBannerNumber, threads[0].number!, projectName)
                : String(format: Localized.addToProjectBannerCount, threads.count, projectName)
            context.present(BannerController(message: message))
        }
    }
}

extension Thread {
    func addToProjectAction(_ project: Project, showBanner: Bool = false) -> AddToProjectAction {
        .init(thread: self, project: project, showBanner: showBanner)
    }
}

extension Array where Element == Thread {
    func addToProjectAction(_ project: Project) -> AddToProjectAction {
        .init(threads: self, project: project)
    }
}
