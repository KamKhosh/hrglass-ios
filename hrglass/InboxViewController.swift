//
//  InboxViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 7/31/17.
//
//

import UIKit
import Firebase

class InboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var noReqLbl: UILabel! = nil
    var loggedInUser: User!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var messagesInboxArray: NSMutableArray = []
    
    var selectedData: NSDictionary!
    var selectedUserId: String = ""
    
    var imageCache: ImageCache = ImageCache()
    
    let dataManager: DataManager = DataManager()
    
    let uid: String = (Auth.auth().currentUser?.uid)!
    var tableData: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.noReqLbl = UILabel(frame: CGRect(x: 0, y:self.navigationBar.frame.maxY + 20 , width: self.view.frame.width, height: 30))
        self.noReqLbl.text = "No Messages"
        self.noReqLbl.textAlignment = .center
        self.noReqLbl.textColor = UIColor.lightGray
        self.noReqLbl.isHidden = true
        self.view.addSubview(self.noReqLbl)
        
        
        self.getInboxData()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    

    
    
    /**********************************************************
     *
     *          TABLE VIEW DELEGATE / DATASOURCE
     *
     **********************************************************/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var count: Int = 0;

        
        count = self.messagesInboxArray.count
        
        if count == 0{
            
            self.noReqLbl.text = "No Messages"
            self.noReqLbl.isHidden = false
        }else{
            self.noReqLbl.isHidden = true
        }
        
        return count
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: InboxTableViewCell = tableView.dequeueReusableCell(withIdentifier: "inboxCell") as! InboxTableViewCell
        
        let inbox: NSDictionary = self.messagesInboxArray[indexPath.row] as! NSDictionary
        
        let photoString: String = inbox.value(forKey: "photoUrl") as! String
        
        
        if (photoString != ""){
            
            self.imageCache.getImage(urlString: photoString, completion: { image in
                
                cell.profImageView.image = image
            })
            
        }else{
            cell.profImageView.image = self.dataManager.defaultsUserPhoto
        }
        
        cell.nameLbl.text = inbox.value(forKey: "name") as? String
        
        let messagesId: String = inbox.value(forKey: "objectId") as! String
        
        self.dataManager.getLatestMessageText(objectId: messagesId, completion: { (
            body) in
            if (body != ""){
                
                cell.messageLbl.text = body
            }
        })
        
        return cell
        
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        self.selectedData = self.messagesInboxArray[indexPath.row] as! NSDictionary
        
        
        self.performSegue(withIdentifier: "toMessagesView", sender: self)
        
    }
    

    

    
    
    
    func getInboxData(){
        
        self.dataManager.getInboxList { (list) in
            
            for (_, dict) in list{
                
                self.messagesInboxArray.add(dict)
            }
            
            self.tableView.reloadData()
            if list.count == 0{
            }
        }
    }
    
    

    
    
    
    @IBAction func unwindToInbox(unwindSegue: UIStoryboardSegue) {
        
        
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toMessagesView"{
            
            let messageVC: MessagesViewController = segue.destination as! MessagesViewController
            messageVC.messagesId = self.selectedData.value(forKey: "objectId") as! String
            messageVC.parentView = "inbox"
            messageVC.loggedInUser = self.loggedInUser
            messageVC.nameString = (self.selectedData.value(forKey: "name") as? String)!
            messageVC.selectedUserId = self.selectedData.value(forKey: "uid") as? String
        }
    }
    
}
