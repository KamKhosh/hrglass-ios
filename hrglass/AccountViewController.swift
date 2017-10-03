//
//  AccountViewController.swift
//  hrglass
//
//  Created by Justin Hershey on 5/7/17.
//


import UIKit
import Firebase

class AccountViewController: UIViewController {

    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameLbl: UILabel!
    
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var usernameView: UIView!
    
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailLbl: UILabel!
    
    @IBOutlet weak var changePasswordView: UIView!
    
    @IBOutlet weak var privacySwitch: UISwitch!
    
    @IBOutlet weak var changePasswordHightlightView: UIView!
    @IBOutlet weak var privateView: UIView!
    
    @IBOutlet weak var blockedUsersView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var blockedAccountsHighlightView: UIView!
    var overlayView = UIView()
    
    let user = Auth.auth().currentUser
    let ref: DatabaseReference = Database.database().reference()
    var currentUserRef: DatabaseReference!
    


    
    
    /*********************************
     *
     * ---------- LIFECYCLE ---------
     *
     *********************************/
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        currentUserRef = ref.child("Users").child((self.user?.uid)!)
        
        self.navigationBar.frame.size = CGSize(width: self.view.frame.width, height: 80)
        self.navigationBar.backgroundColor = UIColor.white
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        self.navigationBar.shadowImage = UIImage()

        let changePasswordTap = UITapGestureRecognizer(target: self, action:  #selector (self.changePasswordAction))
        self.changePasswordView.addGestureRecognizer(changePasswordTap)
        
        let blockedUsersTap = UITapGestureRecognizer(target: self, action:  #selector (self.blockedUsersAction))
        self.blockedUsersView.addGestureRecognizer(blockedUsersTap)
        
        self.setupView()

    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        //ACCOUNT INFO FROM UserDefaults
        if let data: NSDictionary = UserDefaults.standard.value(forKey: "userData") as? NSDictionary{
            
            let name = data.value(forKey:"name") as? String
            let email = data.value(forKey:"email")as? String
            let username = data.value(forKey:"username") as? String
            let isPrivate = data.value(forKey:"isPrivate") as? Bool
            
            self.nameLbl.text = name
            self.emailLbl.text = email
            self.usernameLbl.text = username
            self.privacySwitch.isOn = isPrivate!
            
            
        }
        
        
        
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*********************************
     *
     * ---------- ACTIONS ---------
     *
     *********************************/
    
    @IBAction func privacySwitchAction(_ sender: Any) {
        
        if privacySwitch.isOn{
            
            currentUserRef.child("isPrivate").setValue(true)
            updateLocalPrivateBool(isPrivate: true)
            
        }else{
            currentUserRef.child("isPrivate").setValue(false)
            updateLocalPrivateBool(isPrivate: false)
            
        }
    }
    
    
    //Update UserDefaults to Reflect Private Change
    
    func updateLocalPrivateBool(isPrivate: Bool){
        
        
        let data: NSDictionary = UserDefaults.standard.dictionary(forKey: "userData")! as NSDictionary
        
        
        let tempDict: NSMutableDictionary = data.mutableCopy() as! NSMutableDictionary
        tempDict.setValue(isPrivate, forKey: "isPrivate")
        
        UserDefaults.standard.set(tempDict, forKey: "userData")
        UserDefaults.standard.synchronize()
        
    }
    
    
    
    
    /***********************************
     *
     * --------- SELECTORS ------------
     *
     **********************************/
    
    func blockedUsersAction(){
        
        let blockedAccountsView = self.storyboard?.instantiateViewController(withIdentifier: "blockedAccountsView") as! BlockedAccountsViewController
        
        self.navigationController?.pushViewController(blockedAccountsView, animated: true)

    }
    
    

    func changePasswordAction(){
        
        if (Auth.auth().currentUser?.providerID == "Firebase" ){
            
            self.performSegue(withIdentifier: "toChangePasswordSegue", sender: nil)
            
        }else{
            
            let alert = UIAlertController(title: "Facebook Account linked", message: "Cannot change password", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(defaultAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    
    
    /*********************************
     *
     * ---- SEPERATOR LINES -----
     *
     ********************************/
    
    
    func setupView(){
        
        self.addBottomLine(forView: nameView)
        self.addBottomLine(forView: usernameView)
        self.addBottomLine(forView: emailView)
        self.addBottomLine(forView: changePasswordView)
        self.addBottomLine(forView: privateView)
        self.addBottomLine(forView: blockedUsersView)
        
        self.nameLbl.text = self.user?.displayName
    }
    
    
    func addBottomLine(forView: UIView){
        
        let view = UIView(frame:CGRect(x:forView.frame.minX, y:forView.frame.maxY, width:forView.frame.width,height:1.0))
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1.0
        
        self.contentView.addSubview(view)
        
    }

    
    
    
    /***************************
     *
     * ------ NAVIGATION -----
     *
     ***************************/
    
    
    
    
    @IBAction func unwindToAccountsView(unwindSegue: UIStoryboardSegue){
        
        
    }
    
    
    


}
