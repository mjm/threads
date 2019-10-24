//
//  ProjectDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/9/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData
import CoreServices
import Combine

class ProjectDetailViewController: CollectionViewController<ProjectDetailViewController.Section, ProjectDetailViewController.Cell> {
    enum Section: CaseIterable {
        case viewImages
        case editImages
        case details
        case notes
        case threads
    }
    
    enum Cell: ReusableCell {
        case viewImage(ProjectImage)
        case viewNotes
        case viewThread(ProjectThread, isLast: Bool)
        
        case editImage(ProjectImage)
        case imagePlaceholder
        case editName
        case editNotes
        case editThread(ProjectThread)
        case add
        
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
    
    let project: Project
    var forceEditMode: Bool

    private var threadsList: FetchedObjectList<ProjectThread>!
    private var imagesList: FetchedObjectList<ProjectImage>!
    
    @IBOutlet var actionsButtonItem: UIBarButtonItem!
    
    init?(coder: NSCoder, project: Project, editing: Bool = false) {
        self.project = project
        self.forceEditMode = editing
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override var managedObjectContext: NSManagedObjectContext {
        project.managedObjectContext!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = project.name
        navigationItem.rightBarButtonItems = [actionsButtonItem]

        if forceEditMode {
            setEditing(true, animated: false)
        }
    }

    override func createObservers() -> [Any] {
        [
            project.publisher(for: \.name).assign(to: \.title, on: navigationItem),
            project.publisher(for: \.notes).map { notes in
                (notes ?? NSAttributedString()).replacing(font: .preferredFont(forTextStyle: .body), color: .label)
            }.sink { [weak self] notes in
                (self?.cell(for: .viewNotes) as? TextViewCollectionViewCell)?.textView.attributedText = notes
            },
        ]
    }

    override var currentUserActivity: UserActivity? { .showProject(project) }

    override func dataSourceWillInitialize() {
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let section = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section] else {
                return nil
            }

            switch (kind, section) {
            case (UICollectionView.elementKindSectionHeader, .threads):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath) as! SectionHeaderLabelView
                view.textLabel.text = self?.threadsSectionHeaderText()
                return view
            case (UICollectionView.elementKindSectionHeader, .details):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath) as! SectionHeaderLabelView
                view.textLabel.text = nil
                return view
            case (UICollectionView.elementKindSectionHeader, .notes):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderLabel", for: indexPath) as! SectionHeaderLabelView
                view.textLabel.text = Localized.notesSectionHeader
                return view
            default:
                return nil
            }
        }

        threadsList = FetchedObjectList(
            fetchRequest: ProjectThread.fetchRequest(for: project),
            managedObjectContext: project.managedObjectContext!,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] projectThread in
                self?.updateThreadCell(projectThread)
            }
        )

        imagesList = FetchedObjectList(
            fetchRequest: ProjectImage.fetchRequest(for: project),
            managedObjectContext: project.managedObjectContext!,
            updateSnapshot: { [weak self] in
                self?.updateSnapshot()
            },
            updateCell: { [weak self] image in
                self?.updateImageCell(image)
            }
        )

        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        if isEditing {
            snapshot.appendSections([.editImages, .details])
            snapshot.appendItems(imagesList.objects.map { .editImage($0) }, toSection: .editImages)
            snapshot.appendItems([.imagePlaceholder], toSection: .editImages)
            snapshot.appendItems([.editName, .editNotes], toSection: .details)
        } else {
            if !imagesList.objects.isEmpty {
                snapshot.appendSections([.viewImages])
                snapshot.appendItems(imagesList.objects.map { .viewImage($0) }, toSection: .viewImages)
            }
            if let notes = project.notes, notes.length > 0 {
                snapshot.appendSections([.notes])
                snapshot.appendItems([.viewNotes], toSection: .notes)
            }
        }

        let threads = threadsList.objects
        snapshot.appendSections([.threads])
        snapshot.appendItems(threads.enumerated().map { (index, item) in
            if isEditing {
                return .editThread(item)
            } else {
                let isLast = threads.index(after: index) == threads.endIndex
                return .viewThread(item, isLast: isLast)
            }
        }, toSection: .threads)

        #if !targetEnvironment(macCatalyst)
        if isEditing {
            snapshot.appendItems([.add], toSection: .threads)
        }
        #endif
    }

    override func dataSourceDidUpdateSnapshot(animated: Bool) {
        // update the threads section header if needed
        if let threadSectionIndex = dataSource.snapshot().indexOfSection(.threads),
            let sectionHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: threadSectionIndex)) as? SectionHeaderLabelView {
            sectionHeader.textLabel.text = threadsSectionHeaderText()
            sectionHeader.setNeedsLayout()
        }
    }

    override var cellTypes: [String : RegisteredCellType<UICollectionViewCell>] {
        [
            "TextInput": .nib(TextInputCollectionViewCell.self),
            "TextView": .nib(TextViewCollectionViewCell.self),

            "Image": .nib(ViewImageCollectionViewCell.self),
            "Thread": .nib(ViewProjectThreadCollectionViewCell.self),

            "EditImage": .nib(EditImageCollectionViewCell.self),
            "EditThread": .nib(EditProjectThreadCollectionViewCell.self),
        ]
    }

    override func populate(cell: UICollectionViewCell, item: ProjectDetailViewController.Cell) {
        let project = self.project

        switch item {

        case let .viewImage(image):
            let cell = cell as! ViewImageCollectionViewCell
            cell.populate(image)

        case .viewNotes:
            let cell = cell as! TextViewCollectionViewCell
            cell.textView.isEditable = false
            cell.textView.dataDetectorTypes = .all
            cell.textView.attributedText = (project.notes ?? NSAttributedString()).replacing(font: .preferredFont(forTextStyle: .body), color: .label)
            cell.onChange = { _ in }

        case let .viewThread(projectThread, isLast: isLast):
            let cell = cell as! ViewProjectThreadCollectionViewCell
            cell.populate(projectThread, isLastItem: isLast)

        case let .editImage(image):
            let cell = cell as! EditImageCollectionViewCell
            cell.populate(image)
            return

        case .imagePlaceholder:
            let cell = cell as! EditImageCollectionViewCell
            cell.showPlaceholder()
            return

        case .editName:
            let cell = cell as! TextInputCollectionViewCell
            cell.textField.placeholder = Localized.projectName
            cell.textField.text = project.name
            cell.onChange = { newText in
                project.name = newText
            }
            cell.onReturn = { [unowned cell] in
                cell.textField.resignFirstResponder()
            }

        case .editNotes:
            let cell = cell as! TextViewCollectionViewCell
            cell.textView.isEditable = true
            cell.textView.dataDetectorTypes = []
            cell.textView.attributedText = (project.notes ?? NSAttributedString()).replacing(font: .preferredFont(forTextStyle: .body), color: .label)
            cell.onChange = { [weak self] newText in
                project.notes = newText
                self?.updateSnapshot()
            }

        case let .editThread(projectThread):
            let cell = cell as! EditProjectThreadCollectionViewCell
            cell.populate(projectThread)
            cell.onDecreaseQuantity = {
                if projectThread.amount == 1 {
                    projectThread.managedObjectContext?.delete(projectThread)
                } else {
                    projectThread.amount -= 1
                }
            }
            cell.onIncreaseQuantity = {
                projectThread.amount += 1
            }

        case .add:
            return
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if forceEditMode {
            // focus the project name text field
            if let indexPath = dataSource.indexPath(for: .editName),
                let cell = collectionView.cellForItem(at: indexPath) as? TextInputCollectionViewCell {
                cell.textField.becomeFirstResponder()
            }

            // don't do this again if the view disappears and reappears
            forceEditMode = false
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateSnapshot(animated: animated)

        navigationItem.largeTitleDisplayMode = editing ? .never : .automatic
        navigationItem.setRightBarButtonItems(
            editing ? [editButtonItem] : [actionsButtonItem],
            animated: animated)
        if let rootViewController = splitViewController as? SplitViewController {
            rootViewController.updateToolbar()
        }

        if editing {
            project.managedObjectContext!.commit()
            undoManager?.beginUndoGrouping()
            undoManager?.setActionName(Localized.changeProject)
        } else {
            undoManager?.endUndoGrouping()
            project.managedObjectContext!.commit()
        }
    }

    func updateThreadCell(_ thread: ProjectThread) {
        if let cell = self.cell(for: .viewThread(thread, isLast: false)) as? ViewProjectThreadCollectionViewCell {
            cell.populate(thread)
        } else if let cell = self.cell(for: .viewThread(thread, isLast: true)) as? ViewProjectThreadCollectionViewCell {
            cell.populate(thread, isLastItem: true)
        } else if let cell = self.cell(for: .editThread(thread)) as? EditProjectThreadCollectionViewCell {
            cell.populate(thread)
        }
    }

    func updateImageCell(_ image: ProjectImage) {
        // no-op. there's not currently a meaningful way to update a project image in-place
    }
    
    override func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            let sectionType = self!.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            
            switch sectionType {
            case .viewImages:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let traitCollection = layoutEnvironment.traitCollection
                let showMultipleImages = traitCollection.verticalSizeClass == .compact || traitCollection.horizontalSizeClass == .regular
                let dimension: NSCollectionLayoutDimension = showMultipleImages ? .absolute(200) : .fractionalWidth(0.8)
                let groupSize = NSCollectionLayoutSize(widthDimension: dimension,
                                                       heightDimension: dimension)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = showMultipleImages ? .groupPaging : .groupPagingCentered
                let horizontalInset: CGFloat = showMultipleImages ? 15 : 0
                section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: horizontalInset, bottom: 15, trailing: horizontalInset)
                section.interGroupSpacing = 20
                return section
                
            case .editImages:
                #if targetEnvironment(macCatalyst)
                let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(200),
                                                      heightDimension: .absolute(200))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize =  NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                        heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                #else
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalWidth(0.33))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
                #endif
                group.interItemSpacing = .fixed(1)

                let section = NSCollectionLayoutSection(group: group)
                return section
                
            case .notes:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(88))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(88))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                return section

            case .details:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                              heightDimension: .absolute(34))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                return section

            case .threads:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(44))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .estimated(44))
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerFooterSize,
                    elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [sectionHeader]
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 44, trailing: 0)
                return section
            }
        }
    }
    
    private func threadsSectionHeaderText() -> String {
        let items = threadsList.objects.count
        return String.localizedStringWithFormat(Localized.threadsSectionHeader, items)
    }

    private func cell(for item: Cell) -> UICollectionViewCell? {
        if let indexPath = dataSource.indexPath(for: item) {
            return collectionView.cellForItem(at: indexPath)
        }

        return nil
    }
}

// MARK: - Actions
extension ProjectDetailViewController {
    @IBAction func showActions() {
        let sheet = UIAlertController(actionRunner: actionRunner, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.barButtonItem = actionsButtonItem

        sheet.addAction(UIAlertAction(title: Localized.edit, style: .default) { _ in
            self.setEditing(true, animated: true)
        })
        sheet.addAction(ShareProjectAction(project: project), title: Localized.share)
        sheet.addAction(AddProjectToShoppingListAction(project: project))

        sheet.addAction(
            DeleteProjectAction(project: project),
            title: Localized.delete,
            style: .destructive,
            willPerform: { self.userActivity = nil }
        ) {
            self.performSegue(withIdentifier: "DeleteProject", sender: nil)
        }

        sheet.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))

        present(sheet, animated: true)
    }
    
    @objc func shareProject(_ sender: Any) {
        actionRunner.perform(ShareProjectAction(project: project))
    }
    
    @objc func addProjectToShoppingList(_ sender: Any) {
        actionRunner.perform(AddProjectToShoppingListAction(project: project))
    }

    @objc func addThreads(_ sender: Any) {
        actionRunner.perform(AddThreadAction(mode: .project(project)))
    }
}

// MARK: - Collection View Delegate
extension ProjectDetailViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = dataSource.itemIdentifier(for: indexPath)
        return item == .add || item == .imagePlaceholder
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        switch item {

        case .add:
            addThreads(item)
            collectionView.deselectItem(at: indexPath, animated: true)

        case .imagePlaceholder:
            actionRunner.perform(AddImageToProjectAction(project: project))
            collectionView.deselectItem(at: indexPath, animated: true)

        default:
            assertionFailure("Got didSelectItemAt: with an unexpected item: \(item)")
        }
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard case let .editImage(image) = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            UIMenu(title: "", children: [
                self.actionRunner.menuAction(DeleteProjectImageAction(image: image),
                                             title: Localized.delete,
                                             image: UIImage(systemName: "trash"),
                                             attributes: .destructive)
            ])
        }
    }
}

// MARK: - Collection View Drag Delegate
extension ProjectDetailViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard case let .editImage(image) = dataSource.itemIdentifier(for: indexPath),
            let data = image.data else {
            return []
        }

        let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeImage as String)
        let item = UIDragItem(itemProvider: itemProvider)
        item.localObject = image
        return [item]
    }

    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        self.collectionView(collectionView, itemsForBeginning: session, at: indexPath)
    }
}

// MARK: - Collection View Drop Delegate
extension ProjectDetailViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let indexPath = destinationIndexPath else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        guard section == .editImages else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        let imageCount = imagesList.objects.count
        if indexPath.item >= imageCount {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let indexPath = coordinator.destinationIndexPath else {
            // we don't currently support drops with no index path
            return
        }

        if coordinator.proposal.operation == .move {
            // This should only ever be a single item in this case
            assert(coordinator.items.count == 1)

            let item = coordinator.items[0]
            if let sourceIndex = item.sourceIndexPath?.item {
                let action = MoveProjectImageAction(project: project,
                                                    sourceIndex: sourceIndex,
                                                    destinationIndex: indexPath.item)
                actionRunner.perform(action) {
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

class AddThreadsToProjectDelegate: NSObject, AddThreadViewControllerDelegate {
    let project: Project
    
    init(project: Project) {
        self.project = project
    }
    
    func choicesForAddingThreads(_ addThreadViewController: AddThreadViewController) throws -> [Thread] {
        let projectThreads = try project.managedObjectContext!.fetch(ProjectThread.fetchRequest(for: project))
        let existingThreads = projectThreads.compactMap { $0.thread }
        
        // Not ideal, but I haven't figured out a way in Core Data to get all the threads that
        // aren't in a particular project. Many-to-many relationships are hard.
        let allThreads = try project.managedObjectContext!.fetch(Thread.sortedByNumberFetchRequest())
        
        return allThreads.filter { !existingThreads.contains($0) }
    }
    
    func addThreadViewController(_ addThreadViewController: AddThreadViewController, performActionForAddingThreads threads: [Thread], actionRunner: UserActionRunner) {
        actionRunner.perform(AddToProjectAction(threads: threads, project: project))
    }
}
