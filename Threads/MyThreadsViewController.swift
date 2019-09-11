//
//  MyThreadsViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreData

class MyThreadsViewController: UITableViewController {
    
    enum Section {
        case threads
    }
    
    private var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Thread>!
    private var dataSource: TableViewDiffableDataSource<Section, Thread>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: Thread.inCollectionFetchRequest(),
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        tableView.register(CollectionThreadTableViewCell.nib, forCellReuseIdentifier: "Thread")
        dataSource = TableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath) as! CollectionThreadTableViewCell
            cell.populate(item)
            return cell
        }
        
        dataSource.canEditRow = { _, _, _ in true }
        
        do {
            try fetchedResultsController.performFetch()
            updateSnapshot()
        } catch {
            NSLog("Error fetching objects: \(error)")
        }
        
        let activity = NSUserActivity(activityType: "com.mattmoriarity.Threads.ShowMyThreads")
        activity.title = "My Threads"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        userActivity = activity
    }
    
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections([.threads])
        let objects = fetchedResultsController.fetchedObjects ?? []
        NSLog("updating snapshot with objects: \(objects)")
        snapshot.appendItems(objects, toSection: .threads)
        dataSource.apply(snapshot)
    }
    
    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindAddThread(segue: UIStoryboardSegue) {
        let addViewController = segue.source as! AddThreadViewController
        for thread in addViewController.selectedThreads {
            thread.addToCollection()
        }
        AppDelegate.save()
    }
    
    @IBAction func unwindDeleteThread(segue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                // only choose from threads that aren't already in the collection
                let threads: [Thread]
                do {
                    let request = Thread.notInCollectionFetchRequest()
                    threads = try managedObjectContext.fetch(request)
                } catch {
                    NSLog("Could not fetch threads to search from")
                    threads = []
                }
                
                addController.choices = threads
            }
        }
    }
    
    @IBSegueAction func makeDetailController(coder: NSCoder, sender: IndexPath) -> ThreadDetailViewController? {
        let thread = dataSource.itemIdentifier(for: sender)
        return ThreadDetailViewController(coder: coder, thread: thread!)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ThreadDetail", sender: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let thread = self.fetchedResultsController.object(at: indexPath)
        if thread.amountInCollection == 0 {
            return nil
        }
        
        let bobbin: UIContextualAction
        if thread.onBobbin {
            bobbin = UIContextualAction(style: .normal, title: "Off Bobbin") { action, view, completionHandler in
                thread.onBobbin = false
                AppDelegate.save()
                completionHandler(true)
            }
        } else {
            bobbin = UIContextualAction(style: .normal, title: "On Bobbin") { action, view, completionHandler in
                thread.onBobbin = true
                AppDelegate.save()
                completionHandler(true)
            }
        }
        bobbin.backgroundColor = UIColor(named: "BobbinSwipe")
        
        let config = UISwipeActionsConfiguration(actions: [bobbin])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let thread = self.fetchedResultsController.object(at: indexPath)
        
        let stock: UIContextualAction
        if thread.amountInCollection == 0 {
            stock = UIContextualAction(style: .normal, title: "In Stock") { action, view, completionHandler in
                thread.amountInCollection = 1
                AppDelegate.save()
                completionHandler(true)
            }
            stock.backgroundColor = UIColor(named: "InStockSwipe")
        } else {
            stock = UIContextualAction(style: .destructive, title: "Out of Stock") { action, view, completionHandler in
                thread.amountInCollection = 0
                thread.onBobbin = false
                AppDelegate.save()
                completionHandler(true)
            }
        }
        
        let config = UISwipeActionsConfiguration(actions: [stock])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
}

extension MyThreadsViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .update:
            let thread = anObject as! Thread
            if let cell = tableView.cellForRow(at: indexPath!) as? CollectionThreadTableViewCell {
                cell.populate(thread)
            }
        default:
            break
        }
    }
}
