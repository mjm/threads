//
//  SwatchView.swift
//  Threads
//
//  Created by Matt Moriarity on 9/4/19.
//  Copyright © 2019 Matt Moriarity. All rights reserved.
//

import UIKit

@IBDesignable
class SwatchView: UIView {

    @IBInspectable
    var color: UIColor = .systemBackground {
        didSet {
            colorView.backgroundColor = color
        }
    }
    
    @IBInspectable
    var cornerRadius: CGFloat = 0 {
        didSet {
            colorView.layer.cornerRadius = cornerRadius
        }
    }
    
    private let colorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createSubviews()
    }
    
    private func createSubviews() {
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 0
        
        colorView.layer.shadowColor = UIColor.systemGray.cgColor
        colorView.layer.shadowOffset = CGSize(width: 0, height: 0)
        colorView.layer.shadowRadius = 2
        colorView.layer.shadowOpacity = 0.7
        
        addSubview(colorView)
        
        topAnchor.constraint(equalTo: colorView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: colorView.bottomAnchor).isActive = true
        leadingAnchor.constraint(equalTo: colorView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: colorView.trailingAnchor).isActive = true
    }
}
