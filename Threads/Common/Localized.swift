//
//  Localized.swift
//  Threads
//
//  Created by Matt Moriarity on 9/14/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Foundation

enum Localized {
    static let onBobbin = NSLocalizedString("On Bobbin", comment: "")
    static let offBobbin = NSLocalizedString("Off Bobbin", comment: "")
    static let inStock = NSLocalizedString("In Stock", comment: "")
    static let outOfStock = NSLocalizedString("Out of Stock", comment: "")

    static let markOnBobbin = NSLocalizedString("Mark On Bobbin", comment: "")
    static let markOffBobbin = NSLocalizedString("Mark Off Bobbin", comment: "")
    static let markInStock = NSLocalizedString("Mark In Stock", comment: "")
    static let markOutOfStock = NSLocalizedString("Mark Out of Stock", comment: "")

    static let addToProject = NSLocalizedString("Add to Project", comment: "")
    static let addToProjectMenu = NSLocalizedString("Add to Project…", comment: "")

    static let addToProjectBannerNumber = NSLocalizedString(
        "Added DMC %@ to %@.", comment: "Added {thread number} to {project name}.")

    static let addToProjectBannerCount = NSLocalizedString(
        "Added %lu threads to %@.", comment: "Added {count} threads to {project name}.")

    static let addToShoppingList = NSLocalizedString("Add to Shopping List", comment: "")

    static let addToShoppingListBannerNumber = NSLocalizedString(
        "Added DMC %@ to your shopping list.",
        comment: "Added {thread number} to your shopping list.")

    static let addToShoppingListBannerCount = NSLocalizedString(
        "Added %lu threads to your shopping list.",
        comment: "Added {count} threads to your shopping list.")

    static let removeFromCollection = NSLocalizedString("Remove from Collection", comment: "")
    static let removeThread = NSLocalizedString("Remove Thread", comment: "")

    static let removeThreadPrompt = NSLocalizedString(
        "Are you sure you want to remove this thread from your collection?", comment: "")

    static let cancel = NSLocalizedString("Cancel", comment: "")
    static let remove = NSLocalizedString("Remove", comment: "")

    static let addThreadUndoAction = NSLocalizedString(
        "AddThreadUndoAction", comment: "Add Thread or Add {num} Threads")

    static let addToCollection = NSLocalizedString("Add to Collection", comment: "")

    static let myThreads = NSLocalizedString("My Threads", comment: "")
    static let shoppingList = NSLocalizedString("Shopping List", comment: "")
    static let myProjects = NSLocalizedString("My Projects", comment: "")

    static let dmcNumber = NSLocalizedString("DMC %@", comment: "DMC {thread number}")

    static let dmcNumberUnknown = NSLocalizedString(
        "DMC Unknown", comment: "DMC with missing number")

    static let unnamedProject = NSLocalizedString("Unnamed Project", comment: "")

    static let searchForNewThreads = NSLocalizedString("Search for new threads", comment: "")
    static let addBatchButton = NSLocalizedString("AddBatchButton", comment: "Add or Add ({num})")
    static let dontAdd = NSLocalizedString("Don't Add", comment: "")
    static let matchingThreads = NSLocalizedString("Matching Threads", comment: "")
    static let threadsToAdd = NSLocalizedString("Threads to Add", comment: "")

    static let edit = NSLocalizedString("Edit", comment: "")
    static let stopEditing = NSLocalizedString("Stop Editing", comment: "")
    static let share = NSLocalizedString("Share", comment: "")
    static let delete = NSLocalizedString("Delete", comment: "")

    static let projectName = NSLocalizedString("Project Name", comment: "")
    static let changeProject = NSLocalizedString("Change Project", comment: "")
    static let deleteProject = NSLocalizedString("Delete Project", comment: "")
    static let newProject = NSLocalizedString("New Project", comment: "")
    static let changeStatus = NSLocalizedString("Change Status", comment: "")
    static let status = NSLocalizedString("Status", comment: "")

    static let deleteProjectPrompt = NSLocalizedString(
        "Are you sure you want to delete this project?", comment: "")

    static let threadsSectionHeader = NSLocalizedString(
        "ThreadsSectionHeader", comment: "THREADS or 1 THREAD or 2 THREADS")

    static let inCollectionThreadsSectionHeader = NSLocalizedString(
        "InCollectionThreadsSectionHeader",
        comment: "THREADS YOU HAVE or 1 THREAD YOU HAVE or 2 THREADS YOU HAVE")

    static let notInCollectionThreadsSectionHeader = NSLocalizedString(
        "NotInCollectionThreadsSectionHeader",
        comment: "THREADS YOU NEED or 1 THREAD YOU NEED or 2 THREADS YOU NEED")

    static let notesSectionHeader = NSLocalizedString("NOTES", comment: "")

    static let purchased = NSLocalizedString("Purchased", comment: "")
    static let changePurchased = NSLocalizedString("Change Purchased", comment: "")
    static let changeQuantity = NSLocalizedString("Change Quantity", comment: "")
    static let increaseQuantity = NSLocalizedString("Increase Quantity", comment: "")
    static let decreaseQuantity = NSLocalizedString("Decrease Quantity", comment: "")
    static let removeFromShoppingList = NSLocalizedString("Remove from Shopping List", comment: "")

    static let emptyCollection = NSLocalizedString(
        "You haven't added any threads to your collection.", comment: "")

    static let emptyShoppingList = NSLocalizedString(
        "Your shopping list doesn't have any threads.", comment: "")

    static let emptyProjects = NSLocalizedString("You haven't created any projects.", comment: "")

    static let numberInShoppingList = NSLocalizedString(
        "%lu in Shopping List", comment: "2 in Shopping List")

    static let usedInProjects = NSLocalizedString(
        "UsedInProjects", comment: "Used in {num} Projects")

    static let inShoppingList = NSLocalizedString("In Shopping List", comment: "")
    static let projects = NSLocalizedString("Projects", comment: "")

    static let activeProjects = NSLocalizedString("Active Projects", comment: "")
    static let plannedProjects = NSLocalizedString("Planned Projects", comment: "")
    static let completedProjects = NSLocalizedString("Completed Projects", comment: "")
    static let archivedProjects = NSLocalizedString("Archived Projects", comment: "")

    static let active = NSLocalizedString("Active", comment: "")
    static let planned = NSLocalizedString("Planned", comment: "")
    static let completed = NSLocalizedString("Completed", comment: "")
    static let archived = NSLocalizedString("Archived", comment: "")

    static let addImage = NSLocalizedString("Add Image", comment: "")
    static let moveImage = NSLocalizedString("Move Image", comment: "")
    static let deleteImage = NSLocalizedString("Delete Image", comment: "")

    static let errorOccurred = NSLocalizedString("Error Occurred", comment: "")
    static let dismiss = NSLocalizedString("Dismiss", comment: "")
}
