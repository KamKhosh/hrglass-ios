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


class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, PostViewDelegate{

    
    //class objects
    var navigationMenu: MenuView!
    var dataManager = DataManager()
    var awsManager: AWSManager! = nil
    
    
    //Caches init
    var imageCache: ImageCache = ImageCache()
    var videoStore: VideoStore = VideoStore()
    
    
    //post data of selected tableview cell
    var selectedPostData: PostData!
    var selectedUserUID: String = ""

     // More Menu data
    var moreMenuPostData: PostData!
    
    //refresh control
    var refreshControl: UIRefreshControl!
    var customRefreshView: CustomRefreshControlView!
    
    //Current User
    var loggedInUser: User!
        
    
    
    /**************************
     * Navigation Menu Buttons
     *************************/
    var profileBtn: UIButton!
    var homeBtn: UIButton!
    var discoverBtn: UIButton!
    var messagesBtn: UIButton!

    

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
    @IBOutlet weak var initialLoadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var addPostButton: UIButton!
    
    
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
        
        self.refreshControl = UIRefreshControl()
        
        refreshControl.backgroundColor = UIColor.black
        refreshControl.tintColor = UIColor.white
        self.refreshControl.addTarget(self, action: #selector (refresh), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.initialLoadIndicator.hidesWhenStopped = true
        self.view.addSubview(self.initialLoadIndicator)
        self.initialLoadIndicator.startAnimating()
        
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        
        
        //set button colors
        self.settingsButton.setImage(UIImage(named:"settings")?.transform(withNewColor: UIColor.white), for: .normal)
        self.menuButton.setImage(UIImage(named:"menu")?.transform(withNewColor: UIColor.white), for: .normal)
        self.addPostButton.setImage(UIImage(named:"plus_circle")?.transform(withNewColor: UIColor.white), for: .normal)
        
        //delete the videos cache
        DispatchQueue.global().async() {
           
            self.dataManager.deleteLocalVideosCache()
        }

        
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
    
    
    

    

    func loadCustomRefreshContents() {
        let refreshContents = Bundle.main.loadNibNamed("CustomRefreshControl", owner: self, options: nil)
        
        customRefreshView = refreshContents?.first as! CustomRefreshControlView
        customRefreshView.frame = refreshControl.bounds
        customRefreshView.spinView.startAnimating()
        refreshControl.addSubview(customRefreshView)
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
            }else{
                navigationMenu.show()
                self.view.bringSubview(toFront: navigationMenu)
            }
        }
    }
    
    
    @IBAction func settingsAction(_ sender: Any) {
        self.performSegue(withIdentifier: "toSettingsSegue", sender: nil)
    }
    
    func profileButtonAction (){
        
        self.navigationMenu.close()
        self.performSegue(withIdentifier: "toMyProfileSegue", sender: nil)
        
    }
    
    func homeButtonAction(){
        self.navigationMenu.close()
    }
    
    func discoverButtonAction (){
        self.navigationMenu.close()
        performSegue(withIdentifier: "toDiscoverSegue", sender: nil)
    }
    
    
    func messagesButtonAction (){
        
        self.navigationMenu.close()
        performSegue(withIdentifier: "toInboxSegue", sender: nil)
    }
    
    
    func uploadButtonAction (){
        
        self.navigationMenu.close()
        performSegue(withIdentifier: "toUploadProfile", sender: self)
    }
    
    
    func blockUserAction(){
        
        self.feedData.remove(at: self.blockUserRow)
        print(String(format:"Block User (%@) Action", self.moreMenuPostData))
        self.dataManager.blockUser(postData: self.moreMenuPostData)
        self.tableView.reloadData()
    }
    
    
    func sendMessageAction(){
        
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
            
            self.feedData = data as! [PostData]
            self.tableView.reloadData()
            
            if (self.feedData.count == 0){
                self.noPostsLbl.isHidden = false
            }
            
            if self.refreshControl.isRefreshing{
               self.refreshControl.endRefreshing()
            }
            
            if (self.initialLoadIndicator.isAnimating){
                self.initialLoadIndicator.stopAnimating()
            }
        })
    }
    
    
    
    
    /***************************************************************************************
     
     Function - refresh:
     
     Parameters - NA
     
     Returns: NA
     
     refreshes the current users following/followedby dictionaries, then calls getFeedData
     
     ***************************************************************************************/
    
    func refresh(){
        
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
        
        self.setMenuPhoto(profPhoto:profileURLString)
        
        self.profileBtn.addTarget(self, action: #selector(self.profileButtonAction), for: .touchUpInside)
        
        self.discoverBtn = UIButton(frame: CGRect.zero)
        self.discoverBtn.setImage(UIImage(named:"users")?.transform(withNewColor: UIColor.white), for: .normal)
        self.discoverBtn.center = center
        self.discoverBtn.addTarget(self, action: #selector(self.discoverButtonAction), for: .touchUpInside)
        
        
        self.messagesBtn = UIButton(frame: CGRect.zero)
        self.messagesBtn.setImage(UIImage(named:"mail")?.transform(withNewColor: UIColor.white), for: .normal)
        self.messagesBtn.center = center
        self.messagesBtn.addTarget(self, action: #selector(self.messagesButtonAction), for: .touchUpInside)
        
        self.navigationMenu = MenuView(buttonList: [self.discoverBtn, self.messagesBtn, self.profileBtn], feedViewController: self, offset: true, direction: .Up)
        
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
            self.performSegue(withIdentifier: "toUserProfileSegue", sender: self)
        }
        
        cell.contentSelected = {
            
            UIView.animate(withDuration: 0.4, animations: { 
                self.showPostPopUp(postData: cell.postData, postCenter: cell.contentImageBtn.center, indexPath:indexPath)
            })

            self.dataManager.updateViewsList(post: cell.postData, completion: { views in
                cell.viewCountLbl.text = String(views)
                cell.previewContentView.layer.borderColor = colors.getSeenPostColor().cgColor
            })
        }
        
        
        cell.moreBtnSelected = {
            
            self.moreButtonPressed(data: cell.postData, indexPath: indexPath)
        }

        
        //setting cell content layout/appearance
        cell.contentImageBtn.layer.cornerRadius = cell.contentImageBtn.frame.height/2
        cell.previewContentView.layer.cornerRadius = cell.previewContentView.frame.height/2
        cell.previewContentView.layer.borderWidth = 5.0
        cell.contentImageBtn.clipsToBounds = true
        cell.previewContentView.backgroundColor = UIColor.white
        cell.likeCountLbl.text = String(feedData[indexPath.row].likes)
        cell.viewCountLbl.text = String(feedData[indexPath.row].views)
        cell.categoryLbl.text = feedData[indexPath.row].category.rawValue
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
        let newImage: UIImage = UIImage.init(named: "thumbs up")!
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
        if (feedData[indexPath.row].mood == "✏️"){
            cell.moodLbl.isHidden = true
            
        }else{
            cell.moodLbl.isHidden = false
            cell.moodLbl.text = feedData[indexPath.row].mood
        }

        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        
        return 300.0
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
        postVC.alphaView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
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
        
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel" , style: .cancel) {(_) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(message)
        alert.addAction(block)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
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
            let createPostVC: CreateCustomPostViewController = destinationNavigationController.topViewController as! CreateCustomPostViewController
            createPostVC.loggedInUser = self.loggedInUser
            
            if navigationMenu != nil{
                self.navigationMenu.close()
            }
            
        }else if (segue.identifier == "toUserProfileSegue"){
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let profileVC: ProfileViewController = destinationNavigationController.topViewController as! ProfileViewController
            profileVC.imageCache = self.imageCache
            self.imageCache = ImageCache()
            
            profileVC.currentlyViewingUID = self.selectedUserUID
            profileVC.follwBtnIsUnfollow = true
            
            if navigationMenu != nil{
                self.navigationMenu.close()
            }
            
        }else if (segue.identifier == "toDiscoverSegue"){
            
            let discoverVC = segue.destination as! DiscoverViewController
            
            discoverVC.imageCache = self.imageCache
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
    
}



