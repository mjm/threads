//
//  ReusableCell.swift
//  Threads
//
//  Created by Matt Moriarity on 11/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

protocol ReusableCell: Hashable {
    associatedtype Identifier: CellIdentifier

    var cellIdentifier: Identifier { get }

    static var allCellIdentifiers: [Identifier] { get }
}

extension ReusableCell where Identifier: CaseIterable {
    static var allCellIdentifiers: [Identifier] {
        Array(Identifier.allCases)
    }
}

extension ReusableCell where Identifier.CellType == UITableViewCell {
    static func register(with tableView: UITableView) {
        for identifier in allCellIdentifiers {
            switch identifier.cellType {
            case let .class(cellClass):
                tableView.register(cellClass, forCellReuseIdentifier: identifier.rawValue)
            case let .nib(cellClass):
                cellClass.registerNib(on: tableView, reuseIdentifier: identifier.rawValue)
            case .storyboard:
                break
            }
        }
    }
}

extension ReusableCell where Identifier.CellType == UICollectionViewCell {
    static func register(with collectionView: UICollectionView) {
        for identifier in allCellIdentifiers {
            switch identifier.cellType {
            case let .class(cellClass):
                collectionView.register(cellClass, forCellWithReuseIdentifier: identifier.rawValue)
            case let .nib(cellClass):
                cellClass.registerNib(on: collectionView, reuseIdentifier: identifier.rawValue)
            case .storyboard:
                break
            }
        }
    }
}

protocol CellIdentifier: RawRepresentable where RawValue == String {
    associatedtype CellType

    var cellType: RegisteredCellType<CellType> { get }
}

enum RegisteredCellType<T> {
    case `class`(T.Type)
    case nib(T.Type)
    case storyboard
}
