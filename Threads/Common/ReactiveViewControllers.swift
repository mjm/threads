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

// MARK: - View Controller

class ReactiveViewController: UIViewController {
    private(set) var actionRunner: UserActionRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner
            = UserActionRunner(presenter: self, managedObjectContext: managedObjectContext)
    }

    #if !targetEnvironment(macCatalyst)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    #endif

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        managedObjectContext.undoManager
    }

    //    override func updateUserActivityState(_ activity: NSUserActivity) {
    //        currentUserActivity?.update(activity)
    //    }

    // MARK: - Subclasses can override

    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
}

// MARK: - Table View Controller

class ReactiveTableViewController<SectionType: Hashable, CellType: ReusableCell>: UITableViewController
{
    typealias DataSource = TableViewDiffableDataSource<SectionType, CellType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, CellType>

    private(set) var actionRunner: UserActionRunner!
    private(set) var dataSource: DataSource!
    @Published var animate: Bool = false

    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner
            = UserActionRunner(presenter: self, managedObjectContext: managedObjectContext)

        registerCellTypes()

        dataSource
            = DataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
                guard let self = self else {
                    return nil
                }

                let cell = tableView.dequeueReusableCell(
                    withIdentifier: item.cellIdentifier, for: indexPath)
                self.populate(cell: cell, item: item)
                return cell
            }

        dataSourceWillInitialize()

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
        managedObjectContext.undoManager
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

    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

    var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        [:]
    }

    func populate(cell: UITableViewCell, item: CellType) {
        preconditionFailure("populate(cell:item:) must be implemented for \(type(of: self))")
    }

    func dataSourceWillInitialize() {}

    func subscribe() {}
}

// MARK: - Collection View Controller

class ReactiveCollectionViewController<SectionType: Hashable, CellType: ReusableCell>: UICollectionViewController
{
    typealias DataSource = UICollectionViewDiffableDataSource<SectionType, CellType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, CellType>

    private(set) var actionRunner: UserActionRunner!
    private(set) var dataSource: DataSource!
    @Published var animate: Bool = false

    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner
            = UserActionRunner(presenter: self, managedObjectContext: managedObjectContext)

        registerCellTypes()

        dataSource
            = DataSource(collectionView: collectionView) {
                [weak self] collectionView, indexPath, item in
                guard let self = self else {
                    return nil
                }

                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: item.cellIdentifier, for: indexPath)
                self.populate(cell: cell, item: item)
                return cell
            }

        dataSourceWillInitialize()
        collectionView.collectionViewLayout = createLayout()

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
        managedObjectContext.undoManager
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

    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

    var cellTypes: [String: RegisteredCellType<UICollectionViewCell>] {
        [:]
    }

    func populate(cell: UICollectionViewCell, item: CellType) {
        preconditionFailure("populate(cell:item:) must be implemented for \(type(of: self))")
    }

    func createLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout()
    }

    func dataSourceWillInitialize() {}
    func dataSourceDidUpdateSnapshot(animated: Bool) {}

    func subscribe() {}
}

extension Publisher {
    func apply<Section, Item>(
        to dataSource: UITableViewDiffableDataSource<Section, Item>, animate: Bool = true
    ) -> AnyCancellable
    where Output == NSDiffableDataSourceSnapshot<Section, Item>, Failure == Never {
        combineLatest(Just(animate)).apply(to: dataSource)
    }

    func apply<Section, Item>(to dataSource: UITableViewDiffableDataSource<Section, Item>)
        -> AnyCancellable
    where Output == (NSDiffableDataSourceSnapshot<Section, Item>, Bool), Failure == Never {
        sink { (snapshot, animate) in
            dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }

    func apply<Section, Item>(
        to dataSource: UICollectionViewDiffableDataSource<Section, Item>, animate: Bool = true
    ) -> AnyCancellable
    where Output == NSDiffableDataSourceSnapshot<Section, Item>, Failure == Never {
        combineLatest(Just(animate)).apply(to: dataSource)
    }

    func apply<Section, Item>(to dataSource: UICollectionViewDiffableDataSource<Section, Item>)
        -> AnyCancellable
    where Output == (NSDiffableDataSourceSnapshot<Section, Item>, Bool), Failure == Never {
        sink { (snapshot, animate) in
            dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }
}
