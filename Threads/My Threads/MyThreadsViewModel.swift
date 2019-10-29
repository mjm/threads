//
//  MyThreadsViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class MyThreadsViewModel: ViewModel {
    enum Section { case threads }

    struct Cell: Hashable, ReusableCell {
        var thread: Thread

        var cellIdentifier: String { "Thread" }
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Cell>

    private let threadsList: FetchedObjectList<Thread>

    @Published var selectedCell: Cell?

    override init(context: NSManagedObjectContext = .view) {
        threadsList
            = FetchedObjectList(
                fetchRequest: Thread.inCollectionFetchRequest(),
                managedObjectContext: context
            )

        super.init(context: context)
    }

    var threads: AnyPublisher<[Thread], Never> {
        threadsList.objectsPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        threads.map { threads -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads])
            snapshot.appendItems(threads.map { Cell(thread: $0) }, toSection: .threads)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        threads
            .map { $0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var selectedThread: Thread? { selectedCell?.thread }
}

// MARK: - Actions
extension MyThreadsViewModel {
    func buyPremium() {
        actionRunner.perform(BuyPremiumAction())
    }

    func addThreads() {
        actionRunner.perform(AddThreadAction(mode: .collection))
    }

    var canDeleteSelectedThread: Bool { selectedThread != nil }

    func deleteSelectedThread() {
        if let thread = selectedThread {
            actionRunner.perform(RemoveThreadAction(thread: thread))
        }
    }

    var canToggleSelectedThreadOnBobbin: Bool {
        (selectedThread?.amountInCollection ?? 0) > 0
    }

    func toggleSelectedThreadOnBobbin() {
        guard let thread = selectedThread, thread.amountInCollection > 0 else {
            return
        }

        if thread.onBobbin {
            actionRunner.perform(MarkOffBobbinAction(thread: thread))
        } else {
            actionRunner.perform(MarkOnBobbinAction(thread: thread))
        }
    }

    var canToggleSelectedThreadInStock: Bool { selectedThread != nil }

    func toggleSelectedThreadInStock() {
        guard let thread = selectedThread else {
            return
        }

        if thread.amountInCollection > 0 {
            actionRunner.perform(MarkOutOfStockAction(thread: thread))
        } else {
            actionRunner.perform(MarkInStockAction(thread: thread))
        }
    }
}

// MARK: - Context Menu Actions
extension MyThreadsViewModel {
    struct Action {
        var title: String
        var canPerform: () -> Bool
        var perform: () -> Void
    }

    private func action<A: UserAction>(_ title: String, _ action: A) -> Action {
        Action(
            title: title,
            canPerform: { action.canPerform },
            perform: { self.actionRunner.perform(action) }
        )
    }

    func markActions(for cell: Cell) -> [Action] {
        let thread = cell.thread

        if thread.amountInCollection == 0 {
            return [action(Localized.markInStock, MarkInStockAction(thread: thread))]
        } else {
            return [
                thread.onBobbin
                    ? action(Localized.markOffBobbin, MarkOffBobbinAction(thread: thread))
                    : action(Localized.markOnBobbin, MarkOnBobbinAction(thread: thread)),
                action(Localized.markOutOfStock, MarkOutOfStockAction(thread: thread)),
            ]
        }
    }

    func projectActions(for cell: Cell) -> [Action] {
        let thread = cell.thread

        do {
            let request = Project.allProjectsFetchRequest()
            let projects = try context.fetch(request)

            return projects.map { project in
                action(
                    project.displayName,
                    AddToProjectAction(thread: thread, project: project, showBanner: true))
            }
        } catch {
            presenter?.present(error: error)
            return []
        }
    }

    func addToShoppingListAction(for cell: Cell) -> Action {
        action(
            Localized.addToShoppingList,
            AddToShoppingListAction(thread: cell.thread, showBanner: true))
    }

    func removeAction(for cell: Cell) -> Action {
        action(
            Localized.removeFromCollection,
            RemoveThreadAction(thread: cell.thread))
    }
}

class AddThreadsToCollectionMode: AddThreadMode {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addThreadChoices() throws -> [Thread] {
        let request = Thread.notInCollectionFetchRequest()
        return try context.fetch(request)
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToCollectionAction(threads: threads))
    }
}
