//
//  PostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 8/16/17.
//
// CLASS FOR DISPLAYING POST DATA

import UIKit
import AVFoundation
import AVKit
import Firebase
import MediaPlayer
import StoreKit
import Clarifai


//Protocol for POST VIEW CONTROLLER
protocol PostViewDelegate {
    
    func likedButtonPressed(liked: Bool, indexPath: IndexPath)
    func  moreButtonPressed(data: PostData, indexPath: IndexPath)
}




class PostViewController: UIViewController, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate {
    
    var postData: PostData!
 
    //Managers/ Helper Methods
    let appleMusicManager: AppleMusicManager = AppleMusicManager()
    let dataManager: DataManager = DataManager()
    var imageCache: ImageCache = ImageCache()
    var videoCache: VideoStore = VideoStore()
    let awsManager: AWSManager = AWSManager()
    let colors: Colors = Colors()
    
    //Audio/Video Players
    var avPlayerViewController: AVPlayerViewController!
    var applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    var avMusicPlayer: AVAudioPlayer!

    
    //Storyboard Outlets

    @IBOutlet weak var profileContainer: UIView!
    @IBOutlet weak var linkWebView: UIWebView!
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
    @IBOutlet weak var topGradientView: UIView!
    @IBOutlet weak var bottomGradientView: UIView!
    
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
    
    //secondary view relevant variables and outlets -- not currently being used
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
    
    
    //Source of postViewController
    var source: String = "Feed"
    
    
    /****************************************
     
     -------------  LIFECYCLE
     
     ****************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup dismiss pan gesture
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        self.view.addGestureRecognizer(panGesture)
        panGesture.minimumNumberOfTouches = 1
        panGesture.delegate = self
        
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.clipsToBounds = false
        
        //current user data
        self.currentUserId = Auth.auth().currentUser!.uid
        
        //setup remaining views
        self.viewSetup()
        
        //setup data for post category
        self.dataSetup()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        //set speaker to the large speaker
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {
        }
        
//        let gradient: CAGradientLayer  = CAGradientLayer()
//        gradient.frame = self.topGradientView.bounds;
//        gradient.colors = NSArray.init(array: [UIColor.black, UIColor.clear]) as? [Any]
//        self.topGradientView.layer.insertSublayer(gradient, at: 0)
//        
//        let gradient2: CAGradientLayer  = CAGradientLayer()
//        gradient2.frame = self.bottomGradientView.bounds;
//        gradient2.colors = NSArray.init(array: [UIColor.clear, UIColor.black]) as? [Any]
//        self.bottomGradientView.layer.insertSublayer(gradient, at: 0)
    }
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        


        self.musicViewMinCenter = self.songView.center

        //Auto play if content is of the following categories
        if self.postData.category == .Music{
        
            //maximize music view
            self.maximizeMusicView()
        }else if self.postData.category == .Video{
            
            self.playContentBtn(self)
        }else if self.postData.category == .Recording{
            
            self.playContentBtn(self)
        }
    }
    
    
    
    func viewSetup(){
        
        //set icons to white
        self.moreBtn.setImage(UIImage(named: "moreVertical")?.transform(withNewColor: UIColor.white), for: .normal)
        self.minimizeBtn.setImage(UIImage(named: "chevronDown")?.transform(withNewColor: UIColor.white), for: .normal)
        self.commentBtn.setImage(UIImage(named: "comments")?.transform(withNewColor: UIColor.white), for: .normal)
        self.likeBtn.setImage(UIImage(named: "thumbs up")?.transform(withNewColor: UIColor.white), for: .normal)
        
        //song image view setup
        self.songImageView.layer.cornerRadius = self.songImageView.frame.width/2
        self.songImageView.clipsToBounds = true
        self.songImageView.contentMode = .scaleAspectFill
        
        //profile photo image view
        self.profilePhotoImageView.layer.cornerRadius = self.view.frame.height * 0.08 / 2
        self.profilePhotoImageView.clipsToBounds = true
        self.profilePhotoImageView.contentMode = .scaleAspectFill
        
        //popup view setup
        self.popupView.layer.cornerRadius = 8.0
        self.popupView.layer.masksToBounds = true
        self.popupView.clipsToBounds = true
        self.popupView.layer.shadowColor = UIColor.black.cgColor
        self.popupView.layer.shadowOpacity = 0.3
        self.popupView.layer.shadowRadius = 5
        self.popupView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.popupView.layer.shadowPath = UIBezierPath(rect: self.popupView.bounds).cgPath
        

        
        //initialize hub
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
            
            //set profile image
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
        
            
            //SETUP LIKES and Liked Dictionary
            if let likedDict: NSDictionary = self.postData.usersWhoLiked {
                
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                
                if (likedDict.value(forKey: self.currentUserId) != nil){
                    
                    self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                    self.likedByUser = true
                    self.profileContainer.isHidden = false
                    
                }else{
                    
                    self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
                    self.likedByUser = false
                    self.profileContainer.isHidden = true
                }
            }
            
            //if there is a song with this post, extraData won't be empty/nil
            if (self.postData.songString != "" && self.postData.songString != nil){
                
                
                //configure the music view with the song data
                self.songLengthSlider.minimumValue = 0
                self.songLengthSlider.isContinuous = false
                self.songView.isHidden = false
                self.musicViewMinCenter = CGPoint(x:self.songView.frame.midX, y:self.songView.frame.midY)
                self.blurredMusicImageView.contentMode = .scaleAspectFill
                self.songInfo = self.dataManager.extrapolate(songData: self.postData.songString)
                self.artistLbl.text = self.songInfo.artist
                self.songNameLbl.text = self.songInfo.title
                let source = self.songInfo.source
                
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
                
                self.songLengthSlider.value = 0.0
                self.songTimeSpentLbl.text = "0:00"
                
                if (source == "apple"){
                    //song is from apple music
                    
                    self.setupMusicAccess(completion: { (authorized) in
                        //check if apple music is authorized
                        
                        if authorized{
                            //apple music access authorized
                            
                            self.getSongJson(completion: { (response) in
                                //get song data using the PostData song string
                                
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
                        }else{
                            //apple music not authorized
                            //play the content preview
                            
                        }
                    })
                    
                    
                }else if (source == "local"){
                    //TODO: play song.mp4 from s3
                    self.songLength = (self.applicationMusicPlayer.nowPlayingItem?.playbackDuration)! * 1000
                    self.playPauseSongAction(self)
                
                }else{
                
                    //add other sources later
                }
                

                
                //set the song art as the background image adding a blur and gradient layer
                
                //Note: This code could be very helpful for future blurs
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
                    
                    //add crop filter, otherwise returned blurred image is sized improperly
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
                    gradient.colors = [UIColor.clear.cgColor, self.colors.getBlackishColor().cgColor]
                    gradient.locations = [0.0, 0.9]
                    self.blurredMusicImageView.layer.insertSublayer(gradient, at: 0)
                    
                })
                
                
                //add tap gesture to music view (disabled when maximized)
                songTapGesture = UITapGestureRecognizer(target: self, action:  #selector (self.maximizeMusicView))
                self.songView.addGestureRecognizer(songTapGesture)
                
            }else{
                moveBtnsDown()
                
            }
            
            
            
            
            //Confgiure the main content view based on category
            switch self.postData.category {
            
            case .Photo:
                imageCache.getImage(urlString: self.postData.data, completion: { (image) in
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
                imageCache.getImage(urlString: self.postData.data, completion: { (image) in
                    self.contentImageView.image = image
                })
                
            case .Link:
                
                print("")
                self.linkLbl.isHidden = false
                self.playContentBtn.setImage(self.dataManager.clearImage, for: .normal)
                
//                self.dataManager.setURLView(urlString: self.postData.data as String, completion: { (image, label) in
//
//                    self.contentImageView.image = image
//                    self.linkLbl.adjustsFontSizeToFitWidth = true
//                    self.linkLbl.numberOfLines = 3
//                    self.linkLbl.backgroundColor = UIColor.darkGray
//                    self.linkLbl.alpha = 0.7
//                    self.linkLbl.text = label
//                    self.linkLbl.textAlignment = .center
//                    self.linkLbl.textColor = UIColor.white
//                    self.linkLbl.isHidden = false
//                })
                
                self.linkWebView.isHidden = false
                let url = URL (string: self.postData.data)
                let requestObj = URLRequest(url: url!)
                
                self.linkWebView.loadRequest(requestObj)
                
            default:
                print("")
            }
        }
    }
    
    
    
    
    /***********************************************
     
     ------------- SONG WITH POST METHODS
     
     ************************************************/
    
    //timer start for showing song progress with songLengthSlider
    func songProgressTimerStart (){
        
        self.songTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updatePlaybackViews), userInfo: nil, repeats: true)
    }
    
    //song timer selector -- updates the songLegthSlider every 1 second
    @objc func updatePlaybackViews(){
        if self.applicationMusicPlayer.playbackState == .playing{
            
            let millis = TimeInterval(self.applicationMusicPlayer.currentPlaybackTime * 1000)
            print(millis/self.songLength)
            
            self.songTimeSpentLbl.text = self.applicationMusicPlayer.currentPlaybackTime.minuteSecond
            self.songLengthSlider.setValue(Float(millis/self.songLength * 100), animated: true)
            
            //if the song reaches the end. Stop the player
            if (millis == self.songLength){
                
                //pause actions
                self.playPauseSongAction(self)
                if (applicationMusicPlayer.isPreparedToPlay){
                   self.applicationMusicPlayer.stop()
                }
                
            }
            
        }else if(avMusicPlayer != nil){
            print("AVPlayer not nil")
            
        }
    }
    
    
    func stopSongProgressTimer(){
        self.songTimer.invalidate()
    }
    
    
    //sets and plays the parameter array with the application music player
    func appleMusicPlayTrackId(ids:[String]) {
        
        if applicationMusicPlayer.isPreparedToPlay{
            applicationMusicPlayer.setQueue(with: ids)
        }
        self.playPauseSongAction(self)
        
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
    
    
    //check if apple music/local music is authorized. If not, ask. Completion returns true if authorized
    func setupMusicAccess(completion: @escaping (Bool) -> Void){
        
        if (MPMediaLibrary.authorizationStatus() == .authorized){
            
            //authorized, complete true
            completion(true)
            
        }else{
            //if not authorized, ask for it
            MPMediaLibrary.requestAuthorization { (status) in
                
                switch status
                {
                case .authorized:
                    //user allowed
                    completion(true)
                    
                case .denied, .restricted, .notDetermined:
                    //can't access music, completion yields false
                    print("Not allowed")
                    completion(false)
                }
            }
        }
    }

    
    
    //moves the music view moving to the center-ish
    @objc func maximizeMusicView(){
        
        self.blurredMusicImageView.alpha = 0.0
//        let SongViewCenter = CGPoint(x: self.postContainerPlaceholder.frame.midX, y: self.minimizeBtn.frame.maxY + 20 + self.songView.frame.height/2)
         let SongViewCenter = CGPoint(x: self.postContainerPlaceholder.frame.midX, y: self.postContainerPlaceholder.frame.midY + 10)
        
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
            self.songView.backgroundColor = UIColor.clear
            
            self.songImageView.frame.size = CGSize(width: self.postContainerPlaceholder.frame.width/2, height:self.postContainerPlaceholder.frame.width/2)
            self.songImageView.layer.cornerRadius = self.view.frame.width/4
            self.songImageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY - 150)
            self.playMusicBtn.center = CGPoint(x: self.view.bounds.midX,y: self.view.bounds.midY)
            self.blurredMusicImageView.alpha = 1.0
        }
    }
    
    //moves music view to it's bottom position
    func minimizeMusicView() {
        
        self.songTapGesture.isEnabled = true
        self.musicViewMinimized = true
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
    
    
    //moves the likes, comments, more button down when music view is maximized
    func moveBtnsDown(){
        
        UIView.animate(withDuration: 0.3){
            
            //calculate distance between bottom of song view and bottom of view
            self.likeBtn.center = CGPoint(x: self.likeBtn.center.x,y:self.postContainerPlaceholder.frame.maxY - 20)
            self.commentBtn.center = CGPoint(x: self.commentBtn.center.x,y:self.postContainerPlaceholder.frame.maxY - 20)
            self.moreBtn.center = CGPoint(x: self.moreBtn.center.x,y:self.postContainerPlaceholder.frame.maxY - 20)
        }
    }
    
    
    //moves the likes, comments and moreButton up when the music view is minimized
    func moveBtnsUp(){
    
        UIView.animate(withDuration: 0.3){
    
            self.likeBtn.center = CGPoint(x: self.likeBtn.center.x,y: self.bottomGradientView.frame.minY + 10)
            self.commentBtn.center = CGPoint(x: self.commentBtn.center.x,y:self.bottomGradientView.frame.minY + 10)
            self.moreBtn.center = CGPoint(x: self.moreBtn.center.x,y:self.bottomGradientView.frame.minY + 10)
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
    
    

    @objc func doubleTapped(){
        
        self.likeAction(self)
        
    }
    
    
    /***********************
     *
     *  STORYBOARD ACTIONS
     *
     **********************/
    
    
    
    //should track/seek with song -- not quite working yet
    @IBAction func songSliderAction(_ sender: Any) {
        
        print(self.songLengthSlider.value)
        var newPosition = 0.0
        if self.songLength != 0{
            newPosition = TimeInterval(self.songLengthSlider.value) / 10 * self.songLength
        }
        
            
        if (self.applicationMusicPlayer.playbackState == .playing){
    // seeking isn't quite working so removing for now
//            self.applicationMusicPlayer.currentPlaybackTime = TimeInterval(newPosition.millisecond)
        }
    }
    
    
    //Will Minimize the music view if it is showing and isn't the primary post
    //    otherwise it will close the post view controller
    @IBAction func minimizeAction(_ sender: Any) {
        
        if musicViewMinimized || self.postData.category == .Music{
            
            UIView.animate(withDuration: 0.3, animations: {
            self.popupView.transform = CGAffineTransform(translationX: 0, y: 1000)
                
            }){ (success) in
                if success{

                    if self.applicationMusicPlayer.isPreparedToPlay{
                        self.applicationMusicPlayer.pause()
                    }

                    if self.songTimer != nil{
                        self.songTimer.invalidate()
                    }
                    
                    if (self.applicationMusicPlayer.playbackState == .playing || self.applicationMusicPlayer.playbackState == .paused){
                        self.playPauseSongAction(self)
                        self.applicationMusicPlayer.stop()
                    }
                    
//                    UIView.transition(with: self.view, duration: 0.5, options: .transitionCurlDown, animations: {
//                        self.view.addSubview(commentsVC.view)
//                    }) { (success) in
//                        commentsVC.didMove(toParentViewController: self)
//                    }
                    self.willMove(toParentViewController: nil)
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                    
                }
            }
            
        }else{
            
            self.minimizeMusicView()
        }
    }
    
    
    //Like Button toggle
    @IBAction func likeAction(_ sender: Any) {
        
        let postId:String = self.postData.postId

        if(likedByUser){
            
            if (postId != ""){
                self.profileContainer.isHidden = true
                self.likedByUser = false
                self.flashThumb(liked: likedByUser)
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
                
                self.likedButtonPressed(liked: false, indexPath: self.selectedIndexPath)
            }
            
        }else{
            
            
            if (postId != ""){
                self.profileContainer.isHidden = false
                self.likedByUser = true
                self.flashThumb(liked: likedByUser)
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                
                self.likedButtonPressed(liked: true, indexPath: self.selectedIndexPath)

            }
        }
    }
    
    
    //will add a thumb and fade out based on whether the user has liked the post or unliked it
    func flashThumb(liked: Bool){
        
        let frame: CGRect = CGRect(x: self.postContainerPlaceholder.frame.midX, y: self.postContainerPlaceholder.frame.midX, width: self.postContainerPlaceholder.frame.width/2, height: self.postContainerPlaceholder.frame.width/2)
        
        let thumb: UIImageView = UIImageView(frame: frame)
        thumb.center = self.postContainerPlaceholder.center
        
        let image: UIImage = UIImage.init(named: "thumbs up")!
        thumb.image = image
        
        if liked{
            
            thumb.image = image.transform(withNewColor: UIColor.red)
            self.contentView.addSubview(thumb)
            
            UIView.animate(withDuration: 0.5, animations: {
                thumb.alpha = 0.0
            }, completion: { (success) in
                if success{
                    thumb.removeFromSuperview()
                }
            })
            
        }else{
            
            thumb.image = image.transform(withNewColor: UIColor.white)
            self.contentView.addSubview(thumb)
            
            UIView.animate(withDuration: 0.5, animations: {
                thumb.alpha = 0.0
            }, completion: { (success) in
                if success{
                    thumb.removeFromSuperview()
                }
            })
        }
    }
    
    
    
    
    
    //shows the comments view
    @IBAction func commentsAction(_ sender: Any) {
        
        let commentsVC: CommentViewController = storyboard!.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        commentsVC.viewingUserId = self.postData.user.value(forKey: "uid") as! String
        
        if self.commentData != nil{
            
            commentsVC.commentData = self.commentData
        }

        addChildViewController(commentsVC)
        
        commentsVC.view.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width,height:self.view.frame.height)
        commentsVC.view.center = self.view.center
        
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCurlDown, animations: {
            self.view.addSubview(commentsVC.view)
        }) { (success) in
            commentsVC.didMove(toParentViewController: self)
        }
    }
    
    
    //displays the more menu
    @IBAction func moreBtnAction(_ sender: Any) {
        
        self.moreButtonPressed(data: self.postData, indexPath: self.selectedIndexPath)
    }
    
    
    //Universal Play button, behavior changes based on category
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
    

    
    //SongView playPauseBtn action handler. If playing - pause, if paused - play
    @IBAction func playPauseSongAction(_ sender: Any) {
        
        
        if self.songIsPlaying{
            
            //if song was playing, set icon to play and pause the music player
            self.songIsPlaying = false
            self.playMusicBtn.setImage(UIImage(named: "play"), for: .normal)
            
            if avMusicPlayer != nil{
                avMusicPlayer.pause()
            }else{
                if applicationMusicPlayer.isPreparedToPlay{
                    self.applicationMusicPlayer.pause()
                }
            }
            self.stopSongProgressTimer()
            
            
        }else{
            //if song was paused, set icon to pause image and play the music player
            self.songIsPlaying = true
            self.playMusicBtn.setImage(UIImage(named: "pause"), for: .normal)

            if avMusicPlayer != nil{
                avMusicPlayer.play()
            }else{
                if applicationMusicPlayer.isPreparedToPlay{
                    self.applicationMusicPlayer.play()
                }
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
    @objc func handlePanGesture(panGesture: UIPanGestureRecognizer){
        
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
                        if self.songTimer != nil{
                            self.songTimer.invalidate()
                        }
                        
                        if self.applicationMusicPlayer.playbackState == .playing || self.applicationMusicPlayer.playbackState == .paused{
                            self.playPauseSongAction(self)
                            if (self.applicationMusicPlayer.isPreparedToPlay){
                                self.applicationMusicPlayer.stop()
                            }
                            
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

        let player = AVPlayer(url: URL(string:urlString)!)
        self.avPlayerViewController = AVPlayerViewController()
        self.avPlayerViewController.player = player
        self.avPlayerViewController.view.frame = self.firstPostView.bounds
        self.avPlayerViewController.delegate = self
        player.volume = 2
        
        
        if primary{
            
            self.firstPostView.addSubview(self.avPlayerViewController.view)
            player.play()
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlayingPrimary(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }else{
            self.secondaryContentImageView.addSubview(self.avPlayerViewController.view)
            player.play()
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlayingSeconadary(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        
        
        
                
                
//            case .failure(let error):
//                // handle errror
//                
//                print("Video could not be retrieved")
//                print(error.localizedCapitalized)
//            }
//            
//            
//            
//            
//            
//            
//        }
        
//        let url: URL = URL(string: urlString)!
        

    }
    
    
    
    //POSTVIEWCONTROLLER DELEGTE METHODS
    
    func likedButtonPressed(liked: Bool, indexPath: IndexPath){
        //handle backend updates, then call the delegate method to update the UI
        
        if(!liked){
            
            //the post was previously liked by the user, set likedByUser to false
            if (postData.postId != ""){
                
                //set image to normal color
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
                
                //remove current user from likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postData.user.value(forKey: "uid") as! String).child("users_who_liked").child(currentUserId)
                postLikesDictRef.removeValue()
                
                //remove post from user's liked posts
                let likedDictRef = Database.database().reference().child("Users").child(self.currentUserId).child("liked_posts").child(self.postData.user.value(forKey: "uid") as! String)
                likedDictRef.removeValue()
            }
            
        }else{
            
            //post wasn't liked by user, set likedByUser to true
            if (self.postData.postId != ""){
                
                self.likedByUser = true
                
                //set thumb to be red tint
                let newImage: UIImage = UIImage.init(named: "thumbs up")!
                self.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                
                //Add the current user to the likes list
                let postLikesDictRef = Database.database().reference().child("Posts").child(self.postData.user.value(forKey: "uid") as! String).child("users_who_liked")
                postLikesDictRef.child(currentUserId).setValue(true)
                
                
               // update views list
                self.dataManager.updateViewsList(post: self.postData)
                
                let likedDictRef = Database.database().reference().child("Users").child(self.currentUserId).child("liked_posts")
                likedDictRef.child(self.postData.user.value(forKey: "uid") as! String).setValue(self.postData.expireTime)

            }
        }
        
        if self.delegate != nil{
            self.delegate.likedButtonPressed(liked: liked, indexPath: indexPath)
        }
    }
    
    func  moreButtonPressed(data: PostData, indexPath: IndexPath){
        
        if self.delegate != nil{
            self.delegate.moreButtonPressed(data: data, indexPath: indexPath)
        }
    }

    
    
    
    //NOTIFICATIONS OF COMPELETION
    @objc func playerDidFinishPlayingPrimary(note: NSNotification) {
        
//        self.avPlayerViewController.dismiss(animated: false, completion: nil)
        self.avPlayerViewController.view.removeFromSuperview()
        self.playContentBtn.isHidden = false
        NotificationCenter.default.removeObserver(self)
        print("Video Finished")
    }
    
    @objc func playerDidFinishPlayingSeconadary(note: NSNotification) {
        
//        self.avPlayerViewController.dismiss(animated: false, completion: nil)
        self.secondaryPostPlayBtn.isHidden = false
        self.avPlayerViewController.view.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
        
        print("Video Finished")
    }
    
    

    @IBAction func unwindToPostView(unwindSegue: UIStoryboardSegue) {}
    
    
    
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
