//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

extension ThreadDetailViewModel.Item: ReusableCell {
    var cellIdentifier: String {
        switch self {
        case .details: return "Details"
        case .shoppingList: return "ShoppingList"
        case .project: return "Project"
        }
    }
}

class ThreadDetailViewController: ReactiveTableViewController<ThreadDetailViewModel> {
    let viewModel: ThreadDetailViewModel

    @IBOutlet var actionsButtonItem: UIBarButtonItem!

    init?(coder: NSCoder, thread: Thread) {
        viewModel = ThreadDetailViewModel(thread: thread)
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("ThreadDetailViewController should be created in an IBSegueAction")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let color = viewModel.thread.color {
            let textColor = color.labelColor

            let appearance = navigationController!.navigationBar.standardAppearance.copy()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            appearance.titleTextAttributes[.foregroundColor] = textColor
            appearance.largeTitleTextAttributes[.foregroundColor] = textColor
            appearance.largeTitleTextAttributes[.font]
                = {
                    let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
                    let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .heavy)
                    return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
                }()
            appearance.buttonAppearance.normal.titleTextAttributes[.foregroundColor] = textColor
            navigationItem.standardAppearance = appearance.copy()

            appearance.shadowColor = nil
            navigationItem.scrollEdgeAppearance = appearance.copy()
        }
    }

    override func subscribe() {
        viewModel.presenter = self

        viewModel.number.map { number in
            String(format: Localized.dmcNumber, number!)
        }.assign(to: \.title, on: navigationItem).store(in: &cancellables)

        viewModel.snapshot.apply(to: dataSource, animate: $animate).store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }.assign(to: \.userActivity, on: self).store(
            in: &cancellables)
    }

    override func dataSourceWillInitialize() {
        dataSource.sectionTitle = { _, _, section in
            switch section {
            case .details:
                return nil
            case .shoppingList:
                return Localized.inShoppingList
            case .projects:
                return Localized.projects
            }
        }
    }

    override var cellTypes: [String: RegisteredCellType<UITableViewCell>] {
        [
            "ShoppingList": .nib(ShoppingListThreadTableViewCell.self),
            "Project": .class(ThreadProjectTableViewCell.self),
        ]
    }

    private var shoppingListSubscription: AnyCancellable?

    override func populate(cell: UITableViewCell, item: ThreadDetailViewModel.Item) {
        switch item {

        case .details(let model):
            let cell = cell as! ThreadDetailsTableViewCell
            cell.bind(model)

        case .shoppingList(let model):
            let cell = cell as! ShoppingListThreadTableViewCell
            cell.bind(model)

        case .project(let model):
            let cell = cell as! ThreadProjectTableViewCell
            cell.bind(model)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let textColor = viewModel.thread.color?.labelColor, textColor == .white {
            return .lightContent
        } else {
            return .darkContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.tintColor = viewModel.thread.color?.labelColor
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor = nil
    }
}

// MARK: - Actions
extension ThreadDetailViewController {
    @IBAction func showActions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.barButtonItem = actionsButtonItem

        for action in viewModel.menuActions {
            sheet.addAction(action.alertAction())
        }

        sheet.addAction(
            viewModel.removeAction.alertAction(willPerform: {
                self.userActivity = nil
            }) {
                self.performSegue(withIdentifier: "DeleteThread", sender: nil)
            })

        sheet.addAction(UIAlertAction(title: Localized.cancel, style: .cancel))

        present(sheet, animated: true)
    }
}

// MARK: - Table View Delegate
extension ThreadDetailViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath)
        -> IndexPath?
    {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        if case .project = item {
            return indexPath
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource.itemIdentifier(for: indexPath) {
        case let .project(model):
            guard let activity = model.destinationActivity,
                let scene = view.window?.windowScene
            else {
                return
            }

            let sceneDelegate = scene.delegate as! SceneDelegate
            sceneDelegate.scene(scene, continue: activity.userActivity)

        default:
            return
        }
    }
}
