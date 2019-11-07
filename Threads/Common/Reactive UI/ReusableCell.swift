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

extension ReusableCell {
    static func register(with view: Identifier.CellType.View) {
        for identifier in allCellIdentifiers {
            identifier.register(with: view)
        }
    }
}

extension ReusableCell where Identifier: CaseIterable {
    static var allCellIdentifiers: [Identifier] {
        Array(Identifier.allCases)
    }
}

protocol CellIdentifier: RawRepresentable where RawValue == String {
    associatedtype CellType: Cell

    var cellType: RegisteredCellType<CellType> { get }
    func register(with: CellType.View)
}

extension CellIdentifier where CellType == UITableViewCell {
    func register(with tableView: UITableView) {
        switch cellType {
        case let .class(cellClass):
            tableView.register(cellClass, forCellReuseIdentifier: rawValue)
        case let .nib(cellClass):
            cellClass.registerNib(on: tableView, reuseIdentifier: rawValue)
        case .storyboard:
            break
        }
    }
}

extension CellIdentifier where CellType == UICollectionViewCell {
    func register(with collectionView: UICollectionView) {
        switch cellType {
        case let .class(cellClass):
            collectionView.register(cellClass, forCellWithReuseIdentifier: rawValue)
        case let .nib(cellClass):
            cellClass.registerNib(on: collectionView, reuseIdentifier: rawValue)
        case .storyboard:
            break
        }
    }
}

enum RegisteredCellType<T: Cell> {
    case `class`(T.Type)
    case nib(T.Type)
    case storyboard
}

protocol Cell {
    associatedtype View
}

extension UITableViewCell: Cell {
    typealias View = UITableView
}

extension UICollectionViewCell: Cell {
    typealias View = UICollectionView
}
