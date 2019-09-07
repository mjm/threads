//
//  ShoppingListViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UITableViewController {
    enum Section: CaseIterable {
        case threads
    }
    
    private var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: UITableViewDiffableDataSource<Section, Thread>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.inShoppingListFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        tableView.register(ShoppingListThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! ShoppingListThreadTableViewCell
            cell.populate(item)
            cell.onCheckTapped = {
                item.purchased = !item.purchased
                AppDelegate.save()
            }
            cell.onIncreaseQuantity = {
                item.amountInShoppingList += 1
                AppDelegate.save()
            }
            cell.onDecreaseQuantity = {
                if item.amountInShoppingList == 1 {
                    item.removeFromShoppingList()
                } else {
                    item.amountInShoppingList -= 1
                }
                AppDelegate.save()
            }
            return cell
        }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
    }
    
    func updateSnapshot() {
        // update the rows of the table
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections(Section.allCases)
        let objects = fetchedResultsController.fetchedObjects ?? []
        snapshot.appendItems(objects, toSection: .threads)
        dataSource.apply(snapshot)

        // animate in/out the "Add Checked to Collection" button
        let anyChecked = !objects.filter { $0.purchased }.isEmpty
        let header = self.tableView.tableHeaderView!
        let height = anyChecked
            ? header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            : 0.0

        let animator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 0.3) {
            header.frame.size.height = height
            header.layoutIfNeeded()
        }
        animator.startAnimation()
    }

    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController
        for thread in addViewController.selectedThreads {
            thread.addToShoppingList()
        }
        AppDelegate.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the shopping list
                let threads: [Thread]
                do {
                    let request = Thread.notInShoppingListFetchRequest()
                    threads = try managedObjectContext.fetch(request)
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }

}

extension ShoppingListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let thread = anObject as! Thread
            if let cell = tableView.cellForRow(at: indexPath!) as? ShoppingListThreadTableViewCell {
                cell.populate(thread)
            }
        default:
            break
        }
    }
}
