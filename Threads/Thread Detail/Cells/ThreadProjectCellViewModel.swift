//
//  ThreadProjectCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine

final class ThreadProjectCellViewModel {
    let projectThread: ProjectThread

    init(projectThread: ProjectThread) {
        self.projectThread = projectThread
    }

    var projectName: AnyPublisher<String?, Never> {
        projectThread.publisher(for: \.project?.displayName)
            .eraseToAnyPublisher()
    }

    var destinationActivity: UserActivity? {
        projectThread.project.flatMap { .showProject($0) }
    }
}

extension ThreadProjectCellViewModel: Hashable {
    static func == (lhs: ThreadProjectCellViewModel, rhs: ThreadProjectCellViewModel) -> Bool {
        lhs.projectThread == rhs.projectThread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(projectThread)
    }
}
