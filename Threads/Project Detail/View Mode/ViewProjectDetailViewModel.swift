//
//  ViewProjectDetailViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/30/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class ViewProjectDetailViewModel: ProjectDetailMode {
    typealias Snapshot = ProjectDetailViewModel.Snapshot

    let project: Project

    @Published private(set) var imageViewModels: [ViewProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [ViewProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(project: Project) {
        self.project = project

        $imageViewModels.applyingDifferences(imageChanges.ignoreError()) { projectImage in
            ViewProjectImageCellViewModel(projectImage: projectImage)
        }.assign(to: \.imageViewModels, on: self).store(in: &cancellables)

        $threadViewModels.applyingDifferences(threadChanges.ignoreError()) { projectThread in
            ViewProjectThreadCellViewModel(projectThread: projectThread)
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)
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

            if !imageModels.isEmpty {
                snapshot.appendSections([.viewImages])
                snapshot.appendItems(imageModels.map { .viewImage($0) }, toSection: .viewImages)
            }
            if let notes = notes, notes.length > 0 {
                snapshot.appendSections([.notes])
                snapshot.appendItems([.viewNotes], toSection: .notes)
            }

            snapshot.appendSections([.threads])
            snapshot.appendItems(
                threadModels.enumerated().map { (index, item) in
                    item.isLastItem = threadModels.index(after: index) == threadModels.endIndex
                    return .viewThread(item)
                }, toSection: .threads)

            return snapshot
        }.eraseToAnyPublisher()
    }

    private var notes: AnyPublisher<NSAttributedString?, Never> {
        project.publisher(for: \.notes).eraseToAnyPublisher()
    }
}
