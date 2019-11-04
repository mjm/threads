//
//  Snapshots.swift
//  Threads
//
//  Created by Matt Moriarity on 11/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

extension Publisher {
    func apply<DataSource: DiffableSnapshotApplying, Animate: Publisher, SchedulerType: Scheduler>(
        to dataSource: DataSource,
        animate: Animate,
        on scheduler: SchedulerType
    )
        -> AnyCancellable
    where
        Output == DataSource.SnapshotType,
        Animate.Output == Bool,
        Failure == Never,
        Animate.Failure == Never
    {
        combineLatest(animate).receive(on: scheduler).applySink(dataSource)
    }

    func apply<DataSource: DiffableSnapshotApplying, Animate: Publisher>(
        to dataSource: DataSource,
        animate: Animate
    )
        -> AnyCancellable
    where
        Output == DataSource.SnapshotType,
        Animate.Output == Bool,
        Failure == Never,
        Animate.Failure == Never
    {
        combineLatest(animate).applySink(dataSource)
    }

    func apply<DataSource: DiffableSnapshotApplying>(
        to dataSource: DataSource
    )
        -> AnyCancellable
    where
        Output == DataSource.SnapshotType,
        Failure == Never
    {
        combineLatest(Just(true)).applySink(dataSource)
    }

    private func applySink<DataSource: DiffableSnapshotApplying>(
        _ dataSource: DataSource
    ) -> AnyCancellable
    where
        Output == (DataSource.SnapshotType, Bool),
        Failure == Never
    {
        sink { values in
            let (snapshot, animate) = values
            dataSource.apply(snapshot, animatingDifferences: animate, completion: nil)
        }
    }
}

protocol DiffableSnapshotApplying {
    associatedtype SectionIdentifierType: Hashable
    associatedtype ItemIdentifierType: Hashable

    func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool, completion: (() -> Void)?
    )
}

extension DiffableSnapshotApplying {
    typealias SnapshotType = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
}

extension UITableViewDiffableDataSource: DiffableSnapshotApplying {}
extension UICollectionViewDiffableDataSource: DiffableSnapshotApplying {}
