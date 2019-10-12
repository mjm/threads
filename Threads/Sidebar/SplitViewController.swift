//
//  SplitViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

enum SidebarSelection: Hashable {
    case collection
    case shoppingList
    case project(Project)
}

class SplitViewController: UISplitViewController {
    private var actionRunner: UserActionRunner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionRunner = UserActionRunner(viewController: self, managedObjectContext: managedObjectContext)
        
        primaryBackgroundStyle = .sidebar
    }
    
    var selection: SidebarSelection = .collection {
        didSet {
            sidebarViewController.setSelection(selection)
            detailViewController.setSelection(selection)
        }
    }
    
    @objc func addProject(_ sender: Any) {
        actionRunner.perform(CreateProjectAction()) { project in
            self.showProject(project)
        }
    }
    
    @objc func showProject(_ sender: Any) {
        guard let project = sender as? Project else {
            preconditionFailure("Sender for showProject(_:) should be a Project")
        }
        
        selection = .project(project)
    }
    
    var sidebarViewController: SidebarViewController {
        viewControllers[0] as! SidebarViewController
    }
    
    var detailViewController: DetailViewController {
        viewControllers[1] as! DetailViewController
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
    }
}
