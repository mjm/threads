//
//  ViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

class ViewModel {
    var cancellables = Set<AnyCancellable>()
    let context: NSManagedObjectContext
    let actionRunner: UserActionRunner

    init(context: NSManagedObjectContext = .view) {
        self.context = context

        actionRunner = UserActionRunner(managedObjectContext: context)
    }

    var presenter: UserActionPresenter? {
        get {
            actionRunner.presenter
        }
        set {
            actionRunner.presenter = newValue
        }
    }
}

protocol SnapshotViewModel {
    associatedtype Section: Hashable
    associatedtype Item: Hashable

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    var snapshot: AnyPublisher<Snapshot, Never> { get }
}
