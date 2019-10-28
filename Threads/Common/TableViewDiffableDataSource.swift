//
//  TableViewDiffableDataSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class TableViewDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: UITableViewDiffableDataSource<
    SectionIdentifierType, ItemIdentifierType
>
{
    typealias CanEditProvider = (UITableView, IndexPath, ItemIdentifierType) -> Bool

    var canEditRow: CanEditProvider = { (_, _, _) in false }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let item = itemIdentifier(for: indexPath) else { return false }
        return canEditRow(tableView, indexPath, item)
    }

    typealias SectionTitleProvider = (UITableView, Int, SectionIdentifierType) -> String?

    var sectionTitle: SectionTitleProvider = { (_, _, _) in nil }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
        -> String?
    {
        let sectionIdentifier = snapshot().sectionIdentifiers[section]
        return sectionTitle(tableView, section, sectionIdentifier)
    }
}
