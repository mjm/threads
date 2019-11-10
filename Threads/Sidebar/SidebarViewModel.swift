//
//  SidebarViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combinable
import CombinableCoreData
import CoreData
import UIKit

final class SidebarViewModel: ViewModel, SnapshotViewModel {
    enum Section: Hashable {
        case threads
        case projects(Project.Status)
    }

    enum Item: Hashable {
        case collection
        case shoppingList
        case project(SidebarProjectCellViewModel)
    }

    @Published private(set) var projectViewModels: [SidebarProjectCellViewModel] = []
    @Published var selectedItem: Item = .collection

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        let actionRunner = self.actionRunner

        $projectViewModels.applyingChanges(projectChanges.ignoreError()) { project in
            SidebarProjectCellViewModel(project: project, actionRunner: actionRunner)
        }.assign(to: \.projectViewModels, on: self).store(in: &cancellables)
    }

    var projectChanges: ManagedObjectChangesPublisher<Project> {
        context.changesPublisher(for: Project.projectsByStatusRequest())
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        projectModelsByStatus.map { projectModelsByStatus in
            var snapshot = Snapshot()

            snapshot.appendSections([.threads])
            snapshot.appendItems([.collection, .shoppingList], toSection: .threads)

            for status in Project.Status.allCases {
                if let projectModels = projectModelsByStatus[status] {
                    let section = Section.projects(status)
                    snapshot.appendSections([section])
                    snapshot.appendItems(projectModels.map { .project($0) }, toSection: section)
                }
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var projectModelsByStatus:
        AnyPublisher<[Project.Status: [SidebarProjectCellViewModel]], Never>
    {
        $projectViewModels.map { projectModels in
            Dictionary(grouping: projectModels) { model in
                model.project.status
            }
        }.eraseToAnyPublisher()
    }
}
