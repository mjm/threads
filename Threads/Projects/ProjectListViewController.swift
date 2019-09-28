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

    private var projectsList: FetchedObjectList<Project>!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Project>!
    private var actionRunner: UserActionRunner!
    
    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    private var imagesObserver: Any!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ensure we update the project image correctly.
        //
        // Watch all Core Data object changes, and whenever anything changes about a project image, update the cell for the affected project.
        imagesObserver = managedObjectContext.observeChanges(type: ProjectImage.self) { [weak self] affectedImages in
            guard let self = self else {
                return
            }

            let affectedProjects = Set(affectedImages.compactMap { $0.project })

            for project in affectedProjects {
                self.updateCell(project)
            }
        }

        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)

        ProjectCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "Project")
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Project", for: indexPath) as! ProjectCollectionViewCell
            cell.populate(item)
            return cell
        }
        
        collectionView.collectionViewLayout = createLayout()

        projectsList = FetchedObjectList(
            fetchRequest: Project.allProjectsFetchRequest(),
            managedObjectContext: managedObjectContext,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] project in
                self?.updateCell(project)
            }
        )

        updateSnapshot(animated: false)
        
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, Project>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(projectsList.objects, toSection: .projects)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    func updateCell(_ project: Project) {
        cellForProject(project)?.populate(project)
    }

    private func cellForProject(_ project: Project) -> ProjectCollectionViewCell? {
        dataSource.indexPath(for: project).flatMap { collectionView.cellForItem(at: $0) as? ProjectCollectionViewCell }
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
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: ProjectDetail) -> ProjectDetailViewController? {
        ProjectDetailViewController(coder: coder, project: sender.project, editing: sender.isEditing)
    }
    
    func showDetail(for project: Project, editing: Bool = false) {
        performSegue(withIdentifier: "ProjectDetail",
                     sender: ProjectDetail(project: project, isEditing: editing))
    }
}

@objc class ProjectDetail: NSObject {
    let project: Project
    let isEditing: Bool

    init(project: Project, isEditing: Bool = false) {
        self.project = project
        self.isEditing = isEditing
    }
}

// MARK: - Actions
extension ProjectListViewController {
    @IBAction func createProject() {
        actionRunner.perform(CreateProjectAction()) { project in
            self.showDetail(for: project, editing: true)
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
        
        return UIContextMenuConfiguration(identifier: project.objectID, previewProvider: {
            self.storyboard!.instantiateViewController(identifier: "ProjectPreview") { coder in
                ProjectPreviewViewController(coder: coder, project: project)
            }
        }) { suggestedActions in
            UIMenu(title: "", children: [
                UIAction(title: Localized.edit, image: UIImage(systemName: "pencil")) { _ in
                    self.showDetail(for: project, editing: true)
                },
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
        let project = managedObjectContext.object(with: configuration.identifier as! NSManagedObjectID) as! Project
        animator.addAnimations {
            self.showDetail(for: project)
        }

    }
}
