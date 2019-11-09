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

    init(project: Project, actionRunner: UserActions.Runner) {
        self.project = project
        self.actionRunner = actionRunner
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
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
}

extension SidebarProjectCellViewModel: Hashable {
    static func == (lhs: SidebarProjectCellViewModel, rhs: SidebarProjectCellViewModel) -> Bool {
        lhs.project == rhs.project
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(project)
    }
}
