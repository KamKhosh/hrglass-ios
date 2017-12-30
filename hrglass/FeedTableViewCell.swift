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
    
    @IBOutlet weak var posterNameLbl: UILabel!
    
    @IBOutlet weak var timeRemainingLbl: UILabel!

    @IBOutlet weak var moodLbl: UILabel!
    
    @IBOutlet weak var likeBtn: UIButton!
    
    @IBOutlet weak var loadingIndication: UIActivityIndicatorView!
    
    @IBOutlet weak var playImageView: UIImageView!
    
    @IBOutlet weak var linkLbl: UILabel!
    
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
        
        if(likedByUser){
            
            //the post was previously liked by the user, set likedByUser to false
            if (postId != ""){
                self.likedByUser = false
                
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs_up_uncentered")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
                
                //decrement like count
                let likeCount: Int = Int(self.likeCountLbl.text!)!
                self.likeCountLbl.text = String(likeCount - 1)
                
                let postLikesRef = Database.database().reference().child("Posts").child(self.postUserId).child("likes")

                //remove current user from likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postUserId).child("users_who_liked").child(currentUserId)
                postLikesDictRef.removeValue()
                
                //remove post from user's liked posts
                let likedDictRef = Database.database().reference().child("Users").child(currentUserId).child("liked_posts").child(self.postUserId)
                likedDictRef.removeValue()
                
                postLikesRef.observeSingleEvent(of: .value, with: { snapshot in
                    
                    let likes = snapshot.value as? Int
                    
                    if likes != nil{

                        let tempNum = likes! - 1
                        postLikesRef.setValue(tempNum)

                        self.dataManager.getLikedPostsList(userId: self.currentUserId, completion: { snapshot in
                            
                            if let data: NSMutableDictionary = snapshot.mutableCopy() as? NSMutableDictionary{
                                
                                //Liked Dictionary Cleanup
                                let newdata: NSMutableDictionary = self.dataManager.postsCleanup(dictionary: data).mutableCopy() as! NSMutableDictionary
                                newdata.removeObject(forKey: self.postUserId)
                                
                                let tmp: NSMutableDictionary = self.postData.usersWhoLiked.mutableCopy() as! NSMutableDictionary
                                
                                tmp.removeObject(forKey: (Auth.auth().currentUser?.uid)!)
                                
                                self.postData.usersWhoLiked = tmp;
                                
                                self.postData.likes = tempNum
                                
                                //Fire the action in FEEDVIEWCONTROLLER cellForRowAt:
                                if let likeAction = self.newUsersDict
                                {
                                    likeAction()
                                }
                            }

                        })
                    }
                })
            }
            
            
        }else{
            //post wasn't liked by user, set likedByUser to true
            
            if (postId != ""){
                
                self.likedByUser = true
                
                //set thumb to be red tint
                let newImage: UIImage = UIImage.init(named: "thumbs_up_uncentered")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
            
//                let likeCount: Int = Int(self.likeCountLbl.text!)!
                
            
                let postLikesRef = Database.database().reference().child("Posts").child(self.postUserId).child("likes")
                
                
                //Add the current user to the likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postUserId).child("users_who_liked")
                postLikesDictRef.child(currentUserId).setValue(true)
                
                
                //increment views and update list
                self.dataManager.updateViewsList(post: self.postData, completion: { views in
                    
                    DispatchQueue.main.async {
                        self.viewCountLbl.text = String(views)
                    }
                })
                
                
                let likedDictRef = Database.database().reference().child("Users").child(self.currentUserId).child("liked_posts")
                
                //increment likes and update list
                postLikesRef.observeSingleEvent(of: .value, with: { snapshot in
                
                    var likes = snapshot.value as? Int
                    
                    if likes == nil{
                        likes = 0;
                    }
                    
                    let tempNum = likes! + 1
                    postLikesRef.setValue(tempNum)
                    self.likeCountLbl.text = String(tempNum)
                        
                    self.dataManager.getLikedPostsList(userId: self.currentUserId, completion: { snapshot in
                        
                        if let data: NSMutableDictionary = snapshot.mutableCopy() as? NSMutableDictionary{
                            
                            //make the value the time created (In Milliseconds since 1970) so we can remove from dictionary when appropriate
                            data.setValue(self.postData.expireTime, forKey:self.postUserId)
                            likedDictRef.setValue(data)
                            
                            let tmp: NSMutableDictionary = self.postData.usersWhoLiked.mutableCopy() as! NSMutableDictionary
                            
                            tmp.setValue(true, forKey: (Auth.auth().currentUser?.uid)!)
                            self.postData.usersWhoLiked = tmp;
                            
                            //set liked users dict and call action on tableView
                            self.postData.likes = tempNum
                            
                            if let likeAction = self.newUsersDict
                            {
                                likeAction()
                            }
                            
                        }
                    })
                })
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

