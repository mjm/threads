//
//  BannerController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/21/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class BannerController: UIViewController {
    let message: String

    init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = presentationManager
        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("BannerController should only be created in code")
    }

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .systemIndigo
        view.isUserInteractionEnabled = true

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 20

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = message
        label.textColor = .white
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        stackView.addArrangedSubview(label)

        view.addSubview(stackView)

        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
        ])

        self.view = view
    }

}

private let presentationManager = BannerPresentationManager()

class BannerPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController, presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        BannerPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class BannerPresentationController: UIPresentationController {
    var dismissalTimer: Timer?

    override var shouldPresentInFullscreen: Bool { false }

    override var frameOfPresentedViewInContainerView: CGRect {
        // should have correct width because of constraint set in `presentationTransitionWillBegin`
        let size = presentedView!.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        let top: CGFloat
        if let tabBarController = presentingViewController as? UITabBarController {
            // if presenting in a tab bar controller, show the banner directly above the tabs
            let tabBar = tabBarController.tabBar
            let tabBarTop = containerView!.convert(tabBar.frame.origin, from: tabBar.superview).y
            top = max(0, tabBarTop - size.height)
        } else {
            // otherwise, show at the bottom of the screen
            top = containerView!.bounds.size.height - size.height
        }

        return CGRect(origin: CGPoint(x: 0, y: top), size: size)
    }

    override func presentationTransitionWillBegin() {
        let touchForwardingView = TouchForwardingView()
        touchForwardingView.translatesAutoresizingMaskIntoConstraints = false
        touchForwardingView.passthroughViews = [presentingViewController.view]
        containerView!.insertSubview(touchForwardingView, at: 0)

        NSLayoutConstraint.activate([
            containerView!.leadingAnchor.constraint(equalTo: touchForwardingView.leadingAnchor),
            containerView!.trailingAnchor.constraint(equalTo: touchForwardingView.trailingAnchor),
            containerView!.topAnchor.constraint(equalTo: touchForwardingView.topAnchor),
            containerView!.bottomAnchor.constraint(equalTo: touchForwardingView.bottomAnchor),
        ])

        presentedView!.widthAnchor.constraint(equalToConstant: containerView!.bounds.size.width)
            .isActive = true
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            dismissalTimer?.invalidate()
            dismissalTimer
                = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                    self?.presentingViewController.dismiss(animated: true)
                }
        }
    }
}

class TouchForwardingView: UIView {
    var passthroughViews: [UIView] = []

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        guard hitView == self else {
            return hitView
        }

        for passthroughView in passthroughViews {
            if let hitView = passthroughView.hitTest(
                convert(point, to: passthroughView), with: event)
            {
                return hitView
            }
        }

        return self
    }
}
