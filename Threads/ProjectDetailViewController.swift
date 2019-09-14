//
//  ProjectDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/9/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ProjectDetailViewController: UICollectionViewController {
    enum Section: CaseIterable {
        case details
        case threads
    }
    
    enum Cell: Hashable {
        case viewThread(ProjectThread, isLast: Bool)
        
        case editName
        case editThread(ProjectThread)
        case add
        
        var cellIdentifier: String {
            switch self {
            case .viewThread: return "Thread"
            case .editName: return "TextInput"
            case .editThread: return "EditThread"
            case .add: return "Add"
            }
        }
        
        func populate(cell: UICollectionViewCell, project: Project) {
            switch self {

            case let .viewThread(projectThread, isLast: isLast):
                let cell = cell as! ViewProjectThreadCollectionViewCell
                cell.populate(projectThread, isLastItem: isLast)
                
            case .editName:
                let cell = cell as! TextInputCollectionViewCell
                cell.textField.placeholder = Localized.projectName
                cell.textField.text = project.name
                cell.onChange = { newText in
                    project.name = newText
                }
                cell.onReturn = { [unowned cell] in
                    cell.textField.resignFirstResponder()
                }

            case let .editThread(projectThread):
                let cell = cell as! EditProjectThreadCollectionViewCell
                cell.populate(projectThread)
                cell.onDecreaseQuantity = {
                    if projectThread.amount == 1 {
                        projectThread.managedObjectContext?.delete(projectThread)
                    } else {
                        projectThread.amount -= 1
                    }
                }
                cell.onIncreaseQuantity = {
                    projectThread.amount += 1
                }

            case .add:
                return
            }
        }
    }
    
    let project: Project

    private var fetchedResultsController: NSFetchedResultsController<ProjectThread>!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Cell>!
    
    @IBOutlet var shareButtonItem: UIBarButtonItem!
    
    private var projectNameObserver: NSKeyValueObservation?
    
    init?(coder: NSCoder, project: Project) {
        self.project = project
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = project.name
        navigationItem.rightBarButtonItems = [editButtonItem, shareButtonItem]
        
        projectNameObserver = project.observe(\.name) { [weak self] project, change in
            self?.navigationItem.title = project.name
        }
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: ProjectThread.fetchRequest(for: project),
                                       managedObjectContext: project.managedObjectContext!,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        collectionView.register(ViewProjectThreadCollectionViewCell.nib, forCellWithReuseIdentifier: "Thread")
        collectionView.register(EditProjectThreadCollectionViewCell.nib, forCellWithReuseIdentifier: "EditThread")
        collectionView.register(TextInputCollectionViewCell.nib, forCellWithReuseIdentifier: "TextInput")
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.cellIdentifier, for: indexPath)
            item.populate(cell: cell, project: self.project)
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section] else {
                return nil
            }
            
            switch (kind, section) {
            case (UICollectionView.elementKindSectionHeader, .threads):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath) as! SectionHeaderLabelView
                view.textLabel.text = self?.threadsSectionHeaderText()
                return view
            default:
                return nil
            }
        }
        
        collectionView.collectionViewLayout = createLayout()
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot(animated: false)
        } catch {
            NSLog("Could not load project threads: \(error)")
        }
        
        userActivity = UserActivity.showProject(project).userActivity
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
        project.managedObjectContext?.undoManager
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateSnapshot(animated: animated)

        navigationItem.largeTitleDisplayMode = editing ? .never : .automatic
        navigationItem.setRightBarButtonItems(editing ? [editButtonItem] : [editButtonItem, shareButtonItem],
                                              animated: animated)

        if editing {
            AppDelegate.save()
            undoManager?.beginUndoGrouping()
            undoManager?.setActionName(Localized.changeProject)
        } else {
            undoManager?.endUndoGrouping()
            AppDelegate.save()
        }
    }
    
    func updateSnapshot(animated: Bool = true) {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        
        if isEditing {
            snapshot.appendSections([.details])
            snapshot.appendItems([.editName], toSection: .details)
        }
        
        snapshot.appendSections([.threads])
        snapshot.appendItems(objects.enumerated().map { (index, item) in
            if isEditing {
                return Cell.editThread(item)
            } else {
                let isLast = objects.index(after: index) == objects.endIndex
                return Cell.viewThread(item, isLast: isLast)
            }
        }, toSection: .threads)
        
        if isEditing {
            snapshot.appendItems([.add], toSection: .threads)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animated)
        
        // update the threads section header if needed
        if let threadSectionIndex = snapshot.indexOfSection(.threads),
            let sectionHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: threadSectionIndex)) as? SectionHeaderLabelView {
            sectionHeader.textLabel.text = threadsSectionHeaderText()
            sectionHeader.setNeedsLayout()
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            let sectionType = self!.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            
            switch sectionType {
            case .details:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 34, leading: 0, bottom: 15, trailing: 0)
                return section
            case .threads:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 44, trailing: 0)
                return section
            }
        }
    }
    
    private func threadsSectionHeaderText() -> String {
        let items = self.fetchedResultsController.fetchedObjects?.count ?? 0
        return String.localizedStringWithFormat(Localized.threadsSectionHeader, items)
    }
    
    @IBAction func shareProject() {
        let activityController = UIActivityViewController(activityItems: [project],
                                                          applicationActivities: nil)
        present(activityController, animated: true)
    }

    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController
        for thread in addViewController.selectedThreads {
            thread.add(to: project)
        }
        AppDelegate.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the shopping list
                let threads: [Thread]
                do {
                    let existingThreads = (fetchedResultsController.fetchedObjects ?? []).compactMap { $0.thread }
                    let request = Thread.sortedByNumberFetchRequest()
                    
                    // Not ideal, but I haven't figured out a way in Core Data to get all the threads that
                    // aren't in a particular project. Many-to-many relationships are hard.
                    threads = try project.managedObjectContext!.fetch(request).filter { !existingThreads.contains($0) }
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = dataSource.itemIdentifier(for: indexPath)
        return item == .add
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        if item == .add {
            performSegue(withIdentifier: "AddThread", sender: nil)
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        UserActivity.showProject(project).update(activity)
    }
}

extension ProjectDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let thread = anObject as! ProjectThread

            if let indexPath = dataSource.indexPath(for: .viewThread(thread, isLast: false)),
                let cell = collectionView.cellForItem(at: indexPath) as? ViewProjectThreadCollectionViewCell {
                cell.populate(thread)
            } else if let indexPath = dataSource.indexPath(for: .viewThread(thread, isLast: true)),
                let cell = collectionView.cellForItem(at: indexPath) as? ViewProjectThreadCollectionViewCell {
                cell.populate(thread, isLastItem: true)
            } else if let indexPath = dataSource.indexPath(for: .editThread(thread)),
                let cell = collectionView.cellForItem(at: indexPath) as? EditProjectThreadCollectionViewCell {
                cell.populate(thread)
            }
        default:
            break
        }
    }
}


class SectionHeaderLabelView: UICollectionReusableView {
    @IBOutlet var textLabel: UILabel!
}

class AddThreadCollectionViewCell: UICollectionViewCell {
    override var isSelected: Bool {
        didSet {
            updateBackground()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateBackground()
        }
    }
    
    private func updateBackground() {
        contentView.backgroundColor = (isSelected || isHighlighted) ? .opaqueSeparator : .systemBackground
    }
}
