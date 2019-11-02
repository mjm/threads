//
//  ProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class ProjectDetailViewModel: ViewModel, SnapshotViewModel {
    enum Section {
        case viewImages
        case editImages
        case details
        case notes
        case threads
    }

    enum Item: Hashable {
        case viewImage(ViewProjectImageCellViewModel)
        case viewNotes
        case viewThread(ViewProjectThreadCellViewModel)

        case editImage(EditProjectImageCellViewModel)
        case imagePlaceholder
        case editName
        case editNotes
        case editThread(EditProjectThreadCellViewModel)
        case add
    }

    let project: Project

    @Published var isEditing = false

    var viewModeModel: ViewProjectDetailViewModel!
    var editModeModel: EditProjectDetailViewModel!

    init(project: Project, editing: Bool = false) {
        self.project = project
        self.isEditing = editing

        super.init(context: project.managedObjectContext!)

        viewModeModel = ViewProjectDetailViewModel(project: project)
        editModeModel
            = EditProjectDetailViewModel(
                project: project,
                actionRunner: actionRunner)

        $isEditing.sink { [weak self] editing in
            self?.context.commit()
        }.store(in: &cancellables)
    }

    var currentMode: AnyPublisher<ProjectDetailMode, Never> {
        let viewModeModel = self.viewModeModel!
        let editModeModel = self.editModeModel!

        return $isEditing.removeDuplicates().map { editing -> ProjectDetailMode in
            editing ? editModeModel : viewModeModel
        }.eraseToAnyPublisher()
    }

    var snapshot: AnyPublisher<Snapshot, Never> {
        $isEditing.combineLatest(viewModeModel.snapshot, editModeModel.snapshot) {
            editing, viewSnapshot, editSnapshot in
            editing ? editSnapshot : viewSnapshot
        }.eraseToAnyPublisher()
    }

    var name: AnyPublisher<String?, Never> {
        project.publisher(for: \.displayName).optionally().eraseToAnyPublisher()
    }

    var threadCount: AnyPublisher<Int, Never> {
        viewModeModel.$threadViewModels.map { $0.count }.eraseToAnyPublisher()
    }

    var userActivity: AnyPublisher<UserActivity, Never> {
        Just(.showProject(project)).eraseToAnyPublisher()
    }
}

// MARK: - Actions
extension ProjectDetailViewModel {
    var sheetActions: [BoundUserAction<Void>] {
        [
            editAction,
            shareAction,
            addToShoppingListAction,
        ]
    }

    var shareAction: BoundUserAction<Void> {
        ShareProjectAction(project: project)
            .bind(to: actionRunner, title: Localized.share)
    }

    var addToShoppingListAction: BoundUserAction<Void> {
        AddProjectToShoppingListAction(project: project)
            .bind(to: actionRunner)
    }

    var deleteAction: BoundUserAction<Void> {
        DeleteProjectAction(project: project)
            .bind(to: actionRunner, title: Localized.delete, options: .destructive)
    }

    private var editAction: BoundUserAction<Void> {
        BoundUserAction(title: Localized.edit) { _, _ in
            self.isEditing = true
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
    }

    func addThreads() {
        actionRunner.perform(AddThreadAction(mode: .project(project)))
    }

    func addImage() {
        actionRunner.perform(AddImageToProjectAction(project: project))
    }

    func moveImage(from source: Int, to destination: Int, completion: @escaping () -> Void) {
        actionRunner.perform(
            MoveProjectImageAction(
                project: project,
                sourceIndex: source,
                destinationIndex: destination),
            willPerform: completion
        ).ignoreError().receive(on: RunLoop.main).handle(receiveValue: completion)
    }
}

// MARK: - Toolbar
#if targetEnvironment(macCatalyst)

extension ProjectDetailViewModel: ToolbarItemProviding {
    var title: AnyPublisher<String, Never> {
        project.publisher(for: \.displayName).eraseToAnyPublisher()
    }

    var trailingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> {
        $isEditing.map { editing in
            editing ? [.doneEditing] : [.edit]
        }.eraseToAnyPublisher()
    }
}

#endif

extension ProjectDetailViewModel: Equatable {
    static func == (lhs: ProjectDetailViewModel, rhs: ProjectDetailViewModel) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

protocol ProjectDetailMode {
    var snapshot: AnyPublisher<ProjectDetailViewModel.Snapshot, Never> { get }
}

class AddThreadsToProjectMode: AddThreadMode {
    let project: Project

    init(project: Project) {
        self.project = project
    }

    func addThreadChoices() throws -> [Thread] {
        let projectThreads = try project.managedObjectContext!.fetch(
            ProjectThread.fetchRequest(for: project))
        let existingThreads = projectThreads.compactMap { $0.thread }

        // Not ideal, but I haven't figured out a way in Core Data to get all the threads that
        // aren't in a particular project. Many-to-many relationships are hard.
        let allThreads = try project.managedObjectContext!.fetch(
            Thread.sortedByNumberFetchRequest())

        return allThreads.filter { !existingThreads.contains($0) }
    }

    func add(threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToProjectAction(threads: threads, project: project))
    }
}
