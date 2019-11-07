//
//  Snapshots.swift
//  Threads
//
//  Created by Matt Moriarity on 11/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

protocol DiffableSnapshotApplying: class {
    associatedtype SectionIdentifierType: Hashable
    associatedtype ItemIdentifierType: Hashable

    var cancellables: Set<AnyCancellable> { get set }

    func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool, completion: (() -> Void)?
    )
}

extension DiffableSnapshotApplying {
    typealias SnapshotType = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>

    func bound<Snapshot: Publisher, Animate: Publisher>(
        to snapshot: Snapshot,
        animate: Animate
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never,
        Animate.Output == Bool,
        Animate.Failure == Never
    {
        snapshot.withLatestFrom(animate)
            .sink { [weak self] input in
                let (snapshot, animate) = input
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }

    func bound<Snapshot: Publisher>(
        to snapshot: Snapshot,
        animate: Bool
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never
    {
        snapshot
            .sink { [weak self] snapshot in
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }

    func bound<Snapshot: Publisher, Animate: Publisher, Schedule: Scheduler>(
        to snapshot: Snapshot,
        animate: Animate,
        on scheduler: Schedule
    ) -> Self
    where
        Snapshot.Output == SnapshotType,
        Snapshot.Failure == Never,
        Animate.Output == Bool,
        Animate.Failure == Never
    {
        snapshot.withLatestFrom(animate)
            .receive(on: scheduler)
            .sink { [weak self] input in
                let (snapshot, animate) = input
                self?.apply(snapshot, animatingDifferences: animate, completion: nil)
            }
            .store(in: &cancellables)

        return self
    }
}
