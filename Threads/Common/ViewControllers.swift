//
//  ViewControllers.swift
//  Threads
//
//  Created by Matt Moriarity on 9/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

enum RegisteredCellType<T> {
    case `class`(T.Type)
    case nib(T.Type)
}

// MARK: - View Controller

class ViewController: UIViewController {
    private(set) var actionRunner: UserActionRunner!

    override func viewDidLoad() {
        super.viewDidLoad()

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

        userActivity = currentUserActivity?.userActivity
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

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

protocol ReusableCell: Hashable {
    var cellIdentifier: String { get }
}

class TableViewController<SectionType: Hashable, CellType: ReusableCell>: UITableViewController {
    typealias DataSource = TableViewDiffableDataSource<SectionType, CellType>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SectionType, CellType>

    private(set) var actionRunner: UserActionRunner!
    private(set) var dataSource: DataSource!

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
        updateSnapshot(animated: false)

        userActivity = currentUserActivity?.userActivity
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var undoManager: UndoManager? {
        managedObjectContext.undoManager
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
    func dataSourceDidUpdateSnapshot(animated: Bool) {}
    func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {}
}


// MARK: - Collection View Controller