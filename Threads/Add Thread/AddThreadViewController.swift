//
//  AddThreadViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class AddThreadViewController: TableViewController<AddThreadViewController.Section, AddThreadViewController.Cell> {
    enum Section: CaseIterable {
        case results
        case selected
    }

    enum Cell: ReusableCell {
        case thread(Thread, isResult: Bool)

        var cellIdentifier: String { "Thread" }

        static func ==(lhs: Cell, rhs: Cell) -> Bool {
            switch (lhs, rhs) {
            case let (.thread(left, isResult: _), .thread(right, isResult: _)):
                return left == right
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case let .thread(thread, isResult: _):
                hasher.combine(thread)
            }
        }
    }
    
    weak var delegate: AddThreadViewControllerDelegate?
    var onDismiss: (() -> Void)!
    
    private var choices: [Thread] = []
    
    private var searchController: UISearchController!

    @Published private var threadToAdd: Thread?
    @Published private var query: String = ""
    @Published private var selectedThreads: [Thread] = []
    @Published private var filteredThreads: [Thread] = []
    
    private var isAdding = false

    var canDismiss: Bool {
        return selectedThreads.isEmpty
    }
    
    @IBOutlet var keyboardAccessoryView: UIToolbar!
    @IBOutlet var quickAddButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.automaticallyShowsCancelButton = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false

        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.placeholder = Localized.searchForNewThreads
        searchController.searchBar.keyboardType = .asciiCapableNumberPad
        searchController.searchBar.inputAccessoryView = keyboardAccessoryView
        searchController.searchBar.delegate = self
        searchController.searchBar.searchTextField.delegate = self
        
        #if targetEnvironment(macCatalyst)
        tableView.tableHeaderView = searchController.searchBar
        #else
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        #endif
    }
    
    override func createObservers() -> [Any] {
        let addButton = navigationItem.rightBarButtonItems!.first!
        
        return [
            $query.combineLatest($selectedThreads) { query, selectedThreads -> [Thread] in
                if query.isEmpty {
                    return []
                } else {
                    return self.choices.filter {
                        return !selectedThreads.contains($0) &&
                            $0.number!.lowercased().hasPrefix(query)
                    }
                }
            }.assign(to: \.filteredThreads, on: self),
            
            $query.combineLatest($filteredThreads) { query, threads -> Thread? in
                threads.first { $0.number?.lowercased() == query }
            }.assign(to: \.threadToAdd, on: self),
            
            $threadToAdd.map { $0 != nil}.assign(to: \.isEnabled, on: quickAddButton),
            
            $selectedThreads.map { !$0.isEmpty }.assign(to: \.isEnabled, on: addButton),
            $selectedThreads.map { threads in
                String.localizedStringWithFormat(Localized.addBatchButton, threads.count)
            }.assign(to: \.title, on: addButton),
        ]
    }

    override func dataSourceWillInitialize() {
        dataSource.canEditRow = { _, _, _ in true }

        dataSource.sectionTitle = { _, _, section in
            switch section {
            case .results: return NSLocalizedString("Matching Threads", comment: "")
            case .selected: return NSLocalizedString("Threads to Add", comment: "")
            }
        }
        
        do {
            if let choices = try delegate?.choicesForAddingThreads(self) {
                self.choices = choices
            }
        } catch {
            present(error: error)
        }
    }

    override func buildSnapshotForDataSource(_ snapshot: inout Snapshot) {
        if !filteredThreads.isEmpty {
            snapshot.appendSections([.results])
            snapshot.appendItems(filteredThreads.map { .thread($0, isResult: true) }, toSection: .results)
        }

        if !selectedThreads.isEmpty {
            snapshot.appendSections([.selected])
            snapshot.appendItems(selectedThreads.map { .thread($0, isResult: false) }, toSection: .selected)
        }
    }

    override var cellTypes: [String : RegisteredCellType<UITableViewCell>] {
        ["Thread": .nib(CollectionThreadTableViewCell.self)]
    }

    override func populate(cell: UITableViewCell, item: AddThreadViewController.Cell) {
        switch item {
        case let .thread(thread, isResult: _):
            let cell = cell as! CollectionThreadTableViewCell
            cell.populate(thread)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.searchBar.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.05)
    }
    
    @IBAction func tapKeyboardShortcut(sender: UIBarButtonItem) {
        searchController.searchBar.text = sender.title!
    }

    @IBAction func quickAddThread() {
        guard let thread = threadToAdd else {
            return
        }

        addThread(thread)
    }

    @IBAction func cancel() {
        onDismiss()
    }

    @IBAction func add() {
        delegate?.addThreadViewController(self, performActionForAddingThreads: selectedThreads, actionRunner: actionRunner)
        onDismiss()
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard super.canPerformAction(action, withSender: sender) else {
            return false
        }
        
        switch action {
        case #selector(add):
            return !selectedThreads.isEmpty
        default:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard case .thread(_, isResult: true) = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case let .thread(thread, isResult: true) = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)
        addThread(thread)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if tableView == self.tableView {
            let delete = UIContextualAction(style: .destructive, title: Localized.dontAdd) { action, view, completionHandler in
                self.selectedThreads.remove(at: indexPath.row)
                self.updateSnapshot()
                completionHandler(true)
            }
            delete.image = UIImage(systemName: "nosign")
            
            let config = UISwipeActionsConfiguration(actions: [delete])
            config.performsFirstActionWithFullSwipe = true
            return config
        }
        
        return nil
    }

    private func addThread(_ thread: Thread) {
        isAdding = true

        selectedThreads.insert(thread, at: 0)
        searchController.searchBar.text = ""

        isAdding = false
    }
}

extension AddThreadViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text?.lowercased() ?? ""

        #if targetEnvironment(macCatalyst)
        updateSnapshot(animated: false)
        #else
        updateSnapshot(animated: isAdding)
        #endif
    }
}

extension AddThreadViewController: UISearchBarDelegate {
}

extension AddThreadViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        quickAddThread()
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            guard let existingText = textField.text as NSString? else {
                return false
            }
            
            if range.location == existingText.length {
                // a space at the end of the text means quick add thread
                quickAddThread()
            }
            
            return false
        }
        
        return true
    }
}

protocol AddThreadViewControllerDelegate: NSObjectProtocol {
    func choicesForAddingThreads(_ addThreadViewController: AddThreadViewController) throws -> [Thread]
    func addThreadViewController(_ addThreadViewController: AddThreadViewController,
                                 performActionForAddingThreads threads: [Thread],
                                 actionRunner: UserActionRunner)
}
