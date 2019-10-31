//
//  Operators.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine

extension Publisher {
    func optionally() -> AnyPublisher<Self.Output?, Self.Failure> {
        map { o -> Output? in o }.eraseToAnyPublisher()
    }

    func applyingDifferences<DiffPublisher: Publisher, DiffItem>(
        _ diffs: DiffPublisher,
        _ transform: @escaping (DiffItem) -> Self.Output.Element
    ) -> AnyPublisher<Self.Output, Self.Failure>
    where Self.Output: RangeReplaceableCollection,
        Self.Output.Index == Int,
        DiffPublisher.Output == CollectionDifference<DiffItem>,
        DiffPublisher.Failure == Self.Failure
    {
        combineLatest(diffs) { existing, diff -> Self.Output in
            var objects = existing
            for change in diff {
                switch change {
                case .remove(let offset, _, _):
                    objects.remove(at: offset)
                case .insert(let offset, let obj, _):
                    let transformed = transform(obj)
                    objects.insert(transformed, at: offset)
                }
            }
            return objects
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Output == Bool {
    func invert() -> AnyPublisher<Self.Output, Self.Failure> {
        map { !$0 }.eraseToAnyPublisher()
    }
}
