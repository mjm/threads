//
//  ViewControllers.swift
//  Threads
//
//  Created by Matt Moriarity on 9/28/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

enum RegisteredCellType<T> {
    case `class`(T.Type)
    case nib(T.Type)
}

protocol ReusableCell: Hashable {
    var cellIdentifier: String { get }
}

// MARK: - Navigation Controller

class NavigationController: UINavigationController {
    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}
