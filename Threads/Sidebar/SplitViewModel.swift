//
//  SplitViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 10/31/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import CoreData
import UIKit

final class SplitViewModel: ViewModel {
    enum Selection: Hashable {
        case collection
        case shoppingList
        case project(Project)
    }

    @Published var selection: Selection = .collection

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)
    }

    func bind(to sidebarModel: SidebarViewModel) {
        sidebarModel.$selectedItem.map { item in
            switch item {
            case .collection:
                return .collection
            case .shoppingList:
                return .shoppingList
            case .project(let model):
                return .project(model.project)
            }
        }.removeDuplicates().assign(to: \.selection, on: self).store(in: &cancellables)

        $selection.removeDuplicates().combineLatest(sidebarModel.$projectViewModels).compactMap {
            selection, projectModels -> SidebarViewModel.Item? in
            switch selection {
            case .collection:
                return .collection
            case .shoppingList:
                return .shoppingList
            case .project(let project):
                return projectModels.first { $0.project == project }.flatMap { .project($0) }
            }
        }.assign(to: \.selectedItem, on: sidebarModel).store(in: &cancellables)
    }

    // TODO bind to detail view
}
