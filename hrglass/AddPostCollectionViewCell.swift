//
//  AddPostCollectionViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 6/13/17.
//
//

import UIKit

class AddPostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var playImage: UIImageView!
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var durationLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        playImage.isHidden = true
        
    }

}
