//
//  AddThreadsAction.swift
//  Threads
//
//  Created by Matt Moriarity on 11/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit
import UserActions

struct AddThreadsAction: ReactiveUserAction {
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

    func publisher(context: UserActions.Context<AddThreadsAction>) -> AnyPublisher<(), Error> {
        let activity = UserActivity.addThreads(mode).userActivity
        UIApplication.shared.requestSceneSessionActivation(
            nil, userActivity: activity, options: nil)

        // TODO figure out a way to report completion when the user is actually done
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    #else

    let coordinator = Coordinator()

    func publisher(context: UserActionContext<AddThreadsAction>) -> AnyPublisher<(), Error> {
        let storyboard = UIStoryboard(name: "AddThread", bundle: nil)
        let navController = storyboard.instantiateViewController(identifier: "NavController")
            as! UINavigationController
        let addThreadController = navController.viewControllers[0] as! AddThreadViewController

        let onDismiss = PassthroughSubject<(), Never>()
        coordinator.onDismiss = onDismiss

        addThreadController.viewModel.mode = mode.makeMode(context: context.managedObjectContext)
        addThreadController.onDismiss = {
            context.dismiss()
            onDismiss.send()
            onDismiss.send(completion: .finished)
        }

        navController.presentationController?.delegate = coordinator
        context.present(navController)

        return onDismiss.setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {

        weak var onDismiss: PassthroughSubject<(), Never>?

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController)
            -> Bool
        {
            let navController = presentationController.presentedViewController
                as! UINavigationController
            let addThreadController = navController.viewControllers[0] as! AddThreadViewController
            return addThreadController.canDismiss
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            let navController = presentationController.presentedViewController
                as! UINavigationController
            let addThreadController = navController.viewControllers[0] as! AddThreadViewController
            addThreadController.onDismiss = nil
            onDismiss?.send()
            onDismiss?.send(completion: .finished)
        }
    }

    #endif
}

extension Thread {
    static var addToCollectionAction: AddThreadsAction { .init(mode: .collection) }
    static var addToShoppingListAction: AddThreadsAction { .init(mode: .shoppingList) }
}

extension Project {
    var addThreadsAction: AddThreadsAction { .init(mode: .project(self)) }
}
