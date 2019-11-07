//
//  ReactiveViewControllers.swift
//  Threads
//
//  Created by Matt Moriarity on 10/24/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

// MARK: - Table View Controller

class ReactiveTableViewController<ViewModel: SnapshotViewModel>: UITableViewController
where ViewModel.Item: ReusableCell {
    typealias DataSource = TableViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    typealias Snapshot = ViewModel.Snapshot

    @Published var animate: Bool = false
    var cancellables = Set<AnyCancellable>()

    var dataSource: DataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        registerCellTypes()

        subscribe()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if !targetEnvironment(macCatalyst)
        becomeFirstResponder()
        #endif

        animate = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        #if !targetEnvironment(macCatalyst)
        resignFirstResponder()
        #endif
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        NSManagedObjectContext.view.undoManager
    }

    //    override func updateUserActivityState(_ activity: NSUserActivity) {
    //        currentUserActivity?.update(activity)
    //    }

    private func registerCellTypes() {
        for (identifier, type) in cellTypes {
            switch type {
            case let .class(cellClass):
                tableView.register(cellClass, forCellReuseIdentifier: identifier)
            case let .nib(cellClass):
                cellClass.registerNib(on: tableView, reuseIdentifier: identifier)
            }
        }
    }

    // MARK: - Subclasses can override

    var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        [:]
    }

    func subscribe() {}
}

// MARK: - Collection View Controller

class ReactiveCollectionViewController<ViewModel: SnapshotViewModel>: UICollectionViewController
where ViewModel.Item: ReusableCell {
    typealias DataSource = CollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    typealias Snapshot = ViewModel.Snapshot

    var dataSource: DataSource!
    @Published var animate: Bool = false

    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.collectionViewLayout = createLayout()

        registerCellTypes()
        subscribe()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if !targetEnvironment(macCatalyst)
        becomeFirstResponder()
        #endif

        animate = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        #if !targetEnvironment(macCatalyst)
        resignFirstResponder()
        #endif
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        NSManagedObjectContext.view.undoManager
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.collectionViewLayout.invalidateLayout()
    }

    //    override func updateUserActivityState(_ activity: NSUserActivity) {
    //        currentUserActivity?.update(activity)
    //    }

    private func registerCellTypes() {
        for (identifier, type) in cellTypes {
            switch type {
            case let .class(cellClass):
                collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
            case let .nib(cellClass):
                cellClass.registerNib(on: collectionView, reuseIdentifier: identifier)
            }
        }
    }

    // MARK: - Subclasses can override

    var cellTypes: [String: RegisteredCellType<UICollectionViewCell>] {
        [:]
    }

    func createLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout()
    }

    func subscribe() {}
}

enum RegisteredCellType<T> {
    case `class`(T.Type)
    case nib(T.Type)
}
