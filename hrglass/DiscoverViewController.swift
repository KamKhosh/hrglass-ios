//
//  DiscoverViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 6/25/17.
//
//

import UIKit
import Firebase

class DiscoverViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var backItemBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var discoverUserData: NSMutableArray = NSMutableArray()
    var userIdArray: NSMutableArray = NSMutableArray()
    
    let ref = Database.database().reference()
    
    let currentUserId = Auth.auth().currentUser?.uid
    let dataManager: DataManager = DataManager()
    var imageCache: ImageCache = ImageCache()
    var requestArray: NSMutableArray = []
    
    var showRequestData: Bool = false
    var noReqLbl: UILabel!
    var count: Int = 0
    var hub: RKNotificationHub!
    var selectedUser: User!

    
    @IBOutlet weak var requestsBtn: UIButton!

    
    
    /************************
     *
     *      LIFECYCLE
     *
     ************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        
        //removing bottom navigation line
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.noReqLbl = UILabel(frame: CGRect(x: 0, y:self.navigationBar.frame.maxY + 20 , width: self.view.frame.width, height: 30))
        self.noReqLbl.text = "No Requests"
        self.noReqLbl.textAlignment = .center
        self.noReqLbl.textColor = UIColor.lightGray
        self.noReqLbl.isHidden = true
        self.view.addSubview(self.noReqLbl)
        
        self.getUsers()
        self.getRequestData()
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    @IBAction func requestsAction(_ sender: Any) {
        
        if self.showRequestData{
            self.showRequestData = false
            self.requestsBtn.setTitle("Requests", for: .normal)
            self.tableView.reloadData()
            
        }else {
            self.showRequestData = true
           self.requestsBtn.setTitle("Discover", for: .normal)
            self.tableView.reloadData()
        }
    }
    
    
    
    func getRequestData(){
        
        self.dataManager.getRequests(completion: { array in
            
            if array.count > 0{
                
                let tmpArray: NSArray = array
                self.getUserData(userArray: tmpArray)

            }else{
                
                //show no requests label
                if self.hub == nil{
                    
                    self.hub = RKNotificationHub(view: self.requestsBtn)
                    self.hub.count = array.count
                    self.hub.showCount()
                    self.hub.pop()
                }
            }
        })
    }
    
    
    func getUserData(userArray: NSArray){
        
        for uid in userArray{
            
            self.dataManager.getUserDataFrom(uid: uid as! String, completion: { user in
                
                self.requestArray.add(user)
                
                if self.requestArray.count == userArray.count{
                    
                    self.tableView.reloadData()
                    
                }
            })
        }
    }
    
    
    
    
    func getUsers(){
        
        //For now just grab all users -- TODO: Develop Algorithm for pulling in more relevant users to your discover list
        let usersRef: DatabaseReference = ref.child("Users")

        usersRef.observeSingleEvent(of: .value, with: { snapshot in
            
            let data: NSDictionary = snapshot.value as! NSDictionary
            print(data)
            let followingRef: DatabaseReference = self.ref.child("Following")

            followingRef.child((Auth.auth().currentUser?.uid)!).child("following_list").observeSingleEvent(of: .value, with: { snapshot in
                
                if let followingDict: NSDictionary = snapshot.value as? NSDictionary {
                    
                    for key in data.allKeys{
                        
                        let keyString = key as! String
                        
                        //if the user is not current user add them to datasourse
                        
                        //TODO: REMOVE EXISTING USERS followed by the logged in User
                        if (keyString != self.currentUserId && followingDict.value(forKey: keyString) == nil){
                            
                            
                            self.discoverUserData.add(self.dataManager.setupUserData(data: data.value(forKey: keyString) as! NSMutableDictionary, uid: keyString))
//                            self.userIdArray.add(keyString)
                            
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                }else{
                    
                    for key in data.allKeys{
                        
                        let keyString = key as! String

                        //TODO: Removed the logged in User
                        if (keyString != self.currentUserId){
                            
                            self.discoverUserData.add(self.dataManager.setupUserData(data: data.value(forKey: keyString) as! NSMutableDictionary, uid: keyString))
//                            self.userIdArray.add(keyString)
                            
                        }
                    }
                    
                    self.tableView.reloadData()
                }
                
            })
            
        })
    }
    
    
    
    
    func acceptUserFollowRequest(row: Int){
        
        let user: User = self.requestArray[row] as! User
        let theirUid: String = user.userID
        let myUid: String = (Auth.auth().currentUser?.uid)!
        
        let ref: DatabaseReference = Database.database().reference()
        
        //set their uid value to 0 in my followed_by_list
        let myFollowedByRef: DatabaseReference = ref.child("FollowedBy").child(myUid).child("followed_by_list").child(theirUid)
        myFollowedByRef.setValue(0)
        
        //set my uid value to 0 in their following_list
        let theirFollowingRef: DatabaseReference = ref.child("Following").child(theirUid).child("following_list").child(myUid)
        theirFollowingRef.setValue(0)
        
        self.requestArray.removeObject(at: row)
        self.tableView.reloadData()
        
    }
    
    
    
    /******************************
     *
     *  TABLE VIEW D&DS METHODS
     *
     ******************************/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count: Int = 0
        if showRequestData{
            count = self.requestArray.count
            
            if count == 0{
                self.noReqLbl.isHidden = false
            }else{
                self.noReqLbl.isHidden = true
            }

        }else{
            self.noReqLbl.isHidden = true
            count = self.discoverUserData.count
        }
        
        return count
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var finalCell: UITableViewCell = UITableViewCell(frame: CGRect.zero)
        
        if showRequestData{
            
            let cell: RequestTableViewCell = tableView.dequeueReusableCell(withIdentifier: "requestCell") as! RequestTableViewCell
            
            let user: User = self.requestArray[indexPath.row] as! User
            
            cell.acceptBtnSelected = {
                
                self.acceptUserFollowRequest(row:indexPath.row)
            }
            
            let photoString: String = user.profilePhoto
            if (photoString != ""){
                
                self.imageCache.getImage(urlString: photoString, completion: { image in
                    
                    cell.profImageView.image = image
                })
                
            }else{
                cell.profImageView.image = self.dataManager.defaultsUserPhoto
            }
            
            cell.nameLbl.text = user.name
            
            finalCell = cell
            
        }else{
            
            let cell: DiscoverTableViewCell = tableView.dequeueReusableCell(withIdentifier: "discoverCell") as! DiscoverTableViewCell
            
            let userdata:User = self.discoverUserData[indexPath.row] as! User
            let userId: String = userdata.userID
//            let _: User = self.dataManager.setupUserData(data: userdata.mutableCopy() as! NSMutableDictionary, uid: userId)
            
            cell.activityInd.hidesWhenStopped = true
            cell.activityInd.startAnimating()
            
            cell.userdata = userdata
            cell.userId = userId
            
            
            cell.countObj = {
                
                if (cell.followBtn.titleLabel?.text == "Follow"){
                    self.count += 1
                }else if(cell.followBtn.titleLabel?.text == "Unfollow" || cell.followBtn.titleLabel?.text == "Unrequest"){
                    self.count -= 1
                }
                
                //set the button to say done if more than one user followed
                if self.count > 0{
                    self.backItemBtn.setTitle("Done", for: .normal)
                }else{
                    self.backItemBtn.setTitle("Cancel", for: .normal)
                }
            }
            
            
            if (userdata.profilePhoto != ""){
                
                self.imageCache.getImage(urlString: userdata.profilePhoto as! String, completion: { image in
                    
                    cell.profilePhotoImageView.image = image
                    cell.activityInd.stopAnimating()
                })
                
            }else{
                
                cell.profilePhotoImageView.image = UIImage(named: "defaultUser")
                cell.activityInd.stopAnimating()
            }
            
            
            dataManager.getFollowingCount(userId: userId, completion: { (count) in
                
                cell.followingLbl.text = String(count)
            })
            
            dataManager.getFollowedByCount(userId: userId, completion: { (count) in
                
                cell.followerLbl.text = String(count)
            })

            cell.nameLbl.text = userdata.name as? String
            
            finalCell = cell
        }
        return finalCell
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Show User Profile")
        
        if !showRequestData{
            let user: User = self.discoverUserData[indexPath.row] as! User
            
            self.selectedUser = user
            
            self.performSegue(withIdentifier: "toUserProfileSegue", sender: self)
        }
    }
    
    
    /************************
     *
     *      NAVIGATION
     *
     ************************/
    
    @IBAction func unwindToDiscover(unwindSegue: UIStoryboardSegue) {
        
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "unwindToFeed"){
            
            let fvc = segue.destination as! FeedViewController
            
            self.discoverUserData = NSMutableArray()
            self.userIdArray = NSMutableArray()
            
            fvc.imageCache = self.imageCache
            self.imageCache = ImageCache()
            
        }else if (segue.identifier == "toUserProfileSegue"){
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let profileVC: ProfileViewController = destinationNavigationController.topViewController as! ProfileViewController
            profileVC.imageCache = self.imageCache
            profileVC.parentView = "discover"
            
            profileVC.currentlyViewingUID = self.selectedUser.userID
            profileVC.follwBtnIsUnfollow = true
        }
    }

    


}
