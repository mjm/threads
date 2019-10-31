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

    init(project: Project) {
        self.project = project
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
    }

    var image: AnyPublisher<UIImage?, Never> {
        project.publisher(for: \.primaryImage)
            .map { $0?.thumbnailImage }
            .eraseToAnyPublisher()
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
