//
//  FeedViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 4/27/17.
//


import UIKit
import Firebase
import URLEmbeddedView
import AVKit
import AVFoundation
import MediaPlayer
import Crashlytics

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, PostViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate{
    
    
    //class objects
    var navigationMenu: MenuView!
    var addPostMenu: MenuView!
    var dataManager = DataManager()
    var awsManager: AWSManager! = nil
    var colors: Colors = Colors()
    
    //Caches init
    var imageCache: ImageCache = ImageCache()
    var videoStore: VideoStore = VideoStore()
    
    //discover users // no posts view
    var noPostCollectionView: UICollectionView!
    var discoverUserData: NSMutableArray = NSMutableArray()
    var assetThumbnailSize: CGSize = CGSize.zero
    
    //post data of selected tableview cell
    var selectedPostData: PostData!
    var selectedUserUID: String = ""
    var selectedPostTypeId: Int = 0
    
     // More Menu data
    var moreMenuPostData: PostData!
    
    
    //custom refresh control 
    var refreshControl: UIRefreshControl!
    var refreshLoadingView : UIView!
    var refreshColorView : UIView!
    var compass_spinner : UIImageView!
    var isRefreshAnimating = false
    var rotatePeriod = 1
    var fadeBackground: Bool = false
    
    //Current User
    var loggedInUser: User!
    
    //savedPost
    var savedPost: NSDictionary!
    
    
    /**************************
     * Navigation Menu Buttons
     *************************/
    var profileBtn: UIButton!
    var homeBtn: UIButton!
    var discoverBtn: UIButton!
    var messagesBtn: UIButton!
    
    /**************************
     * Add Post Menu Buttons
     *************************/
    var photoBtn: UIButton!
    var videoBtn: UIButton!
    var recordBtn: UIButton!
    var textBtn: UIButton!
    var musicBtn: UIButton!
    var linkBtn: UIButton!
    var cameraBtn: UIButton!

    /**************************
     * -- TABLE DATA SOURCE --
     **************************/
    var feedData = [PostData]()
    var blockUserRow: Int = -1
    
    
    /**************************************
     *      -- Firebase Ref --
     **************************************/
    let ref: DatabaseReference =  Database.database().reference()
    
    /**************************************
     *      -- STORYBOARD OUTLETS --
     **************************************/
    @IBOutlet weak var noPostsLbl: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsButton: UIButton!
    var initialLoadIndicator: BreathingAnimation!
    @IBOutlet weak var addPostButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    
    var cornerRadius:CGFloat = 0.0
    
    /*********************************
     *
     * --------- LIFECYCLE ----------
     *
     *********************************/
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.navigationController?.navigationBar.isHidden = true
        self.noPostsLbl.isHidden = true
        
        let uid = Auth.auth().currentUser?.uid
        awsManager = AWSManager(uid: uid!)
        
        //did resign active notification listener
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        self.setupRefreshControl()
        
        initialLoadIndicator = BreathingAnimation(frame: CGRect(x: self.logoImageView.frame.midX - 20, y: self.logoImageView.frame.maxY + 60, width: 40, height: 40), image: UIImage(named: "logoGlassOnlyVertical")!)
        self.view.addSubview(self.initialLoadIndicator)
        self.initialLoadIndicator.startAnimating()
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        
        //set button colors
        self.settingsButton.setImage(UIImage(named:"settings")?.transform(withNewColor: UIColor.white), for: .normal)
        self.menuButton.setImage(UIImage(named:"menu")?.transform(withNewColor: UIColor.white), for: .normal)
//        self.addPostButton.setImage(UIImage(named:"addpostbutton")?.transform(withNewColor: UIColor.white), for: .normal)
        
        //delete the videos cache
        DispatchQueue.global().async() {
           
            self.dataManager.deleteLocalVideosCache()
        }

        //update the current local user with firebase user data
        ref.child("Users").child(uid!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            let data = snapshot.value as? NSMutableDictionary
            
            self.loggedInUser = User.init()
            
            UserDefaults.standard.set(data, forKey: "userData")
            UserDefaults.standard.synchronize()
            
            //Configure Logged In User Data
            self.loggedInUser = self.dataManager.setupUserData(data: data!, uid: uid!)
            
            if let username: String = data?.value(forKey: "username") as? String{
                
                if username == ""{
                    self.performSegue(withIdentifier: "createUsernameSegue", sender: nil)
                }else{
                    self.loggedInUser.username = username
                }
            }
            
            self.setupNoPostsCollection()
            
            if (self.loggedInUser != nil){
                
                self.getFeedData()
            }else{
                
                self.getFeedData()
                self.initialLoadIndicator.stopAnimating()
                self.noPostsLbl.isHidden = false
            }
            
            //If navigation menu is nil, set it up
            if (self.navigationMenu == nil){
                self.setupMenuView(profileURLString: "")
            }
            
            if(self.addPostMenu == nil){
                self.setupAddPostMenu()
            }
            
            //set menu photo
            self.setMenuPhoto(profPhoto: self.loggedInUser.profilePhoto)
        
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(loggedInUser != nil){
            self.setMenuPhoto(profPhoto: loggedInUser.profilePhoto)
        }
    }
    

    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @objc func appMovedToBackground(){
        
        if self.addPostMenu != nil{
            addPostMenu.close()
        }
        
        if self.navigationMenu != nil{
            navigationMenu.close()
        }
    }
    
    /*********************************
     *
     * ---- ACTIONS AND SELECTORS ---
     *
     *********************************/
    
    @IBAction func menuAction(_ sender: Any) {
        
        if (navigationMenu != nil){
            
            if (navigationMenu.open){
                navigationMenu.close()
                
                //move hrglass icon back to center
                self.moveIconCenter()
                
            }else{
                navigationMenu.show()
                
                //move hrglass icon right
                self.moveIconRight()
            }
        }
    }
    
    func moveIconRight(){
        UIView.animate(withDuration: 0.3, animations: {
            self.logoImageView.center = CGPoint(x: self.settingsButton.frame.minX - self.logoImageView.frame.width / 2, y:self.logoImageView.center.y)
        })
    }
    func moveIconCenter(){
        UIView.animate(withDuration: 0.3, animations: {
            self.logoImageView.center = CGPoint(x: self.view.frame.midX,y:self.logoImageView.center.y)
        })
    }
    
    
    @IBAction func settingsAction(_ sender: Any) {
        
        if self.navigationMenu != nil{
            self.navigationMenu.close()
            self.moveIconCenter()
        }
        
        self.performSegue(withIdentifier: "toSettingsSegue", sender: nil)
    }
    
    @objc func profileButtonAction (){
        
        if self.navigationMenu != nil{
            self.navigationMenu.close()
            self.moveIconCenter()
        }
        self.performSegue(withIdentifier: "toMyProfileSegue", sender: nil)
        
    }
    
    func homeButtonAction(){
        if self.navigationMenu != nil{
            self.navigationMenu.close()
            self.moveIconCenter()
        }
        if self.addPostMenu != nil{
            self.addPostMenu.close()
        }
    }
    
    @objc func discoverButtonAction (){
        if self.navigationMenu != nil{
            self.navigationMenu.close()
            self.moveIconCenter()
        }
        if self.addPostMenu != nil{
            self.addPostMenu.close()
        }
        performSegue(withIdentifier: "toDiscoverSegue", sender: nil)
    }
    
    
    @objc func messagesButtonAction (){
        
        if self.navigationMenu != nil{
            self.navigationMenu.close()
            self.moveIconCenter()
        }
        if self.addPostMenu != nil{
            self.addPostMenu.close()
        }
        performSegue(withIdentifier: "toInboxSegue", sender: nil)
    }
    
    
    
    @IBAction func addPostBtnAction(_ sender: Any) {
        if (addPostMenu != nil){
            
            if (self.addPostMenu.open){
                self.addPostMenu.close()
            }else{
                self.addPostMenu.show()
                self.view.bringSubview(toFront: self.addPostMenu)
            }
        }
    }
    
    func blockUserAction(){
        
        self.feedData.remove(at: self.blockUserRow)
        print(String(format:"Block User (%@) Action", self.moreMenuPostData))
        self.dataManager.blockUser(postData: self.moreMenuPostData)
        self.tableView.reloadData()
    }
    
    
    func sendMessageAction(){
        
        self.navigationMenu.close()
        self.moveIconCenter()
        self.performSegue(withIdentifier: "toMessagesView", sender: self)
    }
    
    
    
    
    
    /***************************************************************************************
     
     Function - getFeedData:
     
     Parameters - NA
     
     Returns: NA
     
     Retrieves posts from users being followed, hides and shows indicators as needed. Refreshes
        the tableview on when complete
     
     ***************************************************************************************/
    
    
    func getFeedData(){
        
        dataManager.getFeedPosts(userId: (Auth.auth().currentUser?.uid)!, completion: { data in
            
            //data is array of PostData Objects
            self.feedData = data as! [PostData]
            self.tableView.reloadData()
            
            //if there is no feed data
            if (self.feedData.count == 0){
                self.noPostsLbl.isHidden = false
                self.noPostCollectionView.isHidden = false
                self.getPublicUsers()
                
                self.noPostCollectionView.isHidden = false
            }else{
                if (self.noPostCollectionView != nil){
                    self.noPostsLbl.isHidden = true
                    self.noPostCollectionView.isHidden = true
                }
            }
            
            //stop loading animations
            if self.refreshControl.isRefreshing{
               self.refreshControl.endRefreshing()
            }
            
            if (self.initialLoadIndicator.isAnimating){
                self.initialLoadIndicator.stopAnimating()
            }
        })
    }
    
    
    
    
    
    /***************************************************************************************
     
     Function - setupAddPostMenu:
     
     Parameters - NA
     
     Returns: NA
     
     confures the Create Post Menu with the menu buttons to be shown/hidden with createPostBtn
     
     ***************************************************************************************/
    
    func setupAddPostMenu(){
        
        let center = self.addPostButton.center
        
        self.photoBtn = UIButton(frame: CGRect.zero)
        self.photoBtn.tag = 0
        self.photoBtn.setImage(UIImage(named:"gallery")?.transform(withNewColor: UIColor.white), for: .normal)
        self.photoBtn.center = center
        self.photoBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.videoBtn = UIButton(frame: CGRect.zero)
        self.videoBtn.setImage(UIImage(named:"videocall")?.transform(withNewColor: UIColor.white), for: .normal)
        self.videoBtn.center = center
        self.videoBtn.tag = 1
        self.videoBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.textBtn = UIButton(frame: CGRect.zero)
        self.textBtn.setImage(UIImage(named:"pencil")?.transform(withNewColor: UIColor.white), for: .normal)
        self.textBtn.center = center
        self.textBtn.tag = 2
        self.textBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.cameraBtn = UIButton(frame: CGRect.zero)
        self.cameraBtn.setImage(UIImage(named:"camera")?.transform(withNewColor: UIColor.white), for: .normal)
        self.cameraBtn.center = center
        self.cameraBtn.tag = 6
        self.cameraBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.recordBtn = UIButton(frame: CGRect.zero)
        self.recordBtn.setImage(UIImage(named:"microphone")?.transform(withNewColor: UIColor.white), for: .normal)
        self.recordBtn.center = center
        self.recordBtn.tag = 3
        self.recordBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.musicBtn = UIButton(frame: CGRect.zero)
        self.musicBtn.setImage(UIImage(named:"music")?.transform(withNewColor: UIColor.white), for: .normal)
        self.musicBtn.center = center
        self.musicBtn.tag = 4
        self.musicBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        self.linkBtn = UIButton(frame: CGRect.zero)
        self.linkBtn.setImage(UIImage(named:"news")?.transform(withNewColor: UIColor.white), for: .normal)
        self.linkBtn.center = center
        self.linkBtn.tag = 5
        self.linkBtn.addTarget(self, action: #selector(self.postTypeSelected), for: .touchUpInside)
        
        let buttonList: [UIButton] = [self.photoBtn, self.videoBtn, self.textBtn, self.recordBtn, self.musicBtn, self.linkBtn, self.cameraBtn]

        self.addPostMenu = MenuView(buttonList: buttonList, feedViewController: self, direction: .Left, startButton: self.addPostButton, spacing: -10.0, buttonScalor: 0.7)
        
        self.addPostMenu.buttonSpinAngle = 5 * ((CGFloat)(Float.pi) / 4)
        self.addPostMenu.backgroundImageView.image = UIImage(named: "postGradientBar")
        self.addPostMenu.backgroundImageView.contentMode = .scaleToFill
        self.view.addSubview(self.addPostMenu)
        
    }
    

    
    
    /***************************************************************************************
     
     Function - setupMenuView:
     
     Parameters - String: profileURLString
     
     Returns: NA
     
     confures the menuView with the menu buttons to be shown/hidden with menuButton
     
     ***************************************************************************************/
    
    func setupMenuView(profileURLString: String){
        
        let buttonFrame: CGRect = self.menuButton.frame
        let center = self.menuButton.center
        
        self.profileBtn = UIButton(frame: CGRect.zero)
        self.profileBtn.center = center
        self.profileBtn.layer.cornerRadius = buttonFrame.size.width * 0.35
        self.profileBtn.imageView?.contentMode = .scaleAspectFill
        self.profileBtn.clipsToBounds = true
        self.profileBtn.addTarget(self, action: #selector(self.profileButtonAction), for: .touchUpInside)
        
        self.discoverBtn = UIButton(frame: CGRect.zero)
        self.discoverBtn.setImage(UIImage(named:"users")?.transform(withNewColor: UIColor.white), for: .normal)
        self.discoverBtn.center = center
        self.discoverBtn.addTarget(self, action: #selector(self.discoverButtonAction), for: .touchUpInside)
        
        self.messagesBtn = UIButton(frame: CGRect.zero)
        self.messagesBtn.setImage(UIImage(named:"mail")?.transform(withNewColor: UIColor.white), for: .normal)
        self.messagesBtn.center = center
        self.messagesBtn.addTarget(self, action: #selector(self.messagesButtonAction), for: .touchUpInside)

        let buttonList: [UIButton] = [self.discoverBtn, self.messagesBtn, self.profileBtn]

        self.navigationMenu = MenuView(buttonList: buttonList, feedViewController: self, direction: .Right, startButton: self.menuButton, spacing: 0, buttonScalor: 0.7)
        self.navigationMenu.buttonSpinAngle = (CGFloat)(Float.pi)
        
        self.setMenuPhoto(profPhoto:profileURLString)
        self.view.addSubview(self.navigationMenu)

    }
    
    
    
    /***************************************************************************************
     
     Function - setMenuPhoto:
     
     Parameters - String: profPhoto
     
     Returns: NA
     
     using the profPhoto parameter string this will set the menuView's profile button picture
     
     ***************************************************************************************/
    
    func setMenuPhoto(profPhoto: String){
        
        if (profPhoto != ""){
            if dataManager.localPhotoExists(atPath: "profilePhoto"){
                
                self.profileBtn.setImage(self.dataManager.getImageForPath(path: "profilePhoto"), for: .normal)
            }else{
                dataManager.syncProfilePhotosToDevice(user: self.loggedInUser, path: "profilePhoto", completion: { image in
        
                    self.profileBtn.setImage(image, for: .normal)
                })
            }
        }else{
            self.profileBtn.setImage(self.dataManager.defaultsUserPhoto, for: .normal)
        }
    }
    
    
    
    
    /***************************************************************************************************
     
     Function - setupNoPostsCollection:
     
     Parameters - NA
     
     Returns: NA
     
     confures the collection view for when there are no active posts, sets noPostsCollectionView hidden
     
     ***************************************************************************************************/
    
    func setupNoPostsCollection(){
    
        //collectionview layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 3, bottom: 0, right: 3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        //set thumbnail sizes (applicible to both photos and videos collection views)
        assetThumbnailSize = CGSize(width:90, height:110)
        layout.itemSize = assetThumbnailSize
        
        let noPostsFrame: CGRect = CGRect(x: 0, y: self.noPostsLbl.frame.maxY + 20, width: self.view.frame.width, height: 130)
        //set photos collection attributes
        self.noPostCollectionView = UICollectionView(frame: noPostsFrame, collectionViewLayout: layout)
        
        let cellNib = UINib(nibName: "NoPostCollectionViewCell", bundle:nil)
        self.noPostCollectionView.register(cellNib, forCellWithReuseIdentifier: "noPostsCell")
        self.noPostCollectionView.allowsSelection = true
        self.noPostCollectionView.allowsMultipleSelection = false
        self.noPostCollectionView.backgroundColor = colors.getBlackishColor()
        self.noPostCollectionView.delegate = self
        self.noPostCollectionView.dataSource = self
        
        self.tableView.addSubview(noPostCollectionView)
        self.noPostCollectionView.isHidden = true
    }
    

    
    
    
    /***************************************************************************************
     
     Function - getPublicUsers:
     
     Parameters - String: profileURLString
     
     Returns: NA
     
     confures the menuView with the menu buttons to be shown/hidden with menuButton
     
     ***************************************************************************************/
    
    func getPublicUsers(){
        
        //For now just grab all users -- TODO: Develope Algorithm for pulling in more relevant users to this array
        let usersRef: DatabaseReference = ref.child("Users")
        self.discoverUserData.removeAllObjects()
        
        usersRef.observeSingleEvent(of: .value, with: { snapshot in
            
            let data: NSDictionary = snapshot.value as! NSDictionary
            print(data)
            let followingRef: DatabaseReference = self.ref.child("Following")
            
            followingRef.child((Auth.auth().currentUser?.uid)!).child("following_list").observeSingleEvent(of: .value, with: { snapshot in
                
                if let followingDict: NSDictionary = snapshot.value as? NSDictionary {
                    
                    for key in data.allKeys{
                        
                        let keyString = key as! String
                        
                        //if the user is not current user or already followed add them to datasourse
                        if (keyString != Auth.auth().currentUser?.uid && followingDict.value(forKey: keyString) == nil){
                            
                            self.discoverUserData.add(self.dataManager.setupUserData(data: data.value(forKey: keyString) as! NSMutableDictionary, uid: keyString))
                            
                        }
                    }
                    self.noPostCollectionView.isHidden = false
                    self.noPostCollectionView.reloadData()
                    
                }else{
                    
                    for key in data.allKeys{
                        
                        let keyString = key as! String
                        
                        //TODO: Removed the logged in User
                        if (keyString != Auth.auth().currentUser?.uid){
                            
                            self.discoverUserData.add(self.dataManager.setupUserData(data: data.value(forKey: keyString) as! NSMutableDictionary, uid: keyString))
                        }
                    }
                    self.noPostCollectionView.isHidden = false
                    self.noPostCollectionView.reloadData()
                }
                
            })
        })
    }
    
    
    

    /*****************************
     *
     * TABLEVIEW DELEGATE METHODS
     *
     ******************************/
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedData.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FeedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "feedCell") as! FeedTableViewCell
        let colors:Colors = Colors()
        
        cell.postData = feedData[indexPath.row]
        cell.playImageView.image = UIImage(named: "playTriagle")?.transform(withNewColor: UIColor.darkGray)
        //USER DATA DICTIONARY
        let user: NSDictionary = feedData[indexPath.row].user
        
        
        //setting profileImageBtn image
        let photoString: String = user.value(forKey: "profilePhoto") as! String
        if (photoString != ""){
            self.imageCache.getImage(urlString: photoString, completion: { image in
                cell.profileImageBtn.setImage(image, for: .normal)
                cell.loadingIndication.stopAnimating()
            })
        }else{
            cell.profileImageBtn.setImage(self.dataManager.defaultsUserPhoto, for: .normal)
        }
        
        //PostData update for feedData callback
        cell.newUsersDict = {
            
            self.feedData[indexPath.row] = cell.postData
        }
        let fullname: String = (user.value(forKey: "name") as? String)!
        
        /*****************************
         //CELL BUTTON CALLBACKS
         ****************************/
        cell.userProfile = {
            if let userPostDict: NSDictionary = self.feedData[indexPath.row].user{
                self.selectedUserUID = userPostDict.value(forKey: "uid") as! String
            }
            if self.navigationMenu.open{
                self.navigationMenu.close()
            }
            
            self.performSegue(withIdentifier: "toUserProfileSegue", sender: self)
        }
        
        
        cell.contentSelected = {
            
            if self.navigationMenu.open{
                self.navigationMenu.close()
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.showPostPopUp(postData: cell.postData, postCenter: cell.contentImageBtn.center, indexPath:indexPath)
            })
            
            self.dataManager.updateViewsList(post: cell.postData)
            let myUid = (Auth.auth().currentUser?.uid)!
            
            //DB values have already been updated. if not already viewed, update local values
            if(cell.postData.usersWhoViewed.value(forKey:myUid) == nil){
                cell.viewCountLbl.text = String(cell.postData.views + 1)
                cell.postData.usersWhoViewed.setValue(true, forKey: myUid)
            }
            
            cell.previewContentView.layer.borderColor = colors.getSeenPostColor().cgColor

        }
        
        cell.moreBtnSelected = {
            
            self.moreButtonPressed(data: cell.postData, indexPath: indexPath)
        }
        
        //setting cell content layout/appearance
        cell.contentImageBtn.layer.cornerRadius = self.cornerRadius/2
        cell.previewContentView.layer.cornerRadius = self.cornerRadius/2
        cell.previewContentView.layer.borderWidth = 2.0
        cell.contentImageBtn.clipsToBounds = true
        cell.previewContentView.backgroundColor = UIColor.white
        cell.likeCountLbl.text = String(feedData[indexPath.row].likes)
        cell.viewCountLbl.text = String(feedData[indexPath.row].views)
        cell.linkLbl.isHidden = true
        cell.postId = feedData[indexPath.row].postId as String
        cell.profileImageBtn.setImage(self.dataManager.clearImage, for: .normal)
        cell.loadingIndication.hidesWhenStopped = true
        cell.loadingIndication.startAnimating()
        cell.postUserId = user.value(forKey: "uid") as! String
        cell.postData.creationDate = feedData[indexPath.row].creationDate
        cell.posterNameLbl.text = fullname
        cell.playImageView.isHidden = true
        cell.timeRemainingLbl.text = dataManager.getTimeString(expireTime: feedData[indexPath.row].expireTime)
        
        
        //configuring data view based on post category
        switch feedData[indexPath.row].category {
            
        case .Music:
            
            print("Music")
            cell.previewContentView.layer.borderColor = colors.getMusicColor().cgColor
        
            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
            
            //just set the photo for now until we get AWS setup
            cell.profileImageBtn.setImage(self.dataManager.clearImage, for: .normal)
            cell.playImageView.isHidden = false
            cell.contentView.bringSubview(toFront: cell.playImageView)
            
            self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                
                cell.contentImageBtn.setImage(image, for: .normal)
                cell.loadingIndication.stopAnimating()
            })
            
        case .Link:
            
            print("link")
            
            cell.previewContentView.layer.borderColor = UIColor.black.cgColor
            dataManager.setURLView(urlString: feedData[indexPath.row].data as String, completion: { (image, label) in
                
                cell.contentImageBtn.setImage(image, for:.normal)
                cell.linkLbl.adjustsFontSizeToFitWidth = true
                cell.linkLbl.numberOfLines = 3
                cell.linkLbl.backgroundColor = UIColor.darkGray
                cell.linkLbl.alpha = 0.7
                cell.linkLbl.text = label
                cell.linkLbl.textAlignment = .center
                cell.linkLbl.textColor = UIColor.white
                cell.linkLbl.isHidden = false
            })
            
        case .Video:
            
            cell.previewContentView.layer.borderColor = colors.getPurpleColor().cgColor
            
            //thumbnail URL
            let thumbnailURL: String = String(format:"%@/%@/images/thumbnail.jpg", self.awsManager.getS3Prefix(), user.value(forKey: "uid") as! String)
            
            //just set the photo for now until we get AWS setup
            cell.profileImageBtn.setImage(self.dataManager.clearImage, for: .normal)
            cell.playImageView.isHidden = false
            cell.contentView.bringSubview(toFront: cell.playImageView)
            
            self.imageCache.getImage(urlString: thumbnailURL, completion: { image in
                
                cell.contentImageBtn.setImage(image, for: .normal)
                cell.loadingIndication.stopAnimating()
                
            })
            
        case .Photo:
            
            cell.contentImageBtn.setImage(self.dataManager.clearImage, for: .normal)
            cell.contentImageBtn.imageView?.contentMode = .scaleAspectFill
            //default is photo for now
            self.imageCache.getImage(urlString: feedData[indexPath.row].data, completion: { image in
                
                cell.contentImageBtn.setImage(image, for:.normal)
                cell.loadingIndication.stopAnimating()
                
            })
            
            cell.previewContentView.layer.borderColor = colors.getMenuColor().cgColor
            
        case .Recording:
            
            cell.contentImageBtn.setImage(UIImage(named: "audioWave"), for:.normal)
            cell.playImageView.isHidden = false
            cell.previewContentView.layer.borderColor = colors.getAudioColor().cgColor
            
        case .Text:
            
            print("Text Selected")
            
            cell.contentImageBtn.setImage(self.dataManager.clearImage, for: .normal)
            cell.contentImageBtn.imageView?.contentMode = .scaleAspectFill
            
            //default is photo for now
            self.imageCache.getImage(urlString: feedData[indexPath.row].data, completion: { image in
                
                cell.contentImageBtn.setImage(image, for:.normal)
                cell.loadingIndication.stopAnimating()
            })
            
            cell.previewContentView.layer.borderColor = colors.getTextPostColor().cgColor
            
        case .None:
            
            print("No Category")
        }
        
        
        //set like button to white icon
        let newImage: UIImage = UIImage.init(named: "thumbs_up_uncentered")!
        cell.likeBtn.setImage(newImage.transform(withNewColor: UIColor.white), for: .normal)
        
        
        //check if already liked this post
        if let likedDict: NSDictionary = feedData[indexPath.row].usersWhoLiked {
            
            //if not in dict, set thumb to red
            if (likedDict.value(forKey: self.loggedInUser.userID) != nil){
                
                cell.likeBtn.setImage(newImage.transform(withNewColor: UIColor.red), for: .normal)
                cell.previewContentView.layer.borderColor = colors.getSeenPostColor().cgColor
                cell.likedByUser = true
                
            }else{
                
                cell.likedByUser = false
            }
        }
        
        //TODO check view posts lists and set border color to seen
        if let viewedDict: NSDictionary = feedData[indexPath.row].usersWhoViewed{
            
            if (viewedDict.value(forKey: self.loggedInUser.userID) != nil){
                
                cell.previewContentView.layer.borderColor = colors.getSeenPostColor().cgColor
            }
        }
        
        
        //rounded Profile Image
        cell.profileImageBtn.layer.cornerRadius = cell.profileImageBtn.frame.height / 2
        cell.profileImageBtn.clipsToBounds = true
        cell.moreBtn.setImage(UIImage(named:"more")?.transform(withNewColor: UIColor.white), for: .normal)
        cell.viewsBtn.setImage(UIImage(named:"eye")?.transform(withNewColor: UIColor.white), for: .normal)
        
        
        //Hide the mood lbl if none is selected
        if (feedData[indexPath.row].mood == "🚫"){
            cell.moodLbl.isHidden = true
            
        }else{
            cell.moodLbl.isHidden = false
            cell.moodLbl.text = feedData[indexPath.row].mood
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        self.cornerRadius = 175.0 * 0.75
        return 175.0
    }
    
    
    

    
    /*****************************************************
     *
     * NO POSTS COLLECTION VIEW DELEGATE METHODS
     *
     ******************************************************/
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.discoverUserData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: NoPostsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "noPostsCell", for: indexPath) as! NoPostsCollectionViewCell
        let user: User = self.discoverUserData[indexPath.row] as! User
        
        let loadingInd: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loadingInd.hidesWhenStopped = true
        loadingInd.center = cell.imageView.center
        loadingInd.startAnimating()
        
        cell.imageView.layer.cornerRadius = cell.frame.width/2
        cell.imageView.backgroundColor = colors.getBlackishColor()
        
        if user.profilePhoto != ""{
            self.imageCache.getImage(urlString: user.profilePhoto, completion: { (image) in
                
                cell.imageView.image = image
                loadingInd.stopAnimating()
            })
        }else{
            cell.imageView.image = dataManager.defaultsUserPhoto
        }
        
        cell.nameLbl.text = user.name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let user: User = self.discoverUserData[indexPath.row] as! User
        self.selectedUserUID = user.userID
        self.performSegue(withIdentifier: "toUserProfileSegue", sender: self)
        
    }
    
    func collectionView(collectionView : UICollectionView,layout collectionViewLayout:UICollectionViewLayout,sizeForItemAtIndexPath indexPath:NSIndexPath) -> CGSize
    {
        return self.assetThumbnailSize
        
    }
    
     

    
    
    
    
    
    /***************************************************************************************
     
     Function - showPostPopUp:
     
     Parameters - PostData: postData, CGPoint: postCenter, IndexPath:indexPath
     
     Returns: NA
     
     using the indexPath of the selected tableView cell, this function configures and displays
        the postPopupView
     
     ***************************************************************************************/
    
    func showPostPopUp(postData: PostData, postCenter: CGPoint, indexPath:IndexPath){
        
        
        // add child view controller view to container
        let postVC: PostViewController = storyboard!.instantiateViewController(withIdentifier: "postViewController") as! PostViewController
        postVC.delegate = self
        postVC.imageCache = self.imageCache
        postVC.postData = postData
        postVC.videoCache = self.videoStore
        postVC.selectedIndexPath = indexPath
        
        addChildViewController(postVC)
        
        postVC.view.frame = view.bounds
        
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.view.addSubview(postVC.view)
        }) { (success) in
            postVC.didMove(toParentViewController: self)
        }
    }
    
    
    
    
    /******************************************************

     ------ POST POPUP DELEGATE METHODS -----
    
     *****************************************
     
     Function - likeButtonPressed:
     
     Parameters - Bool: liked, IndexPath: indexPath
     
     Returns: NA
     
     calls cell.likeAction for indexPath passed
     
     ***************************************************************************************/
    func likedButtonPressed(liked: Bool, indexPath: IndexPath) {
        
        let cell: FeedTableViewCell = self.tableView.cellForRow(at: indexPath) as! FeedTableViewCell
        cell.likeAction((Any).self)
        
    }
    
    
    /*************************************************
     
     Function - postTypeSelected:
     
     Parameters NA
     
     Returns: NA
     
     calls cell.likeAction for indexPath passed
     
     ***************************************************/
    
    @objc func postTypeSelected(_ sender: UIButton) {
        
        self.selectedPostTypeId = sender.tag
        self.addPostMenu.close()
        self.navigationMenu.close()
        self.moveIconCenter()
        self.performSegue(withIdentifier: "toCreatePostSegue", sender: self)
        
    }

    
   /*****************************************
    
    Function - moreButtonPressed:
    
    Parameters - PostData: data, IndexPath: indexPath
    
    Returns: NA
    
    Selector on more menu button pressed
    
    ***************************************************************************************/
    
    func moreButtonPressed(data: PostData, indexPath: IndexPath){
        
        let fullname: String = data.user.value(forKey: "name") as! String
        
        let alert: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let block: UIAlertAction = UIAlertAction(title: String(format:"Block %@", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            
            self.moreMenuPostData = data
            self.blockUserRow = indexPath.row
            self.blockUserAction()
            alert.dismiss(animated: true, completion: nil)
        }
        
        let message: UIAlertAction = UIAlertAction(title: String(format:"Send %@ a Message", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            
            self.moreMenuPostData = data
            self.blockUserRow = indexPath.row
            self.sendMessageAction()
            alert.dismiss(animated: true, completion: nil)
        }
        
        let delete: UIAlertAction = UIAlertAction(title: String(format:"Expire Post", self.dataManager.getFirstName(name: fullname)) , style: .default) {(_) -> Void in
            //set the expire time to the post creation time
            let ref: DatabaseReference = Database.database().reference().child("Posts").child((Auth.auth().currentUser?.uid)!).child("expire_time")
            ref.setValue(data.creationDate)
            
            alert.dismiss(animated: true, completion: nil)
        }
        
        
        
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel" , style: .cancel) {(_) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        
        
        if (data.user.value(forKey: "uid") as? String  == Auth.auth().currentUser?.uid){
            
            alert.addAction(delete)
        }else{
            alert.addAction(message)
            alert.addAction(block)
            
        }
        
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func getMPMediaItemWith(persistentId: MPMediaEntityPersistentID) -> MPMediaItem{
        
        let query: MPMediaQuery  = MPMediaQuery.songs()  // general songs query
        
        let pred: MPMediaPropertyPredicate = MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID)
        
        // narrow the query down to just items with that ID
        query.addFilterPredicate(pred)
        
        // now get items (there should be only one):
        let item: MPMediaItem = (query.items?.first)!
        
        return item
        
    }
    

    //Checks if the user has previously saved a post
    func checkForSavedPost(){
        
        if let savedPost: NSDictionary = UserDefaults.standard.dictionary(forKey: "savedPost") as NSDictionary?{
            
            //If there is Data in
            if (savedPost.count > 0){
                
                let alert: UIAlertController = UIAlertController(title: "You have a saved Post ready to submit", message: "", preferredStyle: .actionSheet)
                
                let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) {(_) -> Void in
                    
                    alert.dismiss(animated: true, completion: nil)
                }
                
                let delete: UIAlertAction = UIAlertAction(title: "Delete Saved Post", style: .default) {(_) -> Void in
                    
                    UserDefaults.standard.set([:], forKey: "savedPost")
                    alert.dismiss(animated: true, completion: nil)
                }
                
                delete.setValue(UIColor.red, forKey: "titleTextColor")
                
                let view: UIAlertAction = UIAlertAction(title: "View Post", style: .default) {(_) -> Void in
                    
                    self.savedPost = savedPost
                    alert.dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: "useSavedPost", sender: self)
                    
                }
                
                
                alert.addAction(view)
                alert.addAction(delete)
                alert.addAction(cancel)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    

    
    /*************************************
     *
     * ----------- NAVIGATION ------------
     *
     *************************************/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Prepare segues here

        if(segue.identifier == "toMyProfileSegue"){
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let profileVC: ProfileViewController = destinationNavigationController.topViewController as! ProfileViewController
//            let profileVC = segue.destination as! ProfileViewController
            
            profileVC.imageCache = self.imageCache
            self.imageCache = ImageCache()
            
            profileVC.currentlyViewingUser = loggedInUser
            profileVC.follwBtnIsUnfollow = false
            
            
            if navigationMenu != nil{
                self.navigationMenu.close()
            }
        }
            
        else if (segue.identifier == "toCreatePostSegue"){
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let createPostVC: AddPostViewController = destinationNavigationController.topViewController as! AddPostViewController
            createPostVC.loggedInUser = self.loggedInUser
            createPostVC.tabPassedFromParent = self.selectedPostTypeId
            
            if navigationMenu != nil{
                self.navigationMenu.close()
            }
            
        }else if (segue.identifier == "toUserProfileSegue"){
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let profileVC: ProfileViewController = destinationNavigationController.topViewController as! ProfileViewController
            profileVC.imageCache = self.imageCache
            self.imageCache = ImageCache()
            
            profileVC.loggedInUser = self.loggedInUser
            profileVC.currentlyViewingUID = self.selectedUserUID
            
            //if the user is selecting from the noPostsCollectionView, noPostsLbl will not be hidden and we want the follow button to say follow
            if self.noPostsLbl.isHidden{
                profileVC.follwBtnIsUnfollow = true
            }else{
                profileVC.follwBtnIsUnfollow = false
            }
            
            
            if navigationMenu != nil{
                self.navigationMenu.close()
            }
            
        }else if (segue.identifier == "toDiscoverSegue"){
            
            let discoverVC = segue.destination as! DiscoverViewController
            discoverVC.imageCache = self.imageCache
            discoverVC.loggedInUser = self.loggedInUser
            self.imageCache = ImageCache()
            
        }
        
        else if (segue.identifier == "toPostView"){
            
            let postVC = segue.destination as! PostViewController
            
            postVC.imageCache = self.imageCache
            postVC.postData = self.selectedPostData
            postVC.videoCache = self.videoStore

        }else if (segue.identifier == "toInboxSegue"){
            
            let inboxVC = segue.destination as! InboxViewController
            inboxVC.loggedInUser = self.loggedInUser
            inboxVC.imageCache = self.imageCache
            
        }else if (segue.identifier == "toMessagesView"){
            
            let messageVC: MessagesViewController = segue.destination as! MessagesViewController
            messageVC.selectedUserId = self.moreMenuPostData.user.value(forKey: "uid") as! String
            messageVC.nameString = (self.moreMenuPostData.user.value(forKey: "name") as! String)
            messageVC.loggedInUser = self.loggedInUser
        }else if(segue.identifier == "useSavedPost"){
            
            let addPostVC:AddPostViewController =  segue.destination as! AddPostViewController
            
            let cat: Category = Category(rawValue: self.savedPost.value(forKey: "category") as! String)!
            addPostVC.selectedCategory = cat
            addPostVC.selectedMood = Mood(rawValue: self.savedPost.value(forKey: "mood") as! String)!
            addPostVC.loggedInUser = self.loggedInUser
            addPostVC.postWasSaved = true
            
            
            //setting music objects if necessary
            let musicId = self.savedPost.value(forKey: "songString") as! MPMediaEntityPersistentID
            if (String(musicId) != ""){
                
                let musicItem: MPMediaItem = self.getMPMediaItemWith(persistentId: musicId)
                
                addPostVC.selectedMusicItem = musicItem
                
            }
            
            
            //            var secondCat: Category = .None
            //            var savedPostHasChild:Bool = false
            //            if let child: NSDictionary  = self.savedPost.value(forKey: "secondaryPost") as? NSDictionary{
            //                savedPostHasChild = true
            //                addPostVC.hasSecondarySavedPost = true
            //                secondCat = Category(rawValue: child.value(forKey: "secondaryCategory") as! String)!
            //                addPostVC.secondarySelectedCategory = secondCat
            //
            //            }
            
            
            
            if  cat == .Video{
                
                let path = self.dataManager.documentsPathForFileName(name: "savedPostData.mp4")
                
                addPostVC.trimmedVideoPath = path.absoluteString
                addPostVC.selectedThumbnail = self.dataManager.getImageForPath(path:"thumbnail")
                addPostVC.selectedObject = self.dataManager.getSavedPostData(category: cat, primary: true)
            }else if (cat == .Music){
                addPostVC.selectedObject = self.getMPMediaItemWith(persistentId: musicId)
            }else{
                addPostVC.selectedObject = self.dataManager.getSavedPostData(category: cat, primary: true)
            }
            
            
            //
            //            if savedPostHasChild{
            //
            //                if (secondCat == .Video){
            //                    let path = self.dataManager.documentsPathForFileName(name: "secondarySavedPostData.mp4")
            //
            //                    addPostVC.selectedThumbnail = self.dataManager.getImageForPath(path:"thumbnail")
            ////                    addPostVC.secondarySelectedObject = AVAsset(url: path)
            //                    addPostVC.trimmedVideoPath = path.absoluteString
            //                    addPostVC.secondarySelectedObject = self.dataManager.getSavedPostData(category: secondCat, primary: false)
            //                }else{
            //
            //                    addPostVC.secondarySelectedObject = self.dataManager.getSavedPostData(category: secondCat, primary: false)
            //
            //                }
            //            }
        }
    }
    
    
    
    func playURLData(urlString: String){

        let url: URL = URL(string: urlString)!
        let player=AVPlayer(url: url)
        let avPlayerViewController = AVPlayerViewController()
        avPlayerViewController.player =  player
        
        self.present(avPlayerViewController, animated: true) {
            avPlayerViewController.player!.play()
        }
    }
    
    
    @IBAction func unwindToFeed(unwindSegue: UIStoryboardSegue) {
    
        
    }
    
    
    
  
    /*************************************
     *
     * CUSTOM REFRESH CONTROL METHODS
     *
     *************************************/
    
    
    func setupRefreshControl() {
        
        // Programmatically inserting a UIRefreshControl
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(self.refreshControl)
        
        // Setup the loading view, which will hold the moving graphics
        self.refreshLoadingView = UIView(frame: self.refreshControl!.bounds)
        self.refreshLoadingView.backgroundColor = UIColor.clear
        
        // Setup the color view, which will display the rainbowed background
        self.refreshColorView = UIView(frame: self.refreshControl!.bounds)
        self.refreshColorView.backgroundColor = colors.getMusicColor()
        self.refreshColorView.alpha = 0.0
        
        // Create the graphic image views
//        self.compass_background = UIImageView(image: UIImage(named: "logoOutsideRing"))
        self.compass_spinner = UIImageView(image: UIImage(named: "logoGlassOnly"))
        self.compass_spinner.frame = CGRect(x: self.refreshControl.center.x - self.refreshControl.bounds.height/4, y:self.refreshControl.center.y - self.refreshLoadingView.bounds.height/4 ,width: self.refreshControl.bounds.height/2,height: self.refreshControl.bounds.height/2)
        // Add the graphics to the loading view
        self.refreshLoadingView.addSubview(self.compass_spinner)
        
        // Clip so the graphics don't stick out
        self.refreshLoadingView.clipsToBounds = true;
        
        // Hide the original spinner icon
        self.refreshControl!.tintColor = UIColor.clear
        
        // Add the loading and colors views to our refresh control
        self.refreshControl!.addSubview(self.refreshColorView)
        self.refreshControl!.addSubview(self.refreshLoadingView)
        
        // Initalize flags
        self.isRefreshAnimating = false;
        
        // When activated, invoke our refresh function
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
    }
    
    
    
    /***************************************************************************************
     
     Function - refresh:
     
     Parameters - NA
     
     Returns: NA
     
     refreshes the current users following/followedby dictionaries, then calls getFeedData
     
     ***************************************************************************************/
    
    @objc func refresh(){
        
        ref.child("Following").child((Auth.auth().currentUser?.uid)!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            //GET FOLLOWING LIST CONSTANT
            var followingList: NSDictionary!
            if let temp: NSDictionary = snapshot.value as? NSDictionary{
                followingList = temp.value(forKey: "following_list") as! NSDictionary
            }else{
                followingList = [:]
            }
            
            // For now we get nil because we're not saving lists, so pass something else
            if (followingList.count != 0){
                
                self.noPostsLbl.isHidden = true
                self.getFeedData()
                
            }else{
                
                self.noPostsLbl.isHidden = false
                self.getFeedData()
            }
        })
    }
    
    

    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Get the current size of the refresh controller
        var refreshBounds = self.refreshControl!.bounds;
        
        // Distance the table has been pulled >= 0
        let pullDistance = max(0.0, -self.refreshControl!.frame.origin.y);
        
        // Half the width of the table
        let midX = self.tableView.frame.size.width / 2.0;
        
        let spinnerHeight = self.compass_spinner.bounds.size.height;
        let spinnerHeightHalf = spinnerHeight / 2.0;
        
        let spinnerWidth = self.compass_spinner.bounds.size.width;
        let spinnerWidthHalf = spinnerWidth / 2.0;
        
        // Calculate the pull ratio, between 0.0-1.0
        let pullRatio = min( max(pullDistance, 0.0), 100.0) / 100.0;
        self.refreshColorView.alpha = pullRatio / 2.0
        
        // Set the Y coord of the graphics, based on pull distance
        let spinnerY = pullDistance / 2.0 - spinnerHeightHalf;
        
        // Calculate the X coord of the graphics, adjust based on pull ratio
        var spinnerX = midX - spinnerWidthHalf
        
        // If the graphics have overlapped or we are refreshing, keep them together
        if (self.refreshControl!.isRefreshing) {
            spinnerX = midX - spinnerWidthHalf;
        }
        
        //
        var spinnerFrame = self.compass_spinner.frame;
        spinnerFrame.origin.x = spinnerX;
        spinnerFrame.origin.y = spinnerY;
        
        self.compass_spinner.frame = spinnerFrame;
        // Set the encompassing view's frames
        refreshBounds.size.height = pullDistance;
        
        self.refreshColorView.frame = refreshBounds;
        self.refreshLoadingView.frame = refreshBounds;
        

        // If we're refreshing and the animation is not playing, then play the animation
        if (self.refreshControl!.isRefreshing && !self.isRefreshAnimating) {
            self.animateRefreshView()
        }
        
//        print("pullDistance \(pullDistance), pullRatio: \(pullRatio), midX: \(midX), refreshing: \(self.refreshControl!.isRefreshing)")
        
    }
    
    func animateRefreshView() {
        print()
        
        // Background color to loop through for our color view
//        var colorArray = [colors.getSeenPostColor(), colors.getMusicColor(), colors.getMenuColor(), colors.getPurpleColor()]
        
        // In Swift, static variables must be members of a struct or class
        struct ColorIndex {
            static var colorIndex = 0
        }
        
        // Flag that we are animating
        self.isRefreshAnimating = true;
        
        UIView.animate(withDuration:
            Double(0.3),
                       delay: Double(0.0),
                       options: UIViewAnimationOptions.curveLinear,
                       animations: {
                        
                        // Rotate the spinner by M_PI_2 = PI/2 = 90 degrees
                        if (self.rotatePeriod == 1){
                            self.rotatePeriod = 2
                            self.compass_spinner.transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi / 2))
                            
                        }else if (self.rotatePeriod == 2){
                            self.rotatePeriod = 3
                            self.compass_spinner.transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi))
                            
                        }else if (self.rotatePeriod == 3){
                            self.rotatePeriod = 4
                            self.compass_spinner.transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi) * 3/2)
                            
                        }else if (self.rotatePeriod == 4){
                            self.rotatePeriod = 1
                            self.compass_spinner.transform = CGAffineTransform(rotationAngle: 0)
                            
                            
                            //toggle fadeBackground
                            if (self.fadeBackground){
                                self.fadeBackground = false
                            }else{
                                self.fadeBackground = true
                            }
                        }
                        
                        if self.fadeBackground {
                            self.refreshColorView!.alpha = self.refreshColorView!.alpha - 0.1
                        }else{
                            self.refreshColorView!.alpha = self.refreshColorView!.alpha + 0.1
                        }
                        
                        
        },
                       completion: { finished in
                        // If still refreshing, keep spinning, else reset
                        
                        if (self.refreshControl!.isRefreshing) {
                            self.animateRefreshView()
                        }else {
                            self.resetAnimation()
                        }
        })
    }
    
    func resetAnimation() {
        print()
        
        // Reset our flags and }background color
        self.isRefreshAnimating = false;
        self.refreshColorView.alpha = 0.0
        
    }
    
}



