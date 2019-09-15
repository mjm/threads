//
//  Cells.swift
//  Threads
//
//  Created by Matt Moriarity on 9/15/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

extension UITableViewCell {
    class func registerNib(on tableView: UITableView, reuseIdentifier: String) {
        tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
    }
    
    class var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
}

extension UICollectionViewCell {
    class func registerNib(on collectionView: UICollectionView, reuseIdentifier: String) {
        collectionView.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    class var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
    
    class func makePrototype() -> Self {
        return nib.instantiate(withOwner: nil, options: nil).first as! Self
    }
}
