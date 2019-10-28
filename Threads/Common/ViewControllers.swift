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

// MARK: - View Controller Extensions

extension UIViewController {
    func present(error: Error, animated: Bool = true) {
        let alert = UIAlertController(
            title: Localized.errorOccurred,
            message: error.localizedDescription,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.dismiss, style: .cancel))

        present(alert, animated: animated)
    }
}
