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

    struct Item: Hashable {
        var project: Project
    }

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    private let projectsList: FetchedObjectList<Project>

    override init(context: NSManagedObjectContext = .view) {
        projectsList
            = FetchedObjectList(
                fetchRequest: Project.allProjectsFetchRequest(),
                managedObjectContext: context
            )

        super.init(context: context)
    }

    var projects: AnyPublisher<[Project], Never> {
        projectsList.objectsPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        projects.map { projects in
            var snapshot = Snapshot()

            snapshot.appendSections([.projects])
            snapshot.appendItems(projects.map(Item.init(project:)), toSection: .projects)

            return snapshot
        }.eraseToAnyPublisher()
    }

    var isEmpty: AnyPublisher<Bool, Never> {
        projects.map { $0.isEmpty }.eraseToAnyPublisher()
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
