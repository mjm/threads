//
//  ProjectListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/7/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

extension ProjectListViewModel.Item: ReusableCell {
    var cellIdentifier: String { "Project" }
}

class ProjectListViewController: ReactiveCollectionViewController<ProjectListViewModel> {
    let viewModel: ProjectListViewModel

    required init?(coder: NSCoder) {
        viewModel = ProjectListViewModel()
        super.init(coder: coder)
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.snapshot.apply(to: dataSource, animate: $animate).store(in: &cancellables)

        viewModel.isEmpty.sink { [weak self] empty in
            self?.setShowEmptyView(empty)
        }.store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }.assign(to: \.userActivity, on: self).store(
            in: &cancellables)
    }

    private func setShowEmptyView(_ showEmptyView: Bool) {
        if showEmptyView {
            let emptyView = EmptyView()
            emptyView.textLabel.text = Localized.emptyProjects
            emptyView.iconView.image = UIImage(systemName: "rectangle.3.offgrid.fill")
            collectionView.backgroundView = emptyView

            NSLayoutConstraint.activate([
                emptyView.leadingAnchor.constraint(
                    equalTo: collectionView.safeAreaLayoutGuide.leadingAnchor),
                emptyView.trailingAnchor.constraint(
                    equalTo: collectionView.safeAreaLayoutGuide.trailingAnchor),
                emptyView.topAnchor.constraint(
                    equalTo: collectionView.safeAreaLayoutGuide.topAnchor),
                emptyView.bottomAnchor.constraint(
                    equalTo: collectionView.safeAreaLayoutGuide.bottomAnchor),
            ])
        } else {
            collectionView.backgroundView = nil
        }
    }

    override var cellTypes: [String: RegisteredCellType<UICollectionViewCell>] {
        ["Project": .nib(ProjectCollectionViewCell.self)]
    }

    override func populate(cell: UICollectionViewCell, item: ProjectListViewModel.Item) {
        let cell = cell as! ProjectCollectionViewCell
        cell.bind(item)
    }

    override func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let containerSize = layoutEnvironment.container.effectiveContentSize
            let insets = layoutEnvironment.container.effectiveContentInsets

            let minimumColumnWidth: CGFloat = 160.0
            let spacing: CGFloat = 15
            let sectionInsets = NSDirectionalEdgeInsets(
                top: spacing,
                leading: spacing,
                bottom: spacing,
                trailing: spacing)

            // how much space do we have to play with?
            let fixedHorizontalSpacing = insets.leading + insets.trailing + sectionInsets.leading
                + sectionInsets.trailing
            let widthForItems = containerSize.width - fixedHorizontalSpacing

            // how many items can we fit in that space with a reasonable width?
            let numberOfItems = floor(widthForItems / minimumColumnWidth)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(minimumColumnWidth))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize, subitem: item, count: Int(numberOfItems))
            group.interItemSpacing = .fixed(spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = sectionInsets
            return section
        }
    }

    @IBAction func unwindDeleteProject(segue: UIStoryboardSegue) {
    }

    @IBSegueAction func makeDetailController(coder: NSCoder, sender: ProjectDetail)
        -> UIViewController?
    {
        ProjectDetailViewController(
            coder: coder, project: sender.project, editing: sender.isEditing)
    }

    func showDetail(for project: Project, editing: Bool = false) {
        performSegue(
            withIdentifier: "ProjectDetail",
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
        viewModel.createProject().handle { project in
            self.showDetail(for: project, editing: true)
        }
    }
}

// MARK: - Collection View Delegate
extension ProjectListViewController {
    override func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        if let project = dataSource.itemIdentifier(for: indexPath)?.project {
            showDetail(for: project)
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        let project = item.project

        return UIContextMenuConfiguration(
            identifier: viewModel.identifier(for: item),
            previewProvider: {
                self.storyboard!.instantiateViewController(identifier: "ProjectPreview") { coder in
                    ProjectPreviewViewController(coder: coder, project: project)
                }
            }
        ) { suggestedActions in
            UIMenu(
                title: "",
                children: [
                    UIAction(title: Localized.edit, image: UIImage(systemName: "pencil")) { _ in
                        self.showDetail(for: project, editing: true)
                    },
                    item.addToShoppingListAction.menuAction(
                        image: UIImage(systemName: "cart.badge.plus")),
                    item.shareAction.menuAction(image: UIImage(systemName: "square.and.arrow.up")),
                    item.deleteAction.menuAction(image: UIImage(systemName: "trash")),
                ])
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let project = viewModel.project(for: configuration.identifier) else {
            return
        }

        animator.addAnimations {
            self.showDetail(for: project)
        }
    }
}
