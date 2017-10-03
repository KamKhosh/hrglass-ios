//
//  BlockedUserCell.swift
//  hrglass
//
//  Created by Justin Hershey on 5/9/17.
//
//

import UIKit
import Firebase

class BlockedUserCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var userNameLbl: UILabel!
    
    @IBOutlet weak var moreBtn: UIButton!
    
    var userDictionary: NSDictionary!
    
    var moreBtnSelected: (() -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    

    @IBAction func moreBtnAction(_ sender: Any) {
        
        
        if let moreBtnAction = self.moreBtnSelected{
            
            moreBtnAction()
            
        }
        
        
    }
    
    
    
    
}
