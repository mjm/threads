//
//  ViewProjectThreadCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ViewProjectThreadCellViewModel: ProjectThreadCellViewModel {
    let projectThread: ProjectThread

    @Published var isLastItem = false

    init(projectThread: ProjectThread) {
        self.projectThread = projectThread
    }
}

extension ViewProjectThreadCellViewModel: Hashable {
    static func == (lhs: ViewProjectThreadCellViewModel, rhs: ViewProjectThreadCellViewModel)
        -> Bool
    {
        lhs.projectThread == rhs.projectThread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(projectThread)
    }
}
