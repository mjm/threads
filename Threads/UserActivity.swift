//
//  UserActivity.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import CoreData

private let threadURLKey = "ThreadURL"
private let projectURLKey = "ProjectURL"

private enum UserActivityType: String {
    case showMyThreads = "com.mattmoriarity.Threads.ShowMyThreads"
    case showShoppingList = "com.mattmoriarity.Threads.ShowShoppingList"
    case showProjects = "com.mattmoriarity.Threads.ShowProjects"
    case showThread = "com.mattmoriarity.Threads.ShowThread"
    case showProject = "com.mattmoriarity.Threads.ShowProject"
    
    func create() -> NSUserActivity {
        return NSUserActivity(activityType: rawValue)
    }
}

enum UserActivity {
    case showMyThreads
    case showShoppingList
    case showProjects
    case showThread(Thread)
    case showProject(Project)
    
    init?(userActivity: NSUserActivity, context: NSManagedObjectContext) {
        switch UserActivityType(rawValue: userActivity.activityType) {
        case .showMyThreads:
            self = .showMyThreads
        case .showShoppingList:
            self = .showShoppingList
        case .showProjects:
            self = .showProjects
        case .showThread:
            if let threadURL = userActivity.userInfo?[threadURLKey] as? URL,
                let threadID = context.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: threadURL),
                let thread = context.object(with: threadID) as? Thread {
                self = .showThread(thread)
            } else {
                return nil
            }
        case .showProject:
            if let projectURL = userActivity.userInfo?[projectURLKey] as? URL,
                let projectID = context.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: projectURL),
                let project = context.object(with: projectID) as? Project {
                self = .showProject(project)
            } else {
                return nil
            }
        case .none:
            return nil
        }
    }
    
    private var userActivityType: UserActivityType {
        switch self {
        case .showMyThreads: return .showMyThreads
        case .showShoppingList: return .showShoppingList
        case .showProjects: return .showProjects
        case .showThread: return .showThread
        case .showProject: return .showProject
        }
    }
    
    var userActivity: NSUserActivity {
        let activity = userActivityType.create()
        
        // these are generally true and can be turned off as needed
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        if let identifier = persistentIdentifier {
            NSLog("creating user activity with persistent identifier \(identifier)")
            activity.persistentIdentifier = identifier
        }
        
        switch self {
        case .showMyThreads:
            activity.title = "My Threads"
        case .showShoppingList:
            activity.title = "Shopping List"
        case .showProjects:
            activity.title = "My Projects"
        case let .showThread(thread):
            let threadURL = thread.objectID.uriRepresentation()
            activity.title = "DMC \(thread.number ?? "Unknown")"
            activity.userInfo = [threadURLKey: threadURL]
            activity.requiredUserInfoKeys = [threadURLKey]
        case let .showProject(project):
            let projectURL = project.objectID.uriRepresentation()
            activity.title = project.name ?? "Untitled Project"
            activity.userInfo = [projectURLKey: projectURL]
            activity.requiredUserInfoKeys = [projectURLKey]
        }
        
        return activity
    }
    
    var persistentIdentifier: String? {
        switch self {
        case let .showThread(thread):
            return thread.objectID.uriRepresentation().absoluteString
        case let .showProject(project):
            return project.objectID.uriRepresentation().absoluteString
        default:
            return nil
        }
    }
    
    func delete(completion: @escaping () -> Void = {}) {
        if let identifier = persistentIdentifier {
            NSUserActivity.deleteSavedUserActivities(withPersistentIdentifiers: [identifier]) {
                NSLog("Deleted user activity with identifier \(identifier)")
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
}
