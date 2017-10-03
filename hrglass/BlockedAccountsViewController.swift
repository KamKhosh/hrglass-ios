//
//  BlockedAccountsViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/7/17.
//
//

import UIKit
import Firebase

class BlockedAccountsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    let imageCache: ImageCache = ImageCache()
    let dataManager: DataManager = DataManager()
    let colors: Colors = Colors()
    
    let blockedRef: DatabaseReference = Database.database().reference().child("BlockedUsers").child(Auth.auth().currentUser!.uid)
    
    var blockedUsers: NSMutableArray = []
    
    /*********************************
     *
     * ---------- LIFECYCLE ---------
     *
     *********************************/
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //nav bar setup
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        self.navigationBar.backgroundColor = UIColor.white
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        
        
        //set footer to zero so the cell seperators stop after the last cell
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        
        self.dataManager.getBlockedUsers(completion: { blockedDict in
            
    
            if blockedDict.count > 0{

                for key in blockedDict.allKeys{
                    
                    let user: NSDictionary = blockedDict.value(forKey: key as! String) as! NSDictionary
                    self.blockedUsers.add(user)

                }
                
                self.tableView.reloadData()
                
            }else{
                
                let alert: UIAlertController = UIAlertController(title: "No Blocked Users", message: "", preferredStyle: .alert)
                let ok: UIAlertAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.performSegue(withIdentifier: "unwindToAccounts", sender: nil)
                })
                alert.addAction(ok)
                self.present(alert, animated: true, completion:nil)
                
                
            }
            
        })
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*****************************
     *
     * TABLEVIEW DELEGATE METHODS
     *
     ******************************/
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return blockedUsers.count
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: BlockedUserCell = tableView.dequeueReusableCell(withIdentifier: "blockedCell") as! BlockedUserCell
        
        let blockedUserDict: NSDictionary = self.blockedUsers[indexPath.row] as! NSDictionary
        
        
        let profilePicString: String = blockedUserDict.value(forKey: "profilePhoto") as! String
        let name: String = blockedUserDict.value(forKey: "name") as! String

        cell.userDictionary = blockedUserDict
        cell.userImageView.backgroundColor = UIColor.white
        
        cell.moreBtn.layer.borderColor = colors.getOrangeRedColor().cgColor
        cell.moreBtn.layer.borderWidth = 1.0
        cell.moreBtn.layer.cornerRadius = 4.0
        
        self.imageCache.getImage(urlString: profilePicString, completion: { image in
            
            cell.userImageView.image = image
            
        })
        
        cell.moreBtnSelected = {
            
            
            let unblockUid = cell.userDictionary.value(forKey: "uid") as! String
            self.deleteBlockedData(deleteUid: unblockUid)
            
            self.blockedUsers.removeObject(at: indexPath.row)
            
            self.tableView.reloadData()

        }
        
        cell.userNameLbl.text = name
        
        cell.userImageView.layer.cornerRadius = 20
        cell.userImageView.clipsToBounds = true
        cell.userImageView.contentMode = .scaleAspectFill
        
        
        return cell
    }
    
    
    func deleteBlockedData(deleteUid: String){
        
        let currentUid: String = (Auth.auth().currentUser?.uid)!
        
        let deleteRef: DatabaseReference = Database.database().reference().child("BlockedUsers").child(currentUid).child(deleteUid)
        
        deleteRef.removeValue()

        
    }
    
    


}
