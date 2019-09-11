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
        
        collectionView.collectionViewLayout = createLayout()
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot()
        } catch {
            NSLog("Could not load projects: \(error)")
        }
        
        let activity = NSUserActivity(activityType: "com.mattmoriarity.Threads.ShowProjects")
        activity.title = "My Projects"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        userActivity = activity
    }

    func updateSnapshot() {
        let objects = fetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Project>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(objects, toSection: .projects)
        dataSource.apply(snapshot)
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
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: IndexPath) -> ProjectDetailViewController? {
        let project = dataSource.itemIdentifier(for: sender)!
        return ProjectDetailViewController(coder: coder, project: project)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ProjectDetail", sender: indexPath)
    }
}

extension ProjectListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
}
