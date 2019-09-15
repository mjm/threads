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

class ProjectDetailViewController: UICollectionViewController {
    enum Section: CaseIterable {
        case viewImages
        case editImages
        case details
        case notes
        case threads
    }
    
    enum Cell: Hashable {
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
        
        func populate(cell: UICollectionViewCell, project: Project, controller: ProjectDetailViewController) {
            switch self {
                
            case .viewImage:
                return
                
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
                cell.onChange = { [weak controller] newText in
                    project.notes = newText
                    controller?.updateSnapshot()
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
    }
    
    let project: Project

    private var threadsFetchedResultsController: NSFetchedResultsController<ProjectThread>!
    private var imagesFetchedResultsController: NSFetchedResultsController<ProjectImage>!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Cell>!
    
    @IBOutlet var shareButtonItem: UIBarButtonItem!
    @IBOutlet var addToShoppingListButtonItem: UIBarButtonItem!
    
    private var projectNameObserver: NSKeyValueObservation?
    private var projectNotesObserver: NSKeyValueObservation?
    
    init?(coder: NSCoder, project: Project) {
        self.project = project
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addToShoppingListButtonItem.width = 30
        
        navigationItem.title = project.name
        navigationItem.rightBarButtonItems = [editButtonItem, shareButtonItem, addToShoppingListButtonItem]
        
        projectNameObserver = project.observe(\.name) { [weak self] project, change in
            self?.navigationItem.title = project.name
        }
        
        projectNotesObserver = project.observe(\.notes) { [weak self] project, change in
            if let cell = self?.cell(for: .viewNotes) as? TextViewCollectionViewCell {
                cell.textView.attributedText = (project.notes ?? NSAttributedString()).replacing(font: .preferredFont(forTextStyle: .body), color: .label)
            }
        }
        
        threadsFetchedResultsController =
            NSFetchedResultsController(fetchRequest: ProjectThread.fetchRequest(for: project),
                                       managedObjectContext: project.managedObjectContext!,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        threadsFetchedResultsController.delegate = self

        imagesFetchedResultsController =
            NSFetchedResultsController(fetchRequest: ProjectImage.fetchRequest(for: project),
                                       managedObjectContext: project.managedObjectContext!,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        imagesFetchedResultsController.delegate = self

        EditImageCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "EditImage")
        ViewProjectThreadCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "Thread")
        EditProjectThreadCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "EditThread")
        TextInputCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "TextInput")
        TextViewCollectionViewCell.registerNib(on: collectionView, reuseIdentifier: "TextView")
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.cellIdentifier, for: indexPath)
            
            if let self = self {
                item.populate(cell: cell, project: self.project, controller: self)
            }
            
            return cell
        }
        
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
        
        collectionView.collectionViewLayout = createLayout()
        
        do {
            try threadsFetchedResultsController.performFetch()
        } catch {
            NSLog("Could not load project threads: \(error)")
        }

        do {
            try imagesFetchedResultsController.performFetch()
        } catch {
            NSLog("Could not load project images: \(error)")
        }

        updateSnapshot(animated: false)
        
        userActivity = UserActivity.showProject(project).userActivity
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
        project.managedObjectContext?.undoManager
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateSnapshot(animated: animated)

        navigationItem.largeTitleDisplayMode = editing ? .never : .automatic
        navigationItem.setRightBarButtonItems(
            editing ? [editButtonItem] : [editButtonItem,
                                          shareButtonItem,
                                          addToShoppingListButtonItem],
            animated: animated)

        if editing {
            project.managedObjectContext!.commit()
            undoManager?.beginUndoGrouping()
            undoManager?.setActionName(Localized.changeProject)
        } else {
            undoManager?.endUndoGrouping()
            project.managedObjectContext!.commit()
        }
    }
    
    func updateSnapshot(animated: Bool = true) {
        let images = imagesFetchedResultsController.fetchedObjects ?? []
        let threads = threadsFetchedResultsController.fetchedObjects ?? []
        var snapshot = NSDiffableDataSourceSnapshot<Section, Cell>()
        
        if isEditing {
            snapshot.appendSections([.editImages, .details])
            snapshot.appendItems(images.map { .editImage($0) }, toSection: .editImages)
            snapshot.appendItems([.imagePlaceholder], toSection: .editImages)
            snapshot.appendItems([.editName, .editNotes], toSection: .details)
        } else {
//            if images.count > 0 {
//                snapshot.appendSections([.viewImages])
//                snapshot.appendItems(images.map { .viewImage($0) }, toSection: .viewImages)
//            }
            if let notes = project.notes, notes.length > 0 {
                snapshot.appendSections([.notes])
                snapshot.appendItems([.viewNotes], toSection: .notes)
            }
        }
        
        snapshot.appendSections([.threads])
        snapshot.appendItems(threads.enumerated().map { (index, item) in
            if isEditing {
                return Cell.editThread(item)
            } else {
                let isLast = threads.index(after: index) == threads.endIndex
                return Cell.viewThread(item, isLast: isLast)
            }
        }, toSection: .threads)
        
        if isEditing {
            snapshot.appendItems([.add], toSection: .threads)
        }
        
        dataSource.apply(snapshot, animatingDifferences: animated)
        
        // update the threads section header if needed
        if let threadSectionIndex = snapshot.indexOfSection(.threads),
            let sectionHeader = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: threadSectionIndex)) as? SectionHeaderLabelView {
            sectionHeader.textLabel.text = threadsSectionHeaderText()
            sectionHeader.setNeedsLayout()
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            let sectionType = self!.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            
            switch sectionType {
            case .viewImages:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.85),
                                                       heightDimension: .fractionalWidth(0.85))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0)
                return section
                
            case .editImages:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalWidth(0.33))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
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
        let items = self.threadsFetchedResultsController.fetchedObjects?.count ?? 0
        return String.localizedStringWithFormat(Localized.threadsSectionHeader, items)
    }

    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController
        
        let threadCount = addViewController.selectedThreads.count
        let name = String.localizedStringWithFormat(Localized.addThreadUndoAction, threadCount)
        
        project.act(name) {
            for thread in addViewController.selectedThreads {
                thread.add(to: project)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the shopping list
                let threads: [Thread]
                do {
                    let existingThreads = (threadsFetchedResultsController.fetchedObjects ?? []).compactMap { $0.thread }
                    let request = Thread.sortedByNumberFetchRequest()
                    
                    // Not ideal, but I haven't figured out a way in Core Data to get all the threads that
                    // aren't in a particular project. Many-to-many relationships are hard.
                    threads = try project.managedObjectContext!.fetch(request).filter { !existingThreads.contains($0) }
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        UserActivity.showProject(project).update(activity)
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
    @IBAction func shareProject() {
        let activityController = UIActivityViewController(activityItems: [project],
                                                          applicationActivities: nil)
        present(activityController, animated: true)
    }

    @IBAction func addToShoppingList() {
        project.act(Localized.addToShoppingList) {
            project.addToShoppingList()
        }
    }

    func selectNewPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]

        present(imagePickerController, animated: true)
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
            performSegue(withIdentifier: "AddThread", sender: nil)
            collectionView.deselectItem(at: indexPath, animated: true)

        case .imagePlaceholder:
            selectNewPhoto()
            collectionView.deselectItem(at: indexPath, animated: true)

        default:
            assertionFailure("Got didSelectItemAt: with an unexpected item: \(item)")
        }
    }
}

// MARK: - Fetched Results Controller Delegate
extension ProjectDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            if controller == threadsFetchedResultsController {
                let thread = anObject as! ProjectThread

                if let cell = self.cell(for: .viewThread(thread, isLast: false)) as? ViewProjectThreadCollectionViewCell {
                    cell.populate(thread)
                } else if let cell = self.cell(for: .viewThread(thread, isLast: true)) as? ViewProjectThreadCollectionViewCell {
                    cell.populate(thread, isLastItem: true)
                } else if let cell = self.cell(for: .editThread(thread)) as? EditProjectThreadCollectionViewCell {
                    cell.populate(thread)
                }
            } else if controller == imagesFetchedResultsController {
                // TODO
            }
        default:
            break
        }
    }
}

// MARK: - Image Picker Controller Delegate
extension ProjectDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        NSLog("media info = \(info)")
        if let url = info[.imageURL] as? URL {
            do {
                let data = try Data(contentsOf: url)
                project.act(Localized.addImage) {
                    project.addImage(data)
                }
            } catch {
                NSLog("Error saving image data: \(error)")
            }
        } else {
            NSLog("Did not get an original image URL for the chosen media")
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
