//
//  ProjectActions.swift
//  Threads
//
//  Created by Matt Moriarity on 9/16/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import CoreServices
import Events

extension Event.Key {
    static let projectName: Event.Key = "project_name"
    static let byteCount: Event.Key = "byte_count"
    static let activityType: Event.Key = "activity_type"
}

struct CreateProjectAction: UserAction {
    typealias ResultType = Project

    let undoActionName: String? = Localized.newProject

    #if targetEnvironment(macCatalyst)
    func performAsync(_ context: UserActionContext<CreateProjectAction>) {
        let alert = UIAlertController(title: "Create a Project", message: "Enter a name for your new project:", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: Localized.cancel, style: .cancel) { _ in
            context.complete(error: UserActionError.canceled)
        })
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            let project = Project(context: context.managedObjectContext)
            project.name = alert.textFields?[0].text
            
            Event.current[.projectName] = project.name
            
            context.complete(project)
        })
        
        context.present(alert)
    }
    #else
    func performAsync(_ context: UserActionContext<CreateProjectAction>) {
        context.complete(Project(context: context.managedObjectContext))
    }
    #endif
}

struct AddToProjectAction: SyncUserAction {
    let threads: [Thread]
    let project: Project
    let showBanner: Bool

    init(threads: [Thread], project: Project, showBanner: Bool = false) {
        assert(threads.count > 0)

        self.threads = threads
        self.project = project
        self.showBanner = showBanner
    }

    init(thread: Thread, project: Project, showBanner: Bool = false) {
        self.init(threads: [thread], project: project, showBanner: showBanner)
    }

    let undoActionName: String? = Localized.addToProject

    var canPerform: Bool {
        if threads.count > 1 {
            return true
        } else {
            let projectThreads = threads[0].projects as? Set<ProjectThread> ?? []
            return projectThreads.allSatisfy { $0.project != project }
        }
    }

    func perform(_ context: UserActionContext<AddToProjectAction>) throws {
        Event.current[.threadCount] = threads.count
        Event.current[.projectName] = project.name
        
        for thread in threads {
            thread.add(to: project)
        }

        if showBanner {
            let projectName = project.name ?? Localized.unnamedProject
            let message = threads.count == 1
                ? String(format: Localized.addToProjectBannerNumber, threads[0].number!, projectName)
                : String(format: Localized.addToProjectBannerCount, threads.count, projectName)
            context.present(BannerController(message: message))
        }
    }
}

struct AddProjectToShoppingListAction: SyncUserAction {
    let project: Project

    let undoActionName: String? = Localized.addToShoppingList

    func perform(_ context: UserActionContext<AddProjectToShoppingListAction>) throws {
        Event.current[.projectName] = project.name
        project.addToShoppingList()

        let threads = (project.threads as! Set<ProjectThread>).compactMap { $0.thread }
        Event.current[.threadCount] = threads.count
        
        let message = threads.count == 1
            ? String(format: Localized.addToShoppingListBannerNumber, threads[0].number!)
            : String(format: Localized.addToShoppingListBannerCount, threads.count)
        context.present(BannerController(message: message))
    }
}

struct DeleteProjectAction: DestructiveUserAction {
    let project: Project

    let undoActionName: String? = Localized.deleteProject

    let confirmationTitle: String = Localized.deleteProject
    let confirmationMessage: String = Localized.deleteProjectPrompt
    let confirmationButtonTitle: String = Localized.delete

    func performAsync(_ context: UserActionContext<DeleteProjectAction>) {
        Event.current[.projectName] = project.name
        
        UserActivity.showProject(project).delete {
            context.managedObjectContext.delete(self.project)
            context.complete()
        }
    }
}

struct ShareProjectAction: UserAction {
    let project: Project

    // There's not really anything you can do to undo a share, since it leaves the
    // context of the app.
    let undoActionName: String? = nil

    func performAsync(_ context: UserActionContext<ShareProjectAction>) {
        Event.current[.projectName] = project.name
        
        let activityController = UIActivityViewController(activityItems: [ProjectActivity(project: project)],
                                                          applicationActivities: [OpenInSafariActivity()])
        
        activityController.completionWithItemsHandler = { activityType, completed, items, error in
            if let error = error {
                context.complete(error: error)
                return
            }
            
            Event.current[.activityType] = activityType?.rawValue
            
            if completed {
                context.complete()
            } else {
                context.complete(error: UserActionError.canceled)
            }
        }
        
        context.present(activityController)
    }
}

struct AddImageToProjectAction: UserAction {
    let project: Project

    let coordinator = Coordinator()

    let undoActionName: String? = Localized.addImage

    func performAsync(_ context: UserActionContext<AddImageToProjectAction>) {
        Event.current[.projectName] = project.name
        
        coordinator.project = project
        coordinator.context = context

        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = coordinator
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]

        context.present(imagePickerController)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var project: Project!
        var context: UserActionContext<AddImageToProjectAction>!

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.imageURL] as? URL {
                do {
                    let data = try Data(contentsOf: url)
                    Event.current[.byteCount] = data.count
                    project.addImage(data)

                    context.completeAndDismiss()
                } catch {
                    context.completeAndDismiss(error: error)
                }
            } else {
                context.completeAndDismiss(error: Error.noImageURL)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            context.completeAndDismiss(error: UserActionError.canceled)
        }
    }
    
    enum Error: LocalizedError {
        case noImageURL
        
        var errorDescription: String? {
            switch self {
            case .noImageURL:
                return "The chosen media could not be added to the project because it is not a valid image."
            }
        }
    }
}

struct MoveProjectImageAction: SyncUserAction {
    let project: Project
    let sourceIndex: Int
    let destinationIndex: Int

    let undoActionName: String? = Localized.moveImage

    func perform(_ context: UserActionContext<MoveProjectImageAction>) throws -> () {
        Event.current[.projectName] = project.name
        
        var images = project.orderedImages

        let image = images.remove(at: sourceIndex)
        images.insert(image, at: destinationIndex)

        project.orderedImages = images
    }
}

struct DeleteProjectImageAction: SyncUserAction {
    let image: ProjectImage

    let undoActionName: String? = Localized.deleteImage

    func perform(_ context: UserActionContext<DeleteProjectImageAction>) throws {
        Event.current[.projectName] = image.project?.name
        image.delete()
    }
}
