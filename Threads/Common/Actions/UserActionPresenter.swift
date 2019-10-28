//
//  UserActionPresenter.swift
//  Threads
//
//  Created by Matt Moriarity on 10/27/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

protocol UserActionPresenter: class {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool)

    func present(
        _ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?
    )

    func dismiss(animated flag: Bool)
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

extension UserActionPresenter {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool) {
        present(viewControllerToPresent, animated: flag, completion: nil)
    }

    func dismiss(animated flag: Bool) {
        dismiss(animated: flag, completion: nil)
    }
}

extension UserActionPresenter {
    func present(error: Error, animated: Bool = true) {
        let error = error as NSError

        let alert = UIAlertController(
            title: error.localizedDescription,
            message: error.localizedFailureReason,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.dismiss, style: .cancel))

        present(alert, animated: animated)
    }
}

extension UIViewController: UserActionPresenter {}
