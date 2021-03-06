//
//  ThreadDetailViewController.swift
//  Threads
//
//  Created by Matt Moriarity on 9/3/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import CombinableUI
import CoreData
import UIKit

extension ThreadDetailViewModel.Item: BindableCell {
    enum Identifier: String, CaseIterable, CellIdentifier {
        case details = "Details"
        case shoppingList = "ShoppingList"
        case project = "Project"

        var cellType: RegisteredCellType<UITableViewCell> {
            switch self {
            case .details: return .storyboard
            case .shoppingList: return .nib(ShoppingListThreadTableViewCell.self)
            case .project: return .class(ThreadProjectTableViewCell.self)
            }
        }
    }

    var cellIdentifier: Identifier {
        switch self {
        case .details: return .details
        case .shoppingList: return .shoppingList
        case .project: return .project
        }
    }

    func bind(to cell: UITableViewCell) {
        switch self {
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

        dataSource
            = DataSource(tableView)
            .titled([
                .shoppingList: Localized.inShoppingList,
                .projects: Localized.projects,
            ])
            .bound(to: viewModel.snapshot, animate: $animate)

        viewModel.number.map { number in
            String(format: Localized.dmcNumber, number!)
        }.assign(to: \.title, on: navigationItem).store(in: &cancellables)

        viewModel.userActivity.map { $0.userActivity }
            .assign(to: \.userActivity, on: self, weak: true)
            .store(in: &cancellables)
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

    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath),
            case .project(let projectModel) = item
        else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: viewModel.identifier(for: item),
            previewProvider: {
                UIStoryboard(name: "Projects", bundle: nil).instantiateViewController(
                    identifier: "ProjectPreview"
                ) { coder in
                    ProjectPreviewViewController(
                        coder: coder, project: projectModel.projectThread.project!)
                }
            }
        )
    }

    override func tableView(
        _ tableView: UITableView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let project = viewModel.project(for: configuration.identifier) else {
            return
        }

        animator.addAnimations {
            guard let scene = self.view.window?.windowScene else {
                return
            }

            scene.delegate?.scene?(scene, continue: UserActivity.showProject(project).userActivity)
        }
    }
}
