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
import MediaPlayer
import StoreKit


protocol PostViewDelegate {
    
    
    func likedButtonPressed(liked: Bool, indexPath: IndexPath)
    func  moreButtonPressed(data: PostData, indexPath: IndexPath)
}




class PostViewController: UIViewController, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate {
    
    var postData: PostData!
 
    //Managers
    let appleMusicManager: AppleMusicManager = AppleMusicManager()
    let dataManager: DataManager = DataManager()
    var imageCache: ImageCache = ImageCache()
    var videoCache: VideoStore = VideoStore()
    let awsManager: AWSManager = AWSManager()
    var avPlayerViewController: AVPlayerViewController!
    var applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
    var avMusicPlayer: AVAudioPlayer!
    
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
    @IBOutlet weak var songLengthSlider: UISlider!
    @IBOutlet weak var songLengthLbl: UILabel!
    @IBOutlet weak var songTimeSpentLbl: UILabel!
    @IBOutlet weak var linkLbl: UILabel!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var alphaView: UIView!
    @IBOutlet weak var shadowView: UIView!
    
    var likedByUser: Bool = false
    var currentUserId: String = ""
    var hub: RKNotificationHub!
    var commentData: NSDictionary!
    var delegate: PostViewDelegate!
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var songInfo: Song!
    var musicViewMinimized: Bool = true
    var musicViewMinCenter: CGPoint!
    var blurView: UIVisualEffectView!
    var songTapGesture: UITapGestureRecognizer!
    var songIsPlaying: Bool = false
    var songTimer: Timer!
    var songLength: TimeInterval!
    var songSource: String = ""
    var panGesture: UIPanGestureRecognizer!
    
    //secondary view relevant variables and outlets
    @IBOutlet weak var showHideSecondaryView: UIButton!
    @IBOutlet weak var secondaryPostView: UIView!
    @IBOutlet weak var secondaryContentImageView: UIImageView!
    @IBOutlet weak var postContainerPlaceholder: UIView!
    @IBOutlet weak var firstPostView: UIView!
    @IBOutlet weak var secondaryPostPlayBtn: UIButton!
    @IBOutlet weak var secondaryLinkLbl: UILabel!
    @IBOutlet weak var blurredMusicImageView: UIImageView!
    
    var secondaryViewIsShowing: Bool = false
    var swipeLeftGesture: UISwipeGestureRecognizer!
    var swipeRightGesture: UISwipeGestureRecognizer!

    @IBOutlet weak var postCurrentlyViewingStackView: UIStackView!
    @IBOutlet weak var firstPostCircle: UIView!
    @IBOutlet weak var secondPostCircle: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        self.view.addGestureRecognizer(panGesture)
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
        
        
        //Auto play if content is of the following categories
        if self.postData.category == .Music{
            
            self.maximizeMusicView()
            
        }else if self.postData.category == .Video{
            
            self.playContentBtn(self)
            
        }else if self.postData.category == .Recording{
            
            self.playContentBtn(self)
            
        }
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
//            if self.postData.secondaryPost != nil{
//                
//                self.postCurrentlyViewingStackView.isHidden = false
//                self.setupViewingStackView()
//                self.setupSecondaryPostView(user: user, secondaryPostData: self.postData.secondaryPost)
//            }
            

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
            
            
            //if there is a song with this post extra data won't be empty/nil
            if (self.postData.songString != "" && self.postData.songString != nil){
                
                self.songLengthSlider.minimumValue = 0
                self.songLengthSlider.isContinuous = false
                self.songView.isHidden = false
                self.musicViewMinCenter = self.songView.center
                self.blurredMusicImageView.contentMode = .scaleAspectFill
                self.songInfo = self.dataManager.extrapolate(songData: self.postData.songString)
                self.artistLbl.text = self.songInfo.artist
                self.songNameLbl.text = self.songInfo.title
                let source = self.songInfo.source
                
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
                
                self.songLengthSlider.value = 0.0
                self.songTimeSpentLbl.text = "0.00"
                
                if (source == "apple"){
                    //songs on apple music
                    
                    self.getSongJson(completion: { (response) in
                        
                        let data = response.value as! NSDictionary
                        let array = data.value(forKey: "results") as! NSArray

                        let songData: NSDictionary = array[0] as! NSDictionary
                        print(songData)
                        let previewString: String = songData.value(forKey: "previewUrl") as! String
                        let trackId: NSInteger = songData.value(forKey: "trackId") as! NSInteger
                        let millis = songData.value(forKey: "trackTimeMillis") as! NSInteger
                        self.songLength = TimeInterval(millis)
                        print(self.songLength)
                        
                        
                        self.appleMusicManager.appleMusicRequestPermission()

                        if (SKCloudServiceController.authorizationStatus() == .authorized){
                            //play song
                            self.appleMusicPlayTrackId(ids: [String(trackId)])
                            
                        }else{
                            //play preview -- 30 seconds in millis
                            self.songLength = 30 * 1000
                            
                            do {
                                
                               self.avMusicPlayer = try? AVAudioPlayer(contentsOf: URL(string: previewString)!)
                            }
                            
                            self.playPauseSongAction(self)
                            
                        }
                        
                        
                        let seconds = self.songLength / 1000
                        self.songLengthLbl.text = seconds.minuteSecond
                    })
                    
                    
                }else if (source == "local"){
                    //play song.mp4 from s3
                    
                    
                    
                }else{
                    
                    
                    //add other sources later
                }
                


                imageCache.getImage(urlString: thumbnailURL, completion: { (image) in
                    
                    self.songImageView.image = image
                    self.blurredMusicImageView.image = image
                    self.blurredMusicImageView.contentMode = .scaleAspectFill
                    
                    //Blurring the Image
                    let context = CIContext(options: nil)
                    let currentFilter = CIFilter(name: "CIGaussianBlur")
                    let beginImage = CIImage(image: image)
                    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                    currentFilter!.setValue(10, forKey: kCIInputRadiusKey)
                    
                    let cropFilter = CIFilter(name: "CICrop")
                    cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
                    cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
                    
                    let output = cropFilter!.outputImage
                    let cgimg = context.createCGImage(output!, from: output!.extent)
                    let processedImage = UIImage(cgImage: cgimg!)
                    self.blurredMusicImageView.image = processedImage

                    //Adding Gradient Sublayer
                    let gradient: CAGradientLayer = CAGradientLayer()
                    gradient.frame = self.blurredMusicImageView.frame
                    gradient.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
                    gradient.locations = [0.0, 1.0]
                    self.blurredMusicImageView.layer.insertSublayer(gradient, at: 0)
                })
                
                songTapGesture = UITapGestureRecognizer(target: self, action:  #selector (self.maximizeMusicView))
                self.songView.addGestureRecognizer(songTapGesture)
                
            }else{
                moveBtnsDown()
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
                
                self.musicViewMinimized = false
                
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
    
    
    
    
    func songProgressTimerStart (){
        
        self.songTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updatePlaybackViews), userInfo: nil, repeats: true)
        
    }
    
    //song timer selector
    func updatePlaybackViews(){
        if self.applicationMusicPlayer.playbackState == .playing{
            
            let millis = TimeInterval(self.applicationMusicPlayer.currentPlaybackTime * 1000)
//            print(millis/self.songLength)
            self.songTimeSpentLbl.text = self.applicationMusicPlayer.currentPlaybackTime.minuteSecond
            
            self.songLengthSlider.setValue(Float(millis/self.songLength * 100), animated: true)
            
        }else if(avMusicPlayer != nil){
            
            
        }
    }
    
    
    func stopSongProgressTimer(){
        self.songTimer.invalidate()
    }
    
    
    
    func appleMusicPlayTrackId(ids:[String]) {
        
        applicationMusicPlayer.setQueueWithStoreIDs(ids)
        self.playPauseSongAction(self)
        
    }

    
    
    //music view moving to center
    func maximizeMusicView(){
        
        self.blurredMusicImageView.alpha = 0.0
        let SongViewCenter = CGPoint(x: self.postContainerPlaceholder.frame.midX, y: self.minimizeBtn.frame.maxY + 20 + self.songView.frame.height/2)
        
        self.musicViewMinimized = false
        self.blurredMusicImageView.isHidden = false
        self.songTapGesture.isEnabled = false
        
        
        self.moveBtnsDown()
        UIView.animate(withDuration: 0.5) {
            
            self.songNameLbl.textColor = UIColor.white
            self.artistLbl.textColor = UIColor.white
    
            self.songView.center = SongViewCenter
            self.songNameLbl.textAlignment = .center
            self.artistLbl.textAlignment = .center
            self.songView.backgroundColor = UIColor.white
            
            self.songImageView.frame.size = CGSize(width: self.songView.frame.width/2, height:self.songView.frame.width/2)
            self.songImageView.layer.cornerRadius = self.songView.frame.width/4
            self.songImageView.center = CGPoint(x: self.postContainerPlaceholder.frame.midX, y: self.songView.bounds.midY - 40)
            self.playMusicBtn.center = CGPoint(x: self.postContainerPlaceholder.frame.midX,y: self.songView.bounds.maxY - 75)
            
            self.blurredMusicImageView.alpha = 1.0
        }
    }
    
    
    func minimizeMusicView() {
        
        self.songTapGesture.isEnabled = true
        
        self.moveBtnsUp()
        UIView.animate(withDuration: 0.5, animations: {
            
            self.songNameLbl.textAlignment = .left
            self.artistLbl.textAlignment = .left
            self.songNameLbl.textColor = UIColor.black
            self.artistLbl.textColor = UIColor.darkGray
            self.songView.backgroundColor = UIColor.lightGray
            self.songImageView.frame.size = CGSize(width: 50, height:50)
            self.songImageView.layer.cornerRadius = 25
            self.blurredMusicImageView.alpha = 0.0
            self.songView.center = self.musicViewMinCenter
            self.songImageView.center = CGPoint(x: self.songView.bounds.minX + 35,y:self.songView.bounds.minY + 30)
            self.playMusicBtn.center = CGPoint(x: self.songView.bounds.maxX - 35,y:self.songView.bounds.minY + 30)
            
        }) { (success) in
            
            self.blurredMusicImageView.isHidden = true
        }
    }
    
    
    func moveBtnsDown(){
        
        UIView.animate(withDuration: 0.5){
            
            self.likeBtn.center = CGPoint(x: self.likeBtn.center.x,y:self.likeBtn.center.y + 50)
            self.commentBtn.center = CGPoint(x: self.commentBtn.center.x,y:self.commentBtn.center.y + 50)
            self.moreBtn.center = CGPoint(x: self.moreBtn.center.x,y:self.moreBtn.center.y + 50)
        }
    }
    
    func moveBtnsUp(){
    
        UIView.animate(withDuration: 0.5){
    
            self.likeBtn.center = CGPoint(x: self.likeBtn.center.x,y:self.likeBtn.center.y - 50)
            self.commentBtn.center = CGPoint(x: self.commentBtn.center.x,y:self.commentBtn.center.y - 50)
            self.moreBtn.center = CGPoint(x: self.moreBtn.center.x,y:self.moreBtn.center.y - 50)
        }
    }
    
    
//    func setupSecondaryPostView(user: NSDictionary, secondaryPostData:NSDictionary){
//        
//        self.swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeLeftHandler))
//        self.swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeRightHandler))
//        
//        self.swipeLeftGesture.delegate = self
//        self.swipeRightGesture.delegate = self
//        
//        self.swipeLeftGesture.direction = .left
//        self.swipeRightGesture.direction = .right
//        self.swipeRightGesture.numberOfTouchesRequired = 1;
//        self.swipeLeftGesture.numberOfTouchesRequired = 1;
//        
//        self.firstPostView.addGestureRecognizer(swipeLeftGesture)
//        self.secondaryPostView.addGestureRecognizer(swipeRightGesture)
//        
//        self.secondaryLinkLbl.isHidden = true
//        self.secondaryPostPlayBtn.isHidden = true
//        let cat: Category = Category(rawValue: secondaryPostData.value(forKey: "secondaryCategory") as! String)!
//
//        //TODO: SETUP COMMENTS
//        switch cat {
//            
//        case .Photo:
//            print("")
//            imageCache.getImage(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image) in
//                self.secondaryContentImageView.image = image
//            })
//        case .Video:
//            print("")
//            //thumbnail URL
//            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
//            
//            imageCache.getImage(urlString: thumbnailURL, completion: { (image) in
//                self.secondaryContentImageView.image = image
//            })
//            self.secondaryPostPlayBtn.isHidden = false
//            
//        case .Recording:
//            
//            self.secondaryContentImageView.image = UIImage(named:"audioWave")
//            
//        case .Music:
//            
//            self.songView.isHidden = false
//            self.firstPostView.removeGestureRecognizer(swipeLeftGesture)
//            self.secondaryPostView.removeGestureRecognizer(swipeRightGesture)
//            self.postCurrentlyViewingStackView.isHidden = true
//            
//        case .Text:
//            print("")
//            imageCache.getImage(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image) in
//                self.secondaryContentImageView.image = image
//            })
//            
//        case .Link:
//            print("")
//            self.secondaryLinkLbl.isHidden = false
//            self.secondaryPostPlayBtn.setImage(self.dataManager.clearImage, for: .normal)
//            
//            self.dataManager.setURLView(urlString: secondaryPostData.value(forKey: "secondaryData") as! String, completion: { (image, label) in
//                
//                self.secondaryContentImageView.image = image
//                
//                self.secondaryLinkLbl.adjustsFontSizeToFitWidth = true
//                self.secondaryLinkLbl.numberOfLines = 3
//                self.secondaryLinkLbl.backgroundColor = UIColor.darkGray
//                self.secondaryLinkLbl.alpha = 0.7
//                self.secondaryLinkLbl.text = label
//                self.secondaryLinkLbl.textAlignment = .center
//                self.secondaryLinkLbl.textColor = UIColor.white
//                self.secondaryLinkLbl.isHidden = false
//                
//            })
//        default:
//            print("")
//        }
//    }
    
    
    
    
    func setupViewingStackView(){
        
        self.firstPostCircle.layer.cornerRadius = 3.0
        self.secondPostCircle.layer.cornerRadius = 3.0
    }
    
    
    //task completion returns apple music song data as a JSON
    func getSongJson(completion: @escaping (NetworkResponse) -> Void){
        
        var songQuery: String = ""
        
        appleMusicManager.createItunesQuery(songData: self.postData.songString) { (string) in
            
            songQuery = string;
            print(songQuery)
            
            let url: URL = URL(string: songQuery)!
            let task = self.appleMusicManager.buildTask(withURL: url, completion: completion)
            
            // start task
            task.resume()

            return
        }
    }
    
    
    
    /***********************
     *
     *  STORYBOARD ACTIONS
     *
     **********************/
    
    @IBAction func songSliderAction(_ sender: Any) {
        
        print(self.songLengthSlider.value)
        let newPosition = TimeInterval(self.songLengthSlider.value) / 10 * self.songLength
            
        if (self.applicationMusicPlayer.playbackState == .playing){
    // seeking isn't quite working so removing for now
//            self.applicationMusicPlayer.currentPlaybackTime = TimeInterval(newPosition.millisecond)
        }
    }
    
    
    
    @IBAction func minimizeAction(_ sender: Any) {
        
        if musicViewMinimized || self.postData.category == .Music{
            
            UIView.animate(withDuration: 0.2, animations: {
                
                self.shadowView.transform = CGAffineTransform(translationX: 0, y: 1000)
                self.popupView.transform = CGAffineTransform(translationX: 0, y: 1000)
                self.alphaView.alpha = 0.0
                
            }){ (success) in
                if success{

                    self.applicationMusicPlayer.pause()

                    if self.songTimer != nil{
                        self.songTimer.invalidate()
                    }
                    
                    if self.applicationMusicPlayer.playbackState == .playing {
                        self.applicationMusicPlayer.stop()
                    }
                    self.willMove(toParentViewController: nil)
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                    
                }
            }
            
        }else{
            
            self.minimizeMusicView()
        }
    }
    
    
    
    @IBAction func likeAction(_ sender: Any) {
        
        let postId:String = self.postData.postId

        if(likedByUser){
            
            if (postId != ""){
                
                self.likedByUser = false
                
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage, for: .normal)
                
                self.likedButtonPressed(liked: false, indexPath: self.selectedIndexPath)
                
            }
            
        }else{
            
            
            if (postId != ""){
                
                self.likedByUser = true
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                
                self.likedButtonPressed(liked: true, indexPath: self.selectedIndexPath)

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
        
        self.moreButtonPressed(data: self.postData, indexPath: self.selectedIndexPath)
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
    
    
//    @IBAction func secondaryPlayAction(_ sender: Any) {
//        
//        self.secondaryPostPlayBtn.isHidden = true
//        
//        let sData: String =  self.postData.secondaryPost.value(forKey: "secondaryData") as! String
//        let sCat: Category = Category(rawValue: self.postData.secondaryPost.value(forKey: "secondaryCategory") as! String)!
//        
//        switch sCat {
//            
//        case .Video:
//            
//            playURLData(urlString: sData, uid: self.postData.user.value(forKey: "uid") as! String, primary: false)
//            
//        case .Recording:
//            print("")
//            
//            self.playURLData(urlString: sData, uid: self.postData.user.value(forKey: "uid") as! String, primary:  false)
//        case .Link:
//            
//            let urlString = sData
//            
//            //Image will already be cached so we shouldn't need to use a loading indicator
//            UIApplication.shared.open(URL(string: urlString)!)
//            
//        default:
//            
//            print("")
//        }
//    }
    

    
    
    @IBAction func playPauseSongAction(_ sender: Any) {
        
        
        if self.songIsPlaying{
            self.songIsPlaying = false
            self.playMusicBtn.setImage(UIImage(named: "play"), for: .normal)
            
            
            if avMusicPlayer != nil{
                avMusicPlayer.pause()
            }else{
                self.applicationMusicPlayer.pause()
            }
            self.stopSongProgressTimer()
            
            
        }else{
            self.songIsPlaying = true
            self.playMusicBtn.setImage(UIImage(named: "pause"), for: .normal)

            if avMusicPlayer != nil{
                avMusicPlayer.play()
            }else{
                self.applicationMusicPlayer.play()
            }
            self.songProgressTimerStart()
            
        }
    }
    


    //SWIPE GESTURE Handlers
//    func swipeLeftHandler(){
//        
//        UIView.animate(withDuration: 0.3) { 
//            
//            self.secondPostCircle.backgroundColor = UIColor.darkGray
//            self.firstPostCircle.backgroundColor = UIColor.lightGray
//            self.firstPostView.center = CGPoint(x: self.postContainerPlaceholder.center.x - self.firstPostView.frame.width,y: self.postContainerPlaceholder.center.y)
//            self.secondaryPostView.center = self.postContainerPlaceholder.center
//        }
//    }
//    
//    func swipeRightHandler(){
//        
//        UIView.animate(withDuration: 0.3) {
//            self.secondPostCircle.backgroundColor = UIColor.lightGray
//            self.firstPostCircle.backgroundColor = UIColor.darkGray
//            self.firstPostView.center = self.postContainerPlaceholder.center
//            self.secondaryPostView.center = CGPoint(x: self.postContainerPlaceholder.center.x + self.secondaryPostView.frame.width,y: self.postContainerPlaceholder.center.y)
//            
//        }
//    }

    
    
    
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
            self.shadowView.center = self.contentView.center
        }
        
        if panGesture.state == UIGestureRecognizerState.ended {
            // add something you want to happen when the Label Panning has ended
            
            if (xVel > 1000 || yVel > 1000 || sqrt(xVel * xVel + yVel * yVel) > 1000){
                
                UIView.animate(withDuration: 0.1, animations: {
                    
                    self.popupView.transform = CGAffineTransform(translationX: xVel/2, y: yVel/2)
                    self.shadowView.transform = CGAffineTransform(translationX: xVel/2, y: yVel/2)
                    
                }){ (success) in
                    if success{
                        
                        if self.applicationMusicPlayer.playbackState == .playing {
                            self.applicationMusicPlayer.stop()
                        }
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
        
//        if(primary){
            self.firstPostView.addSubview(loadingView)
//        }else{
//            self.secondaryPostView.addSubview(loadingView)
//        }
        
        
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
                print(error.localizedCapitalized)
            }
            
            
            
            
            
            
        }
        
//        let url: URL = URL(string: urlString)!
        

    }
    
    
    
    //DELEGTE METHODS
    
    func likedButtonPressed(liked: Bool, indexPath: IndexPath){
        if self.delegate != nil{
            self.delegate.likedButtonPressed(liked: liked, indexPath: indexPath)
        }
    }
    
    func  moreButtonPressed(data: PostData, indexPath: IndexPath){
        
        if self.delegate != nil{
            self.delegate.moreButtonPressed(data: data, indexPath: indexPath)
        }
        
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
