//
//  CustomMessageCell.swift
//  Circle Chat
//
//  Created by Dalton Teague on 7/22/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import Foundation
import UIKit
import MessageKit

open class CustomMessageCell: UICollectionViewCell {
    
    let label = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    open func setupSubviews() {
        contentView.addSubview(label)
        label.textAlignment = .center
        label.font = UIFont.italicSystemFont(ofSize: 13)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        // Do stuff
        switch message.kind {
        case .custom(let data):
            guard let systemMessage = data as? String else { return }
            label.text = systemMessage
        default:
            break
        }
    }
}

