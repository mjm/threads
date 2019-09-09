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
    
    static let minimumColumnWidth: CGFloat = 160.0
    
    private func sizeForProjectCell() -> CGSize {
        // how much space do we have to play with?
        let fixedHorizontalSpacing = collectionView.contentInset.left + collectionView.contentInset.right + flowLayout.sectionInset.left + flowLayout.sectionInset.right
        let widthForItems = collectionView.bounds.size.width - fixedHorizontalSpacing
        
        // how many items can we fit in that space with a reasonable width?
        let numberOfItems = floor(widthForItems / ProjectListViewController.minimumColumnWidth)
        
        let totalPadding = flowLayout.minimumInteritemSpacing * (numberOfItems - 1.0)
        let targetWidth = (widthForItems - totalPadding) / numberOfItems
        
        let prototypeCell = ProjectCollectionViewCell.makePrototype()
        prototypeCell.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
        return prototypeCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

extension ProjectListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
}

// This was inspired by
//   https://github.com/mischa-hildebrand/AlignedCollectionViewFlowLayout/blob/master/AlignedCollectionViewFlowLayout/Classes/AlignedCollectionViewFlowLayout.swift
// but was heavily adapted/reduced to just what was needed here.
class ProjectListCollectionViewLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        
        guard attributes.indexPath.item > 0 else {
            // if it's the first item, we shouldn't need to move it
            return attributes
        }
        
        let previousIndexPath = IndexPath(item: attributes.indexPath.item - 1, section: attributes.indexPath.section)
        guard let previousItemAttributes = layoutAttributesForItem(at: previousIndexPath) else {
            return attributes
        }
        
        guard previousItemAttributes.frame.origin.y == attributes.frame.origin.y else {
            return attributes
        }
        
        attributes.frame.origin.x = previousItemAttributes.frame.maxX + minimumInteritemSpacing
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let allAttributes = super.layoutAttributesForElements(in: rect)
        return allAttributes?.compactMap { attrs in
            guard attrs.representedElementCategory == .cell else {
                return attrs
            }
            
            guard let attributes = layoutAttributesForItem(at: attrs.indexPath) else {
                return attrs
            }
            
            let newAttributes = attrs.copy() as! UICollectionViewLayoutAttributes
            newAttributes.frame = attributes.frame
            return newAttributes
        }
    }
}
