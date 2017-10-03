//
//  PostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 8/16/17.
//
//

import UIKit
import AVFoundation
import AVKit
import Firebase



class PostViewController: UIViewController, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate
{

    
    var postData: PostData!
 
    //Managers
    let dataManager: DataManager = DataManager()
    var imageCache: ImageCache = ImageCache()
    var videoCache: VideoStore = VideoStore()
    let awsManager: AWSManager = AWSManager()
    var avPlayerViewController: AVPlayerViewController!
    
    //Storyboard Outlets
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var timeRemainingLbl: UILabel!
    @IBOutlet weak var minimizeBtn: UIButton!
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var commentBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var songImageView: UIImageView!
    @IBOutlet weak var artistLbl: UILabel!
    @IBOutlet weak var songNameLbl: UILabel!
    @IBOutlet weak var captionLbl: UILabel!
    @IBOutlet weak var playMusicBtn: UIButton!
    @IBOutlet weak var playContentBtn: UIButton!
    @IBOutlet weak var songView: UIView!
    

    
    
    @IBOutlet weak var linkLbl: UILabel!

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var popupView: UIView!
    
    @IBOutlet weak var alphaView: UIView!
    
    var likedByUser: Bool = false
    var currentUserId: String = ""
    var hub: RKNotificationHub!
    var commentData: NSDictionary!
    
    
    @IBOutlet weak var shadowView: UIView!
    //secondary view relevant variables and outlets
    @IBOutlet weak var showHideSecondaryView: UIButton!
    @IBOutlet weak var secondaryPostView: UIView!
    @IBOutlet weak var secondaryContentImageView: UIImageView!
    @IBOutlet weak var postContainerPlaceholder: UIView!
    @IBOutlet weak var firstPostView: UIView!
    @IBOutlet weak var secondaryPostPlayBtn: UIButton!
    @IBOutlet weak var secondaryLinkLbl: UILabel!
    
    var secondaryViewIsShowing: Bool = false
    var swipeLeftGesture: UISwipeGestureRecognizer!
    var swipeRightGesture: UISwipeGestureRecognizer!
    
    
    
    @IBOutlet weak var postCurrentlyViewingStackView: UIStackView!
    
    @IBOutlet weak var firstPostCircle: UIView!
    
    @IBOutlet weak var secondPostCircle: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
//        self.view.addGestureRecognizer(panGesture)
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.clipsToBounds = false
        
        self.currentUserId = Auth.auth().currentUser!.uid
        
        self.viewSetup()
        self.dataSetup()
        

        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.alphaView.frame.size = CGSize(width: self.contentView.frame.size.width * 3.0 , height: self.contentView.frame.size.height * 3.0)
 
    }
    
    
    
    deinit {
        
//        NotificationCenter.default.removeObserver(self)
        
    }
    
    
    func viewSetup(){
        
        self.songImageView.layer.cornerRadius = self.songImageView.frame.width/2
        self.songImageView.clipsToBounds = true
        self.songImageView.contentMode = .scaleAspectFill
        
        self.profilePhotoImageView.layer.cornerRadius = self.profilePhotoImageView.frame.width/2
        self.profilePhotoImageView.clipsToBounds = true
        self.profilePhotoImageView.contentMode = .scaleAspectFill
        
        self.popupView.layer.cornerRadius = 8.0
        self.popupView.layer.masksToBounds = true
        self.popupView.clipsToBounds = true
        self.popupView.layer.shadowColor = UIColor.black.cgColor
        self.popupView.layer.shadowOpacity = 0.3
        self.popupView.layer.shadowRadius = 5
        self.popupView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.popupView.layer.shadowPath = UIBezierPath(rect: self.popupView.bounds).cgPath
        
        
        self.shadowView.layer.cornerRadius = 8.0
        self.shadowView.layer.masksToBounds = false
        self.shadowView.layer.shadowColor = UIColor.black.cgColor
        self.shadowView.layer.shadowOpacity = 0.3
        self.shadowView.layer.shadowRadius = 5
        self.shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.shadowView.layer.shadowPath = UIBezierPath(rect: self.popupView.bounds).cgPath
        
        
        hub = RKNotificationHub(view: self.commentBtn)
        
        
    }
    
    
    
    
    
    

    
    
    
    func dataSetup(){
        
        self.songView.isHidden = true
        self.playContentBtn.isHidden = true
        self.postCurrentlyViewingStackView.isHidden = true
        
        if (self.postData != nil) {
            
            let user: NSDictionary = postData.user
            
            //setup secondary data if applicable
            if self.postData.secondaryPost != nil{
                
                self.postCurrentlyViewingStackView.isHidden = false
                self.setupViewingStackView()
                self.setupSecondaryPostView(user: user, secondaryPostData: self.postData.secondaryPost)
            }
            
            

            let name: String = user.value(forKey: "name") as! String
            
            self.nameLbl.text = name
            self.timeRemainingLbl.text = dataManager.getTimeString(expireTime: postData.expireTime)
            
            imageCache.getImage(urlString: user.value(forKey: "profilePhoto") as! String, completion: { (image) in
                self.profilePhotoImageView.image = image
            })
            
            
            //get ALL comments and set the count
            dataManager.getCommentDataFromFirebase(uid: user.value(forKey: "uid") as! String, completion: { (comments) in
                
                if comments.count > 0{
                    
                    self.hub.count = comments.count
                    self.hub.pop()
                }else{
                    
                    self.hub.count = 0
                    self.hub.checkZero()
                }
            })
            
            
            
            
            //SETUP LIKES
            if let likedDict: NSDictionary = self.postData.usersWhoLiked {
                
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                
                if (likedDict.value(forKey: self.currentUserId) != nil){
                    
                    self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                    self.likedByUser = true
                    
                }else{
                    
                    self.likeBtn.setImage(newImage, for: .normal)
                    self.likedByUser = false
                }
            }
            
            
            //TODO: SETUP COMMENTS
            switch self.postData.category {
            
            case .Photo:
                print("")
                imageCache.getImage(urlString: self.postData.value(forKey: "data") as! String, completion: { (image) in
                    self.contentImageView.image = image
                })
            case .Video:
                print("")
                //thumbnail URL
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
                
                imageCache.getImage(urlString: thumbnailURL, completion: { (image) in
                    self.contentImageView.image = image
                })
                self.playContentBtn.isHidden = false
                
            case .Recording:

                self.contentImageView.image = UIImage(named:"audioWave")
                
            case .Music:

                self.songView.isHidden = false
                
                
            case .Text:
                print("")
                imageCache.getImage(urlString: self.postData.value(forKey: "data") as! String, completion: { (image) in
                    self.contentImageView.image = image
                })
                
            case .Link:
                print("")
                self.linkLbl.isHidden = false
                self.playContentBtn.setImage(self.dataManager.clearImage, for: .normal)
                
                self.dataManager.setURLView(urlString: self.postData.data as String, completion: { (image, label) in
                    
                    self.contentImageView.image = image
                    
                    self.linkLbl.adjustsFontSizeToFitWidth = true
                    self.linkLbl.numberOfLines = 3
                    self.linkLbl.backgroundColor = UIColor.darkGray
                    self.linkLbl.alpha = 0.7
                    self.linkLbl.text = label
                    self.linkLbl.textAlignment = .center
                    self.linkLbl.textColor = UIColor.white
                    self.linkLbl.isHidden = false
                    
                })
            default:
                print("")
            }
        }
    }
    
    
    
    
    
    
    
    
    func setupSecondaryPostView(user: NSDictionary, secondaryPostData:NSDictionary){
        
        self.swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeLeftHandler))
        
        self.swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeRightHandler))
        
        self.swipeLeftGesture.delegate = self
        self.swipeRightGesture.delegate = self
        
        self.swipeLeftGesture.direction = .left
        self.swipeRightGesture.direction = .right
        self.swipeRightGesture.numberOfTouchesRequired = 1;
        self.swipeLeftGesture.numberOfTouchesRequired = 1;
        
        self.firstPostView.addGestureRecognizer(swipeLeftGesture)
        self.secondaryPostView.addGestureRecognizer(swipeRightGesture)
        
        self.secondaryLinkLbl.isHidden = true
        self.secondaryPostPlayBtn.isHidden = true
        let cat: Category = Category(rawValue: secondaryPostData.value(forKey: "secondaryCategory") as! String)!

        //TODO: SETUP COMMENTS
        switch cat {
            
        case .Photo:
            print("")
            imageCache.getImage(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image) in
                self.secondaryContentImageView.image = image
            })
        case .Video:
            print("")
            //thumbnail URL
            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
            
            imageCache.getImage(urlString: thumbnailURL, completion: { (image) in
                self.secondaryContentImageView.image = image
            })
            self.secondaryPostPlayBtn.isHidden = false
            
        case .Recording:
            
            self.secondaryContentImageView.image = UIImage(named:"audioWave")
            
        case .Music:
            
            self.songView.isHidden = false
            self.firstPostView.removeGestureRecognizer(swipeLeftGesture)
            self.secondaryPostView.removeGestureRecognizer(swipeRightGesture)
            self.postCurrentlyViewingStackView.isHidden = true
            
        case .Text:
            print("")
            imageCache.getImage(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image) in
                self.secondaryContentImageView.image = image
            })
            
        case .Link:
            print("")
            self.secondaryLinkLbl.isHidden = false
            self.secondaryPostPlayBtn.setImage(self.dataManager.clearImage, for: .normal)
            
            self.dataManager.setURLView(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image, label) in
                
                self.secondaryContentImageView.image = image
                
                self.secondaryLinkLbl.adjustsFontSizeToFitWidth = true
                self.secondaryLinkLbl.numberOfLines = 3
                self.secondaryLinkLbl.backgroundColor = UIColor.darkGray
                self.secondaryLinkLbl.alpha = 0.7
                self.secondaryLinkLbl.text = label
                self.secondaryLinkLbl.textAlignment = .center
                self.secondaryLinkLbl.textColor = UIColor.white
                self.secondaryLinkLbl.isHidden = false
                
            })
        default:
            print("")
        }
    }
    
    
    
    
    func setupViewingStackView(){
        
        self.firstPostCircle.layer.cornerRadius = 3.0
        self.secondPostCircle.layer.cornerRadius = 3.0
        
        
    }
    
    
    
    
    
    /***********************
     *
     *  STORYBOARD ACTIONS
     *
     **********************/
    
    

    
    @IBAction func minimizeAction(_ sender: Any) {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.popupView.transform = CGAffineTransform(translationX: 0, y: 1000)
            
        }){ (success) in
            if success{
                self.willMove(toParentViewController: nil)
                self.view.removeFromSuperview()
                self.removeFromParentViewController()
            }
        }
    }
    
    
    
    @IBAction func likeAction(_ sender: Any) {
        
        let postId:String = self.postData.postId
        let postUserId: String = self.postData.user.value(forKey: "uid") as! String

        if(likedByUser){
            
            if (postId != ""){
                self.likedByUser = false
                
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage, for: .normal)
                
                //decrement like count
//               let likeCount: Int = self.postData.likes

                
                let postLikesRef = Database.database().reference().child("Posts").child(postUserId).child("likes")
                
                //remove current user from likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(postUserId).child("users_who_liked").child(currentUserId)
                postLikesDictRef.removeValue()
                
                let likedDictRef = Database.database().reference().child("Users").child(currentUserId).child("liked_posts")
                
                postLikesRef.observeSingleEvent(of: .value, with: { snapshot in
                    
                    let likes = snapshot.value as? Int
                    
                    if likes != nil{
                        
                        let tempNum = likes! - 1
                        postLikesRef.setValue(tempNum)
                        
                        self.dataManager.getLikedPostsList(userId: self.currentUserId, completion: { snapshot in
                            
                            if let data: NSMutableDictionary = snapshot.mutableCopy() as? NSMutableDictionary{
                                
                                //Liked Dictionary Cleanup
                                //Uncomment and change 2 lines below when post timing is in place
                                let newdata: NSMutableDictionary = self.dataManager.postsCleanup(dictionary: data).mutableCopy() as! NSMutableDictionary
                                
                                newdata.removeObject(forKey: postUserId)
                                likedDictRef.setValue(newdata)
                                
                                
                                let tmp: NSMutableDictionary = self.postData.usersWhoLiked.mutableCopy() as! NSMutableDictionary
                                
                                tmp.removeObject(forKey: (Auth.auth().currentUser?.uid)!)
                                
                                self.postData.usersWhoLiked = tmp;
                                
                                self.postData.likes = tempNum
                                
                                //Fire the action in FEEDVIEWCONTROLLER cellForRowAt:
//                                if let likeAction = self.newUsersDict
//                                {
//                                    likeAction()
//                                }
                            }
                            
                        })
                    }
                })
            }
            
            
        }else{
            
            
            if (postId != ""){
                
                self.likedByUser = true
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                
//                let likeCount: Int = self.postData.likes
                
                let postLikesRef = Database.database().reference().child("Posts").child(postUserId).child("likes")
                
                //Add the current user to the likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(postUserId).child("users_who_liked")
                postLikesDictRef.child(currentUserId).setValue(true)
                
                
                let likedDictRef = Database.database().reference().child("Users").child(self.currentUserId).child("liked_posts")
                
                
                //increment likes and update list
                postLikesRef.observeSingleEvent(of: .value, with: { snapshot in
                    
                    let likes = snapshot.value as? Int
                    
                    if likes != nil{
                        
                        let tempNum = likes! + 1
                        postLikesRef.setValue(tempNum)
                        
                        
                        self.dataManager.getLikedPostsList(userId: self.currentUserId, completion: { snapshot in
                            
                            if let data: NSMutableDictionary = snapshot.mutableCopy() as? NSMutableDictionary{
                                
                                //make the value the time created (In Milliseconds since 1970) so we can remove from dictionary when appropriate
                                data.setValue(self.postData.expireTime, forKey:postUserId)
                                likedDictRef.setValue(data)
                                
                                let tmp: NSMutableDictionary = self.postData.usersWhoLiked.mutableCopy() as! NSMutableDictionary
                                
                                tmp.setValue(true, forKey: (Auth.auth().currentUser?.uid)!)
                                self.postData.usersWhoLiked = tmp;
                                
                                //set liked users dict and call action on tableView
                                self.postData.likes = tempNum
                                
//                                if let likeAction = self.newUsersDict
//                                {
//                                    likeAction()
//                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    @IBAction func commentsAction(_ sender: Any) {
        
        let commentsVC: CommentViewController = storyboard!.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        
        commentsVC.viewingUserId = self.postData.user.value(forKey: "uid") as! String
        
        if self.commentData != nil{
            
            commentsVC.commentData = self.commentData
        }

        addChildViewController(commentsVC)
        
        commentsVC.view.frame = view.bounds
        commentsVC.alphaView.backgroundColor = UIColor.clear
        
        view.addSubview(commentsVC.view)
        commentsVC.didMove(toParentViewController: self)
        
    }
    
    
    
    @IBAction func moreBtnAction(_ sender: Any) {
        
        
    }
    
    

    
    
    
    
    @IBAction func playContentBtn(_ sender: Any) {
        
        self.playContentBtn.isHidden = true
        
        switch self.postData.category {
        
        case .Video:
            
            playURLData(urlString: self.postData.data, uid:self.postData.user.value(forKey: "uid") as! String, primary: true)
            
        case .Recording:
            print("")
            
            self.playURLData(urlString: self.postData.data, uid:self.postData.user.value(forKey: "uid") as! String, primary: true)
        case .Link:
            
            let urlString = self.postData.data
            
            //Image will already be cached so we shouldn't need to use a loading indicator
            UIApplication.shared.open(URL(string: urlString)!)

        default:
            
            print("")
        }
    }
    
    
    @IBAction func secondaryPlayAction(_ sender: Any) {
        
        self.secondaryPostPlayBtn.isHidden = true
        
        let sData: String =  self.postData.secondaryPost.value(forKey: "secondaryData") as! String
        let sCat: Category = Category(rawValue: self.postData.secondaryPost.value(forKey: "secondaryCategory") as! String)!
        
        switch sCat {
            
        case .Video:
            
            playURLData(urlString: sData, uid: self.postData.user.value(forKey: "uid") as! String, primary: false)
            
        case .Recording:
            print("")
            
            self.playURLData(urlString: sData, uid: self.postData.user.value(forKey: "uid") as! String, primary:  false)
        case .Link:
            
            let urlString = sData
            
            //Image will already be cached so we shouldn't need to use a loading indicator
            UIApplication.shared.open(URL(string: urlString)!)
            
        default:
            
            print("")
        }
    }
    
    
    
    @IBAction func playPauseSongAction(_ sender: Any) {
        
        
    }
    


    //SWIPE GESTURE Handlers
    func swipeLeftHandler(){
        
        UIView.animate(withDuration: 0.3) { 
            
            self.secondPostCircle.backgroundColor = UIColor.darkGray
            self.firstPostCircle.backgroundColor = UIColor.lightGray
            self.firstPostView.center = CGPoint(x: self.postContainerPlaceholder.center.x - self.firstPostView.frame.width,y: self.postContainerPlaceholder.center.y)
            self.secondaryPostView.center = self.postContainerPlaceholder.center
        }
    }
    
    func swipeRightHandler(){
        
        UIView.animate(withDuration: 0.3) {
            self.secondPostCircle.backgroundColor = UIColor.lightGray
            self.firstPostCircle.backgroundColor = UIColor.darkGray
            self.firstPostView.center = self.postContainerPlaceholder.center
            self.secondaryPostView.center = CGPoint(x: self.postContainerPlaceholder.center.x + self.secondaryPostView.frame.width,y: self.postContainerPlaceholder.center.y)
            
        }
    }
    
    
    //PAN GESTURE
    func handlePanGesture(panGesture: UIPanGestureRecognizer){
        
        // get translation
        let translation = panGesture.translation(in: self.view)
        panGesture.setTranslation(CGPoint.zero, in: self.view)
        
        let xVel = panGesture.velocity(in: self.view).x
        let yVel = panGesture.velocity(in: self.view).y
        
        print(translation)
        
        if panGesture.state == UIGestureRecognizerState.began {
            // add something you want to happen when the Label Panning has started
            self.popupView.center = self.contentView.center
        }
        
        if panGesture.state == UIGestureRecognizerState.ended {
            // add something you want to happen when the Label Panning has ended
            
            if (xVel > 1000 || yVel > 1000 || sqrt(xVel * xVel + yVel * yVel) > 1000){
                
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.popupView.transform = CGAffineTransform(translationX: xVel/2, y: yVel/2)
                    
                }){ (success) in
                    if success{
                        self.willMove(toParentViewController: nil)
                        self.view.removeFromSuperview()
                        self.removeFromParentViewController()
                    }
                }
            }else{
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.view.center = (self.parent!.view.center)
                    
                })
            }
        }
        
        if panGesture.state == UIGestureRecognizerState.changed {
            
            // add something you want to happen when the Label Panning has been change ( during the moving/panning )
            self.view.center = CGPoint(x:self.view.center.x + translation.x, y: self.view.center.y + translation.y)
            
        } else {  
            // or something when its not moving
        }
    }
    
    
    func playURLData(urlString: String, uid: String, primary: Bool){
        
        //add loading idicator while video downloads
        let loadingView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        loadingView.hidesWhenStopped = true
        loadingView.center = self.postContainerPlaceholder.center
        
        if(primary){
            self.firstPostView.addSubview(loadingView)
        }else{
            self.secondaryPostView.addSubview(loadingView)
        }
        
        
        loadingView.startAnimating()
        
        self.videoCache.getFileWith(stringUrl: urlString) { (result) in
            
            loadingView.stopAnimating()
//            self.avPlayerViewController.load
            switch result {
            case .success(let url):
                
                let player = AVPlayer(url: url)
                self.avPlayerViewController = AVPlayerViewController()
                self.avPlayerViewController.player = player
                self.avPlayerViewController.view.frame = self.contentImageView.bounds
                self.avPlayerViewController.delegate = self
                
                if primary{
                    self.contentImageView.addSubview(self.avPlayerViewController.view)
                    player.play()
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlayingPrimary(note:)),
                                                           name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                }else{
                    self.secondaryContentImageView.addSubview(self.avPlayerViewController.view)
                    player.play()
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlayingSeconadary(note:)),
                                                           name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                }
                
                
                
                
                
            case .failure(let error):
                // handle errror
                
                print("Video could not be retrieved")
                
            }
            
            
            
            
            
            
        }
        
//        let url: URL = URL(string: urlString)!
        

    }
    
    
    func playerDidFinishPlayingPrimary(note: NSNotification) {
        
//        self.avPlayerViewController.dismiss(animated: false, completion: nil)
        
        self.avPlayerViewController.view.removeFromSuperview()
        self.playContentBtn.isHidden = false
        NotificationCenter.default.removeObserver(self)
        print("Video Finished")
        
    }
    func playerDidFinishPlayingSeconadary(note: NSNotification) {
        
//        self.avPlayerViewController.dismiss(animated: false, completion: nil)
        self.secondaryPostPlayBtn.isHidden = false
        self.avPlayerViewController.view.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
        
        print("Video Finished")
    }
    
    
    
    
    
    @IBAction func unwindToPostView(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "toCommentsView"{
            let commentsVC: CommentViewController = segue.destination as! CommentViewController
            
            commentsVC.viewingUserId = self.postData.user.value(forKey: "uid") as! String
            
            if self.commentData != nil{
                
                commentsVC.commentData = self.commentData
            }
        }
    }

}
