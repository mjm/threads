//
//  ProjectListViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class ProjectListViewModel: ViewModel {
    enum Section { case projects }

    typealias Item = ProjectCellViewModel

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    @Published private(set) var projectViewModels: [ProjectCellViewModel] = []

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        let actionRunner = self.actionRunner

        $projectViewModels.applyingDifferences(projectChanges.ignoreError()) { project in
            ProjectCellViewModel(project: project, actionRunner: actionRunner)
        }.assign(to: \.projectViewModels, on: self).store(in: &cancellables)
    }

    var projectChanges: ManagedObjectChangesPublisher<Project> {
        context.changesPublisher(for: Project.allProjectsFetchRequest())
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $projectViewModels.map { projectModels in
            var snapshot = Snapshot()

            snapshot.appendSections([.projects])
            snapshot.appendItems(projectModels, toSection: .projects)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        $projectViewModels.map { $0.isEmpty }.eraseToAnyPublisher()
    }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showProjects).eraseToAnyPublisher()
    }

    func identifier(for item: Item) -> NSCopying {
        item.project.objectID
    }

    func project(for identifier: NSCopying) -> Project? {
        context.object(with: identifier as! NSManagedObjectID) as? Project
    }

    func createProject() -> AnyPublisher<Project, Never> {
        actionRunner.perform(CreateProjectAction()).ignoreError().eraseToAnyPublisher()
    }
}
