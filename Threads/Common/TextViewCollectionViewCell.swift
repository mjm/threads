//
//  TextInputCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import Combine
import UIKit

class TextViewCollectionViewCell: ReactiveCollectionViewCell {
    @IBOutlet var textView: UITextView!

    let onChange = PassthroughSubject<NSAttributedString?, Never>()

    func bind<Root: NSObject>(
        to path: ReferenceWritableKeyPath<Root, NSAttributedString?>, on root: Root
    ) {
        root.publisher(for: path).assign(to: \.attributedText, on: textView).store(
            in: &cancellables)
        onChange.assign(to: path, on: root).store(in: &cancellables)
    }
}

extension TextViewCollectionViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onChange.send(textView.attributedText)
    }
}

// source: https://medium.com/@georgetsifrikas/embedding-uitextview-inside-uitableviewcell-9a28794daf01
@IBDesignable
class SidePaddingTextView: UITextView {
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        textContainer.lineFragmentPadding = 0
    }
}
