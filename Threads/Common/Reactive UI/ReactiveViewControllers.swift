//
//  ReactiveViewControllers.swift
//  Threads
//
//  Created by Matt Moriarity on 10/24/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import CoreData
import UIKit

// MARK: - Table View Controller

class ReactiveTableViewController<ViewModel: SnapshotViewModel>: UITableViewController
where ViewModel.Item: ReusableCell, ViewModel.Item.Identifier.CellType == UITableViewCell {
    typealias DataSource = CombinableTableViewDataSource<ViewModel.Section, ViewModel.Item>
    typealias Snapshot = ViewModel.Snapshot

    @Published var animate: Bool = false
    var cancellables = Set<AnyCancellable>()

    var dataSource: DataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

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

    // MARK: - Subclasses can override

    func subscribe() {}
}

// MARK: - Collection View Controller

class ReactiveCollectionViewController<ViewModel: SnapshotViewModel>: UICollectionViewController
where ViewModel.Item: ReusableCell, ViewModel.Item.Identifier.CellType == UICollectionViewCell {
    typealias DataSource = CombinableCollectionViewDataSource<ViewModel.Section, ViewModel.Item>
    typealias Snapshot = ViewModel.Snapshot

    var dataSource: DataSource!
    @Published var animate: Bool = false

    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

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
        NSManagedObjectContext.view.undoManager
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collectionView.collectionViewLayout.invalidateLayout()
    }

    //    override func updateUserActivityState(_ activity: NSUserActivity) {
    //        currentUserActivity?.update(activity)
    //    }

    // MARK: - Subclasses can override

    func createLayout() -> UICollectionViewLayout {
        UICollectionViewFlowLayout()
    }

    func subscribe() {}
}
