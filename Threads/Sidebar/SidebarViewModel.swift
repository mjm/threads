//
//  SidebarViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class SidebarViewModel: ViewModel {
    enum Section {
        case threads
        case projects
    }

    enum Item: Hashable {
        case collection
        case shoppingList
        case project(SidebarProjectCellViewModel)
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    @Published private(set) var projectViewModels: [SidebarProjectCellViewModel] = []
    @Published var selectedItem: Item = .collection

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        let actionRunner = self.actionRunner

        $projectViewModels.applyingDifferences(projectChanges.ignoreError()) { project in
            SidebarProjectCellViewModel(project: project, actionRunner: actionRunner)
        }.assign(to: \.projectViewModels, on: self).store(in: &cancellables)
    }

    var projectChanges: ManagedObjectChangesPublisher<Project> {
        context.changesPublisher(for: Project.allProjectsFetchRequest())
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $projectViewModels.map { projectModels in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads, .projects])
            snapshot.appendItems([.collection, .shoppingList], toSection: .threads)
            snapshot.appendItems(projectModels.map { .project($0) }, toSection: .projects)

            return snapshot
        }.eraseToAnyPublisher()
    }
}
