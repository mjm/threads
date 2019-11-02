//
//  CollectionThreadCellViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class CollectionThreadCellViewModel: ThreadCellViewModel {
    enum Status {
        case onBobbin
        case outOfStock
    }

    let thread: Thread
    let actionRunner: UserActionRunner

    init(thread: Thread, actionRunner: UserActionRunner) {
        self.thread = thread
        self.actionRunner = actionRunner
    }

    var isOutOfStock: AnyPublisher<Bool, Never> {
        let inCollection = publish(\.inCollection)
        let amountInCollection = publish(\.amountInCollection)
        return inCollection.combineLatest(amountInCollection) { inCollection, amount in
            inCollection && amount == 0
        }.eraseToAnyPublisher()
    }

    var status: AnyPublisher<Status?, Never> {
        let isOnBobbin = publish(\.onBobbin)
        return isOutOfStock.combineLatest(isOnBobbin) { outOfStock, onBobbin in
            if onBobbin {
                return .onBobbin
            } else if outOfStock {
                return .outOfStock
            } else {
                return nil
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Swipe Actions
extension CollectionThreadCellViewModel {
    var bobbinAction: BoundUserAction<Void>? {
        guard thread.amountInCollection > 0 else {
            return nil
        }

        if thread.onBobbin {
            return thread.markOffBobbinAction
                .bind(to: actionRunner, title: Localized.offBobbin)
        } else {
            return thread.markOnBobbinAction
                .bind(to: actionRunner, title: Localized.onBobbin)
        }
    }

    var stockAction: BoundUserAction<Void> {
        if thread.amountInCollection == 0 {
            return thread.markInStockAction
                .bind(to: actionRunner, title: Localized.inStock)
        } else {
            return thread.markOutOfStockAction
                .bind(to: actionRunner, title: Localized.outOfStock, options: .destructive)
        }
    }
}

// MARK: - Context Menu Actions
extension CollectionThreadCellViewModel {
    var markActions: [BoundUserAction<Void>] {
        if thread.amountInCollection == 0 {
            return [thread.markInStockAction.bind(to: actionRunner)]
        } else {
            return [
                thread.onBobbin
                    ? thread.markOffBobbinAction.bind(to: actionRunner)
                    : thread.markOnBobbinAction.bind(to: actionRunner),
                thread.markOutOfStockAction.bind(to: actionRunner),
            ]
        }
    }

    var projectActions: [BoundUserAction<Void>] {
        do {
            let request = Project.allProjectsFetchRequest()
            let projects = try thread.managedObjectContext!.fetch(request)

            return projects.map { project in
                thread.addToProjectAction(project, showBanner: true)
                    .bind(to: actionRunner, title: project.displayName)
            }
        } catch {
            actionRunner.presenter?.present(error: error)
            return []
        }
    }

    var addToShoppingListAction: BoundUserAction<Void> {
        thread.addToShoppingListAction(showBanner: true)
            .bind(to: actionRunner)
    }

    var removeAction: BoundUserAction<Void> {
        thread.removeFromCollectionAction
            .bind(
                to: actionRunner,
                title: Localized.removeFromCollection,
                options: .destructive)
    }
}

extension CollectionThreadCellViewModel: Hashable {
    static func == (lhs: CollectionThreadCellViewModel, rhs: CollectionThreadCellViewModel) -> Bool
    {
        lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }
}
