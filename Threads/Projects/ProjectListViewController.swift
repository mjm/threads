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
//        managedObjectContext.commit()

        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Project.allProjectsFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self

        ProjectCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "Project")
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Project", for: indexPath) as! ProjectCollectionViewCell
            cell.populate(item)
            return cell
        }
        
        collectionView.collectionViewLayout = createLayout()
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot(animated: false)
        } catch {
            NSLog("Could not load projects: \(error)")
        }
        
        userActivity = UserActivity.showProjects.userActivity
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

    func updateSnapshot(animated: Bool = true) {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Project>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(objects, toSection: .projects)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let containerSize = layoutEnvironment.container.effectiveContentSize
            let insets = layoutEnvironment.container.effectiveContentInsets

            let minimumColumnWidth: CGFloat = 160.0
            let spacing: CGFloat = 15
            let sectionInsets = NSDirectionalEdgeInsets(top: spacing,
                                                        leading: spacing,
                                                        bottom: spacing,
                                                        trailing: spacing)
            
            // how much space do we have to play with?
            let fixedHorizontalSpacing = insets.leading + insets.trailing + sectionInsets.leading + sectionInsets.trailing
            let widthForItems = containerSize.width - fixedHorizontalSpacing
            
            // how many items can we fit in that space with a reasonable width?
            let numberOfItems = floor(widthForItems / minimumColumnWidth)
            
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(minimumColumnWidth))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(200))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: Int(numberOfItems))
            group.interItemSpacing = .fixed(spacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = sectionInsets
            return section
        }
    }
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: Project) -> ProjectDetailViewController? {
        return ProjectDetailViewController(coder: coder, project: sender)
    }
    
    func showDetail(for project: Project) {
        performSegue(withIdentifier: "ProjectDetail", sender: project)
    }
}

// MARK: - Actions
extension ProjectListViewController {
    func addToShoppingList(_ project: Project) {
        project.act(Localized.addToShoppingList) {
            project.addToShoppingList()
        }
    }
}

// MARK: - Collection View Delegate
extension ProjectListViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let project = dataSource.itemIdentifier(for: indexPath)!
        showDetail(for: project)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let project = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
            self.storyboard!.instantiateViewController(identifier: "ProjectDetail") { coder in
                self.makeDetailController(coder: coder, sender: project)
            }
        }) { suggestedActions in
            UIMenu(title: "", children: [
                UIAction(title: Localized.addToShoppingList, image: UIImage(systemName: "cart.badge.plus")) { _ in
                    self.addToShoppingList(project)
                },
                UIAction(title: Localized.share, image: UIImage(systemName: "square.and.arrow.up")) { _ in
                    NSLog("share!")
                },
                UIAction(title: Localized.delete, image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    NSLog("delete!")
                }
            ])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        let vc = animator.previewViewController!
        animator.addAnimations {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension ProjectListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let project = anObject as! Project
            if let indexPath = dataSource.indexPath(for: project),
                let cell = collectionView.cellForItem(at: indexPath) as? ProjectCollectionViewCell {
                cell.populate(project)
            }
        default:
            return
        }
    }
}