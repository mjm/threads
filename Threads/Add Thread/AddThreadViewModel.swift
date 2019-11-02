//
//  AddThreadViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class AddThreadViewModel: ViewModel, SnapshotViewModel {
    enum Section {
        case filtered
        case selected
    }

    typealias Item = AddThreadCellViewModel

    @Published private(set) var choices: [Item] = []
    @Published var threadToSelect: Thread?
    @Published var query = ""
    @Published private(set) var selectedItems: [Item] = []

    var mode: AddThreadMode = NoOpAddThreadMode() {
        didSet {
            do {
                let threadChoices = try mode.addThreadChoices()
                choices = threadChoices.map { Item(thread: $0, section: .filtered) }
            } catch {
                presenter?.present(error: error)
                choices = []
            }
        }
    }

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        normalizedQuery.combineLatest(filteredChoices) { query, choices -> Thread? in
            choices.first { $0.thread.number?.lowercased() == query }?.thread
        }.assign(to: \.threadToSelect, on: self).store(in: &cancellables)
    }

    var normalizedQuery: AnyPublisher<String, Never> {
        $query.map { $0.lowercased() }.eraseToAnyPublisher()
    }

    var filteredChoices: AnyPublisher<[Item], Never> {
        normalizedQuery.combineLatest($choices, $selectedItems) {
            query, choices, selectedItems -> [Item] in
            if query.isEmpty {
                return []
            } else {
                return choices.filter { choice in
                    return !selectedItems.contains(where: { $0.thread == choice.thread })
                        && choice.thread.number!.lowercased().hasPrefix(query)
                }
            }
        }.eraseToAnyPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $selectedItems.combineLatest(filteredChoices).map { input in
            let (selected, filtered) = input
            var snapshot = Snapshot()

            if !filtered.isEmpty {
                snapshot.appendSections([.filtered])
                snapshot.appendItems(filtered, toSection: .filtered)
            }

            if !selected.isEmpty {
                snapshot.appendSections([.selected])
                snapshot.appendItems(selected, toSection: .selected)
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    var canQuickSelect: AnyPublisher<Bool, Never> {
        $threadToSelect.map { $0 != nil }.eraseToAnyPublisher()
    }

    var canAddSelected: AnyPublisher<Bool, Never> {
        $selectedItems.map { !$0.isEmpty }.eraseToAnyPublisher()
    }

    func select(thread: Thread) {
        selectedItems.insert(Item(thread: thread, section: .selected), at: 0)
        query = ""
    }

    func deselect(at row: Int) {
        selectedItems.remove(at: row)
    }

    func quickSelect() {
        if let thread = threadToSelect {
            select(thread: thread)
        }
    }

    func addSelected() {
        mode.add(threads: selectedItems.map { $0.thread }, actionRunner: actionRunner)
    }
}

protocol AddThreadMode {
    func addThreadChoices() throws -> [Thread]
    func add(threads: [Thread], actionRunner: UserActionRunner)
}

fileprivate final class NoOpAddThreadMode: AddThreadMode {
    func addThreadChoices() throws -> [Thread] {
        []
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
    }
}
