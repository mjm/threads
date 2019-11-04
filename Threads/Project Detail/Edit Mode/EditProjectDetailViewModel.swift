//
//  EditProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class EditProjectDetailViewModel: ProjectDetailMode {
    typealias Snapshot = ProjectDetailViewModel.Snapshot

    let project: Project
    private let actionRunner: UserActionRunner

    @Published private(set) var imageViewModels: [EditProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [EditProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(
        project: Project,
        actionRunner: UserActionRunner
    ) {
        self.project = project
        self.actionRunner = actionRunner

        $imageViewModels.applyingChanges(imageChanges.ignoreError()) { projectImage in
            EditProjectImageCellViewModel(projectImage: projectImage, actionRunner: actionRunner)
        }.assignWeakly(to: \.imageViewModels, on: self).store(in: &cancellables)

        $threadViewModels.applyingChanges(threadChanges.ignoreError()) {
            [weak self] projectThread in
            let model = EditProjectThreadCellViewModel(projectThread: projectThread)
            model.actions.sink { [weak self] action in
                self?.handleAction(action, for: projectThread)
            }.store(in: &model.cancellables)
            return model
        }.assignWeakly(to: \.threadViewModels, on: self).store(in: &cancellables)
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
            threadModels, imageModels, notes -> Snapshot in
            var snapshot = Snapshot()

            snapshot.appendSections([.editImages, .details])
            snapshot.appendItems(imageModels.map { .editImage($0) }, toSection: .editImages)
            snapshot.appendItems([.imagePlaceholder], toSection: .editImages)
            snapshot.appendItems([.editName, .editNotes], toSection: .details)

            snapshot.appendSections([.threads])
            snapshot.appendItems(threadModels.map { .editThread($0) }, toSection: .threads)

            #if !targetEnvironment(macCatalyst)
            snapshot.appendItems([.add], toSection: .threads)
            #endif

            return snapshot
        }.eraseToAnyPublisher()
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
