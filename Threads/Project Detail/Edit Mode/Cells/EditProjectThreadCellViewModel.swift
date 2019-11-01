//
//  EditProjectThreadCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class EditProjectThreadCellViewModel: ProjectThreadCellViewModel {
    enum Action {
        case increment
        case decrement
    }

    let projectThread: ProjectThread

    init(projectThread: ProjectThread) {
        self.projectThread = projectThread
    }

    var cancellables = Set<AnyCancellable>()
    private let onAction = PassthroughSubject<Action, Never>()

    var willRemoveOnDecrement: AnyPublisher<Bool, Never> {
        amount.map { $0 == 1 }.eraseToAnyPublisher()
    }

    var actions: AnyPublisher<Action, Never> {
        onAction.eraseToAnyPublisher()
    }

    func increaseQuantity() {
        onAction.send(.increment)
    }

    func decreaseQuantity() {
        onAction.send(.decrement)
    }
}

extension EditProjectThreadCellViewModel: Hashable {
    static func == (lhs: EditProjectThreadCellViewModel, rhs: EditProjectThreadCellViewModel)
        -> Bool
    {
        lhs.projectThread == rhs.projectThread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(projectThread)
    }
}
