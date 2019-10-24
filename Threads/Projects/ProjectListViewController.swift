//
//  ProjectListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ProjectListViewController: CollectionViewController<ProjectListViewController.Section, ProjectListViewController.Cell> {
    enum Section: CaseIterable {
        case projects
    }

    enum Cell: ReusableCell {
        case project(Project)

        var cellIdentifier: String { "Project" }
    }

    private var projectsList: FetchedObjectList<Project>!

    override func createObservers() -> [Any] {
        [
            managedObjectContext.publisher(type: ProjectImage.self).compactMap { image in
                image.project
            }.sink { [weak self] project in
                self?.updateCell(project)
            },
            projectsList.contentChangePublisher().sink { [weak self] in
                self?.updateSnapshot()
            },
            projectsList.objectPublisher().sink { [weak self] project in
                self?.updateCell(project)
            },
        ]
    }

    override var currentUserActivity: UserActivity? { .showProjects }

    override func dataSourceWillInitialize() {
        projectsList = FetchedObjectList(
            fetchRequest: Project.allProjectsFetchRequest(),
            managedObjectContext: managedObjectContext
        )
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(projectsList.objects.map { .project($0) }, toSection: .projects)
    }

    override func dataSourceDidUpdateSnapshot(animated: Bool) {
        if projectsList.objects.isEmpty {
            let emptyView = EmptyView()
            emptyView.textLabel.text = Localized.emptyProjects
            emptyView.iconView.image = UIImage(systemName: "rectangle.3.offgrid.fill")
            collectionView.backgroundView = emptyView

            NSLayoutConstraint.activate([
                emptyView.leadingAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.leadingAnchor),
                emptyView.trailingAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.trailingAnchor),
                emptyView.topAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.topAnchor),
                emptyView.bottomAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.bottomAnchor),
            ])
        } else {
            collectionView.backgroundView = nil
        }
    }

    override var cellTypes: [String : RegisteredCellType<UICollectionViewCell>] {
        ["Project": .nib(ProjectCollectionViewCell.self)]
    }

    override func populate(cell: UICollectionViewCell, item: ProjectListViewController.Cell) {
        switch item {
        case let .project(project):
            let cell = cell as! ProjectCollectionViewCell
            cell.populate(project)
        }
    }
    
    override func createLayout() -> UICollectionViewLayout {
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

    func updateCell(_ project: Project) {
        cellForProject(project)?.populate(project)
    }

    private func cellForProject(_ project: Project) -> ProjectCollectionViewCell? {
        dataSource.indexPath(for: .project(project)).flatMap { collectionView.cellForItem(at: $0) as? ProjectCollectionViewCell }
    }

    @IBAction func unwindDeleteProject(segue: UIStoryboardSegue) {
    }
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: ProjectDetail) -> UIViewController? {
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
        if case let .project(project) = dataSource.itemIdentifier(for: indexPath) {
            showDetail(for: project)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard case let .project(project) = dataSource.itemIdentifier(for: indexPath) else {
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
