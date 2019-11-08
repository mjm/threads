//
//  ProjectDetailCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 11/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combinable

final class ProjectDetailCellViewModel {
    let project: Project

    init(project: Project) {
        self.project = project
    }
}

extension ProjectDetailCellViewModel: Hashable {
    static func == (lhs: ProjectDetailCellViewModel, rhs: ProjectDetailCellViewModel) -> Bool {
        lhs.project == rhs.project
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(project)
    }
}
