//
//  UserActivity.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreSpotlight
import CoreServices

private let threadURLKey = "ThreadURL"
private let threadNumberKey = "ThreadNumber"
private let projectURLKey = "ProjectURL"
private let projectNameKey = "ProjectName"

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
            } else if let threadNumber = userActivity.userInfo?[threadNumberKey] as? String,
                let thread = try? Thread.withNumber(threadNumber, context: context) {
                self = .showThread(thread)
            } else {
                return nil
            }
        case .showProject:
            if let projectURL = userActivity.userInfo?[projectURLKey] as? URL,
                let projectID = context.persistentStoreCoordinator!.managedObjectID(forURIRepresentation: projectURL),
                let project = context.object(with: projectID) as? Project {
                self = .showProject(project)
            } else if let projectName = userActivity.userInfo?[projectNameKey] as? String,
                let project = try? Project.withName(projectName, context: context) {
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
            activity.title = Localized.myThreads
        case .showShoppingList:
            activity.title = Localized.shoppingList
        case .showProjects:
            activity.title = Localized.myProjects
        case let .showThread(thread):
            let threadURL = thread.objectID.uriRepresentation()
            if let number = thread.number {
                activity.title = String(format: Localized.dmcNumber, number)
            } else {
                activity.title = Localized.dmcNumberUnknown
            }
            let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
            if let image = thread.colorImage, let data = image.pngData() {
                attributes.thumbnailData = data
            }
            activity.contentAttributeSet = attributes
            activity.userInfo = [threadURLKey: threadURL, threadNumberKey: thread.number!]
            activity.requiredUserInfoKeys = [threadURLKey]
        case let .showProject(project):
            let projectURL = project.objectID.uriRepresentation()
            activity.title = project.name ?? Localized.unnamedProject
            let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
            if let image = project.primaryImage?.image,
                let data = image.resized(toFit: CGSize(width: 180, height: 270)).jpegData(compressionQuality: 0.7) {
                attributes.thumbnailData = data
            }
            activity.contentAttributeSet = attributes
            activity.userInfo = [projectURLKey: projectURL, projectNameKey: project.name ?? ""]
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
    
    func update(_ activity: NSUserActivity) {
        guard activity.activityType == userActivityType.rawValue,
            activity.persistentIdentifier == persistentIdentifier else {
            return
        }
        
        let newActivity = userActivity
        activity.title = newActivity.title
        if let userInfo = newActivity.userInfo {
            activity.addUserInfoEntries(from: userInfo)
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
