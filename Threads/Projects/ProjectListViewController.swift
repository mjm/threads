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
    private var actionRunner: UserActionRunner!
    
    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    private var imagesObserver: Any!

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

        // Ensure we update the project image correctly.
        //
        // Watch all Core Data object changes, and whenever anything changes about a project image, update the cell for the affected project.
        imagesObserver = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { [weak self] note in
            guard let userInfo = note.userInfo else {
                return
            }

            var changedObjects = Set<NSManagedObject>()
            changedObjects.formUnion(userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? [])
            changedObjects.formUnion(userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? [])

            let affectedProjects = Set(changedObjects.compactMap { ($0 as? ProjectImage)?.project })

            for project in affectedProjects {
                if let indexPath = self?.dataSource.indexPath(for: project),
                    let cell = self?.collectionView.cellForItem(at: indexPath) as? ProjectCollectionViewCell {
                    cell.populate(project)
                }
            }
        }

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

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

    deinit {
        if let observer = imagesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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

    @IBAction func unwindDeleteProject(segue: UIStoryboardSegue) {
    }
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: Project) -> ProjectDetailViewController? {
        ProjectDetailViewController(coder: coder, project: sender)
    }

    @IBSegueAction func makeNewProjectController(coder: NSCoder, sender: Project) -> ProjectDetailViewController? {
        ProjectDetailViewController(coder: coder, project: sender, editing: true)
    }
    
    func showDetail(for project: Project) {
        performSegue(withIdentifier: "ProjectDetail", sender: project)
    }
}

// MARK: - Actions
extension ProjectListViewController {
    @IBAction func createProject() {
        actionRunner.perform(CreateProjectAction()) { project in
            self.performSegue(withIdentifier: "NewProject", sender: project)
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
                self.actionRunner.menuAction(AddProjectToShoppingListAction(project: project),
                                             image: UIImage(systemName: "cart.badge.plus")),
                self.actionRunner.menuAction(ShareProjectAction(project: project),
                                             title: Localized.share,
                                             image: UIImage(systemName: "square.and.arrow.up")),
                self.actionRunner.menuAction(DeleteProjectAction(project: project),
                                             title: Localized.delete,
                                             image: UIImage(systemName: "trash"),
                                             attributes: .destructive)
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
