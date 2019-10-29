//
//  ProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData

class AddThreadsToProjectMode: AddThreadMode {
    let project: Project

    init(project: Project) {
        self.project = project
    }

    func addThreadChoices() throws -> [Thread] {
        let projectThreads = try project.managedObjectContext!.fetch(
            ProjectThread.fetchRequest(for: project))
        let existingThreads = projectThreads.compactMap { $0.thread }

        // Not ideal, but I haven't figured out a way in Core Data to get all the threads that
        // aren't in a particular project. Many-to-many relationships are hard.
        let allThreads = try project.managedObjectContext!.fetch(
            Thread.sortedByNumberFetchRequest())

        return allThreads.filter { !existingThreads.contains($0) }
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToProjectAction(threads: threads, project: project))
    }
}
