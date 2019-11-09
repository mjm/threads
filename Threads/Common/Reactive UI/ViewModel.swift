//
//  ViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit
import UserActions

class ViewModel {
    var cancellables = Set<AnyCancellable>()
    let context: NSManagedObjectContext
    let actionRunner: UserActions.Runner

    init(context: NSManagedObjectContext = .view) {
        self.context = context

        actionRunner = UserActions.Runner()
        actionRunner.delegate = self
    }

    var presenter: UserActionPresenter? {
        get {
            actionRunner.presenter
        }
        set {
            actionRunner.presenter = newValue
        }
    }
}

extension ViewModel: UserActionRunnerDelegate {
    func actionRunner<A>(
        _ actionRunner: UserActions.Runner, willPerformAction action: A,
        context: UserActions.Context<A>
    ) where A: UserAction {
        context.managedObjectContext = self.context
        if let undoActionName = action.undoActionName {
            self.context.undoManager?.setActionName(undoActionName)
        }
    }

    func actionRunner<A>(
        _ actionRunner: UserActions.Runner, didCompleteAction action: A,
        context: UserActions.Context<A>
    ) where A: UserAction {
        self.context.commit()
    }
}

protocol SnapshotViewModel {
    associatedtype Section: Hashable
    associatedtype Item: Hashable

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    var snapshot: AnyPublisher<Snapshot, Never> { get }
}
