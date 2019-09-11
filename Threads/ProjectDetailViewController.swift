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
        case threads
    }
    
    enum Cell: Hashable {
        case thread(Thread)
        case add
        
        var cellIdentifier: String {
            switch self {
            case .thread: return "Thread"
            case .add: return "Add"
            }
        }
        
        func populate(cell: UICollectionViewCell, project: Project) {
            switch self {
            case let .thread(thread):
                // TODO this is wrong
                let projectThread = thread.projects!.anyObject() as! ProjectThread
                (cell as! ProjectThreadCollectionViewCell).populate(projectThread)
            case .add:
                return
            }
        }
    }
    
    let project: Project

    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Cell>!
    
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
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.fetchRequest(for: project),
                                       managedObjectContext: project.managedObjectContext!,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        collectionView.register(ProjectThreadCollectionViewCell.nib, forCellWithReuseIdentifier: "Thread")
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
                NSLog("index path = \(indexPath)")
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
            updateSnapshot()
        } catch {
            NSLog("Could not load project threads: \(error)")
        }
    }
    
    func updateSnapshot() {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(objects.map { Cell.thread($0) }, toSection: .threads)
        snapshot.appendItems([.add], toSection: .threads)
        dataSource.apply(snapshot)
        
        // update the threads section header if needed
        if let threadSectionIndex = snapshot.indexOfSection(.threads),
            let sectionHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: threadSectionIndex)) as? SectionHeaderLabelView {
            sectionHeader.textLabel.text = threadsSectionHeaderText()
            sectionHeader.setNeedsLayout()
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(60))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                         heightDimension: .estimated(44))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [sectionHeader]
            return section
        }
    }
    
    private func threadsSectionHeaderText() -> String {
        let items = self.fetchedResultsController.fetchedObjects?.count ?? 0
        return items == 0 ? "THREADS" : "\(items) THREAD\(items == 1 ? "" : "S")"
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
                    let existingThreads = fetchedResultsController.fetchedObjects ?? []
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
}

extension ProjectDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
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
