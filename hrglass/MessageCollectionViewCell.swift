//
//  MessageCollectionViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 9/10/17.
//
//

import UIKit

class MessageCollectionViewCell: UICollectionViewCell, UITextViewDelegate {
    
    
    @IBOutlet weak var textView: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        self.textView.delegate = self

        
    }
    
}
