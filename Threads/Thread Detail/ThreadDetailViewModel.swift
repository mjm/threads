//
//  ThreadDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class ThreadDetailViewModel: ViewModel {
    enum Section {
        case details
        case shoppingList
        case projects
    }

    enum Item: Hashable {
        case details(ThreadDetailCellViewModel)
        case shoppingList(ShoppingListCellViewModel)
        case project(ThreadProjectCellViewModel)
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let projectsList: FetchedObjectList<ProjectThread>

    let thread: Thread

    let detailsViewModel: ThreadDetailCellViewModel
    let shoppingListViewModel: ShoppingListCellViewModel
    @Published private(set) var projectViewModels: [ThreadProjectCellViewModel] = []

    init(thread: Thread) {
        self.thread = thread

        projectsList
            = FetchedObjectList(
                fetchRequest: ProjectThread.fetchRequest(for: thread),
                managedObjectContext: thread.managedObjectContext!
            )

        detailsViewModel = ThreadDetailCellViewModel(thread: thread)
        shoppingListViewModel = ShoppingListCellViewModel(thread: thread)

        super.init(context: thread.managedObjectContext!)

        $projectViewModels.applyingDifferences(projectsList.differences) { projectThread in
            ThreadProjectCellViewModel(projectThread: projectThread)
        }.assign(to: \.projectViewModels, on: self).store(in: &cancellables)

        shoppingListViewModel.actions.sink { [weak self] action in
            self?.handleShoppingAction(action)
        }.store(in: &cancellables)
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        let detailModel = detailsViewModel
        let shoppingListModel = shoppingListViewModel

        return $projectViewModels.combineLatest(isInShoppingList, detailsViewModel.onUpdate) {
            projectModels, inShoppingList, _ in
            var snapshot = Snapshot()

            snapshot.appendSections([.details])
            snapshot.appendItems([.details(detailModel)], toSection: .details)

            if inShoppingList {
                snapshot.appendSections([.shoppingList])
                snapshot.appendItems([.shoppingList(shoppingListModel)], toSection: .shoppingList)
            }

            if !projectModels.isEmpty {
                snapshot.appendSections([.projects])
                snapshot.appendItems(projectModels.map { .project($0) }, toSection: .projects)
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var isInShoppingList: AnyPublisher<Bool, Never> {
        thread.publisher(for: \.inShoppingList).eraseToAnyPublisher()
    }

    var number: AnyPublisher<String?, Never> {
        thread.publisher(for: \.number).eraseToAnyPublisher()
    }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showThread(thread)).eraseToAnyPublisher()
    }

    var menuActions: [BoundUserAction<Void>] {
        var actions: [BoundUserAction<Void>] = []

        if !thread.inShoppingList {
            actions.append(AddToShoppingListAction(thread: thread).bind(to: actionRunner))
        }

        // TODO add to project

        if thread.amountInCollection == 0 {
            actions.append(MarkInStockAction(thread: thread).bind(to: actionRunner))
        } else {
            actions.append(
                thread.onBobbin
                    ? MarkOffBobbinAction(thread: thread).bind(to: actionRunner)
                    : MarkOnBobbinAction(thread: thread).bind(to: actionRunner)
            )

            actions.append(MarkOutOfStockAction(thread: thread).bind(to: actionRunner))
        }

        // remove needs special handling in the view controller

        return actions
    }

    var removeAction: BoundUserAction<Void> {
        RemoveThreadAction(thread: thread)
            .bind(
                to: actionRunner,
                title: Localized.removeFromCollection,
                options: .destructive)
    }

    private func handleShoppingAction(_ action: ShoppingListCellViewModel.Action) {
        switch action {
        case .togglePurchased:
            actionRunner.perform(TogglePurchasedAction(thread: thread))
        case .increment:
            actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .increment))
        case .decrement:
            actionRunner.perform(ChangeShoppingListAmountAction(thread: thread, change: .decrement))
        }
    }
}
