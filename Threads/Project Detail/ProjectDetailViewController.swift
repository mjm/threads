//
//  ProjectDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/9/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import CoreServices
import UIKit

extension ProjectDetailViewModel.Item: ReusableCell {
    var cellIdentifier: String {
        switch self {
        case .viewImage: return "Image"
        case .viewNotes: return "TextView"
        case .viewThread: return "Thread"
        case .editImage, .imagePlaceholder: return "EditImage"
        case .editName: return "TextInput"
        case .editNotes: return "TextView"
        case .editThread: return "EditThread"
        case .add: return "Add"
        }
    }
}

class ProjectDetailViewController: ReactiveCollectionViewController<
    ProjectDetailViewModel.Section, ProjectDetailViewModel.Item
>
{
    let viewModel: ProjectDetailViewModel

    private var editNameOnAppear: Bool

    @IBOutlet var actionsButtonItem: UIBarButtonItem!

    init?(coder: NSCoder, project: Project, editing: Bool = false) {
        viewModel = ProjectDetailViewModel(project: project, editing: editing)
        editNameOnAppear = editing
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override var managedObjectContext: NSManagedObjectContext {
        viewModel.context
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems = [actionsButtonItem]
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.snapshot.combineLatest($animate).receive(on: RunLoop.main).apply(to: dataSource)
            .store(in: &cancellables)
        viewModel.name.assign(to: \.title, on: navigationItem).store(
            in: &cancellables)

        // Editing changes
        let isEditing = viewModel.$isEditing.removeDuplicates()

        isEditing.combineLatest($animate).sink { [weak self] editing, animated in
            self?.setEditing(editing, animated: animated)
        }.store(in: &cancellables)

        isEditing.map { editing in
            editing ? .never : .automatic
        }.assign(to: \.largeTitleDisplayMode, on: navigationItem).store(in: &cancellables)

        let barButtonItems = isEditing.map { [weak self] editing -> [UIBarButtonItem] in
            guard let self = self else { return [] }
            return editing ? [self.editButtonItem] : [self.actionsButtonItem]
        }
        barButtonItems.combineLatest($animate).sink { [weak self] items, animate in
            self?.navigationItem.setRightBarButtonItems(items, animated: animate)
        }.store(in: &cancellables)

        isEditing.sink { [weak self] _ in
            if let rootViewController = self?.splitViewController as? SplitViewController {
                rootViewController.updateToolbar()
            }
        }.store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }.assign(to: \.userActivity, on: self).store(
            in: &cancellables)
    }

    override func dataSourceWillInitialize() {
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            else {
                return nil
            }

            switch (kind, section) {
            case (UICollectionView.elementKindSectionHeader, .threads):
                let view
                    = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath)
                    as! SectionHeaderLabelView
                self?.viewModel.threadCount.map { count in
                    String.localizedStringWithFormat(Localized.threadsSectionHeader, count)
                }.sink { [weak view] text in
                    view?.textLabel.text = text
                    view?.setNeedsLayout()
                }.store(in: &view.cancellables)
                return view
            case (UICollectionView.elementKindSectionHeader, .details):
                let view
                    = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath)
                    as! SectionHeaderLabelView
                view.textLabel.text = nil
                return view
            case (UICollectionView.elementKindSectionHeader, .notes):
                let view
                    = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath)
                    as! SectionHeaderLabelView
                view.textLabel.text = Localized.notesSectionHeader
                return view
            default:
                return nil
            }
        }

        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    override var cellTypes: [String: RegisteredCellType<UICollectionViewCell>] {
        [
            "TextInput": .nib(TextInputCollectionViewCell.self),
            "TextView": .nib(TextViewCollectionViewCell.self),

            "Image": .nib(ViewImageCollectionViewCell.self),
            "Thread": .nib(ViewProjectThreadCollectionViewCell.self),

            "EditImage": .nib(EditImageCollectionViewCell.self),
            "EditThread": .nib(EditProjectThreadCollectionViewCell.self),
        ]
    }

    override func populate(cell: UICollectionViewCell, item: ProjectDetailViewModel.Item) {
        switch item {

        case let .viewImage(model):
            let cell = cell as! ViewImageCollectionViewCell
            cell.bind(model)

        case .viewNotes:
            let cell = cell as! TextViewCollectionViewCell
            cell.textView.isEditable = false
            cell.textView.dataDetectorTypes = .all
            cell.bind(to: \.formattedNotes, on: viewModel.project)

        case let .viewThread(model):
            let cell = cell as! ViewProjectThreadCollectionViewCell
            cell.bind(model)

        case let .editImage(model):
            let cell = cell as! EditImageCollectionViewCell
            cell.bind(model)

        case .imagePlaceholder:
            let cell = cell as! EditImageCollectionViewCell
            cell.showPlaceholder()

        case .editName:
            let cell = cell as! TextInputCollectionViewCell
            cell.textField.placeholder = Localized.projectName
            cell.bind(to: \.name, on: viewModel.project)
            cell.actionPublisher().sink { [weak cell] action in
                switch action {
                case .return:
                    cell?.textField.resignFirstResponder()
                }
            }.store(in: &cell.cancellables)

        case .editNotes:
            let cell = cell as! TextViewCollectionViewCell
            cell.textView.isEditable = true
            cell.textView.dataDetectorTypes = []
            cell.bind(to: \.formattedNotes, on: viewModel.project)

        case let .editThread(model):
            let cell = cell as! EditProjectThreadCollectionViewCell
            cell.bind(model)

        case .add:
            return
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if editNameOnAppear {
            if let indexPath = dataSource.indexPath(for: .editName),
                let cell = collectionView.cellForItem(at: indexPath) as? TextInputCollectionViewCell
            {
                cell.textField.becomeFirstResponder()
            }

            // don't do this again if the view disappears and reappears
            editNameOnAppear = false
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        viewModel.isEditing = editing
    }

    override func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            let sectionType = self!.dataSource.snapshot().sectionIdentifiers[sectionIndex]

            switch sectionType {
            case .viewImages:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let traitCollection = layoutEnvironment.traitCollection
                let showMultipleImages = traitCollection.verticalSizeClass == .compact
                    || traitCollection.horizontalSizeClass == .regular
                let dimension: NSCollectionLayoutDimension = showMultipleImages
                    ? .absolute(200) : .fractionalWidth(0.8)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: dimension,
                    heightDimension: dimension)
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = showMultipleImages
                    ? .groupPaging : .groupPagingCentered
                let horizontalInset: CGFloat = showMultipleImages ? 15 : 0
                section.contentInsets
                    = NSDirectionalEdgeInsets(
                        top: 15, leading: horizontalInset, bottom: 15, trailing: horizontalInset)
                section.interGroupSpacing = 20
                return section

            case .editImages:
                #if targetEnvironment(macCatalyst)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(200),
                    heightDimension: .absolute(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item])
                #else
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(0.33))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitem: item, count: 3)
                #endif
                group.interItemSpacing = .fixed(1)

                let section = NSCollectionLayoutSection(group: group)
                return section

            case .notes:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(88))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(88))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets
                    = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                return section

            case .details:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(34))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets
                    = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                return section

            case .threads:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets
                    = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 44, trailing: 0)
                return section
            }
        }
    }
}

// MARK: - Actions
extension ProjectDetailViewController {
    @IBAction func showActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.barButtonItem = actionsButtonItem

        for action in viewModel.sheetActions {
            sheet.addAction(action.alertAction())
        }

        sheet.addAction(
            viewModel.deleteAction.alertAction(
                willPerform: {
                    self.userActivity = nil
                },
                completion: {
                    self.performSegue(withIdentifier: "DeleteProject", sender: nil)
                }))

        sheet.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))

        present(sheet, animated: true)
    }

    @objc func shareProject(_ sender: Any) {
        viewModel.shareAction.perform()
    }

    @objc func addProjectToShoppingList(_ sender: Any) {
        viewModel.addToShoppingListAction.perform()
    }

    @objc func addThreads(_ sender: Any) {
        viewModel.addThreads()
    }
}

// MARK: - Collection View Delegate
extension ProjectDetailViewController {
    override func collectionView(
        _ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        let item = dataSource.itemIdentifier(for: indexPath)
        return item == .add || item == .imagePlaceholder
    }

    override func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        switch item {

        case .add:
            viewModel.addThreads()
            collectionView.deselectItem(at: indexPath, animated: true)

        case .imagePlaceholder:
            viewModel.addImage()
            collectionView.deselectItem(at: indexPath, animated: true)

        default:
            assertionFailure("Got didSelectItemAt: with an unexpected item: \(item)")
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard case let .editImage(model) = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {
            suggestedActions in
            UIMenu(
                title: "",
                children: [
                    model.deleteAction.menuAction(image: UIImage(systemName: "trash")),
                ])
        }
    }
}

// MARK: - Collection View Drag Delegate
extension ProjectDetailViewController: UICollectionViewDragDelegate {
    func collectionView(
        _ collectionView: UICollectionView, itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard case let .editImage(model) = dataSource.itemIdentifier(for: indexPath),
            let data = model.imageData
        else {
            return []
        }

        let itemProvider = NSItemProvider(
            item: data as NSData, typeIdentifier: kUTTypeImage as String)
        let item = UIDragItem(itemProvider: itemProvider)
        item.localObject = model.projectImage
        return [item]
    }

    func collectionView(
        _ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession,
        at indexPath: IndexPath, point: CGPoint
    ) -> [UIDragItem] {
        self.collectionView(collectionView, itemsForBeginning: session, at: indexPath)
    }
}

// MARK: - Collection View Drop Delegate
extension ProjectDetailViewController: UICollectionViewDropDelegate {
    func collectionView(
        _ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        guard let indexPath = destinationIndexPath else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        let snapshot = dataSource.snapshot()

        let section = snapshot.sectionIdentifiers[indexPath.section]
        guard section == .editImages else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        let imageCount = snapshot.numberOfItems(inSection: .editImages) - 1
        if indexPath.item >= imageCount {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(
                operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(
                operation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        guard let indexPath = coordinator.destinationIndexPath else {
            // we don't currently support drops with no index path
            return
        }

        if coordinator.proposal.operation == .move {
            // This should only ever be a single item in this case
            assert(coordinator.items.count == 1)

            let item = coordinator.items[0]
            if let sourceIndex = item.sourceIndexPath?.item {
                viewModel.moveImage(from: sourceIndex, to: indexPath.item) {
                    coordinator.drop(item.dragItem, toItemAt: indexPath)
                }
            }
        } else if coordinator.proposal.operation == .copy {
            assertionFailure("Copying items from another app has not been implemented yet!")
        }
    }
}

class SectionHeaderLabelView: UICollectionReusableView {
    @IBOutlet var textLabel: UILabel!

    var cancellables = Set<AnyCancellable>()
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
        contentView.backgroundColor = (isSelected || isHighlighted)
            ? .opaqueSeparator : .systemBackground
    }
}
