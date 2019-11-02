//
//  DetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 10/12/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class DetailViewController: UITabBarController {
    private var cancellables = Set<AnyCancellable>()

    let viewModel: DetailViewModel

    var myThreadsViewController: MyThreadsViewController!
    var shoppingListViewController: ShoppingListViewController!
    var projectDetailViewController: ProjectDetailViewController?

    required init?(coder: NSCoder) {
        viewModel = DetailViewModel()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.isHidden = true

        myThreadsViewController
            = UIStoryboard(name: "MyThreads", bundle: nil).instantiateInitialViewController {
                coder in
                MyThreadsViewController(coder: coder, viewModel: self.viewModel.collectionViewModel)
            }
        shoppingListViewController
            = UIStoryboard(name: "ShoppingList", bundle: nil).instantiateInitialViewController {
                coder in
                ShoppingListViewController(
                    coder: coder, viewModel: self.viewModel.shoppingListViewModel)
            }

        viewControllers = [myThreadsViewController, shoppingListViewController]

        viewModel.$selection.removeDuplicates().sink { [weak self] selection in
            switch selection {
            case .collection:
                self?.selectedIndex = 0
            case .shoppingList:
                self?.selectedIndex = 1
            case let .project(model):
                self?.showProject(model)
            }

            self?.selectedViewController?.becomeFirstResponder()
        }.store(in: &cancellables)
    }

    func showProject(_ model: ProjectDetailViewModel) {
        if let currentModel = projectDetailViewController?.viewModel,
            model == currentModel
        {
            // nothing to do but make sure it's the currently visible controller
            selectedViewController = projectDetailViewController
            return
        }

        let newController = UIStoryboard(name: "Projects", bundle: nil).instantiateViewController(
            identifier: "ProjectDetail"
        ) { coder in
            ProjectDetailViewController(coder: coder, viewModel: model)
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
