//
//  EditProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class EditProjectDetailViewModel: ProjectDetailMode {
    typealias Snapshot = ProjectDetailViewModel.Snapshot

    let project: Project
    private let imagesList: FetchedObjectList<ProjectImage>
    private let threadsList: FetchedObjectList<ProjectThread>
    private let actionRunner: UserActionRunner

    @Published private(set) var imageViewModels: [EditProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [EditProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(project: Project,
         imagesList: FetchedObjectList<ProjectImage>,
         threadsList: FetchedObjectList<ProjectThread>,
         actionRunner: UserActionRunner) {
        self.project = project
        self.imagesList = imagesList
        self.threadsList = threadsList
        self.actionRunner = actionRunner

        $imageViewModels.applyingDifferences(imagesList.differences) { projectImage in
            EditProjectImageCellViewModel(projectImage: projectImage, actionRunner: actionRunner)
        }.assign(to: \.imageViewModels, on: self).store(in: &cancellables)

        $threadViewModels.applyingDifferences(threadsList.differences) { [weak self] projectThread in
            let model = EditProjectThreadCellViewModel(projectThread: projectThread)
            model.actions.sink { [weak self] action in
                self?.handleAction(action, for: projectThread)
            }.store(in: &model.cancellables)
            return model
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)
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

    private func handleAction(_ action: EditProjectThreadCellViewModel.Action, for projectThread: ProjectThread) {
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
