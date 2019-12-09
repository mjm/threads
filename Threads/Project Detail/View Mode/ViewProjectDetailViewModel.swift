//
//  ViewProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combinable
import CombinableCoreData
import CoreData
import UIKit

final class ViewProjectDetailViewModel: ProjectDetailMode {
    typealias Snapshot = ProjectDetailViewModel.Snapshot

    let project: Project

    let projectDetailModel: ProjectDetailCellViewModel
    @Published private(set) var imageViewModels: [ViewProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [ViewProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(project: Project) {
        self.project = project
        self.projectDetailModel = ProjectDetailCellViewModel(project: project)

        $imageViewModels.applyingChanges(imageChanges.ignoreError()) { projectImage in
            ViewProjectImageCellViewModel(projectImage: projectImage)
        }.assign(to: \.imageViewModels, on: self, weak: true).store(in: &cancellables)

        $threadViewModels.applyingChanges(threadChanges.ignoreError()) { projectThread in
            ViewProjectThreadCellViewModel(projectThread: projectThread)
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
        sectionedThreadModels.combineLatest($imageViewModels, notes) {
            [projectDetailModel] threadModels, imageModels, notes -> Snapshot in
            var snapshot = Snapshot()

            if !imageModels.isEmpty {
                snapshot.appendSections([.viewImages])
                snapshot.appendItems(imageModels.map { .viewImage($0) }, toSection: .viewImages)
            }
            if let notes = notes, notes.length > 0 {
                snapshot.appendSections([.notes])
                snapshot.appendItems([.viewNotes(projectDetailModel)], toSection: .notes)
            }

            let filters: [ProjectDetailViewModel.ThreadFilter] = [.notInCollection, .inCollection]
            for filter in filters {
                if let models = threadModels[filter], !models.isEmpty {
                    snapshot.appendSections([.threads(filter)])
                    snapshot.appendItems(
                        models.enumerated().map { (index, item) in
                            item.isLastItem = models.index(after: index) == models.endIndex
                            return .viewThread(item)
                        }, toSection: .threads(filter))
                }
            }

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var sectionedThreadModels:
        AnyPublisher<[ProjectDetailViewModel.ThreadFilter: [ViewProjectThreadCellViewModel]], Never>
    {
        $threadViewModels.map { models in
            Dictionary(grouping: models) { model in
                return model.isInCollection ? .inCollection : .notInCollection
            }
        }.eraseToAnyPublisher()
    }

    private var notes: AnyPublisher<NSAttributedString?, Never> {
        project.publisher(for: \.notes).eraseToAnyPublisher()
    }
}
