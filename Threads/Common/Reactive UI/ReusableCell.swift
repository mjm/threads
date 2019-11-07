//
//  ReusableCell.swift
//  Threads
//
//  Created by Matt Moriarity on 11/6/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

protocol ReusableCell: Hashable {
    var cellIdentifier: String { get }
}
