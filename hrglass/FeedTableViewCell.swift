//
//  FeedViewControllerCellTableViewCell.swift
//  hrglass
//
//  Created by Justin Hershey on 4/27/17.
//
//

import UIKit
import Firebase




class FeedTableViewCell: UITableViewCell {

    @IBOutlet weak var moreBtn: UIButton!
    
    @IBOutlet weak var viewsBtn: UIButton!
    
    @IBOutlet weak var categoryLbl: UILabel!
    
    @IBOutlet weak var viewCountLbl: UILabel!
    
    @IBOutlet weak var likeCountLbl: UILabel!
    
    @IBOutlet weak var previewContentView: UIView!
    
    @IBOutlet weak var contentImageBtn: UIButton!
    
    @IBOutlet weak var profileImageBtn: UIButton!
    
    @IBOutlet weak var posterUsernameLbl: UILabel!
    
    @IBOutlet weak var timeRemainingLbl: UILabel!

    @IBOutlet weak var moodLbl: UILabel!
    
    @IBOutlet weak var likeBtn: UIButton!
    
    @IBOutlet weak var loadingIndication: UIActivityIndicatorView!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    @IBOutlet weak var linkLbl: UILabel!
    
    @IBOutlet weak var nsfwLbl: UILabel!
    
    @IBOutlet weak var profileView: UIView!
    
    
    var likedByUser: Bool = false
    
    var postId: String = ""
    var postUserId: String = ""
    
    let dataManager: DataManager = DataManager()
    
    var postData: PostData!
    
    
    //Constraints used to change content shape based on circle or square post
    @IBOutlet weak var postPreviewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var postPreviewHeightConstraint: NSLayoutConstraint!
    
    
    var newUsersDict : (() -> Void)? = nil
    var userProfile: (() -> Void)? = nil
    var contentSelected: (() -> Void)? = nil
    var moreBtnSelected: (() -> Void)? = nil
//    var likeBtnSelected: (() -> Void)? = nil
    let currentUserId: String = Auth.auth().currentUser!.uid
    
    
    /**************************************************************************
     *
     *                  CELL BUTTON ACTIONS
     *
     *    -- Relays to FeedViewController Table View Cell what actions to Perform
     *
     ***************************************************************************/
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.previewContentView.layer.cornerRadius = self.previewContentView.frame.height/2
    }
    


    @IBAction func moreBtnAction(_ sender: Any) {
        
        if let moreBtnAction = self.moreBtnSelected{
            
            moreBtnAction()
            
        }
    }

    @IBAction func profileBtnAction(_ sender: Any) {
        
        if let profileBtnAction = self.userProfile{
            
            profileBtnAction()
        }
    }
    
    
    
    @IBAction func contentBtnAction(_ sender: Any) {
        
        if let contentBtnAction = self.contentSelected{
            
            contentBtnAction()
        }
    }
    


    
    
    
    /**************************************************************************
     *          ACTIONS
     *
     *  - LikeBtn Action -- increment/decrement like count, change button color
     *
     ***************************************************************************/
    
    
    @IBAction func likeAction(_ sender: Any) {
        
        
        
//        if let likeAction = self.likeBtnSelected{
//
//            likeAction()
//        }
//
        if(likedByUser){
            
            //the post was previously liked by the user, set likedByUser to false
            if (postId != ""){
                self.likedByUser = false
                self.profileView.isHidden = true
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs_up_uncentered")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
                
                //decrement local like count
                let likes = self.postData.likes
                if likes > 0{
                    self.likeCountLbl.text = String(likes - 1)
                    self.postData.likes = likes - 1
                }
                
                
                //remove current user from likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postUserId).child("users_who_liked").child(currentUserId)
                postLikesDictRef.removeValue()

                //remove post from user's liked posts
                let likedDictRef = Database.database().reference().child("Users").child(currentUserId).child("liked_posts").child(self.postUserId)
                likedDictRef.removeValue()
                
                if let likeAction = self.newUsersDict{
                        likeAction()
                }
            }
            
            
        }else{
            //post wasn't liked by user, set likedByUser to true
            
            if (postId != ""){
                
                self.likedByUser = true
                self.profileView.isHidden = false
                
                //set thumb to be red tint
                let newImage: UIImage = UIImage.init(named: "thumbs_up_uncentered")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
            

//                //Add the current user to the likes list
                print("Updating Likes Lists")
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postUserId).child("users_who_liked").child(currentUserId)
                postLikesDictRef.setValue(true)
                
                let likedDictRef = Database.database().reference().child("Users").child(self.currentUserId).child("liked_posts").child(self.postUserId)
                likedDictRef.setValue(self.postData.expireTime)
//
                
                //increment views and update list in Firebase
                self.dataManager.updateViewsList(post: self.postData)
                
                //update local counts for views if I haven't viewed yet
                let myUid = Auth.auth().currentUser?.uid
                if(self.postData.usersWhoViewed.value(forKey:myUid!) == nil){
                    let views = self.postData.views + 1
                    self.viewCountLbl.text = String(views)
                    self.postData.views = views
                    
                    //check for empty dictionary
                    if self.postData.usersWhoViewed.count == 0{
                        self.postData.usersWhoViewed = NSDictionary.init(dictionary: [myUid ?? "":true])
                     }else{
                        self.postData.usersWhoViewed.setValue(true, forKey: myUid!)
                    }
                    
                }
                
                let likes = self.postData.likes + 1
                self.likeCountLbl.text = String(likes)
                self.postData.likes = likes
                
                //check for empty dictionary
                if self.postData.usersWhoLiked.count == 0{
                    self.postData.usersWhoLiked = NSDictionary.init(dictionary: [myUid ?? "":true])
                }else{
                    self.postData.usersWhoLiked.setValue(true, forKey: myUid!)
                }
                
                
                if let likeAction = self.newUsersDict{
                    likeAction()
                }
            }
        }
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
}


//UIImage extention to chang the context Color of the image passed to it

extension UIImage {
    
    func transform(withNewColor color: UIColor) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.clip(to: rect, mask: cgImage!)
        
        color.setFill()
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
        
    }
}

