//
//  PostCollectionViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 5/15/17.
//
//

import UIKit

class ProfileCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var borderView: UIView!
    
    @IBOutlet weak var imageButton: UIButton!
    
    
    @IBOutlet weak var playImageView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    let post: PostData? = nil
    
    var contentSelected: (() -> Void)? = nil
    
    @IBAction func contentBtnAction(_ sender: Any) {
        
        if let contentBtnAction = self.contentSelected{
            
            contentBtnAction()
            
        }
    }
}
