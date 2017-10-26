//
//  ProfileViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/11/17.
//
//

import UIKit
import Firebase
import URLEmbeddedView
import AVKit
import AVFoundation
import CLImageEditor


class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, PostViewDelegate, CLImageEditorDelegate{
    
    let dataManager = DataManager()
    let colors = Colors()
    var progressView: ProgressView!
    var timer: Timer!
    
    //DataSource
    var latestPostData:PostData!
    var likedDataArray = [PostData]()
    var ref: DatabaseReference = Database.database().reference()
    var latestPostRef: DatabaseReference!
    var imageCache: ImageCache = ImageCache()
    var awsManager: AWSManager! = nil
    
    //Must set User in prepare segue in this VC's parent
    var currentlyViewingUser: User!
    var currentlyViewingUID: String = ""
    var follwBtnIsUnfollow: Bool = false
    var isChoosingProfile: Bool = false
    let imagePicker = UIImagePickerController()
    
    //table view with one cell
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var coverPhoto: UIImageView!
    
    
    /*******************************
     *
     *  LIFECYCLE
     *
     *******************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.profileTableView.delegate = self
        self.profileTableView.dataSource = self
        self.imagePicker.delegate = self
        //In case phone is in silent mode
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        
        self.profileTableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        
        
        //If the current user was set before in prepare for segue
        if currentlyViewingUser != nil{
            
            currentlyViewingUID = (Auth.auth().currentUser?.uid)!
            awsManager = AWSManager(uid: currentlyViewingUID)
            
            
            //PULLED FROM FIREBASE
            self.getLatestPostData()
            self.getLikedPostData()
            
            //SET THE CURRENT USER COVER PHOTO AS BACKGROUND
            if (currentlyViewingUser.coverPhoto != ""){
                 
                if dataManager.localPhotoExists(atPath: "coverPhoto"){
                        
                    self.coverPhoto.image = dataManager.getImageForPath(path:"coverPhoto")

                }else{
                        
                    dataManager.syncProfilePhotosToDevice(user: self.currentlyViewingUser, path: "coverPhoto", completion: { image in
                            
                        self.coverPhoto.image = image
                    })
                }
            }else{
                
                self.coverPhoto.image = dataManager.clearImage
                self.view.backgroundColor = UIColor.white
            }
            
            self.profileTableView.reloadData()
            
        }else{
            
            // GET USER COVER PHOTO FROM BACKEND
            if (currentlyViewingUID != "")
            {
                let userRef = ref.child("Users").child(currentlyViewingUID)
                self.editBtn.isHidden = true
                awsManager = AWSManager(uid: currentlyViewingUID)
                
                userRef.observeSingleEvent(of: .value, with: { snapshot in
                    
                    if let userDict:NSMutableDictionary = snapshot.value as? NSMutableDictionary {
                        
                        self.currentlyViewingUser = self.dataManager.setupUserData(data: userDict, uid: self.currentlyViewingUID)
                        
                        if (self.currentlyViewingUser.coverPhoto != ""){
                            
                            self.imageCache.getImage(urlString: self.currentlyViewingUser.coverPhoto, completion: { image in

                                    self.coverPhoto.image = image
                            })
                            
                        }else{
                            
                            self.coverPhoto.image = self.dataManager.clearImage
                            self.view.backgroundColor = UIColor.white
                            
                        }
                        
                        self.profileTableView.reloadData()
                        
                        //PULLED FROM FIREBASE
                        self.getLatestPostData()
                        self.getLikedPostData()
            
                    }
                })
            }
        }
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    
    deinit{
        
        self.awsManager = nil
        self.imageCache = ImageCache()
        self.currentlyViewingUser = nil
        self.currentlyViewingUID = ""
        self.likedDataArray = [PostData]()
        
    }
    
    
    
    

    @IBAction func editAction(_ sender: Any) {
        
        let editAlert: UIAlertController = UIAlertController(title: "Edit Profile Pictures", message: "", preferredStyle: .actionSheet)
        
        let profilePhotoAction: UIAlertAction = UIAlertAction(title: "Change Profile Photo", style: .default) { (success) in
            
            print("chose to edit profile picture")
            self.isChoosingProfile = true
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            
            self.presentImagePicker()
        }
        
        let coverPhotoAction: UIAlertAction = UIAlertAction(title: "Change Cover Photo", style: .default) { (success) in
            
            print("chose to edit profile picture")
            
            self.isChoosingProfile = false
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            
            self.presentImagePicker()
        }
        
        let editBioAction: UIAlertAction = UIAlertAction(title: "Edit Bio", style: .default) { (success) in
            
            print("chose to bio")
            let indexPath: IndexPath = IndexPath(row: 0, section: 0)
            let cell: ProfileTableViewCell = self.profileTableView.cellForRow(at: indexPath) as! ProfileTableViewCell
            cell.bioTextView.becomeFirstResponder();
            editAlert.dismiss(animated: true, completion: nil)
            
        }
        
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { (success) in
            
            print("chose to edit profile picture")
            editAlert.dismiss(animated: true, completion: nil)
        }
        
        editAlert.addAction(profilePhotoAction)
        editAlert.addAction(coverPhotoAction)
        editAlert.addAction(editBioAction)
        editAlert.addAction(cancel)
        
        self.present(editAlert, animated: true, completion: nil)
        
    }
    
    
    
    
    func presentImagePicker(){
        
        present(self.imagePicker, animated: true, completion: nil)
    }
    
    
    
    
    func postFailedAlert(title: String, message: String){
        
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default) {(_) -> Void in
            
            alert.dismiss(animated: true, completion: nil)
            
        }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    func uploadCoverPhoto(completion: @escaping (String) -> ()){
        
        let imageName: String = "coverPhoto.jpg"
        
        let coverRef = self.ref.child("Users").child(currentlyViewingUser.userID as String)
        
        let uploadImage: UIImage = self.coverPhoto.image!
        
        let data: Data = UIImageJPEGRepresentation(uploadImage, 0.8)! as Data
        
        //Save photo to local documents dir
        dataManager.saveImageForPath(imageData: data, name: "coverPhoto")
        
        let path = dataManager.documentsPathForFileName(name: "coverPhoto.jpg")
        
        self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "coverPhoto", type:"jpg", completion:{ success in
            
            if success{
                
                print("Success, Stop the things")
                
                let downloadURL: String = String(format:"%@/%@/images/\(imageName)", self.awsManager.getS3Prefix(), self.currentlyViewingUID)
                self.currentlyViewingUser.coverPhoto = downloadURL as String
                coverRef.child("coverPhoto").setValue(downloadURL)
                completion(downloadURL)
                
            }else{
                
                print("Failure, try again?")
                self.postFailedAlert(title: "Post Failed", message: "try again")
                
                return
            }
        })
    }
    
    
    
    
    
    func uploadProfilePhoto(completion: @escaping (String) -> ()){
        
        let imageName: String = "profilePhoto.jpg"
        
        let profileRef = self.ref.child("Users").child(currentlyViewingUser.userID as String)

        let path = dataManager.documentsPathForFileName(name: "profilePhoto.jpg")
        
        self.awsManager.uploadPhotoAction(resourceURL: path, fileName: "profilePhoto", type:"jpg", completion:{ success in
            
            if success{
                
                print("Success, Stop the things")
                
                //store downloadURL
                let downloadURL: String = String(format:"%@/%@/images/\(imageName)", self.awsManager.getS3Prefix(), self.currentlyViewingUID)
                
                self.currentlyViewingUser.profilePhoto = downloadURL as String
                
                profileRef.child("profilePhoto").setValue(downloadURL)
                
//                self.updatePostPhotoURL(urlString: downloadURL)
                
                completion(downloadURL)
                
            }else{
                
                print("Failure, try again?")
                self.postFailedAlert(title: "Post Failed", message: "try again")
                
                return
            }
        })
        
    }
    
    
    
    
    
    /************************
     *
     * IMAGE PICKER DELEGATE
     *
     ***********************/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        //if picture is edited use the edited version
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            
            if (isChoosingProfile){
                
                let indexPath: IndexPath = IndexPath(row: 0, section: 0)
                let cell: ProfileTableViewCell = self.profileTableView.cellForRow(at: indexPath) as! ProfileTableViewCell
                
                cell.profilePhoto.contentMode = .scaleAspectFill
                
                let data: Data = UIImageJPEGRepresentation(editedImage, 0.8)! as Data
                dataManager.saveImageForPath(imageData: data, name: "profilePhoto")
                
                cell.profilePictureIndicator.startAnimating()
                
                self.uploadProfilePhoto(completion: { (url) in
                    print(url)
                    
                    self.imageCache.replacePhotoForKey(url: url, image: editedImage)
                    self.profileTableView.reloadData()
                    cell.profilePictureIndicator.stopAnimating()
                })
                
            }else{
                
                coverPhoto.contentMode = .scaleAspectFill
                coverPhoto.image = editedImage
                
                self.uploadCoverPhoto(completion: { (url) in
                    print(url)
                    self.imageCache.replacePhotoForKey(url: url, image: editedImage)

                })
            }
        }
            
        else{
            //else use the original
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                if (isChoosingProfile){
                    
                    let indexPath: IndexPath = IndexPath(row: 0, section: 0)
                    let cell: ProfileTableViewCell = self.profileTableView.cellForRow(at: indexPath) as! ProfileTableViewCell
                    
                    cell.profilePhoto.contentMode = .scaleAspectFill

                    let data: Data = UIImageJPEGRepresentation(pickedImage, 0.8)! as Data
                    dataManager.saveImageForPath(imageData: data, name: "profilePhoto")
                    
                    cell.profilePictureIndicator.startAnimating()
                    self.profileTableView.reloadData()
                    
                    self.uploadProfilePhoto(completion: { (url) in
                        print(url)
                        
                        self.imageCache.replacePhotoForKey(url: url, image: pickedImage)
                        self.profileTableView.reloadData()
                        cell.profilePictureIndicator.stopAnimating()
                    })
                    
                }else{
                    
                    coverPhoto.contentMode = .scaleAspectFill
                    coverPhoto.image = pickedImage
                    self.uploadCoverPhoto(completion: { (url) in
                        print(url)
                        self.imageCache.replacePhotoForKey(url: url, image: pickedImage)
                    })
                }
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
//    func progressUpdateTimer(){
//        
//        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.photoTimer), userInfo: nil, repeats: true)
//    }
//    
//    
//    func photoTimer(){
//        
//        if (self.progressView.percentageComplete <= 1.0){
//            
//            self.awsManager.photoUploadProgressCheck()
//            self.progressView.percentageComplete = CGFloat(self.awsManager.photoUploadProgress)
//            
//            self.progressView.updateProgress()
//            
//        }else{
//            
//            self.timer.invalidate()
//        }
//    }
    
    
    
    //CLImageEditor Delegate Functions
    func presentImageEditorWithImage(image:UIImage){
        
        guard let editor = CLImageEditor(image: image, delegate: self) else {
            
            return;
        }
        
        editor.theme.backgroundColor = UIColor.white
        editor.theme.toolbarColor = UIColor.white
        editor.theme.toolbarTextColor = UIColor.lightGray
        editor.theme.toolIconColor = "black"
        
        self.present(editor, animated: true, completion: {});
    }
    
    
    
    func imageEditor(_ editor: CLImageEditor!, didFinishEditingWith image: UIImage!) {

        let indexPath: IndexPath = IndexPath(row: 0, section: 0)
        let cell: ProfileTableViewCell = self.profileTableView.cellForRow(at: indexPath) as! ProfileTableViewCell
        
        cell.profilePhoto.contentMode = .scaleAspectFill
        cell.profilePhoto.image = image
        self.profileTableView.reloadData()
        
        editor.dismiss(animated: true, completion: nil)
        
    }
    
    
    
    
    
    

    /*******************************
     *
     *  Post Profile Photo Update
     *
     ******************************/
    
    //In the case where the user updates their profile picture with a current post we need to update the post profilephotos download URL
    
//    func updatePostPhotoURL(urlString: String){
//        
//        let postRef: DatabaseReference = self.ref.child("Posts").child(currentlyViewingUser.userID as String).child("user")
//        
//        postRef.observeSingleEvent(of: .value, with: { snapshot in
//            
//            if let _: NSDictionary = snapshot.value as? NSDictionary{
//                
//                postRef.child("profilePhoto").setValue(urlString)
//                
//            }
//        })
//    }
    
    
    
    /******************************************************************************
     *
     *      Latest Post DATA RETRIEVAL
     *      -- sets self.latestPostData to nil if the post is expired
     *****************************************************************************/
    
    func getLatestPostData(){
        
        if (currentlyViewingUser != nil){
            
            let uid = self.currentlyViewingUID
            latestPostRef = ref.child("Posts").child(uid)
            latestPostRef.observeSingleEvent(of: .value, with: { snapshot in
                
                if let postData: NSDictionary = snapshot.value as? NSDictionary {
                    
                        if let _: NSMutableDictionary = postData.value(forKey: "liked_by_list") as? NSMutableDictionary{
                            
                            
                            self.latestPostData = self.dataManager.getPostDataFromDictionary(postDict: postData, uid: uid)
                            if (Double(self.latestPostData.expireTime)! < Date().millisecondsSince1970) {
                                
                                self.latestPostData = nil
                            }else{
                                self.latestPostData.category = Category(rawValue: postData.value(forKey: "category") as! String)!
                            }
                            
                            
                        }else{
                            postData.setValue([:], forKey: "liked_by_list")
                            self.latestPostData = self.dataManager.getPostDataFromDictionary(postDict: postData, uid: uid)
                            if (Double(self.latestPostData.expireTime)! < Date().millisecondsSince1970) {
                                
                                self.latestPostData = nil
                            }else{
                                self.latestPostData.category = Category(rawValue: postData.value(forKey: "category") as! String)!
                            }
                        }
    
                    
                        self.profileTableView.reloadData()
                        
                } else{
                    
                    //NO Post Data
                    print("No Recent Post Data")

                }
            })
        }
    }
    
    
    /**********************************
     *
     * TABLE VIEW DELEGATE METHODS
     *
     **********************************/
    
    //We use a tableView with the profile as one cell so we can use a horizonantal collection view and still be
    //able to scroll vertically -- however, for now I've disabled collection view scrolling as I'm not sure we want it
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ProfileTableViewCell = profileTableView.dequeueReusableCell(withIdentifier: "profileCell") as! ProfileTableViewCell
        
        cell.bioTextView.delegate = self
        cell.likedDataArray = self.likedDataArray
        
        if currentlyViewingUser != nil{
            
            cell.nameLbl.text = currentlyViewingUser.name as String
            
            if(currentlyViewingUser.bio as String == ""){
                
                cell.bioTextView.text = "Write about yourself..."
                cell.bioTextView.textColor = UIColor.lightGray
                
            }else{
                cell.bioTextView.text = currentlyViewingUser.bio as String
            }
            
            self.adjustUITextViewHeight(arg: cell.bioTextView)
            
            cell.postsUserLikedLbl.text = String(format: "Content %@ liked", currentlyViewingUser.name)
            
            //HIDE FOLLOW BUTTON IF VIEWING YOUR OWN PROFILE
            if(currentlyViewingUser.userID as String == Auth.auth().currentUser?.uid){
                cell.followBtn.isHidden = true
                cell.bioTextView.isUserInteractionEnabled = true
            }else{
                
                cell.bioTextView.isUserInteractionEnabled = false
                if (follwBtnIsUnfollow){
                    
                    cell.followBtn.setTitle("Unfollow", for: .normal)
                    cell.followBtn.setTitleColor(colors.getMenuColor(), for: .normal)
                    cell.followBtn.backgroundColor = UIColor.clear
                    
                }else{

                    cell.followBtn.backgroundColor = colors.getMenuColor()
                }
            }
        }
        
        
        cell.followBtn.layer.cornerRadius = 5.0
        cell.followBtn.layer.borderColor = colors.getMenuColor().cgColor
        cell.followBtn.layer.borderWidth = 1
        
        cell.latestPostBackground.layer.cornerRadius = cell.latestPostBackground.frame.width / 2
        cell.latestPostImageButton.layer.cornerRadius = cell.latestPostImageButton.frame.width / 2
        cell.latestPostBackground.layer.borderWidth = 5.0
        
        cell.latestPostImageButton.clipsToBounds = true
        cell.latestPostImageButton.setBackgroundImage(dataManager.clearImage, for: .normal)
        
        cell.postIndicator.startAnimating()
        cell.profilePictureIndicator.startAnimating()
        
        cell.bioTextView.textColor = UIColor.white
        
        cell.user = self.currentlyViewingUser
        cell.likedCollectionView.reloadData()
    

        //use enum switch to determine UIImageView Image
        
        if self.latestPostData != nil{
            
            cell.latestPostBackground.isHidden = false
            cell.latestPostImageButton.isHidden = false
            cell.playImageView.isHidden = true
            cell.noRecentPostsLbl.isHidden = true
        
            cell.latestPostBackground.layer.borderColor = self.dataManager.getUIColorForCategory(category: self.latestPostData.category).cgColor
            
            
            
            
            switch self.latestPostData.category {
                
            case .Link:
                
                dataManager.setURLView(urlString: latestPostData.data as String, completion: { (image, label) in

                    cell.latestPostImageButton.setBackgroundImage(image, for: .normal)
                    
                    let linkLabel = UILabel(frame: CGRect(x: cell.latestPostImageButton.bounds.minX, y:cell.latestPostImageButton.bounds.midY, width: cell.latestPostImageButton.frame.width ,height: cell.latestPostImageButton.frame.height/3))
                    
                    linkLabel.adjustsFontSizeToFitWidth = true
                    linkLabel.numberOfLines = 3
                    linkLabel.backgroundColor = UIColor.darkGray
                    linkLabel.alpha = 0.7
                    linkLabel.text = label
                    linkLabel.textAlignment = .center
                    linkLabel.textColor = UIColor.white
                    
                    cell.latestPostImageButton.addSubview(linkLabel)
                    cell.postIndicator.stopAnimating()
                    
                })

                
            case .Music:
                
                print("Music")
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), currentlyViewingUID)
                
                self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                    
                    cell.latestPostImageButton.setBackgroundImage(image, for: .normal)
                    cell.playImageView.isHidden = false
                    cell.postIndicator.stopAnimating()
                    
                })
                
            case .Video:
                
                let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), currentlyViewingUID)
                
                self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                    
                    cell.latestPostImageButton.setBackgroundImage(image, for: .normal)
                    cell.playImageView.isHidden = false
                    cell.postIndicator.stopAnimating()
                    
                })

                
            case .Photo:

                self.imageCache.getImage(urlString: latestPostData.data, completion: { image in
                    
                    cell.latestPostImageButton.setBackgroundImage(image, for: .normal)
                    cell.postIndicator.stopAnimating()
                    
                })
                
                
            case .Recording:
                
                print("Recording")
                cell.latestPostImageButton.setBackgroundImage(UIImage(named:"audioWave"), for: .normal)
                cell.playImageView.isHidden = false

                
            case .Text:

                print("Text")
                self.imageCache.getImage(urlString: latestPostData.data, completion: { image in
                    
                    cell.latestPostImageButton.setBackgroundImage(image, for: .normal)
                    cell.postIndicator.stopAnimating()
                    
                })
            default:
                print("default")
                
            }
            
        }else{
            
            cell.latestPostBackground.isHidden = true
            cell.latestPostImageButton.isHidden = true
            cell.noRecentPostsLbl.isHidden = false
            
        }
        
        
        if (currentlyViewingUser != nil){
            
            if (currentlyViewingUser.bio == ""){
                
                cell.bioTextView.frame.size = CGSize(width: cell.bioTextView.frame.width, height:0)
                
            }
            
            
            if (currentlyViewingUser.profilePhoto != ""){
                
                if currentlyViewingUID == Auth.auth().currentUser?.uid{
                    
                    cell.profilePhoto.image = dataManager.getImageForPath(path:"profilePhoto")
                    cell.profilePictureIndicator.stopAnimating()
                    
                }else{
                    
                    self.imageCache.getImage(urlString: self.currentlyViewingUser.profilePhoto, completion: { image in
                        
                        cell.profilePhoto.image = image
                        cell.profilePictureIndicator.stopAnimating()
                        
                    })
                }
            }else{
                
                 cell.profilePhoto.image = dataManager.defaultsUserPhoto
            }

            cell.profilePhoto.layer.cornerRadius = cell.profilePhoto.frame.width / 2
            cell.profilePhoto.clipsToBounds = true
            
            let followedByCountRef: DatabaseReference = self.ref.child("FollowedBy").child(currentlyViewingUID).child("followed_by_count")
            let followingCountRef: DatabaseReference = self.ref.child("Following").child(currentlyViewingUID).child("following_count")
            
            followedByCountRef.observeSingleEvent(of: .value, with: { (snapshot) in

                if (snapshot.exists()){
                    cell.followerLbl.text = String(describing: snapshot.value as! NSInteger)
                }else{
                    cell.followerLbl.text = "0"
                }
                
            })
            
            
            followingCountRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if (snapshot.exists()){
                    cell.followingLbl.text = String(describing: snapshot.value as! NSInteger)
                }else{
                    cell.followingLbl.text = "0"
                }
                
            })
        }
        
        
        
        //Uses the selectedCellRow property of ProfileTableViewCell which will contain the selected cell row
        // to get the correct likedDataArray object
        cell.collectionContentSelected = {
            
            let collCellData: PostData = self.likedDataArray[cell.selectedCellRow]
            
            let postVC: PostViewController = self.storyboard!.instantiateViewController(withIdentifier: "postViewController") as! PostViewController
            
            postVC.delegate = self
            postVC.imageCache = self.imageCache
            postVC.postData = collCellData
            postVC.source = "Profile"
            
            self.addChildViewController(postVC)
            
            postVC.view.frame = self.view.bounds
            postVC.alphaView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            
            self.view.addSubview(postVC.view)
            postVC.didMove(toParentViewController: self)
        }
        
        
        //Action that is called when the latest post is selected
        cell.latestContentSelected = {
            
            let postVC: PostViewController = self.storyboard!.instantiateViewController(withIdentifier: "postViewController") as! PostViewController
            
            postVC.delegate = self
            postVC.imageCache = self.imageCache
            postVC.postData = self.latestPostData
            
            postVC.source = "Profile"
            
            self.addChildViewController(postVC)
            
            postVC.view.frame = self.view.bounds
            postVC.alphaView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            
            self.view.addSubview(postVC.view)
            postVC.didMove(toParentViewController: self)
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
        
    }
    
    
    
    /****************************
     *
     * LIKED POSTS DATA RETRIEVE
     *
     ****************************/
    
    func getLikedPostData(){
        let currentUserId = self.currentlyViewingUID
        
        let likedRef = Database.database().reference().child("Users").child(currentUserId).child("liked_posts")
        let postRef = Database.database().reference().child("Posts")
        
        likedRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if let likedPosts: NSDictionary = snapshot.value as? NSDictionary
            {
                
                let totalCount: Int = likedPosts.count
                
                var i: Int = 0
                
                for (key, _) in likedPosts{
                    

                    let postUserId = key as! String
                    
                    postRef.child(postUserId).observeSingleEvent(of: .value, with: { postSnapshot in
                        
                        if let post: NSDictionary = postSnapshot.value as? NSDictionary{
                            
                            
                            let postData: PostData = self.dataManager.getPostDataFromDictionary(postDict: post, uid: key as! String)
                            
                            
                            
                            
                            if (Double(postData.expireTime)! > Date().millisecondsSince1970) {
                                
                                self.likedDataArray.append(self.dataManager.getPostDataFromDictionary(postDict: post, uid: key as! String))
                            }
                            
                            i += 1
                            if (i == totalCount){
                                self.profileTableView.reloadData()
                                
                            }
                        }
                    })
                }
            }
        })
    }
    

    
    //Post View Delegates
    func likedButtonPressed(liked: Bool, indexPath: IndexPath) {
        //don't do anything
        
    }
    
    func moreButtonPressed(data: PostData, indexPath: IndexPath) {
        
        //don't do anything
    }
    
    func blockUserAction(){
        

        //don't do anything

    }
    
    //Will play a video
//    func playURLData(url: URL){
//    
//        let player=AVPlayer(url: url)
//        
//        let avPlayerViewController = AVPlayerViewController()
//        avPlayerViewController.player =  player
//        
//        self.present(avPlayerViewController, animated: true) {
//            avPlayerViewController.player!.play()
//        }
//    }
//    

    
    /******************************
     *
     *  -- Text View Delegates --
     *
     ****************************/
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        textView.backgroundColor = UIColor.white
        textView.textColor = UIColor.black
        
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.white
        self.currentlyViewingUser.bio = textView.text
        self.ref.child("Users").child((Auth.auth().currentUser?.uid)!).child("bio").setValue(textView.text)
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        
        
        let numLines: Int = Int(textView.contentSize.height / textView.font!.lineHeight);
        
        if numLines > 1{
            self.adjustUITextViewHeight(arg: textView)
        }else {
            
            textView.isScrollEnabled = true
        }
    }

    
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
    }

    
    
    /**********************
     *
     *  -- NAVIGATION --
     *
     **********************/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        if segue.identifier == "toAllPostsSegue"{
//            
//            let vc: AllPostsViewController = segue.destination as! AllPostsViewController
//            
//            vc.postsArray = self.postDataArray
//            
//        }else
//            
        if(segue.identifier == "toAllLikedSegue"){
            
            let vc = segue.destination as! AllPostsViewController
            
            vc.postsArray = self.likedDataArray
            vc.imageCache = self.imageCache
            
        }else if(segue.identifier == "unwindToFeedSegue"){
            
            let vc = segue.destination as! FeedViewController
            
            if currentlyViewingUser.userID == Auth.auth().currentUser?.uid{
                vc.loggedInUser = self.currentlyViewingUser
            }
            
            vc.imageCache = self.imageCache
            
        }
    }
    
    
    @IBAction func unwindToProfile(unwindSegue: UIStoryboardSegue) {
        
        
    }
    


    

}
