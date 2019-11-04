//
//  Operators.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine

extension Publisher {
    func ignoreError() -> Publishers.Catch<Self, Empty<Output, Never>> {
        self.catch { _ in Empty(completeImmediately: true) }
    }

    func optionally() -> AnyPublisher<Self.Output?, Self.Failure> {
        map { o -> Output? in o }.eraseToAnyPublisher()
    }

    func handle(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Void
    ) {
        var cancellable: AnyCancellable?
        cancellable
            = sink(
                receiveCompletion: { completion in
                    receiveCompletion(completion)
                    cancellable?.cancel()
                }, receiveValue: receiveValue)
    }

    func applyingChanges<Changes: Publisher, ChangeItem>(
        _ changes: Changes,
        _ transform: @escaping (ChangeItem) -> Output.Element
    ) -> AnyPublisher<Output, Failure>
    where Output: RangeReplaceableCollection,
        Output.Index == Int,
        Changes.Output == CollectionDifference<ChangeItem>,
        Changes.Failure == Failure
    {
        zip(changes) { existing, changes -> Output in
            var objects = existing
            for change in changes {
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

extension Publisher where Failure == Never {
    func handle(receiveValue: @escaping (Output) -> Void) {
        handle(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    func assign<Root: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<Root, Output>,
        on object: Root,
        weak: Bool
    ) -> AnyCancellable {
        // TODO maybe implement this as a real subscriber
        if weak {
            return sink { [weak object] newValue in
                object?[keyPath: keyPath] = newValue
            }
        } else {
            return assign(to: keyPath, on: object)
        }
    }
}
