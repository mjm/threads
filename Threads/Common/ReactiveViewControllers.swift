//
//  ReactiveViewControllers.swift
//  Threads
//
//  Created by Matt Moriarity on 10/24/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import Combine

// MARK: - View Controller

class ReactiveViewController: UIViewController {
    private(set) var actionRunner: UserActionRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

        userActivity = currentUserActivity?.userActivity
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

    override func updateUserActivityState(_ activity: NSUserActivity) {
        currentUserActivity?.update(activity)
    }

    // MARK: - Subclasses can override

    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

    var currentUserActivity: UserActivity? {
        return nil
    }
}

// MARK: - Table View Controller

class ReactiveTableViewController<SectionType: Hashable, CellType: ReusableCell>: UITableViewController {
    typealias DataSource = TableViewDiffableDataSource<SectionType, CellType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, CellType>

    private(set) var actionRunner: UserActionRunner!
    private(set) var dataSource: DataSource!
    @Published var animate: Bool = false

    private var observers: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

        registerCellTypes()

        dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self = self else {
                return nil
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
            self.populate(cell: cell, item: item)
            return cell
        }

        dataSourceWillInitialize()

        observers = createObservers()

        userActivity = currentUserActivity?.userActivity
    }

    #if !targetEnvironment(macCatalyst)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        
        animate = true
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

    override func updateUserActivityState(_ activity: NSUserActivity) {
        currentUserActivity?.update(activity)
    }

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
    
    var selectedCell: CellType? {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return nil
        }
        
        return dataSource.itemIdentifier(for: indexPath)
    }

    // MARK: - Subclasses can override

    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

    var currentUserActivity: UserActivity? {
        return nil
    }

    var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        [:]
    }

    func populate(cell: UITableViewCell, item: CellType) {
        preconditionFailure("populate(cell:item:) must be implemented for \(type(of: self))")
    }

    func dataSourceWillInitialize() {}

    func createObservers() -> [Any] {
        []
    }
}


// MARK: - Collection View Controller

class ReactiveCollectionViewController<SectionType: Hashable, CellType: ReusableCell>: UICollectionViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<SectionType, CellType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, CellType>

    private(set) var actionRunner: UserActionRunner!
    private(set) var dataSource: DataSource!

    private var observers: [Any] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

        registerCellTypes()

        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else {
                return nil
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.cellIdentifier, for: indexPath)
            self.populate(cell: cell, item: item)
            return cell
        }

        dataSourceWillInitialize()
        collectionView.collectionViewLayout = createLayout()
        updateSnapshot(animated: false)

        observers = createObservers()

        userActivity = currentUserActivity?.userActivity
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        currentUserActivity?.update(activity)
    }

    func updateSnapshot(animated: Bool = true) {
        var snapshot = Snapshot()
        buildSnapshotForDataSource(&snapshot)
        dataSource.apply(snapshot, animatingDifferences: animated)

        dataSourceDidUpdateSnapshot(animated: animated)
    }

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

    var currentUserActivity: UserActivity? {
        return nil
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
    func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {}

    func createObservers() -> [Any] {
        []
    }
}
