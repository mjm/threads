//
//  EditProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combinable
import CombinableCoreData
import CoreData
import UIKit
import UserActions

final class EditProjectDetailViewModel: ProjectDetailMode {
    typealias Snapshot = ProjectDetailViewModel.Snapshot

    let project: Project
    private let actionRunner: UserActions.Runner

    let projectDetailModel: ProjectDetailCellViewModel
    @Published private(set) var imageViewModels: [EditProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [EditProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(
        project: Project,
        actionRunner: UserActions.Runner
    ) {
        self.project = project
        self.projectDetailModel = ProjectDetailCellViewModel(project: project)
        self.actionRunner = actionRunner

        $imageViewModels.applyingChanges(imageChanges.ignoreError()) { projectImage in
            EditProjectImageCellViewModel(projectImage: projectImage, actionRunner: actionRunner)
        }.assign(to: \.imageViewModels, on: self, weak: true).store(in: &cancellables)

        $threadViewModels.applyingChanges(threadChanges.ignoreError()) {
            [weak self] projectThread in
            let model = EditProjectThreadCellViewModel(projectThread: projectThread)
            model.actions.sink { [weak self] action in
                self?.handleAction(action, for: projectThread)
            }.store(in: &model.cancellables)
            return model
        }.assign(to: \.threadViewModels, on: self, weak: true).store(in: &cancellables)
    }

    private var context: NSManagedObjectContext {
        project.managedObjectContext!
    }

    var imageChanges: ManagedObjectChangesPublisher<ProjectImage> {
        context.changesPublisher(for: ProjectImage.fetchRequest(for: project))
    }

    var threadChanges: ManagedObjectChangesPublisher<ProjectThread> {
        context.changesPublisher(for: ProjectThread.fetchRequest(for: project))
    }

    var snapshot: AnyPublisher<ProjectDetailViewModel.Snapshot, Never> {
        $threadViewModels.combineLatest($imageViewModels, notes) {
            [projectDetailModel] threadModels, imageModels, notes -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.editImages, .details])
            snapshot.appendItems(imageModels.map { .editImage($0) }, toSection: .editImages)
            snapshot.appendItems([.imagePlaceholder], toSection: .editImages)
            snapshot.appendItems(
                [.editName(projectDetailModel), .editNotes(projectDetailModel)], toSection: .details
            )

            snapshot.appendSections([.threads(.all)])
            snapshot.appendItems(threadModels.map { .editThread($0) }, toSection: .threads(.all))

            #if !targetEnvironment(macCatalyst)
            snapshot.appendItems([.add], toSection: .threads(.all))
            #endif

            return snapshot
        }.eraseToAnyPublisher()
    }

    var nameItem: ProjectDetailViewModel.Item {
        .editName(projectDetailModel)
    }

    private var notes: AnyPublisher<NSAttributedString?, Never> {
        project.publisher(for: \.notes).eraseToAnyPublisher()
    }

    private func handleAction(
        _ action: EditProjectThreadCellViewModel.Action, for projectThread: ProjectThread
    ) {
        switch action {
        case .increment:
            projectThread.amount += 1
        case .decrement:
            if projectThread.amount == 1 {
                projectThread.managedObjectContext?.delete(projectThread)
            } else {
                projectThread.amount -= 1
            }
        }
    }
}
