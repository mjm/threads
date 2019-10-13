//
//  DetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class DetailViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.isHidden = true
    }
    
    var myThreadsViewController: MyThreadsViewController {
        viewControllers![0] as! MyThreadsViewController
    }
    
    var shoppingListViewController: ShoppingListViewController {
        viewControllers![1] as! ShoppingListViewController
    }
    
    var projectDetailViewController: ProjectDetailViewController?
    
    func setSelection(_ selection: SidebarSelection) {
        switch selection {
        case .collection:
            selectedIndex = 0
        case .shoppingList:
            selectedIndex = 1
        case let .project(project):
            showProject(project)
        }
    }
    
    func showProject(_ project: Project, editing: Bool = false) {
        if let currentProject = projectDetailViewController?.project, currentProject == project {
            // nothing to do but make sure it's the currently visible controller
            selectedViewController = projectDetailViewController
            return
        }
        
        let newController = UIStoryboard(name: "Projects", bundle: nil).instantiateViewController(identifier: "ProjectDetail") { coder in
            ProjectDetailViewController(coder: coder, project: project, editing: editing)
        }
        
        if let existingController = projectDetailViewController {
            let index = viewControllers!.firstIndex(of: existingController)!
            viewControllers![index] = newController
            selectedIndex = index
        } else {
            viewControllers!.append(newController)
            selectedViewController = newController
        }
        
        projectDetailViewController = newController
    }
    
    var currentUserActivity: NSUserActivity? {
        selectedViewController?.userActivity
    }
}
