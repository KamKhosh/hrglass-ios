//
//  SubmitPostViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 6/25/17.
//
//

import UIKit
import FirebaseStorage
import Firebase
import AVFoundation
import AWSS3
import Photos
import AVKit
import MediaPlayer
import Clarifai

class SubmitPostViewController: UIViewController {
    
//    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var postImagePreview: UIImageView!
    @IBOutlet weak var postBtn: UIButton!
    
    var linkContentView: UILabel!
    var currentUserId: String!
    var loggedInUser: User!
    
    let colors: Colors = Colors()
    let dataManager: DataManager = DataManager()
    var awsManager: AWSManager! = nil
    var progressView: ProgressView!
    var timer: Timer!
    var hasSecondaryPost: Bool = false;
    var ref: DatabaseReference!
    var postRef: DatabaseReference!
    
    var transferring: Bool = false
    var addPostCategory: Category = .None
    //set on segue
    var selectedObject: AnyObject!
    var selectedCategory: Category = .None
    var selectedMood: Mood = .None
    var selectedThumbnail: UIImage!
    var selectedVideoPath: String = ""
    var selectedMusicItem: AnyObject!
    
    //secondary post data
//    var secondarySelectedObject: AnyObject!
//    var secondarySelectedCategory: Category = .None
//    var primaryVideoURL: String = ""
//    var secondaryVideoThumbnail: UIImage!
    
    //Bool set to true if user is posting a saved post -- ie sent from the createCustomPostVC
    var postWasSaved: Bool = false
    var buttonArray: NSMutableArray = NSMutableArray()
    var stackView: UIStackView = UIStackView()
    
    
    @IBOutlet weak var musicLbl: UILabel!
    
    //Preview Shape Constraints
    @IBOutlet weak var postPreviewWidth: NSLayoutConstraint!
    @IBOutlet weak var postPreviewHeight: NSLayoutConstraint!
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var moodLbl: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!
    
    //extra content button
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var photoBtn: UIButton!
    var videoBtn: UIButton!
    var textBtn: UIButton!
    var recordingBtn: UIButton!
    var musicBtn: UIButton!
    var linkBtn: UIButton!
    var clarifaiApp: ClarifaiApp!
    
    
    //Secondary Content View
//    @IBOutlet weak var secondaryPostBtn: UIButton!
//    var removeBtn: UIButton = UIButton()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.clarifaiApp = ClarifaiApp.init(apiKey: "f20abe6d4a7042f8967bb30cbc96586b")
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.stopAnimating()
        
        self.awsManager = AWSManager.init(uid: (Auth.auth().currentUser?.uid)!)

        currentUserId = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.postRef = self.ref.child("Posts").child(currentUserId!)

        self.postImagePreview.clipsToBounds = true
        self.postImagePreview.contentMode = .scaleAspectFill
        
        self.linkContentView = UILabel(frame:  CGRect(x: self.postImagePreview.bounds.minX, y: self.postImagePreview.bounds.midX, width: self.postImagePreview.frame.width, height: self.postImagePreview.frame.height/4))
        
        self.linkContentView.textAlignment = .center
        self.linkContentView.backgroundColor = UIColor.darkGray
        self.linkContentView.alpha = 0.7
        self.linkContentView.textColor = UIColor.white
        self.linkContentView.adjustsFontSizeToFitWidth = true
        self.linkContentView.isHidden = true
        
        self.photoBtn = UIButton(type: .custom)
        self.photoBtn.setImage(UIImage(named: "gallery"), for: .normal)
        self.videoBtn = UIButton(type: .custom)
        self.videoBtn.setImage(UIImage(named: "videocall"), for: .normal)
        self.textBtn = UIButton(type: .custom)
        self.textBtn.setImage(UIImage(named: "pencil"), for: .normal)
        self.recordingBtn = UIButton(type: .custom)
        self.recordingBtn.setImage(UIImage(named: "microphone"), for: .normal)
        self.musicBtn = UIButton(type: .custom)
        self.musicBtn.setImage(UIImage(named: "music"), for: .normal)
        self.linkBtn = UIButton(type: .custom)
        self.linkBtn.setImage(UIImage(named: "news"), for: .normal)
        
//        self.photoBtn.addTarget(self, action: #selector(self.photoBtnAction(_:)), for: .touchUpInside)
//        self.videoBtn.addTarget(self, action: #selector(self.videoBtnAction(_:)), for: .touchUpInside)
//        self.textBtn.addTarget(self, action: #selector(self.textBtnAction(_:)), for: .touchUpInside)
//        self.recordingBtn.addTarget(self, action: #selector(self.recordingBtnAction(_:)), for: .touchUpInside)
//        self.musicBtn.addTarget(self, action: #selector(self.musicBtnAction(_:)), for: .touchUpInside)
//        self.linkBtn.addTarget(self, action: #selector(self.linkBtnAction(_:)), for: .touchUpInside)
        
        self.buttonArray = []
        
        
//        if (self.hasSecondaryPost){
//            self.setSecondaryPostButtons(hidden: true)
//            self.addExtraLbl.isHidden = true
//            self.postLabel.text = "Ready to post!"
//        }
        
        
        
        self.postImagePreview.layer.borderColor = dataManager.getUIColorForCategory(category: self.selectedCategory).cgColor
        
        self.stackView = UIStackView(frame: CGRect(x: 30 ,y: self.moodLbl.frame.maxY + 15,width: self.view.frame.width - 60,height: 50))
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillEqually
        self.postBtn.layer.borderWidth = 1.0
        self.postBtn.layer.borderColor = colors.getMenuColor().cgColor
        self.postBtn.layer.cornerRadius = 3.0
        self.postBtn.clipsToBounds = true
        
        
        if self.selectedMood != .None{
            self.moodLbl.text = self.selectedMood.rawValue
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setPreviewImageViewFor(primaryPost: true)
        self.postImagePreview.layer.cornerRadius = self.postImagePreview.frame.height/2
        self.postImagePreview.layer.borderWidth = 3.0
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.postImagePreview.frame.size = CGSize(width: self.postImagePreview.frame.width, height:self.postImagePreview.frame.width)

//        if (self.hasSecondaryPost){
        
//            self.setSecondaryPostButtons(hidden: true)
//            self.addExtraLbl.isHidden = true
//            self.postLabel.text = "Ready to post!"
//            self.uniquePostLbl.isHidden = true
            
//            setupSecondaryBtn();
//        }
    }
//    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
//    func setupSecondaryBtn(){
//        
//        self.secondaryPostBtn.clipsToBounds = true
//        self.secondaryPostBtn.isHidden = false
//        self.secondaryPostBtn.layer.cornerRadius = self.secondaryPostBtn.frame.width / 2
//        self.secondaryPostBtn.layer.borderWidth = 3.0
//        self.secondaryPostBtn.layer.borderColor = dataManager.getUIColorForCategory(category: self.secondarySelectedCategory).cgColor
//        
//        let closeImage: UIImage = UIImage(named: "close")!
//        self.removeBtn = UIButton(frame: CGRect(x: self.secondaryPostBtn.frame.maxX - 3, y: self.secondaryPostBtn.frame.minY - 3, width: 15, height:15))
//        removeBtn.setImage(closeImage, for: .normal)
//        removeBtn.addTarget(self, action: #selector(removeSecondaryPost), for: .touchUpInside)
//        self.view.addSubview(removeBtn)
//        
//        self.setPreviewImageViewFor(primaryPost: false)
//    }
    
    
//    func removeSecondaryPost(){
//        
//        self.secondaryPostBtn.isHidden = true
//        self.hasSecondaryPost = false
//        self.secondarySelectedCategory = .None
//        self.secondarySelectedObject = nil
//        
//        self.setSecondaryPostButtons(hidden: false)
//        self.addExtraLbl.isHidden = false
//        self.postLabel.text = "Let's make this post unique"
//        self.uniquePostLbl.isHidden = false
//        self.removeBtn.removeFromSuperview()
//        
//    }
    
    
//    func setSecondaryPostButtons(hidden: Bool){
//        
//        self.photoBtn.isHidden = hidden
//        self.videoBtn.isHidden = hidden
//        self.textBtn.isHidden = hidden
//        self.recordingBtn.isHidden = hidden
//        self.musicBtn.isHidden = hidden
//        self.linkBtn.isHidden = hidden
//    }
    
    
    
    func setPreviewImageViewFor(primaryPost: Bool){
        
        var categorySwitch:Category = .None
//        if primaryPost {
            categorySwitch = self.selectedCategory
//        }else{
//            categorySwitch = self.secondarySelectedCategory
//        }
        
        if self.selectedMusicItem != nil{
            
            let item: MPMediaItem = self.selectedMusicItem as! MPMediaItem
            
            self.musicLbl.isHidden = false
            
            var artist: String = "Unknown Artist"
            var title: String = "Unknown Title"
            
            if let a: String = item.artist{
                artist = a
            }
            if let t: String = item.title{
                title = t
            }
            
            self.musicLbl.text = String(format: "%@ by: %@", title, artist)
            
        }
        
        
        switch categorySwitch {
            
        case .Photo:
    
            if primaryPost{
                
                self.postImagePreview.image = self.selectedObject as? UIImage
                self.buttonArray.add(self.photoBtn)
                
            }
            
            
//            else{
//                
//                self.secondaryPostBtn.setBackgroundImage(self.secondarySelectedObject as? UIImage, for:UIControlState.normal)
//                
//            }
            
            
        case .Video:
            
            if primaryPost{
                
                self.buttonArray.add(self.videoBtn)
                accessoryImageView.image = UIImage(named: "playTriagle")?.transform(withNewColor: UIColor.darkGray)
                accessoryImageView.isHidden = false
                
                //Set the Photo
                if self.selectedThumbnail == nil{
                    if let asset: PHAsset = self.selectedObject as? PHAsset{
                        
                        PHImageManager.default().requestImage(for: asset, targetSize: self.postImagePreview.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
                            if result != nil {
                                self.postImagePreview.image = result
                            }
                        })
                    }
                    
                }else{

                    self.postImagePreview.image = self.selectedThumbnail
                }
                
            }
            
//            else{
//                if self.selectedThumbnail == nil{
//                    if let asset: PHAsset = self.secondarySelectedObject as? PHAsset{
//                        
//                        PHImageManager.default().requestImage(for: asset, targetSize: self.secondaryPostBtn.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {(result, info)in
//                            if result != nil {
//                                 self.secondaryPostBtn.setBackgroundImage(result, for:UIControlState.normal)
//                            }
//                        })
//                    }
//                    
//                }else{
//                    self.secondaryPostBtn.setBackgroundImage(self.selectedThumbnail, for:UIControlState.normal)
//                }
//            }
            
            
            
        case .Text:
            
            if primaryPost{
                
                self.postImagePreview.image = self.selectedObject as? UIImage
                self.buttonArray.add(self.textBtn)
                
            }
            
//            else{
//                
//                self.secondaryPostBtn.setBackgroundImage(self.secondarySelectedObject as? UIImage, for:UIControlState.normal)
//            }
            
            
        case .Recording:
            
            
            if primaryPost{
                
                self.postImagePreview.image = UIImage(named: "audioWave")
                self.buttonArray.add(self.recordingBtn)
                
            }
            
//            else{
//                
//                self.secondaryPostBtn.setBackgroundImage(UIImage(named: "audioWave"), for:UIControlState.normal)
//            }
            

            
        case .Music:
            if primaryPost{
                self.buttonArray.add(self.musicBtn)
            }
            self.postImagePreview.layer.borderColor = colors.getMusicColor().cgColor
            
            let mediaitem = self.selectedObject as! MPMediaItem
            
            
            //set image
            var image: UIImage = UIImage(named:"default_music")!
            if mediaitem.artwork?.image != nil{
                image = (mediaitem.artwork?.image(at: self.postImagePreview.frame.size))!
            }
            
            self.postImagePreview.image = image
            self.accessoryImageView.image = UIImage(named: "music")
            self.accessoryImageView.isHidden = false
            
        case .Link:
            
            if primaryPost{
               self.buttonArray.add(self.linkBtn)
                setURLView(urlString: self.selectedObject as! String, primary: primaryPost)
            }
//            
//            else{
//                setURLView(urlString: self.secondarySelectedObject as! String, primary: primaryPost)
//            }
            
            

        default:
            print("")
        }
        
        for button in buttonArray{
            self.stackView.addArrangedSubview(button as! UIView)
        }
        
//        self.view.addSubview(self.stackView)

    }
    
    
    @IBAction func secondaryPostAction(_ sender: Any) {
        
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    
    @IBAction func photoBtnAction(_ sender: Any) {
        self.addPostCategory = .Photo
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    @IBAction func videoBtnAction(_ sender: Any) {
        self.addPostCategory = .Video
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    @IBAction func textBtnAction(_ sender: Any) {
        self.addPostCategory = .Text
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    @IBAction func recordingBtnAction(_ sender: Any) {
        self.addPostCategory = .Recording
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    @IBAction func musicBtnAction(_ sender: Any) {
        self.addPostCategory = .Music
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    @IBAction func linkBtnAction(_ sender: Any) {
        self.addPostCategory = .Link
        self.performSegue(withIdentifier:"toAddSecondPost", sender:self)
    }
    
    
    
    
    
    
    
    /*************************************************************************************************
     *
     *      POST ACTION -- on post button touchedUpInside
     *    Checks if user can post, if so will write data to Firebase and AWS (if necessary)
     *
     *
     **************************************************************************************************/
    func nsfwCheckAlert(message:String, title: String){
        
        let alert: UIAlertController = UIAlertController(title:  title, message: message, preferredStyle: .alert)
        let cancel: UIAlertAction = UIAlertAction(title: "Ok", style: .cancel) { (action) in
            
            alert.dismiss(animated: true, completion: nil)
            
        }
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    @IBAction func postAction(_ sender: Any) {
        
        self.activityIndicator.startAnimating()
        self.postBtn.isUserInteractionEnabled = false
        self.postBtn.setTitle("", for: .normal)
        
        let postID: String = currentUserId! + String(Int(Date().millisecondsSince1970))
        let userDictionary: NSDictionary = ["uid": Auth.auth().currentUser!.uid, "profilePhoto": self.loggedInUser.profilePhoto, "name": self.loggedInUser.name, "username":self.loggedInUser.username]
        
        
        
        //check for objectionable content with clarifai and mark as nsfw if it meets the bar
        self.postLabel.text = "Checking for NSFW content..."
        self.checkForNSFWContent(completion: { isNsfw in
            
            if (isNsfw == ""){
                //if is NSFW, change data dictionary nsfw key to value 1
                self.nsfwCheckAlert(message: "Problem checking post for nsfw content", title: "Error")
                
            }else if (isNsfw == "previewphoto"){
                self.nsfwCheckAlert(message: "Post Contains NSFW Content", title: "Rejected")
                
            }else{
                print("Can post content")
                
                self.postCanBePosted(completion: { (success, remainingTime) in
                    
                    if (success){
                        
                        self.transferring = true
                        self.progressView = ProgressView(frame: self.postBtn.bounds)
                        self.progressView.backgroundColor = UIColor.clear
                        self.postBtn.addSubview(self.progressView)
                        self.postLabel.text = "Uploading content..."
                        
                        switch self.selectedCategory {
                            
                            
                            /********************
                             * PHOTO
                             ********************/
                            
                        case .Photo:
                            print("Photo Selected")
                            
                            let uploadImage: UIImage = self.selectedObject as! UIImage
                            
                            //convert uiimage to JPG
                            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
                            self.dataManager.saveImageForPath(imageData: data, name: "post")
                            let path = self.dataManager.documentsPathForFileName(name: "post.jpg")
                            
                            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "post", type:"jpg", completion:{ success in
                                
                                if success{
                                    
                                    print("Success")
                                    
                                    let songString: String = ""
                                    let downloadURL: String = String(format:"%@/%@/images/post.jpg", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                                    let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": downloadURL, "category":"Photo", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                    
                                    if (self.selectedMusicItem != nil){
                                        //music added, set songString in dataDictionary and submit
                                        
                                        self.uploadSongThumbnail(image:self.selectedThumbnail)
                                        self.getSongStringWith(completion: { (string) in
                                            
                                            dataDictionary.setValue(string, forKey: "songString")
                                            self.submitPost(dataDictionary: dataDictionary)
                                            //                                    self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                        })
                                        
                                    }else{
                                        //else no music, submit the post and unwind
                                        
                                        self.submitPost(dataDictionary: dataDictionary)
                                        //                                self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                        
                                    }
                                    
                                }else{
                                    
                                    print("Failure, try again?")
                                    
                                    self.postFailedAlert(title: "Post Failed", message: "try again")
                                }
                            })
                            
                            self.progressUpdateTimer(category: .Photo)
                            
                            
                            
                            /********************
                             * VIDEO
                             ********************/
                        case .Video:
                            
                            print("Video Selected")
                            
                            let uploadImage: UIImage = self.postImagePreview.image!
                            
                            //convert uiimage to JPG
                            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
                            self.dataManager.saveImageForPath(imageData: data, name: "thumbnail")
                            let path = self.dataManager.documentsPathForFileName(name: "thumbnail.jpg")
                            
                            
                            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "thumbnail", type: "jpg", completion: { (success) in
                                
                                if success{
                                    
                                    print("Success thumbnail uploaded")
                                }else{
                                    
                                    print("Failure, try again?")
                                }
                            })
                            
                            
                            let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": "", "category":"Video", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":"","nsfw":"0"]
                            
                            
                            //selectedVideoPath is only avaiable from a saved post that has a video
                            if(self.selectedVideoPath != ""){
                                
                                self.uploadVideo(url: URL(string:self.selectedVideoPath)!, postID: postID, dataDict: dataDictionary, primary: true)
                                
                            }else{
                                
                                let asset: PHAsset = self.selectedObject as! PHAsset
                                
                                self.dataManager.getURLForPHAsset(videoAsset: asset, name: "savedPostData.mp4", completion: { url in
                                    
                                    self.uploadVideo(url: url, postID: postID, dataDict: dataDictionary, primary: true)
                                })
                            }
                            
                            self.progressUpdateTimer(category: .Video)
                            
                            
                            
                            
                            /********************
                             * LINK
                             ********************/
                            
                        case .Link:
                            
                            print("Link Selected")
                            
                            let linkString: String = self.selectedObject as! String
                            
                            self.selectedObject = linkString as AnyObject
                            
                            if(linkString != ""){
                                
                                
                                //                        if self.hasSecondaryPost{
                                //                            self.postSecondaryData(primaryData: dataDictionary)
                                //                        }else{
                                
                                
                                let songString: String = ""
                                let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": linkString, "category":"Link", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                
                                if (self.selectedMusicItem != nil){
                                    
                                    self.uploadSongThumbnail(image:self.selectedThumbnail)
                                    self.getSongStringWith(completion: { (string) in
                                        
                                        dataDictionary.setValue(string, forKey: "songString")
                                        self.submitPost(dataDictionary: dataDictionary)
                                        //                                self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                    })
                                }else{
                                    self.submitPost(dataDictionary: dataDictionary)
                                    //                            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                }
                                
                            }else{
                                
                                self.postFailedAlert(title: "Empty Link", message: "")
                            }
                            
                            
                            
                            
                            
                            /********************
                             * MUSIC
                             ********************/
                        case .Music:
                            
                            print("Music Selected")
                            
                            let item: MPMediaItem = self.selectedObject as! MPMediaItem
                            var title: String = ""
                            var artist: String = ""
                            var album: String = ""
                            
                            if let t: String = item.title {
                                print("no title")
                                title = t
                            }
                            if let a: String = item.artist{
                                print("no artist")
                                artist = a
                            }
                            if let at: String = item.albumTitle{
                                print("no title")
                                album = at
                            }
                            
                            var songString = String(format: "%@:%@:%@", title, artist, album)
                            
                            let uploadImage: UIImage = self.postImagePreview.image!
                            
                            self.uploadSongThumbnail(image:uploadImage)
                            
                            var toExport: URL!
                            if let temp: URL = item.assetURL {
                                toExport = temp
                            }
                            
                            //if an assetURL exists
                            if toExport != nil{
                                
                                self.dataManager.export(toExport, completionHandler: { (url, error) in
                                    
                                    if error == nil{
                                        
                                        if (url != nil){
                                            //if URL is not nil, upload the audio and save the url
                                            self.awsManager.uploadAudioAction(resourceURL: url!, fileName: "music", type:"m4a", completion:{ success in
                                                if success{
                                                    
                                                    songString = songString + ":local"
                                                    let downloadURL: String = String(format:"%@/%@/audio/music.m4a", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                                                    
                                                    let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": downloadURL, "category":"Music", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                                    
                                                    //                            if self.hasSecondaryPost{
                                                    //                                self.postSecondaryData(primaryData: dataDictionary)
                                                    //                            }else{
                                                    self.submitPost(dataDictionary: dataDictionary)
                                                    //                            }
                                                    //                                            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                                    
                                                }else{
                                                    
                                                    print("Failure, try again?")
                                                    self.postFailedAlert(title: "Post Failed", message: "try again")
                                                }
                                            })
                                            
                                            self.progressUpdateTimer(category: .Recording)
                                            
                                        }else {
                                            //if URL is nil, the song is not exportable and we just need to write the itunes search criteria
                                            
                                            songString = songString + ":apple"
                                            let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": "", "category":"Music", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                            
                                            //                            if self.hasSecondaryPost{
                                            //                                self.postSecondaryData(primaryData: dataDictionary)
                                            //                            }else{
                                            self.submitPost(dataDictionary: dataDictionary)
                                            
                                            self.progressUpdateTimer(category: .Recording)
                                            //                            }
                                            //                                    self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                            
                                            
                                        }
                                        
                                    }else{
                                        
                                        print(error?.localizedDescription ?? "error exporting")
                                        
                                    }
                                    
                                })
                                
                            }else{
                                //assetRUL doesn't exists, set source as apple by default so we can get a preview later
                                songString = songString + ":apple"
                                let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": "", "category":"Music", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                
                                //                            if self.hasSecondaryPost{
                                //                                self.postSecondaryData(primaryData: dataDictionary)
                                //                            }else{
                                self.submitPost(dataDictionary: dataDictionary)
                                //                            }
                                
                                self.progressUpdateTimer(category: .Recording)
                                //                        self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                
                            }
                            
                            
                            
                            
                            /********************
                             * RECORDING
                             ********************/
                        case .Recording:
                            
                            //selected object will be of type NSDATA
                            
                            let url = self.dataManager.documentsPathForFileName(name: "recording.m4a")
                            
                            self.awsManager.uploadAudioAction(resourceURL: url, fileName: "post", type:"m4a", completion:{ success in
                                
                                if success{
                                    
                                    let downloadURL: String = String(format:"%@/%@/audio/post.m4a", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                                    
                                    let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": downloadURL, "category":"Recording", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":"","nsfw":"0"]
                                    
                                    //                            if self.hasSecondaryPost{
                                    //                                self.postSecondaryData(primaryData: dataDictionary)
                                    //                            }else{
                                    self.submitPost(dataDictionary: dataDictionary)
                                    //                            }
                                    //                            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                    
                                }else{
                                    
                                    print("Failure, try again?")
                                    self.postFailedAlert(title: "Post Failed", message: "try again")
                                }
                            })
                            
                            self.progressUpdateTimer(category: .Recording)
                            
                            
                            
                            
                            /********************
                             * TEXT
                             ********************/
                        case .Text:
                            
                            print("Text Selected")
                            
                            let uploadImage: UIImage = self.selectedObject as! UIImage
                            
                            //convert uiimage to JPG
                            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
                            self.dataManager.saveImageForPath(imageData: data, name: "post")
                            let path = self.dataManager.documentsPathForFileName(name: "post.jpg")
                            
                            
                            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "post", type:"jpg", completion:{ success in
                                
                                if success{
                                    
                                    print("Success")
                                    
                                    let downloadURL: String = String(format:"%@/%@/images/post.jpg", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
                                    
                                    
                                    //check for song to add
                                    let songString: String = ""
                                    
                                    let dataDictionary: NSMutableDictionary = ["postID":postID,"likes":0,"user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": downloadURL, "category":"Text", "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":songString,"nsfw":"0"]
                                    
                                    if (self.selectedMusicItem != nil){
                                        
                                        self.uploadSongThumbnail(image:self.selectedThumbnail)
                                        self.getSongStringWith(completion: { (string) in
                                            
                                            dataDictionary.setValue(string, forKey: "songString")
                                            self.submitPost(dataDictionary: dataDictionary)
                                            //                                    self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                        })
                                        
                                    }else{
                                        
                                        self.submitPost(dataDictionary: dataDictionary)
                                        //                                self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                                    }
                                    
                                    
                                }else{
                                    
                                    print("Failure, try again?")
                                    self.postFailedAlert(title: "Post Failed", message: "try again")
                                }
                            })
                            
                            self.progressUpdateTimer(category: .Photo)
                            
                        default:
                            print("None, do nothing")
                        }
                        
                    }else{
                        
                        
                        //Calculate and Set Time Remaining Lbl
                        let timeRemaining: Int = Int(remainingTime)
                        var timeString: String = ""
                        var timelbl: String = ""
                        
                        if(((timeRemaining / 1000) % 60) >= 2){
                            timeString = String(format: "%d", timeRemaining / (60*60*1000))
                            timelbl = "hours"
                            
                        }else if(((timeRemaining / 1000) % 60) >= 1){
                            
                            timeString = "1"
                            timelbl = "hour"
                            
                        }else if(((timeRemaining / (1000*60)) % 60) > 0){
                            
                            timeString = String(format:"%d", ((timeRemaining / (1000*60)) % 60))
                            timelbl = "mins"
                            
                        }
                        
                        
                        
                        let alert: UIAlertController = UIAlertController(title: String(format: "%@ %@ until you can post", timeString, timelbl), message: "", preferredStyle: .actionSheet)
                        
                        let cancel: UIAlertAction = UIAlertAction(title: "Cancel" , style: .cancel) {(_) -> Void in
                            
                            alert.dismiss(animated: true, completion: nil)
                            self.activityIndicator.stopAnimating()
                            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                            
                        }
                        
                        
                        let savePost: UIAlertAction = UIAlertAction(title: "Save Post for Later", style: .default){(_) -> Void in
                            
                            alert.dismiss(animated: true, completion: nil)
                            
                            let dataDictionary: NSMutableDictionary = NSMutableDictionary(dictionary: ["postID":postID,"likes":0, "user":userDictionary, "mood": self.selectedMood.rawValue, "views":0, "data": self.selectedObject, "category":self.selectedCategory.rawValue, "creation_date":String(Int(Date().millisecondsSince1970)), "expire_time":String(Int(Date().oneDayFromNowInMillis)), "songString":"","nsfw":"0"])
                            
                            
                            //if music, save thumbnail and set songString in dataDictionary
                            if (self.selectedMusicItem != nil){
                                
                                //set the persitentId as the song string, this way we can easily retrieve the MPMediaItem
                                let persistentID = self.selectedMusicItem.persistentID
                                
                                dataDictionary.setValue(persistentID, forKey: "songString")
                                
                            }
                            
                            self.savePostForLater(primary: true, postData: dataDictionary)
                            
                            self.postBtn.setTitle("Post", for: .normal)
                            self.activityIndicator.stopAnimating()
                            self.postBtn.isUserInteractionEnabled = true
                            
                            self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                            
                            
                            
                            
                            
                            
                            
                            //                    if (self.hasSecondaryPost){
                            //
                            //
                            //                        let secondary: NSMutableDictionary = NSMutableDictionary()
                            //                        secondary.setValue(self.secondarySelectedCategory.rawValue, forKey: "secondaryCategory")
                            //                        secondary.setValue(self.secondarySelectedObject, forKey: "secondaryData")
                            //
                            //
                            //
                            //                        dataDictionary.setValue(secondary, forKey: "secondaryPost")
                            //
                            //                    }
                            
                            
                            
                            
                        }
                        
                        alert.addAction(savePost)
                        alert.addAction(cancel)
                        
                        alert.popoverPresentationController?.sourceRect = self.postBtn.frame
                        alert.popoverPresentationController?.sourceView = self.postBtn
                        
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                })
                
                
                
                
                
                
                
            }
            
        });
        
        
    }
    
    
    
    
    
    
    //uploads image to AWS S3 with name thumbnail.jpg for logged in user
    
    func uploadSongThumbnail(image: UIImage){
        
        //convert uiimage to JPG
        let data: Data = UIImageJPEGRepresentation(image, 0.8)! as Data
        self.dataManager.saveImageForPath(imageData: data, name: "thumbnail")
        let path = self.dataManager.documentsPathForFileName(name: "thumbnail.jpg")
        
        
        self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "thumbnail", type: "jpg", completion: { (success) in
            
            if success{
                
                print("Success thumbnail uploaded")
            }else{
                
                print("Failure, try again?")
            }
        })
        
    }
    
    
    
    
    
    
    
    //Used to get Song Data for saving posts
    //Completion, returns the song string
    //Parameter: dataDictionary
    //Only for Music not as the primary post
    
    func getSongStringWith(completion: @escaping (String) -> ()){
        
        let item: MPMediaItem = self.selectedMusicItem as! MPMediaItem

        var songString = ""
        guard let title: String = item.title else{
            print("no title")
            return
        }
        guard let artist: String = item.artist else{
            print("no artist")
            return
        }
        guard let album: String = item.albumTitle else{
            print("no title")
            return
        }
        
        songString = String(format: "%@:%@:%@", title, artist, album)
        
        if let toExport: URL = item.assetURL {
            
            self.dataManager.export(toExport, completionHandler: { (url, error) in
                
                if error == nil{
                    
                    if url != nil{
                        songString = songString + ":local"
                        
                        self.awsManager.uploadAudioAction(resourceURL: url!, fileName: "music", type:"m4a", completion:{ success in
                            if success{
                                print("song uploaded")
                                
                                completion(songString)
                                
                                
                            }else{
                                
                                print("Failure, try again?")
                                self.postFailedAlert(title: "Post Save Failed", message: "try again")
                            }
                        })
                    }else{
                        
                        songString = songString + ":apple"
                        completion(songString)
                    }
                }
            })
            
        }else{
            songString = songString + ":apple"
            completion(songString)
        }

    }
    
    
    

    
    
    
    /*************************************************************************************************
    *
    *
    *    If Post has a secondary item in the post this method will be called from postAction:
    *
    *
    **************************************************************************************************/
    
    
//    func postSecondaryData(primaryData: NSMutableDictionary){
//
//        let postID: String = primaryData.value(forKey: "postID") as! String
//        let secondaryData: NSMutableDictionary = NSMutableDictionary()
//
//        switch self.secondarySelectedCategory {
//
//        case .Photo:
//            print("Photo Selected")
//
//            let uploadImage: UIImage = self.secondarySelectedObject as! UIImage
//           secondaryData.setValue("Photo", forKey: "secondaryCategory")
//
//            //convert uiimage to JPG
//            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
//            self.dataManager.saveImageForPath(imageData: data, name: "secondaryPost")
//            let path = self.dataManager.documentsPathForFileName(name: "secondaryPost.jpg")
//
//            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "secondaryPost", type:"jpg", completion:{ success in
//                
//                if success{
//                    
//                    print("Success")
//                    
//                    let downloadURL: String = String(format:"%@/%@/images/secondaryPost.jpg", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
//                    
//                    secondaryData.setValue(downloadURL, forKey: "secondaryData")
//                    primaryData.setValue(secondaryData, forKey: "secondaryPost")
//                    self.submitPost(dataDictionary: primaryData)
//                    
//                    
//                }else{
//                    
//                    print("Failure, try again?")
//                    
//                    self.postFailedAlert(title: "Post Failed", message: "try again")
//                }
//            })
//            
//            self.progressUpdateTimer(category: .Photo)
//            
//        case .Video:
//            
//            print("Video Selected")
//            
//            let uploadImage: UIImage = self.secondaryPostBtn.backgroundImage(for: .normal)!
//            secondaryData.setValue("Video", forKey: "secondaryCategory")
//            
//            //convert uiimage to JPG
//            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
//            self.dataManager.saveImageForPath(imageData: data, name: "thumbnail")
//            let path = self.dataManager.documentsPathForFileName(name: "thumbnail.jpg")
//            
//            
//            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "thumbnail", type: "jpg", completion: { (success) in
//                
//                if success{
//                    
//                    print("Success thumbnail uploaded")
//                    
//                }else{
//                    
//                    print("Failure, try again?")
//                    
//                }
//            })
//            
//            if(self.selectedVideoPath != ""){
//                
//                self.uploadVideo(url: URL(string:self.selectedVideoPath)!, postID: postID, dataDict: primaryData, primary: false)
//                
//            }else{
//                
//                let asset: PHAsset = self.secondarySelectedObject as! PHAsset
//                
//                self.dataManager.getURLForPHAsset(videoAsset: asset, name: "savedPostData.mp4", completion: { url in
//                    
//                    self.uploadVideo(url: url, postID: postID, dataDict: primaryData, primary: false)
//                })
//            }
//            
//            self.progressUpdateTimer(category: .Video)
//            
//            
//        case .Link:
//            
//            print("Link Selected")
//            secondaryData.setValue("Link", forKey: "secondaryCategory")
//            let linkString: String = self.selectedObject as! String
//            
//            self.selectedObject = linkString as AnyObject
//            
//            
//            if(linkString != ""){
//                
//                secondaryData.setValue(linkString, forKey: "secondaryData")
//                primaryData.setValue(secondaryData, forKey: "secondaryPost")
//                self.submitPost(dataDictionary: primaryData)
//                
//            }else{
//                
//                self.postFailedAlert(title: "Empty Link", message: "")
//            }
//            
//        case .Music:
//            
//            print("Music Selected")
//            secondaryData.setValue("Music", forKey: "secondaryCategory")
//            
//            //TODO, add music upload
//            
//        case .Recording:
//            
//            //selected object will be of type NSDATA
//            
//            let url = self.dataManager.documentsPathForFileName(name: "recording.m4a")
//            secondaryData.setValue("Recording", forKey: "secondaryCategory")
//            
//            self.awsManager.uploadAudioAction(resourceURL: url, fileName: "post", type:"m4a", completion:{ success in
//                
//                if success{
//                    
//                    let downloadURL: String = String(format:"%@/%@/audio/post.m4a", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
//                    
//                    secondaryData.setValue(downloadURL, forKey: "secondaryData")
//                    primaryData.setValue(secondaryData, forKey: "secondaryPost")
//                    self.submitPost(dataDictionary: primaryData)
//                    
//                }else{
//                    
//                    print("Failure, try again?")
//                    self.postFailedAlert(title: "Post Failed", message: "try again")
//                }
//            })
//            
//            self.progressUpdateTimer(category: .Recording)
//            
//        case .Text:
//            
//            print("Text Selected")
//            secondaryData.setValue("Text", forKey: "secondaryCategory")
//
//            let uploadImage: UIImage = self.secondarySelectedObject as! UIImage
//            
//            //convert uiimage to JPG
//            let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
//            self.dataManager.saveImageForPath(imageData: data, name: "secondaryPost")
//            let path = self.dataManager.documentsPathForFileName(name: "secondaryPost.jpg")
//            
//            self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "secondaryPost", type:"jpg", completion:{ success in
//                
//                if success{
//                    
//                    print("Success")
//                    
//                    let downloadURL: String = String(format:"%@/%@/images/secondaryPost.jpg", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
//                    
//                    secondaryData.setValue(downloadURL, forKey: "secondaryData")
//                    primaryData.setValue(secondaryData, forKey: "secondaryPost")
//                    self.submitPost(dataDictionary: primaryData)
//                    
//                }else{
//                    
//                    print("Failure, try again?")
//                    self.postFailedAlert(title: "Post Failed", message: "try again")
//                }
//            })
//            
//            self.progressUpdateTimer(category: .Photo)
//            
//        default:
//            print("None, do nothing")
//        }
//    }
    
    
    
    
    
    
    
    
    
    
    func setURLView(urlString: String, primary: Bool){
        
        dataManager.setURLView(urlString: urlString, completion: { (image, label) in
            DispatchQueue.main.async {
                
                
                if primary{
                    self.postImagePreview.image = image
                    
                    self.linkContentView.text = label
                    self.linkContentView.numberOfLines = 3
                    
                    self.postImagePreview.isHidden = false
                    self.linkContentView.isHidden = false
                    self.postImagePreview.addSubview(self.linkContentView)
                    
                }
                
//                else{
//                    
//                    self.secondaryPostBtn.setBackgroundImage(image, for:UIControlState.normal)
//                    
//                    self.linkContentView.text = label
//                    self.linkContentView.numberOfLines = 3
//                    
//                    self.postImagePreview.isHidden = false
//                    self.linkContentView.isHidden = false
//                    self.secondaryPostBtn.addSubview(self.linkContentView)
//                    
//                }
            }
        })
    }
    
    
    
    
    
    func uploadVideo(url: URL, postID: String, dataDict: NSMutableDictionary, primary: Bool){
        
        let vUrl: URL = url

        if(self.selectedVideoPath != ""){
            
//            var tmp: URL!
//            if primary{
//                tmp = self.dataManager.documentsPathForFileName(name: "savedPostData")
//            }else{
//                tmp = self.dataManager.documentsPathForFileName(name: "secondarySavedPostData")
//            }
            
            
//            addPostVC.secondarySelectedObject = AVAsset(url: self.selectedVideoPath)
            
//            self.dataManager.saveVideoToNewPath(path: self.selectedVideoPath, newName: "post.mp4")
            
            DispatchQueue.main.async{
                
                self.dataManager.deleteFileAt(path: vUrl.relativeString)
                self.dataManager.deleteFileAt(path: self.selectedVideoPath)
            }
        }
        
        
        self.awsManager.uploadVideoAction(resourceURL: vUrl, fileName: "post", type:"mp4", completion:{ success in
            
            if success{
                
                print("Success, Stop the things")
                
                let downloadURL: String = String(format:"%@/%@/videos/post.mp4", self.awsManager.getS3Prefix(), (Auth.auth().currentUser?.uid)!)
            
                
//                if (!self.hasSecondaryPost) {
                
                    dataDict.setValue(downloadURL, forKey: "data")
                    self.submitPost(dataDictionary: dataDict)
                    
//                }
                
//                else if (self.hasSecondaryPost  && primary){
//                    
//                    self.primaryVideoURL = downloadURL
//                    dataDict.setValue(downloadURL, forKey: "data")
//                    self.postSecondaryData(primaryData: dataDict)
//                    
//                }else if (!primary) {
//                    
//                    let secondaryData: NSMutableDictionary = NSMutableDictionary()
//                    secondaryData.setValue(downloadURL, forKey: "secondaryData")
//                    secondaryData.setValue("Video", forKey: "secondaryCategory")
//                    dataDict.setValue(secondaryData, forKey: "secondaryPost")
//                    
//                    self.submitPost(dataDictionary: dataDict)
//                    
//                }
            }else{
                
                print("Failure, try again?")
                self.postFailedAlert(title: "Post Failed", message: "try again")
            }
        })
    }
    
    
    
    
    
    //Uses Clarifai to determine image content is not nsfw
    func checkForNSFWContent(completion:@escaping (String) -> ()){
        
        //Uses Clarifai API to return a confidence value of NSFW content
        var image: ClarifaiImage = ClarifaiImage()
        let category = self.selectedCategory
        
        if (category == .Photo || category == .Text || category == .Video || category == .Music){
            
            image = ClarifaiImage(image: self.postImagePreview.image)
            
        }else{
            completion("0")
            return
        }
        
        
        self.clarifaiApp.getModelByName("nsfw-v1.0", completion: { (model, error) in
            
            if ((error == nil)){
                model?.predict(on: [image], completion: { (outputArray, error) in
                    if error == nil{
                        let output: ClarifaiOutput = outputArray![0]
                        //                            let response: [String:Any] = output.responseDict! as! [String : Any]
                        if let response = output.responseDict as NSDictionary? as! [String:Any]? {
                            
                            //parse response data
                            let data: NSDictionary = response["data"] as! NSDictionary
                            let concepts: NSArray = data.value(forKey: "concepts") as! NSArray
                            var sfw: Double = 0
                            
                            //get the sfw rating
                            for glob in concepts{
                                let item: NSDictionary = glob as! NSDictionary
                                if (item.value(forKey: "name") as! String == "sfw"){
                                    sfw = item.value(forKey: "value") as! Double
                                }
                            }
                            if (sfw > 0.7){
                                //not nsfw
                                DispatchQueue.main.async(execute: {() -> Void in
                                    self.postLabel.text = ""
                                })
                                completion("0")
                                
                            }else{
                                //nsfw
                                DispatchQueue.main.async(execute: {() -> Void in
                                    self.postLabel.text = "Post marked NSFW"
                                })
                                //denotes the preview photo is nsfw, in time we will add nsfw for videos and we will want to be able to check the preview photo as well as the video
                                completion("previewphoto")
                            }
                        }else{
                            completion("")
                        }
                    }else{
                        completion("")
                    }
                });
            }else{
                completion("")
            }
            
        });
    }
    
    

    
    func submitPost(dataDictionary: NSMutableDictionary){
//        if hasSecondaryPost && selectedCategory == .Video{
//            dataDictionary.setValue(self.primaryVideoURL, forKey: "data")
//        }
        

                self.postRef.setValue(dataDictionary)
                
                //reset comments
                let commentRef: DatabaseReference = Database.database().reference().child("Comments").child(Auth.auth().currentUser!.uid)
                commentRef.removeValue()
                
                DispatchQueue.main.async(execute: {() -> Void in
                    
                    self.activityIndicator.stopAnimating()
                })
                
                self.progressView.percentageComplete = 1.0;
                self.progressView.updateProgress()
        
                let alert: UIAlertController = UIAlertController(title: "Success", message: "", preferredStyle: .alert)
                
                let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default) {(_) -> Void in
                    
                    self.progressView.removeFromSuperview()
                    alert.dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: "unwindToFeed", sender: nil)
                }
                
                alert.addAction(ok)
                self.present(alert, animated: true, completion: nil)
                
                //If post was a saved post, delete it on submission
                if self.postWasSaved{
                    
                    UserDefaults.standard.set([:], forKey:"savedPost")
                    UserDefaults.standard.synchronize()
                    
                }
        
    }


    //Check last post timestamp and return true if it is passed 24 hours
    func postCanBePosted(completion: @escaping (Bool, Double) -> ()){
        
        let expireRef: DatabaseReference = Database.database().reference().child("Posts").child((Auth.auth().currentUser?.uid)!).child("expire_time")
        
        expireRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let expireString: String = snapshot.value as? String{
                
                let expireTime: Double = Double(expireString)!
                let now: Double = Date().millisecondsSince1970
                
                if now > expireTime{
                    
                    completion(true, 0)
                }else{
                    
                    completion(false, expireTime - now)
                }
                
            }else{
                
                completion(true, 0)
            }
        })
    }
    
    
    
    
    func postFailedAlert(title: String, message: String){
        
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default) {(_) -> Void in
            
            self.postBtn.setTitle("Post", for: .normal)
            self.activityIndicator.stopAnimating()
            self.postBtn.isUserInteractionEnabled = true
            
            self.progressView.removeFromSuperview()
            
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }

    
    
    
    
    /***************************************************************************
     * SavePostForLater -- saves dictionary conaining post data to defaults
     *
     *  if the post contains secondary data, it will also save that data
     *
     *****************************************************************************/
    
    
    func savePostForLater(primary: Bool, postData: NSMutableDictionary){
        
        var category: Category = .None
        var object: AnyObject? = nil
        let dictionaryKey: String = "savedPost"
        var dataKey: String = ""
        let thumbnailKey: String = "thumbnail"
//        let musicItemId: MPMediaEntityPersistentID = postData.value(forKey: "songString") as! MPMediaEntityPersistentID
        
        if primary{
            
            category = self.selectedCategory
            object = self.selectedObject
            dataKey = "savedPostData"
        }
        
//        else{
//            
//            category = self.secondarySelectedCategory
//            object = self.secondarySelectedObject
//            dataKey = "secondarySavedPostData"
//            
//        }
        
        if (category != .Video){
            
            self.dataManager.savePostData(category: category, data: object!, primary: primary, completion:{ value in

//                if (!self.hasSecondaryPost){
                    let dataPath = value
                    postData.setValue(dataPath, forKey:"data")
                    
                    let newDict: NSDictionary = postData as NSDictionary
                    
                    UserDefaults.standard.set(newDict, forKey: dictionaryKey)
                    UserDefaults.standard.set(dataPath, forKey: dataKey)
                    UserDefaults.standard.synchronize()
                
                    
//                }else if self.hasSecondaryPost && primary{
//                    let dataPath = value
//                    postData.setValue(dataPath, forKey:"data")
//                    
//                    self.savePostForLater(primary: true, postData: postData)
//
//                }else if (!primary){
//                    
//                    let dataPath = value
//                    let secondaryData: NSMutableDictionary = postData.value(forKey: "secondaryPost") as! NSMutableDictionary
//                    secondaryData.setValue(dataPath, forKey: "secondaryData")
//                    postData.setValue(secondaryData, forKey:"secondaryData")
//                    
//                    let newDict: NSDictionary = postData as NSDictionary
//                    
//                    UserDefaults.standard.set(newDict, forKey: dictionaryKey)
//                    UserDefaults.standard.set(dataPath, forKey: dataKey)
//                    UserDefaults.standard.synchronize()
//                    
//                }
            })
            
        }else{
            
            
            var thumbnailImage: UIImage = self.dataManager.clearImage
            if primary{
                thumbnailImage = self.postImagePreview.image!
                
            }
            
//            else{
//                thumbnailImage = self.secondaryPostBtn.backgroundImage(for: .normal)!
//            }
            
            let data: Data = UIImageJPEGRepresentation(thumbnailImage, 0.8)! as Data
            self.dataManager.saveImageForPath(imageData: data, name: thumbnailKey)
            let tpath = self.dataManager.documentsPathForFileName(name: String(format:"%@.jpg", thumbnailKey))
            
            
            
            self.dataManager.savePostData(category: category, data: object!, primary: primary, completion:{ value in
                
//                if (!self.hasSecondaryPost){
                
                    postData.setValue(self.selectedVideoPath, forKey:"data")
                    postData.setValue(tpath.absoluteString, forKey: thumbnailKey)
                    
                    let newDict: NSDictionary = postData as NSDictionary
                    
                    UserDefaults.standard.set(newDict, forKey: dictionaryKey)
                    UserDefaults.standard.set(self.selectedVideoPath, forKey: dataKey)
                    UserDefaults.standard.synchronize()
                    
                    
//                }else if self.hasSecondaryPost && primary{
//                    
//                    postData.setValue(self.selectedVideoPath, forKey:"data")
//                    postData.setValue(tpath.absoluteString, forKey: thumbnailKey)
//                    
//                    self.savePostForLater(primary: true, postData: postData)
//
//                }else if (!primary){
//                    
//                    postData.setValue(tpath.absoluteString, forKey: thumbnailKey)
//                    let secondaryData: NSMutableDictionary = postData.value(forKey: "secondaryPost") as! NSMutableDictionary
//                    secondaryData.setValue(self.selectedVideoPath, forKey: "secondaryData")
//                    postData.setValue(secondaryData, forKey:"secondaryPost")
//                    
//                    
//                    let newDict: NSDictionary = postData as NSDictionary
//                    
//                    UserDefaults.standard.set(newDict, forKey: dictionaryKey)
//                    UserDefaults.standard.synchronize()
//                    
//                    
//                }
            })
        }
    }
    
    
    
    func progressUpdateTimer(category: Category){
    
        self.postLabel.text = "Uploading..."
        
        switch category {
        case .Photo:
            print("Photo Upload")
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.photoTimer), userInfo: nil, repeats: true)
            
        case .Video:
            
            print("Video Upload")
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.videoTimer), userInfo: nil, repeats: true)
            
        case .Recording:
            
            print("Recording Upload")
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.audioTimer), userInfo: nil, repeats: true)
            
        case .Music:
            print("Music Upload")
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.audioTimer), userInfo: nil, repeats: true)
            
        default:
            print("default")
        }
    }
    
    
    @objc func videoTimer(){
        
        if (self.progressView.percentageComplete <= 1.0){
            
            self.awsManager.videoUploadProgressCheck()
            self.progressView.percentageComplete = CGFloat(self.awsManager.videoUploadProgress)
            self.progressView.updateProgress()
//            print(self.progressView.loadingFrame.frame.width)
//            print(self.progressView.percentageComplete)
            
            
        }else{
            
            self.timer.invalidate()
        }
    }
    
    @objc func photoTimer(){
        
        if (self.progressView.percentageComplete <= 1.0){
            
            self.awsManager.photoUploadProgressCheck()
            self.progressView.percentageComplete = CGFloat(self.awsManager.photoUploadProgress)
            
            self.progressView.updateProgress()
            
        }else{
            
            self.timer.invalidate()
        }
    }
    
    @objc func audioTimer(){
        if (self.progressView.percentageComplete <= 1.0){
            
            self.awsManager.audioUploadProgressCheck()
            self.progressView.percentageComplete = CGFloat(self.awsManager.audioUploadProgress)
            self.progressView.updateProgress()
        }else{
            
            self.timer.invalidate()
        }
    }
    

    
    // MARK: - Navigation
    
    @IBAction func unwindToSubmitPost(unwindSegue: UIStoryboardSegue) {
        
    }
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "unwindToMoodSegue"){
            
            if transferring{
                 self.awsManager.cancelRequest()
            }
        }
//        else if (segue.identifier == "toAddSecondPost"){
//            
//            let addVC: AddSecondaryPostViewController = segue.destination as! AddSecondaryPostViewController
//            addVC.selectedCategory = self.addPostCategory
//            
//
//            if hasSecondaryPost{
//                
//                if self.selectedThumbnail != nil{
//                    addVC.selectedThumbnail = selectedThumbnail
//                }
//                if self.secondarySelectedCategory != .None{
//                    addVC.selectedCategory = secondarySelectedCategory
//                }
//                if self.secondarySelectedObject != nil{
//                    addVC.selectedObject = secondarySelectedObject
//                }
//                if self.selectedVideoPath != ""{
//                    addVC.trimmedVideoPath = self.selectedVideoPath
//                }
//            }
//        }
    }
}






extension Date {
    
    var millisecondsSince1970:Double {
        return Double((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    var oneDayFromNowInMillis:Double{
        
        return Double((self.timeIntervalSince1970 * 1000.0 + 86400000).rounded())
        
    }
    
    init(milliseconds:Double) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
