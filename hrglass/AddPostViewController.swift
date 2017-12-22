//
//  AddPostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/25/17.
//


import UIKit
import Firebase
import Photos
import URLEmbeddedView
import AVFoundation
import MediaPlayer
import AVKit
import AWSS3
import iOSPhotoEditor


class AddPostViewController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIVideoEditorControllerDelegate, MPMediaPickerControllerDelegate, PhotoEditorDelegate{

    
    //DEMO COLOR
    let ourColors: Colors = Colors()
    let orangishRed: UIColor = UIColor.init(red: 255.0/255.0, green: 95.0/255.0, blue: 69.0/255.0, alpha: 1.0)
    
    //POST DATA
    var postData: PostData!
    var videoStore: VideoStore = VideoStore()
    var dataManager = DataManager()
    var ref: DatabaseReference!
    var currentUserID = Auth.auth().currentUser?.uid
    var postRef: DatabaseReference!
    var loggedInUser: User!

    //TabBar View Variables
    var selectedTab: Int = 1
    var previousSelectedTab = 1
    var tabPassedFromParent = 0
    
    //TabBar Views
    var linkTextField: UITextField!
    var videoCollectionView: UICollectionView!
    var photoCollectionView: UICollectionView!
//    var musicTableView: UITableView!
    var recordingView: UIView!
    var textPostView: UITextField!
    var cameraView: UIImageView!
    var playBtn: UIButton!
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioURL: URL!
    var loadingView: UILabel!

    //CollectionView Data
    var photosAsset: PHFetchResult<AnyObject>!
    var videosAsset: PHFetchResult<AnyObject>!
    var assetThumbnailSize: CGSize!
    
    //tableView data (Music)
//    var musicItemsArray: NSMutableArray!
//    var masterMusicArray: NSMutableArray!
//    var musicSearch: UISearchBar!
    
    
    //music views/players
    var musicView: UIView!
    var applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    var avMusicPlayer: AVAudioPlayer!
    
    //photo and video selected cells
    var selectedPhotoCell: Int = -1
    var selectedVideoCell: Int = -1
    
    //Slider Btns, and ColorSliders
    var backgroundSlider: ColorSlider!
    var textSlider: ColorSlider!
    var backgroundColorBtn: UIButton!
    var textColorBtn: UIButton!
    
    //primary post data
    var selectedObject: AnyObject!
    var selectedCategory: Category = .None
    var selectedMood: Mood = .None
    var selectedShape: String = "circle"
    var trimmedVideoPath: String = ""
    var selectedThumbnail: UIImage!
    
    //set when music is the primary and as an embellishement
    var selectedMusicItem: AnyObject!
    
    //secondary post data, not currently used
//    var secondarySelectedObject: AnyObject!
//    var secondarySelectedCategory: Category = .None
//    var secondarySelectedMood: Mood = .None
//    var secondaryTrimmedVideoPath: String = ""
//    var secondarySelectedThumbnail: UIImage!
//    var hasSecondarySavedPost: Bool = false
//    var selectedTextColor: UIColor!
//    var selectedTextBackroungColor: UIColor!
    
    //ContentPreview Views
    var postPhotoView: UIImageView!
    var linkContentView: UILabel!
    var keyboardHeight: CGFloat = 0.0
    
//    var panGesture: UIPanGestureRecognizer!
    
    //pickers and editors
    var imagePicker: UIImagePickerController!
    var songPicker: MPMediaPickerController!
    var editorVC: UIVideoEditorController!
    var photoEditor: PhotoEditorViewController!
    
    
    //set to true by previous view controller if the post was retrieved from a saved stat
    var postWasSaved: Bool = false
    
    
    //Storyboard outlets
    @IBOutlet weak var musicLbl: UILabel!
    @IBOutlet weak var editVideoBtn: UIButton!
    @IBOutlet weak var moodBtn: UIButton!
    @IBOutlet weak var currentTabView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var postContentView: UIView!
//    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var squareImageBtn: UIButton!
    @IBOutlet weak var circleImagebtn: UIButton!
    @IBOutlet weak var editThumbnailBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var topContainerView: UIView!
    
    
    /********************************
     *
     *  LIFECYCLE METHODS
     *
     ********************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set db ref
        self.ref = Database.database().reference()
        
        //current post db ref
        postRef = self.ref.child("Posts").child(currentUserID!)
        
        //set keyboard notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        //In case phone is in silent mode
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])

        
        self.view.bringSubview(toFront: self.navView)
        //removing bottom navigation line
//        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        self.navigationBar.shadowImage = UIImage()
        
        //swipe down gesture setup -- selector: swipeDownAction
        let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownAction))
        swipeDown.direction = .down
        swipeDown.delegate = self
        self.view.addGestureRecognizer(swipeDown)
        
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {
        }
    }
    
    
    //remove keyboard notif on de-init
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.photoCollectionView == nil{
            //if the mood menu is nil, so are the rest of the content subviews, configure them
            self.currentTabView.frame = CGRect(x: 0,y: self.topContainerView.frame.maxY,width: self.view.frame.width, height:self.view.frame.maxY - self.topContainerView.frame.maxY)
            //setting static frames here since larger screens cause unwanted behviour
            
            //set thumbnail sizes (applicible to both photos and videos collection views)
            self.assetThumbnailSize = CGSize(width:self.currentTabView.bounds.width/3, height:self.currentTabView.bounds.width/3)
            
            //SETUP VIEWS
            self.setupTabBarDetails()
            self.setupContentSubviews()
            self.setupTabViews()
            self.setupMediaAccess()
            self.setupPlayBtn()
            self.setupSliderButtons()

            self.photoCollectionView.isHidden = false
        }
        
        if tabPassedFromParent != 0{
            //tab view button clicked by user in previous view controller
            
            //set selectedTab back to 0 and move to the selectedView
            self.selectedTab = 0
            self.tabBar(self.tabBar, didSelect: (self.tabBar.items?[self.tabPassedFromParent])!)
            self.tabBar.selectedItem = self.tabBar.items?[self.tabPassedFromParent]
            
            print("Selected Tab Value")
            print(self.selectedTab)
            self.tabPassedFromParent = 0
        }else{
            self.tabBar.selectedItem = self.tabBar.items?[0]
        }
        
        
        if postWasSaved{
            
            //if post was saved, retrieve data from documents and user defaults and set them in the corresponding views
            switch self.selectedCategory {
                
            case .Photo:
                
                self.setPhotoView(image: (self.selectedObject as? UIImage)!)
                self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)
                self.playBtn.isHidden = false
                self.postPhotoView.layer.borderColor = ourColors.getMenuColor().cgColor
                
            case .Video:
                
                if (self.trimmedVideoPath != ""){
                    
                    let data: Data!
                    let tpath: URL = self.dataManager.documentsPathForFileName(name: "thumbnail.jpg")
                    do {
                        
                        data = try Data(contentsOf: tpath)
                        self.selectedThumbnail = UIImage(data: data)
                        self.setPhotoView(image: self.selectedThumbnail)
                        self.hideResizeButtons()
                        self.playBtn.isHidden = false

                    }catch{
                        print(error)
                    }
                    
                    self.showVideoEditingBtns()
                    
                }else if (self.selectedThumbnail == nil){
                    if let asset: PHAsset = self.selectedObject as? PHAsset{
                        
                        PHImageManager.default().requestImage(for: asset, targetSize: self.postContentView.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                            if result != nil {
                                self.postPhotoView.image = result
                            }
                        })
                    }
                }
                self.postPhotoView.layer.borderColor = self.ourColors.getPurpleColor().cgColor
                
            case .Text:
                
                self.postPhotoView.image = self.selectedObject as? UIImage
                self.postPhotoView.layer.borderColor = UIColor.black.cgColor
                
            case .Recording:
                
                self.postPhotoView.image =  UIImage(named: "audioWave")
                self.playBtn.isHidden = false
                self.postPhotoView.layer.borderColor = ourColors.getAudioColor().cgColor
                
            case .Music:
                
                print("Music")
                self.setMusicItemData(mpMediaItem: self.selectedObject as! MPMediaItem)
                
            case .Link:
                
                setURLView(urlString: self.selectedObject as! String)
                self.postPhotoView.layer.borderColor = UIColor.black.cgColor
                
            default:
                print("")
            }
            
            //add Music Data
            if self.selectedCategory != .Music{
                self.setMusicItemData(mpMediaItem: self.selectedMusicItem as! MPMediaItem)
            }
            
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    
    
    //keyboard notifications
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    
    
    
    
    
    //Swipe Gesture to resign first responder
    @objc func swipeDownAction(){
        
        if self.linkTextField.isFirstResponder{
            
            self.linkTextField.resignFirstResponder()
            
        }else if self.textPostView.isFirstResponder{
            
            self.textPostView.resignFirstResponder()
            
        }
//        else if self.musicSearch.isFirstResponder{
//            
//            self.musicSearch.endEditing(true)
//            self.musicSearch.resignFirstResponder()
//        }
    }
    
    
    //play button actions/image changes based on the selected. This configures the button to use the play image intially
    func setupPlayBtn(){
        
        self.playBtn = UIButton(frame: CGRect(x: self.postPhotoView.frame.minX,y: self.postPhotoView.frame.minY, width: self.postPhotoView.frame.width, height: self.postPhotoView.frame.height))
        self.playBtn.setImage(UIImage(named:"play"), for: .normal)
        self.playBtn.addTarget(self, action: #selector(self.playBtnAction), for: .touchUpInside)
        self.playBtn.isHidden = true
        self.view.addSubview(self.playBtn)
        self.view.bringSubview(toFront: self.playBtn)
        
    }
    
    
    
    
    
    func setupContentSubviews(){
        
        self.postContentView.layer.cornerRadius = self.postContentView.frame.width / 2
        self.postPhotoView = UIImageView(frame: self.postContentView.frame)
        self.postPhotoView.layer.cornerRadius = self.postContentView.frame.width / 2
        self.postPhotoView.layer.borderColor = UIColor.white.cgColor
        self.postPhotoView.layer.borderWidth = 5.0
        self.postPhotoView.clipsToBounds = true
        self.postPhotoView.contentMode = .scaleAspectFill
        
        self.linkContentView = UILabel(frame:  CGRect(x: self.postPhotoView.bounds.minX, y: self.postPhotoView.bounds.midX, width: self.postContentView.frame.width, height: self.postContentView.frame.height/4))
        
        self.linkContentView.textAlignment = .center
        self.linkContentView.backgroundColor = UIColor.darkGray
        self.linkContentView.alpha = 0.7
        self.linkContentView.textColor = UIColor.white
        self.linkContentView.adjustsFontSizeToFitWidth = true
        
        self.circleImagebtn.layer.borderColor = UIColor.darkGray.cgColor
        self.circleImagebtn.layer.borderWidth = 2
        self.circleImagebtn.layer.cornerRadius = self.circleImagebtn.frame.width/2
        
        self.squareImageBtn.layer.borderColor = UIColor.lightGray.cgColor
        self.squareImageBtn.layer.borderWidth = 1
        
        //hide resize buttons until they are needed
        hideResizeButtons()

        self.postPhotoView.isHidden = true
        self.linkContentView.isHidden = true
        
        self.view.addSubview(postPhotoView)
        self.postPhotoView.addSubview(linkContentView)
        
    }
    

    
    
    
    
    
    /*****************************
     *
     * TEXT SLIDER ACTIONS/METHODS
     *
     ****************************/

    func setTextImage(){

        let image: UIImage = UIImage(view: self.textPostView)
        self.selectedObject = image
        self.setPhotoView(image: image)
        
    }
    
    
    //background color slider selector
    @objc func changedBackgroundColor(_ slider: ColorSlider) {
        let color = slider.color
        self.textPostView.backgroundColor = color
        self.backgroundColorBtn.backgroundColor = color
        
        self.setTextImage()
    }
    
    
    //text color slider selector
    @objc func changedTextColor(_ slider: ColorSlider) {
        let color = slider.color
        self.textPostView.textColor = color
        self.textColorBtn.backgroundColor = color
        
       self.setTextImage()
    }
    
    
    //also toggles the resize buttons visibility as well as the background color slider
    @objc func toggleBackgroundColorSliderVisibility(){
        
        self.hideVideoEditingBtns()
        if self.backgroundSlider.isHidden{
            self.backgroundSlider.isHidden = false
            self.hideResizeButtons()
        }else{
            self.backgroundSlider.isHidden = true
//            self.showResizeButtons()
        }
    }
    
    
    //toggle the text color slider visibility
    @objc func toggleTextColorSliderVisibility(){
        
        self.hideVideoEditingBtns()
        if self.textSlider.isHidden{
            self.textSlider.isHidden = false
            
        }else{
            self.textSlider.isHidden = true
        }
    }
    
    
    
    /*****************************
     *
     *    VIDEO EDITING
     *
     ****************************/

    @IBAction func editThumbnailAction(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toThumbnailView", sender: self)
    }
    
    
    
    //edit vidwo storyboard action
    @IBAction func editVideoAction(_ sender: Any) {
        
        self.editorVC = UIVideoEditorController()
        editorVC.delegate = self
        
        //max video lent is 10 minutes or 600 seconds
        editorVC.videoMaximumDuration = 600
        editorVC.videoQuality = .typeHigh

        //show the loading view
        self.showLoadingView()
        
        //If it's still a PHAsset
        if let asset: PHAsset = self.selectedObject as? PHAsset{
            
            //get the asset URL
            self.dataManager.getURLForPHAsset(videoAsset: asset, name: "savedPostData.mp4", completion: { url in
                
                print(url.relativePath)
                let path = url.relativePath
                self.editorVC.videoPath = path
                
                //edit video if possible
                let can = UIVideoEditorController.canEditVideo(atPath:path)
        
                if !can {
                    print("can't edit this video")
                    self.hideLoadingView()
                    return
                }else{
                    
                    self.present(self.editorVC, animated: true) {
                        print("done")
                        self.hideLoadingView()
                    }
                }
            })
            
        }else{
            //It's stored in Documents as savedPostVideo.mp4
            let path = self.dataManager.documentsPathForFileName(name: "savedPostData.mp4")
            self.editorVC.videoPath = path.relativePath
            
            //edit video if possible
            let can = UIVideoEditorController.canEditVideo(atPath:path.relativePath)
            
            if !can {
                print("can't edit this video")
                self.hideLoadingView()
                return
            }else{
                
                self.present(self.editorVC, animated: true) {
                    print("done")
                    self.hideLoadingView()
                }
            }
        }
    }
    
    
    /*****************************
     *
     *    POST ACTIONS/METHODS
     *
     ****************************/

    //goto submit view controller
    @IBAction func nextAction(_ sender: Any) {
        
        if selectedObject != nil{
            
            performSegue(withIdentifier: "toMoodSegue", sender: self)
        }
    }
    
    
    //Resize picture to square or circle
    @IBAction func squareImageAction(_ sender: Any) {
        
        self.playBtn.isHidden = true
        self.circleImagebtn.layer.borderColor = UIColor.lightGray.cgColor
        self.circleImagebtn.layer.borderWidth = 1
        self.squareImageBtn.layer.borderColor = UIColor.darkGray.cgColor
        self.squareImageBtn.layer.borderWidth = 2
        
//        self.postPhotoView.frame = CGRect(x: 0, y:self.navigationBar.frame.maxY, width:self.view.frame.width, height:self.tabBar.frame.minY - self.navigationBar.frame.maxY - 10)
        
        self.playBtn.center = postPhotoView.center
        
        self.selectedShape = "square"
        self.postPhotoView.layer.borderWidth = 0.0
        self.postPhotoView.layer.cornerRadius = 0
        self.hideResizeButtons()
    }
    
    
    
    @IBAction func circleImageAction(_ sender: Any) {
        
        self.playBtn.isHidden = false
        self.circleImagebtn.layer.borderColor = UIColor.darkGray.cgColor
        self.circleImagebtn.layer.borderWidth = 2
        self.squareImageBtn.layer.borderColor = UIColor.lightGray.cgColor
        self.squareImageBtn.layer.borderWidth = 1
        
        self.postPhotoView.frame.size = self.postContentView.frame.size
        self.postPhotoView.center = self.postContentView.center
        
        self.playBtn.center = postPhotoView.center
        self.selectedShape = "circle"
        self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)

        self.postPhotoView.layer.borderWidth = 5.0
        self.postPhotoView.layer.cornerRadius = self.postPhotoView.frame.width/2
        
    }
    
    
    
    
    /**************************
     *
     *    RECORDING METHODS
     *
     **************************/
    
    func startRecording() {
        
        self.playBtn.setImage(UIImage(named: "play"), for: .normal)
        self.selectedCategory = .Recording
        self.audioURL = self.dataManager.documentsPathForFileName(name: "recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: self.audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Tap to Stop", for: .normal)
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    
    
    //Finish recording and set the necessary category, object, border color and photo
    func finishRecording(success: Bool) {
        
        audioRecorder.stop()
        self.hideResizeButtons()
        
        if success {
            
            recordButton.setTitle("Tap to Re-record", for: .normal)
            
            self.playBtn.isHidden = false
            self.playBtn.isEnabled = true

            self.view.bringSubview(toFront: self.playBtn)

            self.selectedObject = NSData(contentsOf: self.audioURL)
            self.selectedCategory = .Recording
            self.postPhotoView.layer.borderColor = self.ourColors.getAudioColor().cgColor
            self.setPhotoView(image: UIImage(named: "audioWave")!)
            
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    
    //ask and setup mic access
    func setupMicAccess(){
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            //Failed to record!
            //TODO: Alert
        }
    }
    

    
    //Prepare Audio Player
    func preparePlayer() {
        
        do {
            
            //try to play recording
            try audioPlayer = AVAudioPlayer(contentsOf: dataManager.documentsPathForFileName(name: "recording.m4a"))
            audioPlayer.delegate = self
            audioPlayer.volume = 1
            audioPlayer.prepareToPlay()
            
        } catch {
            print(error)
        }
    }
    
    
    //setup recording UI
    func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.recordingView.bounds.width, height: self.recordingView.bounds.height))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(UIColor.white, for: .normal)
        recordButton.titleLabel?.textAlignment = .center
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        self.recordingView.addSubview(recordButton)
    }
    
    //RECORD AUDIO
    @objc func recordTapped() {
        if audioRecorder == nil || recordButton.title(for: .normal) == "Tap to Re-record" {
            
            self.hideVideoEditingBtns()
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    

    
    /************************************
     *
     *  VIDEO PROCESSING LOADING VIEW
     *
     **********************************/
    
    func showLoadingView(){
        
        self.loadingView = UILabel(frame: CGRect(x: self.view.frame.width/2 - self.view.frame.width/4 - 25, y:self.view.frame.height/2 - 25, width: self.view.frame.width/2 + 50, height: 50))
        self.loadingView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.loadingView.textColor = UIColor.white
        self.loadingView.textAlignment = .center
        self.loadingView.text = "Processing Thumbnails..."
        self.loadingView.layer.cornerRadius = 2.0
        self.loadingView.clipsToBounds = true
        self.loadingView.layer.shadowColor = UIColor.black.cgColor
        self.loadingView.layer.shadowOffset = CGSize(width: 3.0,height: 3.0)
        
        self.view.addSubview(loadingView)
    }
    
    
    func hideLoadingView(){
        
        self.loadingView.removeFromSuperview()
    }
    
    
    
    
    /*************************************************
     *
     *     PLAYBACK METHODS -- AUDIO and VIDEO
     *
     *************************************************/
    
    @objc func playBtnAction() {
        
        if self.selectedCategory == .Recording{
            //recording, use audio player to play
            if (playBtn.image(for: .normal) != UIImage(named: "stopSquare")){
                
                //Play Recording
                print("Play Recording button pressed")
                
                recordButton.isEnabled = false
                playBtn.setImage(UIImage(named: "stopSquare"), for: .normal)
                
                preparePlayer()
                audioPlayer.play()
        
            }else{
                
                audioPlayer.stop()
                playBtn.setImage(UIImage(named: "play"), for: .normal)
            }
            
        }else if self.selectedCategory == .Video{
            
            //play Video
            print("Play Video button pressed")
            
            if(self.trimmedVideoPath == ""){
                
                let selectedVideo = self.selectedObject as! PHAsset
                self.playVideoWithAsset(view: self, videoAsset: selectedVideo)
            }else{
                self.playVideoWithURL(view: self, url: self.dataManager.documentsPathForFileName(name: "savedPostData.mp4"))
            }

            
        }else if self.selectedCategory == .Photo || selectedCategory == .Text{
            
            //show photo editor
            self.presentImageEditorWithImage(image: self.selectedObject as! UIImage)
            
        }else if self.selectedCategory == .Music{
            //play with avMusicPlayer
            
            if (playBtn.image(for: .normal) != UIImage(named: "pause")){
                //play the song and set image to pause
                self.playBtn.setImage(UIImage(named: "pause"), for: .normal)
                
                if avMusicPlayer != nil{
                    avMusicPlayer.pause()
                }else{
                    self.applicationMusicPlayer.play()
                }
                
            }else{
                //pause the song and set the image to play
                self.playBtn.setImage(UIImage(named: "play"), for: .normal)
                
                if avMusicPlayer != nil{
                    avMusicPlayer.play()
                }else{
                    self.applicationMusicPlayer.pause()
                }
            }
        }
    }
    
    
    //play song with apple track ID
    func appleMusicPlayTrackId() {
        
        let collection: MPMediaItemCollection = MPMediaItemCollection(items: [self.selectedMusicItem as! MPMediaItem])
        applicationMusicPlayer.setQueue(with: collection)
    }
    
    
    
    //PhotoEditor Functions
    func presentImageEditorWithImage(image:UIImage){
    
        photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
        
        //PhotoEditorDelegate
        photoEditor.photoEditorDelegate = self
        
        //The image to be edited
        photoEditor.image = image
        
        //Stickers that the user will choose from to add on the image
        //photoEditor.stickers.append(UIImage(named: "sticker" )!)
        
        //Optional: To hide controls - array of enum control
        photoEditor.hiddenControls = [.share]
        
        //Optional: Colors for drawing and Text, If not set default values will be used
        photoEditor.colors = [.black,.purple,.red,.orange,.yellow,.green,.blue,.white]
        
        //Present the View Controller
        present(photoEditor, animated: true, completion: nil)
        
    }

    
    
    
    func doneEditing(image: UIImage) {
        
        //edited image
        self.setPhotoView(image: image)
        self.selectedObject = image
        photoEditor.dismiss(animated: true, completion: nil)
    }
    
    func canceledEditing() {
        photoEditor.dismiss(animated: true, completion: nil)
    }
    
    
    
//    func imageEditor(_ editor: CLImageEditor!, didFinishEditingWith image: UIImage!) {
//
//        self.setPhotoView(image: image)
//        self.selectedObject = image
//        editor.dismiss(animated: true, completion: nil)
//
//    }

    


    

    
    
    /**************************************
     *  AUDIO RECORDING/PLAYING DELEGATES
     **************************************/
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            
            finishRecording(success: false)
        }

    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.isEnabled = true
        playBtn.setImage(UIImage(named: "play"), for: .normal)
    }
    
    
    
    
    
    /************************************************************
     *
     * PHOTO/VIDEO/RECORDING ACCESS METHODS
     *
     ***********************************************************/
    
    func playVideoWithAsset (view: UIViewController, videoAsset: PHAsset) {
        
        //return if not a video type
        guard (videoAsset.mediaType == .video) else {
            print("Not a valid video media type")
            return
        }
        //else show loading and play video asset
        self.showLoadingIndicator()
        dataManager.getURLForPHAsset(videoAsset: videoAsset, name: "savedPostData.mp4", completion:{ url in
            
            DispatchQueue.main.async {
                
                self.hideLoadingIndicator()
                let player = AVPlayer(url: url)
                player.volume = 1.0
                
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                view.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        })
    }
    
    
    //play video with existing URL
    func playVideoWithURL(view: UIViewController, url: URL){
        
//        guard (videoAsset.mediaType == .video) else {
//            print("Not a valid video media type")
//            return
//        }
        self.showLoadingIndicator()
            
        DispatchQueue.main.async {
                
            self.hideLoadingIndicator()
            let player = AVPlayer(url: url)
            player.volume = 1.0
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            view.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    /******************************************
     *
     *    LOADING INDICATORS SHOW/HIDE
     *
     *******************************************/
    
    
    
    
    
    func showLoadingIndicator(){
        self.playBtn.isHidden = true
        self.loadingIndicator.startAnimating()
        self.view.bringSubview(toFront: self.loadingIndicator)
        
    }
    
    
    
    func hideLoadingIndicator(){
        self.playBtn.isHidden = false
        self.loadingIndicator.stopAnimating()
        
    }
    
    
    
    
    
    
    /********************************
     *
     *    MEDIA ACCESS/ ALERTS
     *
     *********************************/
    
    @objc func setupMusicAccess(){
        
        if (MPMediaLibrary.authorizationStatus() == .authorized){
            
            //authorized, get songs data
            self.getSongs()
            
        }else{
            //if not authorized, ask for it
            MPMediaLibrary.requestAuthorization { (status) in
                
                switch status
                {
                case .authorized:
                    
                    self.getSongs()
                    
                case .denied, .restricted:
                    
                    print("Not allowed")
                    self.accessDeniedAlert()
                    
                case .notDetermined:
                    print("Not determined yet")
                }
                
            }
        }
    }
    
    func getSongs(){
        //setup song picker

//        let temp: NSMutableArray = MPMediaQuery.songs().items as! NSMutableArray
//        self.musicItemsArray = NSMutableArray()
//        self.masterMusicArray = NSMutableArray()
//        self.musicItemsArray = temp
//        self.masterMusicArray = temp
//        print(String(format: "%d songs found", self.musicItemsArray.count))
//        
//        self.musicTableView.reloadData()
        
        songPicker = MPMediaPickerController(mediaTypes: .music)
        songPicker.view.frame = self.currentTabView.frame
        songPicker.allowsPickingMultipleItems = false
        songPicker.showsCloudItems = true
        songPicker.delegate = self
        present(songPicker, animated: true, completion:nil)
    }
    

    func setupMediaAccess(){
        
        if (PHPhotoLibrary.authorizationStatus() == .authorized) {
            
            //Authorized, get media
            self.getMedia()
            
        }else{
            //not authorized, ask for it
            PHPhotoLibrary.requestAuthorization { (status) in
            
            switch status
            {
            case .authorized:
                
                self.getMedia()
                
            case .denied, .restricted:
                
                print("Not allowed")
                self.accessDeniedAlert()
                
            case .notDetermined:
                print("Not determined yet")
            }
                
            }
        }
    }
    
    
    
    //get images and videos and put asset data into respective collection data source arrays
    func getMedia(){
        
        let fetchOptions = PHFetchOptions()

        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:false)]
        self.photosAsset = PHAsset.fetchAssets(with: .image, options: fetchOptions) as! PHFetchResult<AnyObject>
        
        
        print("Found \(self.photosAsset.count) images")
        
        let fOptions = PHFetchOptions()
        fOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:false)]
        self.videosAsset = PHAsset.fetchAssets(with: .video, options: fOptions) as! PHFetchResult<AnyObject>
        
        print("Found \(self.videosAsset.count) videos")
        
        DispatchQueue.main.async {
            
            self.photoCollectionView.reloadData()
            self.videoCollectionView.reloadData()
        }
    }

    
    
    
    //alert for non authorized media
    func accessDeniedAlert(){
        
        let alert: UIAlertController = UIAlertController(title: "Access Denied", message: "Edit Settings to Allow Hrglass access to your Photos", preferredStyle: .alert)
        
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .default) {(_) -> Void in
            
            alert.dismiss(animated: true, completion: nil)
        }
        
        let settings: UIAlertAction = UIAlertAction(title: "Settings", style: .default) {(_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
            alert.dismiss(animated: true, completion: nil)
            
        }
        
        alert.addAction(cancel)
        alert.addAction(settings)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    

    //sets main photo
    func setPhotoView(image: UIImage){
        
        self.postPhotoView.image = image
        self.linkContentView.isHidden = true
        self.postPhotoView.isHidden = false
    }
    
    
    /********************************
     *
     *    Hide/Show views
     *
     *********************************/
    
    //hide resize btns
    func hideResizeButtons(){
        
        self.circleImagebtn.isHidden = true
        self.squareImageBtn.isHidden = true
    }
    
    
    //show resize btns
    func showResizeButtons(){
        
        self.circleImagebtn.isHidden = false
        self.squareImageBtn.isHidden = false
        self.view.bringSubview(toFront: self.circleImagebtn)
        self.view.bringSubview(toFront: self.squareImageBtn)
    }
    
    
    //hide video btns
    func hideVideoEditingBtns(){
        
        self.editVideoBtn.isHidden = true
        self.editThumbnailBtn.isHidden = true
    }
    
    
    //show video editing btns
    func showVideoEditingBtns(){
        
        self.editVideoBtn.isHidden = false
        self.editThumbnailBtn.isHidden = false
    }
    

    //hide both color sliders
    func hideColorSliders(){
        
        self.backgroundSlider.isHidden = true
        self.textSlider.isHidden = true
    }
    
    
    //hide the color slider buttons
    func hideColorBtns(){
        
        self.backgroundColorBtn.isHidden = true
        self.textColorBtn.isHidden = true
    }
    
    //show the color sliders
    func showColorSliders(){
        
        self.backgroundSlider.isHidden = false
        self.textSlider.isHidden = false
    }
    
    
    //show the color slider buttons
    func showColorBtns(){
        
        self.backgroundColorBtn.isHidden = false
        self.textColorBtn.isHidden = false
    }
    
    
    
    //set the url view
    func setURLView(urlString: String){
        
        dataManager.setURLView(urlString: urlString, completion: { (image, label) in
            DispatchQueue.main.async {
                
                
                self.setPhotoView(image: image)
                self.hideResizeButtons()
                
                self.linkContentView.text = label
                self.linkContentView.numberOfLines = 3
                self.linkContentView.isHidden = false

            }
        })
    }
    
    
    
    
    
    /********************************
     *
     *    CONTENT VIEWS Center Setup
     *
     *********************************/
    
    
    

    
    //Sets up corresponding tab views, moves all views to right of visible screen except the photos collectionview
    func recenterResize(){
        
//        let height: CGFloat = self.view.frame.height - self.tabBar.frame.maxY - 5
//        let rect: CGRect = CGRect(x: 0,y: self.tabBar.frame.maxY + 5, width: self.view.frame.width, height: height)
//        self.currentTabView.frame = rect
        
        let rightCenter = CGPoint(x: self.currentTabView.center.x + self.view.frame.width, y: self.currentTabView.center.y)
        let nib = UINib(nibName: "AddPostCollectionViewCell", bundle:nil)
        
        setupPhotosCollectionView(center: self.currentTabView.center, cellNib: nib)
        setupVideosCollectionView(center: rightCenter, cellNib: nib)
        setupMusicView(center: rightCenter)
        setupLinkTextField(center: rightCenter)
        setupTextPostView(center: rightCenter)
        setupRecordingView(center: rightCenter)
        setupCameraView(center: rightCenter)
        
        
    }
    

    
    
    /*****************************
     *
     *     TAB VIEW SETUP
     *
     ****************************/

    func setupTabViews(){
        
        //Start all views other than the PhotoView off to the right of the Screen
        self.recenterResize()
        
        //add subviews to view
        self.view.addSubview(photoCollectionView)
        self.view.addSubview(videoCollectionView)
        self.view.addSubview(linkTextField)
        self.view.addSubview(musicView)
        self.view.addSubview(recordingView)
        self.view.addSubview(textPostView)
        self.view.addSubview(cameraView)
        
        self.photoCollectionView.isHidden = true
//        panGesture = UIPanGestureRecognizer(target: self, action:#selector(self.handlePanGesture(panGesture:)))

    }
    
    //PHOTO VIEW, TAG 1
    func setupPhotosCollectionView(center: CGPoint, cellNib: UINib){
        
        //collectionview layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        
        layout.itemSize = self.assetThumbnailSize
        
        //set photos collection attributes
        self.photoCollectionView = UICollectionView(frame: self.currentTabView.bounds, collectionViewLayout: layout)
        
        self.photoCollectionView.register(cellNib, forCellWithReuseIdentifier: "addPostCell")
        self.photoCollectionView.tag = 1
        self.photoCollectionView.allowsSelection = true
        self.photoCollectionView.allowsMultipleSelection = false
        self.photoCollectionView.center = center
        self.photoCollectionView.backgroundColor = ourColors.getBlackishColor()
        self.photoCollectionView.delegate = self
        self.photoCollectionView.dataSource = self
        
        
    }
    
    //VIDEO VIEW, TAG 2
    func setupVideosCollectionView(center: CGPoint, cellNib: UINib){
        
        //setup layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = assetThumbnailSize
        
        //set videos collection view attributes
        self.videoCollectionView = UICollectionView(frame: CGRect(x: self.currentTabView.center.x + self.currentTabView.frame.width, y: self.currentTabView.center.y, width: self.currentTabView.frame.width, height:self.currentTabView.frame.height), collectionViewLayout: layout)
        
        
        
        self.videoCollectionView.register(cellNib, forCellWithReuseIdentifier: "addPostCell")
        self.videoCollectionView.tag = 2
        self.videoCollectionView.allowsSelection = true
        self.videoCollectionView.allowsMultipleSelection = false
        self.videoCollectionView.center = center
        self.videoCollectionView.backgroundColor = ourColors.getBlackishColor()
        self.videoCollectionView.delegate = self
        self.videoCollectionView.dataSource = self
        
        self.hideVideoEditingBtns()
        
    }
    

    //TEXT VIEW, TAG 3
    func setupTextPostView(center: CGPoint){
    
        //set textPostView attributes
        self.textPostView = UITextField(frame:CGRect.zero)
        self.textPostView.frame.size = self.currentTabView.frame.size
        self.textPostView.placeholder = "What's on your mind?"
        textPostView.attributedPlaceholder =
            NSAttributedString(string: "What's on your mind?", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        self.textPostView.backgroundColor = ourColors.getBlackishColor()
        self.textPostView.tintColor = UIColor.white
        self.textPostView.textColor = UIColor.white
        self.textPostView.center = center
        self.textPostView.tag = 3
        self.textPostView.delegate = self
        self.textPostView.textAlignment = .center
        
    }
    
    
    func setupSliderButtons(){
        
        //setup color slider buttons
        self.backgroundColorBtn = UIButton(frame: CGRect(x: 15,y: self.currentTabView.frame.minY - 90, width: 30,height: 30))
        self.backgroundColorBtn.clipsToBounds = true
        self.backgroundColorBtn.layer.cornerRadius = backgroundColorBtn.frame.width / 2
        self.backgroundColorBtn.backgroundColor = ourColors.getBlackishColor()
        self.backgroundColorBtn.layer.borderColor = UIColor.white.cgColor
        self.backgroundColorBtn.layer.borderWidth = 1.0
        self.backgroundColorBtn.addTarget(self, action: #selector(toggleBackgroundColorSliderVisibility), for: .touchUpInside)
        
        //
        self.textColorBtn = UIButton(frame: CGRect(x: self.view.frame.width - 45,y:self.currentTabView.frame.minY - 90,width: 30,height: 30))
        self.textColorBtn.clipsToBounds = true
        self.textColorBtn.layer.cornerRadius = textColorBtn.frame.width / 2
        self.textColorBtn.backgroundColor = ourColors.getBlackishColor()
        self.textColorBtn.layer.borderColor = UIColor.white.cgColor
        self.textColorBtn.layer.borderWidth = 1.0
        self.textColorBtn.addTarget(self, action: #selector(toggleTextColorSliderVisibility), for: .touchUpInside)
        self.textColorBtn.setTitle("T", for: .normal)
        self.textColorBtn.setTitleColor(.white, for: .normal)
        
        //add buttons to view
        self.view.addSubview(backgroundColorBtn)
        self.view.addSubview(textColorBtn)
        
        
        //set color slider attributes
        self.backgroundSlider = ColorSlider(frame: CGRect(x: 55, y: self.backgroundColorBtn.frame.minY + 5,width:self.currentTabView.frame.width * 0.6, height:20))
        self.backgroundSlider.orientation = .horizontal
        self.backgroundSlider.borderWidth = 2.0
        self.backgroundSlider.borderColor = UIColor.white
        self.backgroundSlider.previewEnabled = true
        self.backgroundSlider.addTarget(self, action: #selector(changedBackgroundColor(_:)), for: .valueChanged)
        self.backgroundSlider.isHidden = true
        
        self.textSlider = ColorSlider(frame: CGRect(x: self.view.frame.width - 45,y: self.textColorBtn.frame.minY - 10 - self.textPostView.frame.height * 0.7 ,width:20, height:self.textPostView.frame.height * 0.7))
        
        self.textSlider.orientation = .vertical
        self.textSlider.borderWidth = 2.0
        self.textSlider.borderColor = UIColor.white
        self.textSlider.previewEnabled = true
        self.textSlider.addTarget(self, action: #selector(changedTextColor(_:)), for: .valueChanged)
        self.textSlider.isHidden = true
        
        //add sliders to view
        self.view.addSubview(textSlider)
        self.view.addSubview(backgroundSlider)
        
        self.textPostView.bringSubview(toFront: backgroundColorBtn)
        self.textPostView.bringSubview(toFront: textColorBtn)
        self.textPostView.bringSubview(toFront: textSlider)
        self.textPostView.bringSubview(toFront: backgroundSlider)
        
        self.hideColorBtns()
        
    }
    
    
    
    //RECORDING VIEW, TAG 4
    func setupRecordingView(center: CGPoint){
        
        self.recordingView = UIView(frame:CGRect.zero)
        self.recordingView.frame.size = self.currentTabView.frame.size
        self.recordingView.backgroundColor = ourColors.getBlackishColor()
        self.recordingView.center = center
        self.recordingView.tag = 4
        
        self.setupMicAccess()
    }
    
    
    //MUSIC VIEW, TAG 5
    func setupMusicView(center: CGPoint){
        
        
        self.musicView = UIView(frame:CGRect.zero)
        self.musicView.frame.size = self.currentTabView.frame.size
        self.musicView.backgroundColor = ourColors.getBlackishColor()
        self.musicView.center = center
        self.musicView.tag = 5
        
        //choose music lable setup
        let label: UILabel = UILabel(frame: CGRect(x: self.musicView.frame.width / 2 - 100,y: 10 ,width: 200, height:30))
        label.text = "Choose a music library"
        label.textColor = UIColor.white
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        
        let appleLibraryBtn: UIButton = UIButton(frame: CGRect(x: self.musicView.frame.width / 2 - self.musicView.frame.width / 4  - 10,y: label.frame.maxY + 20 , width: self.musicView.frame.width / 4,height: self.musicView.frame.width / 4))
        appleLibraryBtn.setImage(UIImage(named:"appleMusicIcon")?.transform(withNewColor: UIColor.white), for: .normal)
        appleLibraryBtn.addTarget(self, action: #selector(self.setupMusicAccess), for: .touchUpInside)
        appleLibraryBtn.contentMode = .scaleAspectFill
        
        let localMusicBtn: UIButton = UIButton(frame: CGRect(x: self.musicView.frame.width / 2 - self.musicView.frame.width / 8,y: label.frame.maxY + 20 , width: self.musicView.frame.width / 4,height: self.musicView.frame.width / 4))
        localMusicBtn.setImage(UIImage(named:"musicFolder"), for: .normal)
        
        localMusicBtn.addTarget(self, action: #selector(self.setupMusicAccess), for: .touchUpInside)
        localMusicBtn.contentMode = .scaleAspectFill
        
//        musicView.addSubview(label)
//        musicView.addSubview(appleLibraryBtn)
        
        //only add localMusic Button for now
        musicView.addSubview(localMusicBtn)
        
        
        //music search bar setup, not currently used
//        self.musicSearch = UISearchBar(frame: CGRect(x: self.musicView.bounds.minX, y: self.musicView.bounds.minY, width:self.musicView.bounds.width, height: 44))
//        self.musicSearch.showsCancelButton = true;
//        self.musicSearch.barStyle = .default
//        self.musicSearch.returnKeyType = .done
//        self.musicSearch.delegate = self
//        self.musicSearch.tintColor = UIColor.black
//        
//        self.musicTableView = UITableView(frame: CGRect(x: self.musicView.bounds.minX, y: self.musicSearch.bounds.maxY, width:self.musicView.bounds.width, height: self.musicView.bounds.height - 44))
//        self.musicTableView.rowHeight = 44.0
//        self.musicTableView.backgroundColor = UIColor.white
//
//        self.musicTableView.allowsSelection = true
//        self.musicTableView.allowsMultipleSelection = false
//        self.musicTableView.separatorStyle = .singleLine
//        self.musicTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.musicTableView.frame.size.width, height: 1))
//        
//        let nib = UINib(nibName: "AddPostTableViewCell", bundle:nil)
//        self.musicTableView.register(nib, forCellReuseIdentifier: "addPostTableCell")
//        self.musicTableView.dataSource = self
//        self.musicTableView.delegate = self
//        
//
//        self.musicView.addSubview(self.musicSearch)
//        self.musicView.addSubview(self.musicTableView)
    }
    
    
    //LINK VIEW, TAG 6
    func setupLinkTextField(center: CGPoint){
        
        self.linkTextField = UITextField(frame: CGRect.zero)
        self.linkTextField.frame.size = CGSize(width: self.currentTabView.frame.width - 20, height: self.currentTabView.frame.height/4)
        self.linkTextField.center = center
        self.linkTextField.backgroundColor = ourColors.getBlackishColor()
        self.linkTextField.adjustsFontSizeToFitWidth = true
        self.linkTextField.clearButtonMode = .whileEditing
        self.linkTextField.returnKeyType = .done
        self.linkTextField.tag = 6
        self.linkTextField.textColor = UIColor.white
        self.linkTextField.tintColor = UIColor.white
//        self.linkTextField.backgroundColor = UIColor.init(white: 1, alpha: 0.8)
        
        let bottomLine = UIView(frame: CGRect(x: self.linkContentView.bounds.minX, y:self.linkContentView.bounds.maxY, width: self.currentTabView.frame.width - 20, height: 1))
        bottomLine.backgroundColor = UIColor.white
        
        self.linkTextField.delegate = self
        linkTextField.attributedPlaceholder =
            NSAttributedString(string: "Paste a link", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        self.linkTextField.addSubview(bottomLine)
        self.linkTextField.textAlignment = .center
    }
    

    //CAMERA VIEW, TAG 7
    func setupCameraView(center: CGPoint){
        
        //setup camera attributes
        self.cameraView = UIImageView(frame: CGRect.zero)
        self.cameraView.frame.size = self.currentTabView.frame.size
        self.cameraView.center = center
        self.cameraView.tag = 7
        self.cameraView.layer.backgroundColor = ourColors.getBlackishColor().cgColor
        self.cameraView.contentMode = .scaleAspectFit
        
    }
    
    
    //set initial tab bar details
    func setupTabBarDetails(){

        tabBar.delegate = self
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
        
        for item: UITabBarItem in tabBar.items!{
            let newImage = item.image?.transform(withNewColor: UIColor.white)
            item.image = newImage
        }
        
//        self.tabBar.selectedItem = tabBar.items?[0]

    }

    
    //tab bar select delegate, calls moveViews based on tab bar item tag
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        self.hideColorBtns()
        self.hideColorSliders()
        
        if (self.isFirstResponder){
            self.resignFirstResponder()
        }

        if self.selectedTab != item.tag{
            
            self.previousSelectedTab = self.selectedTab
            self.selectedTab = item.tag
            
            switch item.tag {
                
            case 1:
                print("Photo Chosen")
                moveViews(newView: self.photoCollectionView)
                
            case 2:
                print("Video Chosen")
                moveViews(newView: self.videoCollectionView)
                
            case 3:
                print("Text Post Chosen")
                moveViews(newView: self.textPostView)
                self.showColorBtns()
                
            case 4:
                print("Recording Chosen")
                
                moveViews(newView: self.recordingView)
                
            case 5:
                print("Music Chosen")
                moveViews(newView: self.musicView)
                self.setupMusicAccess()
                
            case 6:
                print("Link Chosen")
                moveViews(newView: self.linkTextField)
                self.linkTextField.becomeFirstResponder()
                
            case 7:
                
                print("Camera Chosen")
                moveViews(newView: self.cameraView)
                
                imagePicker =  UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                
                present(imagePicker, animated: true, completion: {
                    
                    self.tabBar(self.tabBar, didSelect: (self.tabBar.items?[0])!)
                    self.tabBar.selectedItem = self.tabBar.items?[0]
//                    self.moveViews(newView: self.photoCollectionView)
                })
                
            default:
                print("Default")

            }
        }
    }
    
    
    
    
    /*****************************
     *
     *      ANIMATIONS
     *
     ****************************/
    
    
    //animates the view movement between tabs
    func moveViews(newView: UIView){
        
        let tabViewArray = [self.photoCollectionView, self.videoCollectionView, self.textPostView, self.recordingView, self.musicView, self.linkTextField]
        
        let rightSideCenter: CGPoint = CGPoint(x:self.currentTabView.center.x + self.currentTabView.frame.width, y: self.currentTabView.center.y)
        let leftSideCenter: CGPoint = CGPoint(x:self.currentTabView.center.x - self.currentTabView.frame.width, y: self.currentTabView.center.y)
        
        
        UIView.animate(withDuration: 0.4, animations: {
            
            for view in tabViewArray{
                
                if(view?.tag == newView.tag){
                    
                    view?.center = self.currentTabView.center
                }
                    
                else if ((view?.tag)! < newView.tag){
                    
                    view?.center = leftSideCenter
                    
                }
                else if ((view?.tag)! > newView.tag){
                    
                    view?.center = rightSideCenter
                    
                }
            }
        })
    }

    
    /**************************************
     *
     * TABLE VIEW DELEGATE/DATASOURCE
     *
     ************************************/

//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("Did Select Row")
//        
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        
//        var count = 0;
//        if (self.musicItemsArray != nil){
//           count = self.musicItemsArray.count;
//        }
//        return count;
//        
//    }
//    
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        let cell: AddPostTableViewCell = tableView.dequeueReusableCell(withIdentifier: "addPostTableCell", for: indexPath) as! AddPostTableViewCell
//        
//        let item: MPMediaItem = self.musicItemsArray[indexPath.row] as! MPMediaItem
//        
//        if let artist: String =  item.value(forProperty:MPMediaItemPropertyArtist) as? String {
//            // Add it to the array of valid songs
//            cell.artistLbl.text = artist
//        }
//        
//        if let title: String = item.value(forProperty:MPMediaItemPropertyTitle) as? String{
//            // Add it to the array of valid songs
//            cell.songNameLbl.text = title
//        }
//        
//        if let artwork: MPMediaItemArtwork = item.value(forProperty:MPMediaItemPropertyArtwork) as? MPMediaItemArtwork{
//            cell.songImageView.image = artwork.image(at: CGSize(width: 44, height: 44))
//        }else{
//            
//            cell.songImageView.image = UIImage(named: "musicpink")
//        }
//        
//        return cell
//        
//    }
    
    
    
    

    /******************************************
     *
     *   CollectionView Delegate Methods
     *
     *****************************************/
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //get item count for necessary collection view
        var count: Int = 0
        
        if (collectionView.tag == 1){
            
            if (videosAsset != nil){
                
                count = photosAsset.count
            }
            
            print("Items in Section: ")
            print(count)
            
        }else if (collectionView.tag == 2){
            
            if (videosAsset != nil){
                
               count = videosAsset.count
                
            }
            
            print("Items in Section: ")
            print(count)
            
        }
    
        return count
        
    }
    
    

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
       //return cell for corresponding collection view
        
        var cell: AddPostCollectionViewCell! = AddPostCollectionViewCell()
        
        if (collectionView.tag == 1){
            //photo collection view
            //Modify the cell
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addPostCell", for: indexPath) as! AddPostCollectionViewCell
            
            cell.playImage.isHidden = true
            cell.layer.borderWidth = 3.0
            
            if(indexPath.row == self.selectedPhotoCell){
                cell.layer.borderColor = self.ourColors.getMenuColor().cgColor;
            }else {
                cell.layer.borderColor = UIColor.clear.cgColor
            }
            
            let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
            
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: self.assetThumbnailSize.width * 4, height: self.assetThumbnailSize.height * 4), contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                if result != nil {
                    cell.imageView.image = result
                }
            })
            
        }else if (collectionView.tag == 2){
            //video collectionView
            
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addPostCell", for: indexPath) as! AddPostCollectionViewCell
            
            let asset: PHAsset = self.videosAsset[indexPath.item] as! PHAsset
            cell.layer.borderWidth = 3.0
            
            if(indexPath.row == self.selectedVideoCell){
                cell.layer.borderColor = self.ourColors.getPurpleColor().cgColor
            }else {
                cell.layer.borderColor = UIColor.clear.cgColor
            }
            
            cell.durationLbl.text = String(Int(asset.duration)) + "s"
            
            cell.playImage.isHidden = false
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: self.assetThumbnailSize.width * 4, height: self.assetThumbnailSize.height * 4), contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                if result != nil {
                    cell.imageView.image = result
                }
            })
        }
        
        return cell
    }
    
    
    func collectionView(collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAtIndexPath indexPath:NSIndexPath) -> CGSize
    {
        //cell size, set in tab bar setup
        return self.assetThumbnailSize
        
    }
    
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        //inter cell spacing
        return 2.0
    }
    
    
    func collectionView(collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        //line spacing
        return 2.0
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        
        
        let options: PHImageRequestOptions = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        //PHOTO COLLECTION
        if (collectionView.tag == 1){
            
            self.selectedPhotoCell = indexPath.row
            self.selectedVideoCell = -1
            
            self.hideVideoEditingBtns()
            
            let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
            
            
            //get selected image asset
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: self.assetThumbnailSize.width * 4, height: self.assetThumbnailSize.height * 4), contentMode: .aspectFill, options: options, resultHandler: {(result, info)in
                
                if result != nil {
                    
                    //set photo and selected object data
                    self.setPhotoView(image: result!)
                    self.postPhotoView.layer.borderColor = self.ourColors.getMenuColor().cgColor
                    self.selectedObject = result
                    self.selectedCategory = .Photo
                    self.playBtn.isHidden = false
                    self.circleImageAction(self)
//                    self.showResizeButtons()
                    self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)
                }
            })
            
            
        //VIDEO COLLECTION
        }else if(collectionView.tag == 2){
            
            let asset: PHAsset = self.videosAsset[indexPath.item] as! PHAsset
            
            self.selectedVideoCell = indexPath.row
            self.selectedPhotoCell = -1
            self.hideResizeButtons()
            self.selectedCategory = .Video
            
            //get selected asset
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: self.assetThumbnailSize.width * 4, height: self.assetThumbnailSize.height * 4), contentMode: .aspectFill, options: options, resultHandler: {(result, info)in
                
                if result != nil {
                    
                    let duration: TimeInterval = asset.duration
                    
                    //sets default result as thumbnail image
                    self.setPhotoView(image: result!)
                    self.postPhotoView.layer.borderColor = self.ourColors.getPurpleColor().cgColor
                    
                    self.playBtn.setImage(UIImage(named: "play"), for: .normal)
                    
                    self.hideResizeButtons()
                    self.view.bringSubview(toFront: self.playBtn)
                    
                    //video less than 10 mins (600s)
                    if (duration < 600.0){
                        
                        self.selectedObject = asset
                        self.showVideoEditingBtns()
                        self.playBtn.isHidden = false
                        
                    }else{
                        
                        //length alert
                        let ac = UIAlertController(title: "Video cannot exceed 10 minutes", message: "", preferredStyle: .actionSheet)
                        
                        let trimAction: UIAlertAction = UIAlertAction(title: "Trim Video", style: .default, handler: { (action) in
                            
                            self.selectedObject = asset
                            ac.dismiss(animated: true, completion: nil)
                            self.editVideoAction(self)
//                            self.performSegue(withIdentifier: "toTrimView", sender: self)
                        })
                        
                        let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
                        
                        ac.addAction(trimAction)
                        ac.addAction(cancel)
                        self.present(ac, animated: true)
                        
                    }
                }
            })
        }
        //reload collection data
        self.photoCollectionView.reloadData()
        self.videoCollectionView.reloadData()
    }
    
    
    
    
    /*****************************
     *
     *     Search Bar DELEGATE
     *
     ****************************/
    
//    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//        
//        print("Ended Editing")
////        self.musicTableView.scrollsToTop = true
//        
//        UIView.animate(withDuration: 0.4) {
//            self.tabBar.alpha = 1.0
//            self.tabBar.isHidden = false
//            
//           self.musicView.center = self.currentTabView.center
//        }
//    }
//    
//    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        
//        print("Began Editing")
////        self.musicTableView.scrollsToTop = true
//        
//        UIView.animate(withDuration: 0.4) {
//            self.tabBar.alpha = 0.0
//            self.tabBar.isHidden = true
//            
//            if(self.keyboardHeight == 0.0){
//            
//                self.musicView.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.currentTabView.frame.height/4 + 300))
//            
//            }else{
//            
//                self.musicView.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.musicTableView.frame.height/4 + self.keyboardHeight))
//
//            }
//        }
//    }
//    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        print("Cancel Clicked")
//        searchBar.endEditing(true)
//    }
//    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        
//        print(String(format:"Search String = %@",searchBar.text!))
//        self.musicItemsArray.removeAllObjects()
//        
//        if (searchBar.text == "") {
//            self.musicItemsArray.addObjects(from: self.masterMusicArray as! [MPMediaItem])
//            self.musicTableView.reloadData()
//            return
//        }
//        
//        for obj in self.masterMusicArray{
//            
//            if let item = obj as? MPMediaItem{
//                
//                
//                guard let artist: String =  item.value(forProperty:MPMediaItemPropertyArtist) as? String else{
//                    //return
//                    return
//                }
//                
//                guard let title: String = item.value(forProperty:MPMediaItemPropertyTitle) as? String else{
//                    
//                    // return
//                    return
//                }
//                
//                
//                if (artist.localizedCaseInsensitiveContains(searchText) || title.localizedCaseInsensitiveContains(searchText)){
//                    
//                    self.musicItemsArray.add(item)
//                }
//            }
//        }
//
//        self.musicTableView.reloadData()
//    }
    
    
    
    
    /*****************************
     *
     *     TEXT FIELD DELEGATE
     *
     ****************************/
    

    func textFieldDidEndEditing(_ textField: UITextField) {
        
        self.tabBar.isHidden = false
        
        if textField == self.linkTextField{
            //link text field
            if(self.linkTextField.text! != ""){
                
                let urlString = self.linkTextField.text!
                setURLView(urlString: urlString)
                self.selectedObject = urlString as AnyObject
                self.selectedCategory = .Link
                self.postPhotoView.layer.borderColor = ourColors.getTextPostColor().cgColor
                
            }else{
                self.postPhotoView.isHidden = true
            }
            
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.linkTextField.center = self.currentTabView.center
                
            })
        }else if(textField == self.textPostView){
            //text post view
            //set the text field data as a photo to allow the user to edit with CLImage Editor
            
            self.showColorBtns()
            
            if(self.textPostView.text! != ""){
                
                self.setTextImage()
                
                self.selectedCategory = .Text
                self.postPhotoView.layer.borderColor = ourColors.getTextPostColor().cgColor
                self.playBtn.isHidden = false
                self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)
//                self.showResizeButtons()
                
            }else{
                self.postPhotoView.isHidden = true
            }
            
            //move view back to under the tab bar
            UIView.animate(withDuration: 0.3, animations: {
                
                self.textPostView.center = self.currentTabView.center
                
            })
        }
    }
    
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        self.tabBar.isHidden = true

        self.hideResizeButtons()
        self.hideVideoEditingBtns()
            
        if textField == self.linkTextField{
            
            UIView.animate(withDuration: 0.4, animations: {
                
                if(self.keyboardHeight == 0.0){
                    
                    self.linkTextField.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.linkTextField.frame.height * 2 + 300))
                    
                }else{
                    
                    self.linkTextField.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.linkTextField.frame.height * 2 + self.keyboardHeight))
                }
            })
            
        }else if (textField == self.textPostView){
            
            self.hideColorSliders()
            self.hideColorBtns()
            
            UIView.animate(withDuration: 0.4, animations: {
                
                if(self.keyboardHeight == 0.0){
                    
                    self.textPostView.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.textPostView.frame.height/2 + 300 ))
                    
                }else{
                    
                    self.textPostView.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.textPostView.frame.height/2 + self.keyboardHeight))
                }
            })
            
        }

    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    
    /*****************************
     *
     *  UIImagePicker Methods
     *
     ****************************/
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    //On Photo taken return
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            imagePicker.dismiss(animated: true, completion: nil)
            
            self.setPhotoView(image: image)
            self.postPhotoView.layer.borderColor = self.ourColors.getMenuColor().cgColor
            self.selectedObject = image
            self.selectedCategory = .Photo
            
            self.playBtn.setImage(UIImage(named: "cropClear"), for: .normal)
            self.playBtn.isHidden = false
//            self.showResizeButtons()
            self.hideVideoEditingBtns()
            
            self.tabBar.selectedItem = self.tabBar.items?[0]
            self.moveViews(newView: self.photoCollectionView)
        }
    }
    
    
    
    //----- setMusicItemData(MPMediaItem)
    //----- parameter: MPMediaItem
    //----- If not the primarypost, a video, or a recording will set selectedMediaItem Only
    // ---- If primary post, will set album art as picture, and unhide play button
    // ---- NOTE: Only allows music posts with non-sound producing primary posts
    func setMusicItemData(mpMediaItem: MPMediaItem){
        var artist: String = "Unknown Artist"
        var title: String = "Unknown Title"
        
        if let a: String = mpMediaItem.artist{
            artist = a
        }
        if let t: String = mpMediaItem.title{
            title = t
        }
        
        
        if (self.selectedCategory != .Video && self.selectedCategory != .Recording){
            
            self.musicLbl.text = String(format:"%@ by: %@", title, artist)
            self.musicLbl.isHidden = false
            self.selectedMusicItem = mpMediaItem
            self.appleMusicPlayTrackId()
            
            if self.selectedCategory == .None || self.selectedCategory == .Music{
                
                self.postPhotoView.layer.borderColor = self.ourColors.getMusicColor().cgColor
                let image: UIImage = (mpMediaItem.artwork?.image(at: self.postPhotoView.frame.size))!
                self.setPhotoView(image: image)
                self.selectedObject = mpMediaItem
                self.selectedCategory = .Music
                self.playBtn.setImage(UIImage(named:"play"), for: .normal)
                self.playBtn.isHidden = false
            }
            
        }else{
            self.showToast(message: "Cannot add music to video or recording at this time")
        }
        
        self.hideResizeButtons()
        self.hideVideoEditingBtns()
        
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Error saving photo", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    
    /******************************************************
     *
     *    MARK: - Music Picker Delegate Methods
     *
     ******************************************************/
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {

        dismiss(animated: true, completion: {
            
           self.tabBar.selectedItem = self.tabBar.items?[4]
        })
        
        
        for mpMediaItem in mediaItemCollection.items {
            print("Add \(mpMediaItem) to a playlist, prep the player, etc.")
            
            self.setMusicItemData(mpMediaItem: mpMediaItem)
        }
    }
    
    
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        print("User selected Cancel tell me what to do")
        
        dismiss(animated: true, completion: {
            
            self.tabBar.selectedItem = self.tabBar.items?[4]
            
        })
    }
    
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }

    
    /******************************************************
     *
     *    MARK: - VIDEO EDITOR DELEGATE METHODS
     *
     ******************************************************/
    
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print(error)
    }
    
    //dismiss editor on cancel
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        
        self.dismiss(animated: true) {
            print("edit dismissed")
        }
    }
    
    
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        print(editedVideoPath)
        
        self.trimmedVideoPath = editedVideoPath
        
        self.dataManager.saveVideoToNewPath(path: editedVideoPath, newName: "savedPostData.mp4")
        
        self.editorVC.dismiss(animated: true, completion: {
            
            print("Editor Dismissed")
            self.showVideoEditingBtns()
            self.playBtn.isHidden = false
            
        })
    }
    
    
    /****************************
     *
     *    MARK: - NAVIGATION
     *
     ****************************/
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        self.applicationMusicPlayer.stop()
        
        if segue.identifier == "toMoodSegue"{
            
            let vc: MoodViewController = segue.destination as! MoodViewController
            vc.selectedMood = self.selectedMood
            vc.selectedObject = self.selectedObject
            vc.selectedCategory = self.selectedCategory
            vc.loggedInUser = self.loggedInUser
            vc.selectedVideoPath = self.trimmedVideoPath
            vc.selectedThumbnail = self.selectedThumbnail
            vc.postWasSaved = self.postWasSaved
            vc.selectedMusicItem = self.selectedMusicItem
            //            if self.hasSecondarySavedPost{
            //
            //                vc.secondarySelectedCategory = self.secondarySelectedCategory
            //                vc.secondarySelectedObject = self.secondarySelectedObject
            //                vc.hasSecondaryPost = true
            //            }
            
        } else if segue.identifier == "unwindToCreateCustomPostSegue"{
            
            self.tabBar(self.tabBar, didSelect: (self.tabBar.items?[0])!)
            
        }
//        else if (segue.identifier == "toCropView"){
//            
//            let cropVC: CropViewController = segue.destination as! CropViewController
//            cropVC.originalImage = self.selectedObject
//
//        }
        else if (segue.identifier == "toThumbnailView"){
            
            let thumbVC: SelectThumbnailViewController = segue.destination as! SelectThumbnailViewController
            
            if(self.trimmedVideoPath == ""){
                thumbVC.selectedObject = self.selectedObject
            }else{
                thumbVC.selectedVideoPath = self.dataManager.documentsPathForFileName(name: "savedPostData.mp4").relativePath
                
            }
        }
    }
    
    
    
    @IBAction func unwindToAddPost(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
}
