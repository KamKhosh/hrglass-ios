//
//  CollectionViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 5/23/17.
//
//

import UIKit

class AllPostsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var borderView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    let post: PostData? = nil
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    var moreBtnSelected: (() -> Void)? = nil
    
    
    
    @IBAction func moreBtnAction(_ sender: Any) {
        
        if let moreBtnAction = self.moreBtnSelected{
            
            moreBtnAction()
            
        }
    }
    
}
