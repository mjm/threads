//
//  SidebarProjectCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit
import UserActions

final class SidebarProjectCellViewModel {
    let project: Project
    let actionRunner: UserActions.Runner

    var cancellables = Set<AnyCancellable>()

    init(project: Project, actionRunner: UserActions.Runner) {
        self.project = project
        self.actionRunner = actionRunner
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
    }

    var status: AnyPublisher<Project.Status, Never> {
        project.publisher(for: \.statusValue)
            .map { Project.Status(rawValue: $0) ?? .planned }
            .eraseToAnyPublisher()
    }

    var addToShoppingListAction: BoundUserAction<Void> {
        project.addToShoppingListAction.bind(to: actionRunner)
    }

    var shareAction: BoundUserAction<Void> {
        project.shareAction.bind(to: actionRunner, title: Localized.share)
    }

    var deleteAction: BoundUserAction<Void> {
        project.deleteAction.bind(to: actionRunner, title: Localized.delete, options: .destructive)
    }

    var statusActions: ([BoundUserAction<Void>], Int?) {
        let index = Project.Status.allCases.firstIndex(of: project.status)
        let actions = Project.Status.allCases.map { status in
            project.changeStatusAction(status: status)
                .bind(to: actionRunner)
        }

        return (actions, index)
    }
}

extension SidebarProjectCellViewModel: Hashable {
    static func == (lhs: SidebarProjectCellViewModel, rhs: SidebarProjectCellViewModel) -> Bool {
        lhs.project == rhs.project
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(project)
    }
}
