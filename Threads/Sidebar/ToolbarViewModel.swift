//
//  ToolbarViewModel.swift
//  Threads
//
//  Created by Matt Moriarity on 11/1/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

final class ToolbarViewModel: ViewModel {
    #if targetEnvironment(macCatalyst)
    @Published var itemProvider: ToolbarItemProviding?

    @Published private(set) var leadingItems: [NSToolbarItem.Identifier] = []
    @Published private(set) var trailingItems: [NSToolbarItem.Identifier] = []
    @Published private(set) var title: String = ""

    private var itemProviderSubscriptions = Set<AnyCancellable>()

    override init(context: NSManagedObjectContext = .view) {
        super.init(context: context)

        $itemProvider.sink { [weak self] itemProvider in
            guard let self = self else { return }
            self.itemProviderSubscriptions.removeAll()

            guard let itemProvider = itemProvider else { return }

            itemProvider.title.assign(to: \.title, on: self).store(
                in: &self.itemProviderSubscriptions)
            itemProvider.leadingToolbarItems.assign(to: \.leadingItems, on: self).store(
                in: &self.itemProviderSubscriptions)
            itemProvider.trailingToolbarItems.assign(to: \.trailingItems, on: self).store(
                in: &self.itemProviderSubscriptions)
        }.store(in: &cancellables)
    }

    var items: AnyPublisher<[NSToolbarItem.Identifier], Never> {
        $leadingItems.combineLatest($trailingItems) { leading, trailing in
            var items: [NSToolbarItem.Identifier] = [
                .addProject,
                .title,
                .flexibleSpace,
            ]

            items.append(contentsOf: leading)
            items.append(contentsOf: [.addThreads, .share])
            items.append(contentsOf: trailing)

            return items
        }.eraseToAnyPublisher()
    }
    #endif
}

#if targetEnvironment(macCatalyst)
protocol ToolbarItemProviding {
    var title: AnyPublisher<String, Never> { get }
    var leadingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> { get }
    var trailingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> { get }
}

extension ToolbarItemProviding {
    var leadingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var trailingToolbarItems: AnyPublisher<[NSToolbarItem.Identifier], Never> {
        Just([]).eraseToAnyPublisher()
    }
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
#endif
