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
    private let imagesList: FetchedObjectList<ProjectImage>
    private let threadsList: FetchedObjectList<ProjectThread>

    @Published private(set) var imageViewModels: [ViewProjectImageCellViewModel] = []
    @Published private(set) var threadViewModels: [ViewProjectThreadCellViewModel] = []

    private var cancellables = Set<AnyCancellable>()

    init(project: Project,
         imagesList: FetchedObjectList<ProjectImage>,
         threadsList: FetchedObjectList<ProjectThread>) {
        self.project = project
        self.imagesList = imagesList
        self.threadsList = threadsList

        $imageViewModels.applyingDifferences(imagesList.differences) { projectImage in
            ViewProjectImageCellViewModel(projectImage: projectImage)
        }.assign(to: \.imageViewModels, on: self).store(in: &cancellables)

        $threadViewModels.applyingDifferences(threadsList.differences) { projectThread in
            ViewProjectThreadCellViewModel(projectThread: projectThread)
        }.assign(to: \.threadViewModels, on: self).store(in: &cancellables)
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
