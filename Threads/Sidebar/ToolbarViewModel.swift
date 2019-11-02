//
//  ToolbarViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 11/1/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ToolbarViewModel {
    
}

extension NSToolbarItem.Identifier {
    static let addProject = NSToolbarItem.Identifier("addProject")
    static let title = NSToolbarItem.Identifier("title")
    static let addThreads = NSToolbarItem.Identifier("addThreads")
    static let edit = NSToolbarItem.Identifier("edit")
    static let doneEditing = NSToolbarItem.Identifier("doneEditing")
    static let share = NSToolbarItem.Identifier("share")
    static let addCheckedToCollection = NSToolbarItem.Identifier("addCheckedToCollection")
}
