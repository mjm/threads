//
//  AddThreadsAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CoreData
import UIKit

struct AddThreadAction: AsyncUserAction {
    enum Mode {
        case collection
        case shoppingList
        case project(Project)

        func makeMode(context: NSManagedObjectContext) -> AddThreadMode {
            switch self {
            case .collection:
                return AddThreadsToCollectionMode(context: context)
            case .shoppingList:
                return AddThreadsToShoppingListMode(context: context)
            case let .project(project):
                return AddThreadsToProjectMode(project: project)
            }
        }
    }

    let mode: Mode

    var undoActionName: String? { nil }

    #if targetEnvironment(macCatalyst)

    func performAsync(_ context: UserActionContext<AddThreadAction>) {
        let activity = UserActivity.addThreads(mode).userActivity
        UIApplication.shared.requestSceneSessionActivation(
            nil, userActivity: activity, options: nil)
    }

    #else

    let coordinator = Coordinator()

    func performAsync(_ context: UserActionContext<AddThreadAction>) {
        let storyboard = UIStoryboard(name: "AddThread", bundle: nil)
        let navController = storyboard.instantiateViewController(identifier: "NavController")
            as! UINavigationController
        let addThreadController = navController.viewControllers[0] as! AddThreadViewController

        addThreadController.viewModel.mode = mode.makeMode(context: context.managedObjectContext)
        addThreadController.onDismiss = {
            context.completeAndDismiss()
        }

        navController.presentationController?.delegate = coordinator
        context.present(navController)
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController)
            -> Bool
        {
            let navController = presentationController.presentedViewController
                as! UINavigationController
            let addThreadController = navController.viewControllers[0] as! AddThreadViewController
            return addThreadController.canDismiss
        }
    }

    #endif
}
