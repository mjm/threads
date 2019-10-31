//
//  AddThreadCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class AddThreadCellViewModel: ThreadCellViewModel {
    let thread: Thread
    let section: AddThreadViewModel.Section

    init(thread: Thread, section: AddThreadViewModel.Section) {
        self.thread = thread
        self.section = section
    }
}

extension AddThreadCellViewModel: Hashable {
    static func == (lhs: AddThreadCellViewModel, rhs: AddThreadCellViewModel) -> Bool {
        lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }
}
