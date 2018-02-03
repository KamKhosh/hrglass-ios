//
//  NoPostsCollectionViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 11/21/17.
//

import UIKit

class NoPostsCollectionViewCell: UICollectionViewCell {
    
    let colors: Colors = Colors()
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var followBtn: UIButton!
    
    @IBOutlet weak var nameLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = colors.getBlackishColor()
        self.imageView.layer.cornerRadius = self.frame.width/2
        self.imageView.clipsToBounds = true
        self.imageView.layer.borderColor = UIColor.lightGray.cgColor
        self.imageView.layer.borderWidth = 2.0
    }
    
}
