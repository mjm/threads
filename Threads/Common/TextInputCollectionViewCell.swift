//
//  TextInputCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class TextInputCollectionViewCell: UICollectionViewCell {
    @IBOutlet var textField: UITextField!
    
    var onReturn: () -> Void = {}
    var onChange: (String) -> Void = { _ in }
    
    @IBAction func textChanged() {
        onChange(textField.text ?? "")
    }
}

extension TextInputCollectionViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn()
        return true
    }
}
