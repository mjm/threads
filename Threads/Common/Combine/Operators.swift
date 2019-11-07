//
//  Operators.swift
//  Threads
//
//  Created by Matt Moriarity on 10/29/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine

extension Publisher {
    /// Swallow errors, completing the stream immediately.
    func ignoreError() -> Publishers.Catch<Self, Empty<Output, Never>> {
        self.catch { _ in Empty(completeImmediately: true) }
    }

    /// Transform the stream into one that produces optional values of the same time.
    ///
    /// This allows you to use a stream that produces non-optional values with a subscriber that is expecting optionals.
    ///
    func optionally() -> AnyPublisher<Self.Output?, Self.Failure> {
        map { o -> Output? in o }.eraseToAnyPublisher()
    }

    /// A variant of sink that keeps the subscription alive until it completes.
    ///
    /// Use this for publishers that are known to complete at some point in the near future when there is no appropriate
    /// place to store the subscription. Using this with a publisher that doesn't complete will cause a memory leak.
    ///
    /// - Parameters:
    ///    - receiveCompletion: The closure to execute on completion.
    ///    - receiveValue: The closure to execute on receipt of a value.
    ///
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

    /// Modifies the collections in the output by applying lists of changes from another publisher.
    ///
    /// This is most useful when the publisher feeds this result back into itself, so that the next element in the stream
    /// is the result of applying the last collection of changes.
    ///
    /// Use the `transform` closure to produce a collection of elements parallel to the elements in the collection
    /// producing the changes. The benefit of doing this instead of just mapping over the collection is that you only
    /// create new elements when they were inserted in the original list: otherwise, the value remains the same.
    ///
    /// - Parameters:
    ///    - changes: A publisher that emits collections of changes that should be applied to the collections
    ///      that this publisher produces. The type of element for the changes can be different than the elements
    ///      in those collections.
    ///    - transform: A closure that is called on each inserted element found in `changes` that transforms
    ///      it into the element that will inserted into the collections emitted by the returned publisher.
    ///
    /// - Returns: A new publisher that emits the collections from this publisher with the changes applied.
    ///
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
    /// Inverts boolean values in the stream.
    func invert() -> AnyPublisher<Self.Output, Self.Failure> {
        map { !$0 }.eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Never {
    /// A variant of sink that keeps the subscription alive until it completes.
    ///
    /// Use this for publishers that are known to complete at some point in the near future when there is no appropriate
    /// place to store the subscription. Using this with a publisher that doesn't complete will cause a memory leak.
    ///
    /// - Parameters:
    ///    - receiveValue: The closure to execute on receipt of a value.
    ///
    func handle(receiveValue: @escaping (Output) -> Void) {
        handle(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }

    /// Assign the output to a property of an object.
    ///
    /// - Parameters:
    ///    - keyPath: A key path indicating the property to assign.
    ///    - object: The object that contains the property.
    ///    - weak: Whether to hold `object` weakly or not. Use this to avoid cycles.
    ///
    /// - Returns:A subscriber that assigns the value to the property.
    ///
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
