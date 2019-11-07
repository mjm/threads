//
//  CollectionViewDiffableDataSource.swift
//  Threads
//
//  Created by Matt Moriarity on 11/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class CollectionViewDiffableDataSource<
    SectionIdentifierType: Hashable, ItemIdentifierType: ReusableCell
>: UICollectionViewDiffableDataSource<
    SectionIdentifierType, ItemIdentifierType
>, DiffableSnapshotApplying
{
    var cancellables = Set<AnyCancellable>()

    init(
        _ collectionView: UICollectionView,
        configureCell: @escaping (UICollectionViewCell, ItemIdentifierType) -> Void
    ) {
        super.init(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: item.cellIdentifier, for: indexPath)
            configureCell(cell, item)
            return cell
        }
    }

    typealias SupplementaryViewProviderWithType = (
        UICollectionView, String, IndexPath, SectionIdentifierType
    ) -> UICollectionReusableView?

    func withSupplementaryViews(_ viewProvider: @escaping SupplementaryViewProviderWithType) -> Self
    {
        self.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.snapshot().sectionIdentifiers[indexPath.section]
            else {
                return nil
            }

            return viewProvider(collectionView, kind, indexPath, section)
        }

        return self
    }
}
