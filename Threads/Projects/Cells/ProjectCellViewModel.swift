//
//  ProjectCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ProjectCellViewModel {
    let project: Project
    let actionRunner: UserActionRunner

    init(project: Project, actionRunner: UserActionRunner) {
        self.project = project
        self.actionRunner = actionRunner
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
    }

    var image: AnyPublisher<UIImage?, Never> {
        project.publisher(for: \.primaryImage)
            .map { $0?.thumbnailImage }
            .eraseToAnyPublisher()
    }

    var addToShoppingListAction: BoundUserAction<Void> {
        project.addToShoppingListAction.bind(to: actionRunner)
    }

    var shareAction: BoundUserAction<Void> {
        project.shareAction.bind(to: actionRunner, title: Localized.share)
    }

    var deleteAction: BoundUserAction<Void> {
        project.deleteAction
            .bind(to: actionRunner, title: Localized.delete, options: .destructive)
    }
}

extension ProjectCellViewModel: Hashable {
    static func == (lhs: ProjectCellViewModel, rhs: ProjectCellViewModel) -> Bool {
        lhs.project == rhs.project
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(project)
    }
}
