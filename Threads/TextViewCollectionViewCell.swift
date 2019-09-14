//
//  TextInputCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

class TextViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var textView: UITextView!
    
//    var onReturn: () -> Void = {}
    var onChange: (NSAttributedString) -> Void = { _ in }

    static let nib = UINib(nibName: "TextViewCollectionViewCell", bundle: nil)
}

extension TextViewCollectionViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onChange(textView.attributedText)
    }
}

// source: https://medium.com/@georgetsifrikas/embedding-uitextview-inside-uitableviewcell-9a28794daf01
@IBDesignable
class NoPaddingTextView: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
    }
}
