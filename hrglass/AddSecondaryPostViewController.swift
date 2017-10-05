//
//  AddPostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/25/17.
//
//


import UIKit
import Firebase
import Photos
import URLEmbeddedView
import AVFoundation
import MediaPlayer
import AVKit
import AWSS3



class AddSecondaryPostViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, MPMediaPickerControllerDelegate, UIVideoEditorControllerDelegate{
    
    
    //DEMO COLOR
    let ourColors: Colors = Colors()
    let orangishRed: UIColor = UIColor.init(red: 255.0/255.0, green: 95.0/255.0, blue: 69.0/255.0, alpha: 1.0)
    
    //POST DATA
    var secondaryPostData: PostData!
    var videoStore: VideoStore = VideoStore()
    var dataManager = DataManager()
    var currentUserID = Auth.auth().currentUser?.uid

    
    //TabBar View Variables
    var secondaryPostType: Category = .None
    
    //TabBar Views
    var linkTextField: UITextField!
    var videoCollectionView: UICollectionView!
    var photoCollectionView: UICollectionView!
    var musicView: UIView!
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
    
    var selectedPhotoCell: Int = -1
    var selectedVideoCell: Int = -1
    
    //Slider Btns, and ColorSliders
    var backgroundSlider: ColorSlider!
    var textSlider: ColorSlider!
    var backgroundColorBtn: UIButton!
    var textColorBtn: UIButton!
    
    var selectedObject: AnyObject!
    var selectedCategory: Category = .None
    var trimmedVideoPath: String = ""
    var selectedThumbnail: UIImage!
    
    var selectedTextColor: UIColor!
    var selectedTextBackroungColor: UIColor!
    var useSecondaryPostData: Bool = false
    
    //ContentPreview Views
    var postPhotoView: UIImageView!
    var linkContentView: UILabel!
    var keyboardHeight: CGFloat = 0.0
    var imagePicker: UIImagePickerController!
    var songPicker: MPMediaPickerController!
    var editorVC: UIVideoEditorController!
    var postWasSaved: Bool = false
    
    @IBOutlet weak var editVideoBtn: UIButton!
    @IBOutlet weak var currentTabView: UIView!
    @IBOutlet weak var postContentView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var squareImageBtn: UIButton!
    @IBOutlet weak var circleImagebtn: UIButton!
    @IBOutlet weak var editThumbnailBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    
    
    /********************************
     *
     *  LIFECYCLE METHODS
     *
     ********************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
         NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        //In case phone is in silent mode
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        
        self.view?.backgroundColor = UIColor(white: 1, alpha: 1.0)
        
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        
        //removing bottom navigation line
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
        
        //SETUP
        self.setupContentSubviews()
        
        self.setupMediaAccess()
        
        self.setupPlayBtn()
        
        self.setViewForCategory()
        
        
    }

    

    
    
    func setViewForCategory(){
        
        //on 6+ phones the collection view is slighly off and needs to be recentered on viewDidAppear
        
        let nib = UINib(nibName: "AddPostCollectionViewCell", bundle:nil)
        
        switch self.selectedCategory {
            
        case .Photo:
            
            if(self.selectedObject != nil){
                
                self.setPhotoView(image: (self.selectedObject as? UIImage)!)
                self.playBtn.setImage(UIImage(named: "cropClear"), for: .normal)
                self.playBtn.isHidden = false
                self.postPhotoView.layer.borderColor = ourColors.getMenuColor().cgColor
            }
            
            setupPhotosCollectionView(center: self.currentTabView.center, cellNib: nib)
            self.view.addSubview(photoCollectionView)
            
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
                    self.postPhotoView.layer.borderColor = ourColors.getPurpleColor().cgColor
                    
                }catch{
                    print(error)
                }
                
                self.showVideoEditingBtns()
                
            }
            
            
            setupVideosCollectionView(center: self.currentTabView.center, cellNib: nib)
            self.view.addSubview(videoCollectionView)
            
        case .Text:
            
            if selectedObject != nil{
                
                self.postPhotoView.image = self.selectedObject as? UIImage
                self.postPhotoView.layer.borderColor = UIColor.black.cgColor
            }
            
            let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownAction))
            swipeDown.direction = .down
            swipeDown.delegate = self
            self.view.addGestureRecognizer(swipeDown)
            
            setupTextPostView(center: self.currentTabView.center)
            self.view.addSubview(textPostView)
            
        case .Recording:
            if selectedObject != nil{
                
                self.postPhotoView.image =  UIImage(named: "audioWave")
                self.playBtn.isHidden = false
                self.postPhotoView.layer.borderColor = ourColors.getAudioColor().cgColor
            }
            
            setupRecordingView(center: self.currentTabView.center)
            self.view.addSubview(recordingView)
            
        case .Music:
            setupMusicView(center: self.currentTabView.center)
            self.view.addSubview(musicView)
        case .Link:
            
            if selectedObject != nil{
                setURLView(urlString: self.selectedObject as! String)
                self.postPhotoView.layer.borderColor = UIColor.black.cgColor
            }
            
            let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeDownAction))
            swipeDown.direction = .down
            swipeDown.delegate = self
            self.view.addGestureRecognizer(swipeDown)
            
            setupLinkTextField(center: self.currentTabView.center)
            self.view.addSubview(linkTextField)
            
        default:
            print("")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    func swipeDownAction(){
        
        if self.linkTextField != nil{
            
            self.linkTextField.resignFirstResponder()
            
        }else if self.textPostView != nil{
            
            self.textPostView.resignFirstResponder()
        }
    }
    
    
    func setupPlayBtn(){
        
        self.playBtn = UIButton(frame: CGRect(x: self.postPhotoView.frame.minX,y: self.postPhotoView.frame.minY, width: self.postPhotoView.frame.width, height: self.postPhotoView.frame.height))
        self.playBtn.setImage(UIImage(named:"play"), for: .normal)
        self.playBtn.addTarget(self, action: #selector(self.playBtnAction), for: .touchUpInside)
        self.playBtn.isHidden = true
        self.view.addSubview(self.playBtn)
        self.view.bringSubview(toFront: self.playBtn)
        
    }
    
    
    @objc func keyboardNotification(notification: NSNotification){

        
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
    
    
    
    func changedBackgroundColor(_ slider: ColorSlider) {
        let color = slider.color
        self.textPostView.backgroundColor = color
        self.backgroundColorBtn.backgroundColor = color
        
        self.setTextImage()
        
    }
    
    func changedTextColor(_ slider: ColorSlider) {
        let color = slider.color
        self.textPostView.textColor = color
        self.textColorBtn.backgroundColor = color
        
        self.setTextImage()
        
    }
    
    
    func toggleBackgroundColorSliderVisibility(){
        
        self.hideVideoEditingBtns()
        if self.backgroundSlider.isHidden{
            self.backgroundSlider.isHidden = false
            self.hideResizeButtons()
        }else{
            self.backgroundSlider.isHidden = true
            self.showResizeButtons()
        }
    }
    
    func toggleTextColorSliderVisibility(){
        
        self.hideVideoEditingBtns()
        if self.textSlider.isHidden{
            self.textSlider.isHidden = false
            
        }else{
            self.textSlider.isHidden = true
        }
    }
    
    
    @IBAction func editThumbnailAction(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toThumbnailView", sender: self)
        
    }
    
    @IBAction func editVideoAction(_ sender: Any) {
        
        self.editorVC = UIVideoEditorController()
        editorVC.delegate = self
        editorVC.videoMaximumDuration = 15
        editorVC.videoQuality = .typeHigh
        
        self.showLoadingView()
        
        //If it's still a PHAsset
        if let asset: PHAsset = self.selectedObject as? PHAsset{
            
            self.dataManager.getURLForPHAsset(videoAsset: asset, name: "savedPostData.mp4", completion: { url in
                
                print(url.relativePath)
                let path = url.relativePath
                self.editorVC.videoPath = path
                
                let can = UIVideoEditorController.canEditVideo(atPath:path)
                
                
                if !can {
                    print("can't edit this video")
                    return
                }else{
                    
                    self.present(self.editorVC, animated: true) {
                        print("done")
                        self.hideLoadingView()
                    }
                }
            })
            
        }else{
            //It's stored in Documents as savedPostData.mp4
            let path = self.dataManager.documentsPathForFileName(name: "secondarySavedPostData.mp4")
            self.editorVC.videoPath = path.relativePath
            
            let can = UIVideoEditorController.canEditVideo(atPath:path.relativePath)
            
            if !can {
                print("can't edit this video")
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
    
    
    @IBAction func nextAction(_ sender: Any) {
        
        if selectedObject != nil{
            self.useSecondaryPostData = true
            performSegue(withIdentifier: "unwindToSubmitPost", sender: self)
        }
    }
    
    
    @IBAction func squareImageAction(_ sender: Any) {
        
        self.playBtn.isHidden = true
        self.circleImagebtn.layer.borderColor = UIColor.lightGray.cgColor
        self.circleImagebtn.layer.borderWidth = 1
        self.squareImageBtn.layer.borderColor = UIColor.darkGray.cgColor
        self.squareImageBtn.layer.borderWidth = 2
        
        self.postPhotoView.frame = CGRect(x: 0, y:self.navigationBar.frame.maxY, width:self.view.frame.width, height:self.squareImageBtn.frame.minY - self.navigationBar.frame.maxY - 10)
        
        self.playBtn.center = postPhotoView.center
        
        self.postPhotoView.layer.borderWidth = 0.0
        self.postPhotoView.layer.cornerRadius = 0
        
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
        self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)
        
        self.postPhotoView.layer.borderWidth = 5.0
        self.postPhotoView.layer.cornerRadius = self.postPhotoView.frame.width/2
        
    }
    
    
    
    
    /**************************
     *    RECORDING METHODS
     **************************/
    func startRecording() {
        self.playBtn.setImage(UIImage(named: "play"), for: .normal)
        self.selectedCategory = .Recording
        self.audioURL = self.dataManager.documentsPathForFileName(name: "secondaryRecording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
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
            try audioPlayer = AVAudioPlayer(contentsOf: dataManager.documentsPathForFileName(name: "secondaryRecording.m4a"))
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 30.0
        } catch {
            print(error)
        }
    }
    
    
    
    func loadRecordingUI() {
        
        recordButton = UIButton(frame: CGRect(x: 0, y: 0, width: self.recordingView.bounds.width, height: self.recordingView.bounds.height))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.setTitleColor(UIColor.black, for: .normal)
        recordButton.titleLabel?.textAlignment = .center
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        self.recordingView.addSubview(recordButton)
    }
    
    //RECORD AUDIO
    func recordTapped() {
        if audioRecorder == nil {
            
            self.hideVideoEditingBtns()
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    
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
    func playBtnAction() {
        
        if self.selectedCategory == .Recording{
            
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
                self.playVideoWithURL(view: self, url: self.dataManager.documentsPathForFileName(name: "secondarySavedPostData.mp4"))
            }
            
            
        }
        else if self.selectedCategory == .Photo || selectedCategory == .Text{
            
            self.performSegue(withIdentifier: "toCropView", sender: self)
        }
    }
    
    
    

    
    
    
    
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
     * PHOTO/VIDEO/RECORDING/MUSIX ACCESS METHODS
     *
     ***********************************************************/
    
    func playVideoWithAsset (view: UIViewController, videoAsset: PHAsset) {
        
        guard (videoAsset.mediaType == .video) else {
            print("Not a valid video media type")
            return
        }
        self.showLoadingIndicator()
        dataManager.getURLForPHAsset(videoAsset: videoAsset, name: "savedPostData.mp4", completion:{ url in
            
            DispatchQueue.main.async {
                
                self.hideLoadingIndicator()
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                view.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            }
        })
    }
    
    
    
    func playVideoWithURL(view: UIViewController, url: URL){

        self.showLoadingIndicator()
        
        DispatchQueue.main.async {
            
            self.hideLoadingIndicator()
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            view.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    
    func showLoadingIndicator(){
        self.playBtn.isHidden = true
        self.loadingIndicator.startAnimating()
        self.view.bringSubview(toFront: self.loadingIndicator)
        
    }
    
    
    
    func hideLoadingIndicator(){
        self.playBtn.isHidden = false
        self.loadingIndicator.stopAnimating()
        
    }
    
    
    func setupMusicAccess(){
        
        if (MPMediaLibrary.authorizationStatus() == .authorized){
            
            self.getSongPicker()
            
        }else{
            
            MPMediaLibrary.requestAuthorization { (status) in
                
                switch status
                {
                case .authorized:
                    
                    self.getSongPicker()
                    
                case .denied, .restricted:
                    
                    print("Not allowed")
                    self.accessDeniedAlert()
                    
                case .notDetermined:
                    print("Not determined yet")
                }
                
            }
        }
    }
    
    func getSongPicker(){
        
        songPicker = MPMediaPickerController(mediaTypes: .music)
        songPicker.allowsPickingMultipleItems = false
        songPicker.showsCloudItems = true
        songPicker.delegate = self
        present(songPicker, animated: true, completion:nil)
    }
    
    
    
    func setupMediaAccess(){
        
        if (PHPhotoLibrary.authorizationStatus() == .authorized) {
            
            //Authorized
            self.getMedia()
            
        }else{
            
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
            
            if self.selectedCategory == .Photo{
                self.photoCollectionView.reloadData()
            }
            else if self.selectedCategory == .Video{
                
                self.videoCollectionView.reloadData()
            }
        }
    }
    
    
    
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
    
    
    
    
    /********************************
     *
     *    CONTENT PREVIEW VIEWS
     *
     *********************************/
    
    
    
    func setPhotoView(image: UIImage){
        
        self.postPhotoView.image = image
        self.linkContentView.isHidden = true
        self.postPhotoView.isHidden = false
        self.showResizeButtons()
        
    }
    
    
    func hideResizeButtons(){
        
        self.circleImagebtn.isHidden = true
        self.squareImageBtn.isHidden = true
        
    }
    
    func hideVideoEditingBtns(){
        
        self.editVideoBtn.isHidden = true
        self.editThumbnailBtn.isHidden = true
        
    }
    
    func showVideoEditingBtns(){
        
        self.editVideoBtn.isHidden = false
        self.editThumbnailBtn.isHidden = false
        
    }
    
    
    func showResizeButtons(){
        
        self.circleImagebtn.isHidden = false
        self.squareImageBtn.isHidden = false
        self.view.bringSubview(toFront: self.circleImagebtn)
        self.view.bringSubview(toFront: self.squareImageBtn)
    }
    
    func hideColorSliders(){
        
        self.backgroundSlider.isHidden = true
        self.textSlider.isHidden = true
    }
    
    func hideColorBtns(){
        
        self.backgroundColorBtn.isHidden = true
        self.textColorBtn.isHidden = true
    }
    
    func showColorSliders(){
        
        self.backgroundSlider.isHidden = false
        self.textSlider.isHidden = false
    }
    
    func showColorBtns(){
        
        self.backgroundColorBtn.isHidden = false
        self.textColorBtn.isHidden = false
    }
    
    
    func setURLView(urlString: String){
        
        dataManager.setURLView(urlString: urlString, completion: { (image, label) in
            DispatchQueue.main.async {
                
                self.postPhotoView.image = image
                self.hideResizeButtons()
                
                self.linkContentView.text = label
                self.linkContentView.numberOfLines = 3
                
                self.postPhotoView.isHidden = false
                self.linkContentView.isHidden = false
                
            }
        })
    }
    
    
    
    
    /*****************************
     *
     *     TAB VIEW SETUP
     *
     ****************************/
    

    
    //PHOTO VIEW, TAG 1
    func setupPhotosCollectionView(center: CGPoint, cellNib: UINib){
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        
        self.assetThumbnailSize = CGSize(width:self.currentTabView.bounds.width/3, height:self.currentTabView.bounds.width/3)
        layout.itemSize = assetThumbnailSize
        
        self.photoCollectionView = UICollectionView(frame: self.currentTabView.bounds, collectionViewLayout: layout)
        
        self.photoCollectionView.register(cellNib, forCellWithReuseIdentifier: "addPostCell")
        self.photoCollectionView.tag = 1
        self.photoCollectionView.allowsSelection = true
        self.photoCollectionView.allowsMultipleSelection = false
        self.photoCollectionView.center = self.currentTabView.center
        self.photoCollectionView.backgroundColor = UIColor.white
        self.photoCollectionView.delegate = self
        self.photoCollectionView.dataSource = self
        
    }
    
    //VIDEO VIEW, TAG 2
    func setupVideosCollectionView(center: CGPoint, cellNib: UINib){
        
        
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        self.assetThumbnailSize = CGSize(width:self.currentTabView.bounds.width/3, height:self.currentTabView.bounds.width/3)
        layout.itemSize = assetThumbnailSize
        
        self.videoCollectionView = UICollectionView(frame: CGRect(x: self.currentTabView.center.x + self.currentTabView.frame.width, y: self.currentTabView.center.y, width: self.currentTabView.frame.width, height:self.currentTabView.frame.height), collectionViewLayout: layout)
        
        self.videoCollectionView.register(cellNib, forCellWithReuseIdentifier: "addPostCell")
        self.videoCollectionView.tag = 2
        self.videoCollectionView.allowsSelection = true
        self.videoCollectionView.allowsMultipleSelection = false
        self.videoCollectionView.center = center
        self.videoCollectionView.backgroundColor = UIColor.white
        self.videoCollectionView.delegate = self
        self.videoCollectionView.dataSource = self
        
        self.hideVideoEditingBtns()
        
    }
    
    
    //TEXT VIEW, TAG 3
    func setupTextPostView(center: CGPoint){
        
        self.textPostView = UITextField(frame:CGRect.zero)
        self.textPostView.frame.size = self.currentTabView.frame.size
        self.textPostView.placeholder = "What's on your mind?"
        self.textPostView.backgroundColor = UIColor.white
        self.textPostView.center = center
        self.textPostView.tag = 3
        self.textPostView.delegate = self
        self.textPostView.textAlignment = .center
        
        self.backgroundColorBtn = UIButton(frame: CGRect(x: 15,y: self.currentTabView.frame.minY - 50, width: 30,height: 30))
        self.backgroundColorBtn.clipsToBounds = true
        self.backgroundColorBtn.layer.cornerRadius = backgroundColorBtn.frame.width / 2
        self.backgroundColorBtn.backgroundColor = UIColor.white
        self.backgroundColorBtn.layer.borderColor = UIColor.black.cgColor
        self.backgroundColorBtn.layer.borderWidth = 1.0
        self.backgroundColorBtn.addTarget(self, action: #selector(toggleBackgroundColorSliderVisibility), for: .touchUpInside)
        
        self.textColorBtn = UIButton(frame: CGRect(x: self.textPostView.frame.width - 40,y:self.currentTabView.frame.minY - 50,width: 30,height: 30))
        self.textColorBtn.clipsToBounds = true
        self.textColorBtn.layer.cornerRadius = textColorBtn.frame.width / 2
        self.textColorBtn.backgroundColor = UIColor.black
        self.textColorBtn.layer.borderColor = UIColor.black.cgColor
        self.textColorBtn.layer.borderWidth = 1.0
        self.textColorBtn.addTarget(self, action: #selector(toggleTextColorSliderVisibility), for: .touchUpInside)
        self.textColorBtn.setTitle("T", for: .normal)
        self.textColorBtn.setTitleColor(.white, for: .normal)
        
        self.backgroundSlider = ColorSlider(frame: CGRect(x: 55, y: self.backgroundColorBtn.frame.minY + 5,width:self.currentTabView.frame.width * 0.6, height:20))
        self.backgroundSlider.orientation = .horizontal
        self.backgroundSlider.borderWidth = 2.0
        self.backgroundSlider.borderColor = UIColor.black
        self.backgroundSlider.previewEnabled = true
        self.backgroundSlider.addTarget(self, action: #selector(changedBackgroundColor(_:)), for: .valueChanged)
        self.backgroundSlider.isHidden = true
        
        
        self.textSlider = ColorSlider(frame: CGRect(x: self.textPostView.frame.width - 35,y: self.textColorBtn.frame.minY - 10 - self.textPostView.frame.height * 0.7 ,width:20, height:self.textPostView.frame.height * 0.7))
        self.textSlider.orientation = .vertical
        self.textSlider.borderWidth = 2.0
        self.textSlider.borderColor = UIColor.black
        self.textSlider.previewEnabled = true
        self.textSlider.addTarget(self, action: #selector(changedTextColor(_:)), for: .valueChanged)
        self.textSlider.isHidden = true
        
        self.view.addSubview(backgroundColorBtn)
        self.view.addSubview(textColorBtn)
        self.view.addSubview(textSlider)
        self.view.addSubview(backgroundSlider)
        
        self.textPostView.bringSubview(toFront: backgroundColorBtn)
        self.textPostView.bringSubview(toFront: textColorBtn)
        self.textPostView.bringSubview(toFront: textSlider)
        self.textPostView.bringSubview(toFront: backgroundSlider)
        
    }
    
    //RECORDING VIEW, TAG 4
    func setupRecordingView(center: CGPoint){
        
        self.recordingView = UIView(frame:CGRect.zero)
        self.recordingView.frame.size = self.currentTabView.frame.size
        self.recordingView.backgroundColor = UIColor.white
        self.recordingView.center = center
        self.recordingView.tag = 4
        
        self.setupMicAccess()
    }
    
    //MUSIC VIEW, TAG 5
    func setupMusicView(center: CGPoint){
        
        self.musicView = UIView(frame:CGRect.zero)
        self.musicView.frame.size = self.currentTabView.frame.size
        self.musicView.backgroundColor = UIColor.white
        self.musicView.center = center
        self.musicView.tag = 5
        
        let label: UILabel = UILabel(frame: CGRect(x: self.musicView.frame.width / 2 - 100,y: 10 ,width: 200, height:30))
        label.text = "Choose a music library"
        label.textColor = UIColor.lightGray
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        
        let appleLibraryBtn: UIButton = UIButton(frame: CGRect(x: self.musicView.frame.width / 2 - self.musicView.frame.width / 4  - 10,y: label.frame.maxY + 20 , width: self.musicView.frame.width / 4,height: self.musicView.frame.width / 4))
        appleLibraryBtn.setImage(UIImage(named:"appleMusicIcon"), for: .normal)
        appleLibraryBtn.addTarget(self, action: #selector(self.setupMusicAccess), for: .touchUpInside)
        appleLibraryBtn.contentMode = .scaleAspectFill
        
        let spotifyBtn: UIButton = UIButton(frame: CGRect(x: self.musicView.frame.width / 2 + 10,y: label.frame.maxY + 20 , width: self.musicView.frame.width / 4,height: self.musicView.frame.width / 4))
        spotifyBtn.setImage(UIImage(named:"spotifyIcon"), for: .normal)
        
        //        spotifyBtn.addTarget(self, action: #selector(self.setupMusicAccess), for: .touchUpInside)
        spotifyBtn.contentMode = .scaleAspectFill
        
        musicView.addSubview(label)
        musicView.addSubview(appleLibraryBtn)
        musicView.addSubview(spotifyBtn)
        
    }
    
    
    //LINK VIEW, TAG 6
    func setupLinkTextField(center: CGPoint){
        
        self.linkTextField = UITextField(frame: CGRect.zero)
        self.linkTextField.frame.size = CGSize(width: self.currentTabView.frame.width - 20, height: self.currentTabView.frame.height/4)
        self.linkTextField.center = center
        self.linkTextField.backgroundColor = UIColor.white
        self.linkTextField.adjustsFontSizeToFitWidth = true
        self.linkTextField.clearButtonMode = .whileEditing
        self.linkTextField.returnKeyType = .done
        self.linkTextField.tag = 6
        self.linkTextField.textColor = UIColor.darkGray
        self.linkTextField.backgroundColor = UIColor.init(white: 1, alpha: 0.8)
        
        let bottomLine = UIView(frame: CGRect(x: self.linkContentView.bounds.minX, y:self.linkContentView.bounds.maxY, width: self.currentTabView.frame.width - 20, height: 1))
        bottomLine.backgroundColor = UIColor.white
        
        self.linkTextField.delegate = self
        self.linkTextField.placeholder = "Paste a link"
        self.linkTextField.addSubview(bottomLine)
        self.linkTextField.textAlignment = .center
        
    }
    
    
    func setupCameraView(center: CGPoint){
        
        self.cameraView = UIImageView(frame: CGRect.zero)
        self.cameraView.frame.size = self.currentTabView.frame.size
        self.cameraView.center = center
        self.cameraView.tag = 7
        self.cameraView.layer.backgroundColor = UIColor.white.cgColor
        self.cameraView.contentMode = .scaleAspectFit
        
    }
    
    
//    func setupTabBarDetails(){
//        
//        tabBar.delegate = self
//        UITabBar.appearance().layer.borderWidth = 0.0
//        UITabBar.appearance().clipsToBounds = true
//        //        self.tabBar.selectedItem = tabBar.items?[0]
//        
//    }
    
    
    
    
    
    
    /*****************************
     *
     *      ANIMATIONS
     *
     ****************************/
    
    
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
    
    
    
    
    /*****************************
     *
     *   CollectionView Methods
     *
     ****************************/
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
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
        
        var cell: AddPostCollectionViewCell! = AddPostCollectionViewCell()
        
        if (collectionView.tag == 1){
            
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
            
            PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                if result != nil {
                    cell.imageView.image = result
                }
            })
        }else if (collectionView.tag == 2){
            
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
            PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                if result != nil {
                    cell.imageView.image = result
                }
            })
        }
        
        return cell
    }
    
    
    func collectionView(collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAtIndexPath indexPath:NSIndexPath) -> CGSize
    {
        
        return self.assetThumbnailSize
        
    }
    
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    
    func collectionView(collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //PHOTO COLLECTION
        if (collectionView.tag == 1){
            
            self.selectedPhotoCell = indexPath.row
            self.selectedVideoCell = -1
            
            self.hideVideoEditingBtns()
            
            let asset: PHAsset = self.photosAsset[indexPath.item] as! PHAsset
            
            PHImageManager.default().requestImage(for: asset, targetSize: self.postContentView.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                if result != nil {
                    
                    self.setPhotoView(image: result!)
                    self.postPhotoView.layer.borderColor = self.ourColors.getMenuColor().cgColor
                    self.selectedObject = result
                    self.selectedCategory = .Photo
                    self.playBtn.isHidden = false
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
            
            PHImageManager.default().requestImage(for: asset, targetSize: self.postContentView.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                
                if result != nil {
                    
                    let duration: TimeInterval = asset.duration
                    
                    
                    self.setPhotoView(image: result!)
                    self.postPhotoView.layer.borderColor = self.ourColors.getPurpleColor().cgColor
                    
                    self.playBtn.setImage(UIImage(named: "play"), for: .normal)
                    
                    self.hideResizeButtons()
                    self.view.bringSubview(toFront: self.playBtn)
                    
                    if (duration < 15.0){
                        
                        self.selectedObject = asset
                        self.showVideoEditingBtns()
                        self.playBtn.isHidden = false
                        
                    }else{
                        let ac = UIAlertController(title: "Video cannot exceed 15s", message: "", preferredStyle: .actionSheet)
                        
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
        
        if self.selectedCategory == .Photo{
            self.photoCollectionView.reloadData()
        }else if self.selectedCategory == .Video{
            self.videoCollectionView.reloadData()
        }
    }
    
    
    
    /*****************************
     *
     *     TEXT FIELD DELEGATE
     *
     ****************************/
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
//        self.tabBar.isHidden = false
        
        if self.linkTextField != nil{
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
        }else if(self.textPostView != nil) {
            
            self.showColorBtns()
            
            if(self.textPostView.text! != ""){
                
                self.setTextImage()
                
                self.selectedCategory = .Text
                self.postPhotoView.layer.borderColor = ourColors.getTextPostColor().cgColor
                self.playBtn.isHidden = false
                self.playBtn.setImage(UIImage(named:"cropClear"), for: .normal)
                self.showResizeButtons()
                
            }else{
                self.postPhotoView.isHidden = true
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.textPostView.center = self.currentTabView.center
                
            })
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
//        self.tabBar.isHidden = true
        
        self.hideResizeButtons()
        self.hideVideoEditingBtns()
        
        if self.linkTextField != nil{
            
            UIView.animate(withDuration: 0.3, animations: {
                
                if(self.keyboardHeight == 0.0){
                    
                    self.linkTextField.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.linkTextField.frame.height * 2 + 300))
                    
                }else{
                    
                    self.linkTextField.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.linkTextField.frame.height * 2 + self.keyboardHeight))
                }
            })
            
        }else if (self.textPostView != nil){
            
            self.hideColorSliders()
            self.hideColorBtns()
            
            UIView.animate(withDuration: 0.3, animations: {
                
                if(self.keyboardHeight == 0.0){
                    
                    self.textPostView.center = CGPoint(x:self.currentTabView.center.x , y: self.view.frame.height - (self.textPostView.frame.height/2 + 300))
                    
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
            self.showResizeButtons()
            self.hideVideoEditingBtns()
            
//            self.tabBar.selectedItem = self.tabBar.items?[0]
            self.moveViews(newView: self.photoCollectionView)
        }
        
        
        
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Error saving photo", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    
    /******************************************************
     *
     *    MARK: - Music Picker Methods
     *
     ******************************************************/
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        
        dismiss(animated: true, completion: nil)
        
        for mpMediaItem in mediaItemCollection.items {
            print("Add \(mpMediaItem) to a playlist, prep the player, etc.")
            
            print (mpMediaItem.artist ?? "")
            print (mpMediaItem.albumTitle ?? "")
            print (mpMediaItem.title ?? "")
            
            self.postPhotoView.layer.borderColor = self.ourColors.getAudioColor().cgColor
            
            let image: UIImage = (mpMediaItem.artwork?.image(at: self.postPhotoView.frame.size))!
            self.setPhotoView(image: image)
            
            self.hideResizeButtons()
            self.hideVideoEditingBtns()
            
            self.selectedObject = mpMediaItem
            self.selectedCategory = .Music
        }
    }
    
    
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        print("User selected Cancel tell me what to do")
        
        dismiss(animated: true, completion: {
            
//            self.tabBar(self.tabBar, didSelect: (self.tabBar.items?[0])!)
//            self.tabBar.selectedItem = self.tabBar.items?[0]
            
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
        
        if segue.identifier == "unwindToSubmitPost"{
            
//            let submitVC: SubmitPostViewController = segue.destination as! SubmitPostViewController
            
//            if (self.useSecondaryPostData){
//                
//                submitVC.hasSecondaryPost = true;
//                submitVC.secondarySelectedObject = self.selectedObject
//                submitVC.secondarySelectedCategory = self.selectedCategory
//                
//                if self.selectedCategory == .Video{
//                    
//                    submitVC.selectedThumbnail = self.postPhotoView.image!
//                    
//                    if trimmedVideoPath != ""{
//                        submitVC.selectedVideoPath = self.trimmedVideoPath
//                    }
//                    
//                }
//                
//            }
            
        }else if (segue.identifier == "toCropView"){
            
            let cropVC: CropViewController = segue.destination as! CropViewController
            cropVC.originalImage = self.selectedObject
            cropVC.parentView = "secondaryPostView"
            
        }else if (segue.identifier == "toThumbnailView"){
            
            let thumbVC: SelectThumbnailViewController = segue.destination as! SelectThumbnailViewController
            thumbVC.parentView = "secondaryPostView"
            if(self.trimmedVideoPath == ""){
                thumbVC.selectedObject = self.selectedObject
            }else{
                thumbVC.selectedVideoPath = self.dataManager.documentsPathForFileName(name: "secondarySavedPostData.mp4").relativePath
                
            }
        }
    }
    
    
    
    @IBAction func unwindToAddSecondPost(unwindSegue: UIStoryboardSegue) {
        
        
    }
}

