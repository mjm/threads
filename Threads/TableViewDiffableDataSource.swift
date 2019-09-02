//
//  TableViewDiffableDataSource.swift
//  Threads
//
//  Created by Matt Moriarity on 9/2/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class TableViewDiffableDataSource<S: Hashable, I: Hashable>: UITableViewDiffableDataSource<S, I> {
    var isEditable = true
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditable
    }
}
