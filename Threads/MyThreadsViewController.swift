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
    private var dataSource: UITableViewDiffableDataSource<Section, Thread>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request: NSFetchRequest<Thread> = Thread.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        fetchedResultsController =
            NSFetchedResultsController(fetchRequest: request,
                                       managedObjectContext: managedObjectContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
        fetchedResultsController.delegate = self
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "Thread", for: indexPath)
            cell.textLabel!.text = "\(item.number ?? ""): \(item.label ?? "")"
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, Thread>()
        snapshot.appendSections([.threads])
        let objects = fetchedResultsController.fetchedObjects ?? []
        NSLog("updating snapshot with objects: \(objects)")
        snapshot.appendItems(objects, toSection: .threads)
        dataSource.apply(snapshot)
    }
    
    @IBAction func unwindCancelAdd(segue: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let addController = navController.viewControllers.first as? AddThreadViewController {
                addController.managedObjectContext = managedObjectContext
            }
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MyThreadsViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateSnapshot()
    }
}
