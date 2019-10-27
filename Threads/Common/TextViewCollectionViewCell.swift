//
//  TextInputCollectionViewCell.swift
//  Threads
//
//  Created by Matt Moriarity on 9/13/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit
import Combine

class TextViewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var textView: UITextView!
    
    var cancellables = Set<AnyCancellable>()
    
    let onChange = PassthroughSubject<NSAttributedString?, Never>()
    
    func textPublisher() -> AnyPublisher<NSAttributedString?, Never> {
        onChange.eraseToAnyPublisher()
    }
    
    func bind<Root: NSObject>(to path: ReferenceWritableKeyPath<Root, NSAttributedString?>, on root: Root) {
        root.publisher(for: path).assign(to: \.attributedText, on: textView).store(in: &cancellables)
        textPublisher().assign(to: path, on: root).store(in: &cancellables)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cancellables.removeAll()
    }
}

extension TextViewCollectionViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onChange.send(textView.attributedText)
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
