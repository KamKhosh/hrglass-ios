//
//  DiscoverTableViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 6/25/17.
//
//

import UIKit
import Firebase

class DiscoverTableViewCell: UITableViewCell {

    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var followBtn: UIButton!
    @IBOutlet weak var activityInd: UIActivityIndicatorView!
    @IBOutlet weak var followerLbl: UILabel!
    @IBOutlet weak var followingLbl: UILabel!
    
    let dataManager: DataManager = DataManager()
    let colors: Colors = Colors()
    
    var userdata: User!
    var userId: String = ""
    
    var countObj : (() -> Void)? = nil
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.profilePhotoImageView.layer.cornerRadius = self.profilePhotoImageView.frame.width/2
        self.followBtn.layer.cornerRadius = 3
        self.followBtn.layer.borderColor = colors.getSearchBarColor().cgColor
        self.followBtn.layer.borderWidth = 1.0
        
        self.profilePhotoImageView.clipsToBounds = true
        self.profilePhotoImageView.contentMode = .scaleAspectFill
    }
    
    
    
    @IBAction func followAction(_ sender: Any) {
        
//        let userData: User = dataManager.setupUserData(data: self.userdata.mutableCopy() as! NSMutableDictionary, uid: self.userId)
        
        if (self.followBtn.titleLabel?.text == "Follow" ){
            
            dataManager.addToFollowerList(userId: self.userdata.userID, privateAccount: self.userdata.isPrivate)
            
            if (self.userdata.isPrivate){
                followBtn.setTitle("Unrequest", for: .normal)
            }else{
                
                followBtn.setTitle("Unfollow", for: .normal)
            }
            
            followBtn.setTitleColor(colors.getSearchBarColor(), for: .normal)
            followBtn.backgroundColor = UIColor.clear
            
            if let followAction = self.countObj{
                followAction()
            }
            
        
            
        }else if (self.followBtn.titleLabel?.text == "Unfollow" || self.followBtn.titleLabel?.text == "Unrequest"){
            
            dataManager.removeFromFollowerList(userId: self.userdata.userID)

            followBtn.setTitle("Follow", for: .normal)
            
            followBtn.setTitleColor(UIColor.white, for: .normal)
            followBtn.backgroundColor = colors.getSearchBarColor()
            
            if let followAction = self.countObj{
                followAction()
            }
            
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
