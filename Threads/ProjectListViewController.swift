//
//  ProjectListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ProjectListViewController: UICollectionViewController {
    enum Section: CaseIterable {
        case projects
    }

    private var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }

    private var fetchedResultsController: NSFetchedResultsController<Project>!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Project>!
    
    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var project = Project(context: managedObjectContext)
//        project.name = "Susie – Undertale"
//
//        project = Project(context: managedObjectContext)
//        project.name = "Good Vibes"
//
//        project = Project(context: managedObjectContext)
//        project.name = "Stardew Chicken"
//
//        AppDelegate.save()

        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Project.allProjectsFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self

        collectionView.register(ProjectCollectionViewCell.nib, forCellWithReuseIdentifier: "Project")
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Project", for: indexPath) as! ProjectCollectionViewCell
            cell.nameLabel.text = item.name
            cell.colorView.backgroundColor = .systemOrange
            return cell
        }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot()
        } catch {
            NSLog("Could not load projects: \(error)")
        }
    }

    func updateSnapshot() {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Project>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(objects, toSection: .projects)
        dataSource.apply(snapshot)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        flowLayout.itemSize = sizeForProjectCell()
    }
    
    private func sizeForProjectCell() -> CGSize {
        let prototypeCell = ProjectCollectionViewCell.makePrototype()
        let horizontalSpacing = collectionView.contentInset.left + collectionView.contentInset.right + flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing
        let targetWidth = (collectionView.bounds.size.width - horizontalSpacing) / 2
        prototypeCell.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
        return prototypeCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

extension ProjectListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
}
